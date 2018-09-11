# Calculate fire management zone thresholds
library(tidyverse)
library(sf)
library(velox)
library(raster)
library(spatial.tools)
library(foreach)
library(doParallel)

# Setup
source("../config/global_config.r")
source("../config/config_linux.r")
source("fire_cell_function.r")

log_it("Starting fire management zone analysis")
### Load rasters
log_it("Loading year list")
year_list = read_csv(paste0(rast_temp,"/yearlist.csv"))
file_list = paste0(rast_temp,"/",year_list$year,".tif")
int_list = year_list$year


log_it("Loading template raster")
tmprast = raster(paste0(rast_temp,"/rTimeSinceLast.tif"))

#### Read fire management zones
# Read fire history table and transform
log_it("Reading fire management zones, projecting and repairing")
v_fmz= read_sf(asset_gdb,i_vt_fmz)
v_fmz = st_transform(v_fmz,crs=proj_crs)
v_fmz = st_cast(v_fmz,"MULTIPOLYGON") # Multisurface features cause errors
v_fmz = st_make_valid(v_fmz) # repair invalid geometries
log_it("Fire management zone import complete")


log_it("Loading region boundary")
v_thisregion = read_sf(paste0(rast_temp,"/v_region.gpkg"))

log_it("Clipping fire management zone to ROI")
v_fmz = st_intersection(v_fmz,v_thisregion)
log_it("Clipping  fire management zone complete")

log_it("Extracting SFAZ polygons")
v_sfaz = filter(v_fmz,(!!rlang::sym(f_fmz)) == c_sfaz)

log_it("Repairing SFAZ polygons")
v_sfaz = st_make_valid(v_sfaz)

log_it("Writing SFAZ polygons")
write_sf(v_sfaz,paste0(rast_temp,"/v_sfaz.gpkg"))

log_it("Rasterizing SFAZ polygons")
rex = paste(extent(tmprast)[c(1,3,2,4)],collapse=" ")
rres = res(tmprast)
#cmd = paste0(gdal_rasterize," -burn 1 -l year_fire -of GTiff ",
#             "-te ",rex," -tr ",rres[1]," ",rres[2]," -ot byte -co COMPRESS=PACKBITS ",
#            paste0(rast_temp,"/","year_fire.gpkg")," ",paste0(rast_temp,"/",int_list[yr],".tif"))
cmd = g_rasterize("v_sfaz","v_sfaz.gpkg",paste0(rast_temp,"/r_fmz.tif"),attribute="")
system(cmd)
unlink(paste0(rast_temp,"/v_fmz.gpkg"))
log_it("Finished rasterizing SFAZ layer")

log_it("Loading time since fire vector layer")
v_tsl = read_sf(paste0(rast_temp,"/v_tsl.gpkg"))

log_it("Intersecting SFAZ and TSF layers")
v_tsl_sfaz = st_intersection(v_sfaz,v_tsl)

log_it("Generating SFAZ threshold class")
v_tsl_sfaz$SFAZStatus = 0

# Status
v_tsl_sfaz= v_tsl_sfaz %>% mutate(SFAZStatus = case_when(TSL<=6 ~ 6,
                                         TSL >6 & TSL <= 10 ~ 7,
                                         TSL >10 ~ 8))

v_tsl_sfaz$SFAZStatusText = ""
v_tsl_sfaz= v_tsl_sfaz %>% mutate(SFAZStatusText = case_when(TSL<=6 ~ "Recently Treated",
                                                         TSL >6 & TSL <= 10 ~ "Monitor OFH in the field",
                                                         TSL >10 ~ "Priority for Assessment and Treatment"))

log_it("Writing SFAZ threshold polygons")
v_tsl_sfaz = v_tsl_sfaz %>% st_cast("MULTIPOLYGON")
v_tsl_sfaz = filter(v_tsl_sfaz,as.numeric(st_area(v_tsl_sfaz))>0)

log_it("Saving SFAZ threshold polygons")
write_sf(v_tsl_sfaz,paste0(rast_temp,"/v_tsl_sfaz.gpkg"))
log_it("SFAZ thresholds saved. Cleaning up")

log_it("Rasterizing SFAZ categories")
rex = paste(extent(tmprast)[c(1,3,2,4)],collapse=" ")
rres = res(tmprast)
cmd = g_rasterize("v_tsl_sfaz","v_tsl_sfaz.gpkg",paste0(rast_temp,"/r_tsl_sfaz.tif"),attribute="SFAZStatus")
system(cmd)

log_it("Loading SFAZ raster")
r_tsl_sfaz = raster(paste0(rast_temp,"/r_tsl_sfaz.tif"))
log_it("Loading biodiversity and fire zone raster")
r_fmz_bio = raster(paste0(rast_temp,"/r_fmz_bio_out.tif"))

log_it("Merging SFAZ to combined raster")
beginCluster(clustNo)


c_func = function(x,y){ifelse(x==0,y,x)}
s = stack(r_tsl_sfaz,r_fmz_bio)
invisible(capture.output(r_comb <- clusterR(s,overlay,args=list(fun=c_func))))
s <- NULL
rm(s)
gc()

endCluster()

log_it("Saving SFAZ - FMZ - Heritage combined raster")
bigWrite(r_comb,paste0(rast_temp,"/r_sfaz_fmz_bio_out.tif"))

#####################
log_it("Vectorizing SFAZ - FMZ - Heritage combined categories")

#r_comb = raster(paste0(rast_temp,"/r_sfaz_fmz_bio_out.tif"))
log_it("Converting SFAZ - FMZ - Heritage raster to polygons")

if(OS == "Windows"){
v_sfaz_all_out = polygonizer_win(r_comb,
                           pypath="C:/OSGeo4W64/bin/gdal_polygonize.py")
}else{
  v_sfaz_all_out = polygonizer(r_comb)
}

v_sfaz_all_out = st_as_sf(v_sfaz_all_out)
st_crs(v_sfaz_all_out)=proj_crs

log_it("Dissolving  SFAZ - FMZ - Heritage polygons")
v_sfaz_all_out = v_sfaz_all_out %>% st_cast("MULTIPOLYGON") #%>% group_by(DN) %>% summarise()




log_it("Repairing  SFAZ - FMZ - Heritage polygons")
v_sfaz_all_out = filter(v_sfaz_all_out,as.numeric(st_area(v_sfaz_all_out))>0)

v_sfaz_all_out = st_make_valid(v_sfaz_all_out)


log_it("Clipping to region of interest")
v_thisregion = read_sf(paste0(rast_temp,"/v_region.gpkg"))
v_sfaz_all_out = st_intersection(v_sfaz_all_out,v_thisregion)


t_threshold=tibble(DN=c(1,2,3,4,5,9,6,7,8,NA),
                   FinalStatus = c("NoFireRegime",
                                 "TooFrequentlyBurnt",
                                 "Vulnerable",
                                 "LongUnburnt",
                                 "WithinThreshold",
                                 "Unknown",
                                 "Recently Treated",
                                 "Monitor OFH In the Field",
                                 "Priority for Assessment and Treatment",NA))

log_it("Joining  SFAZ - FMZ - Heritage labels to polygons")
v_sfaz_all_out = left_join(v_sfaz_all_out,t_threshold)
v_sfaz_all_out$DN = NULL


log_it("Saving f SFAZ - FMZ - Heritage polygons")
write_sf(v_sfaz_all_out,paste0(rast_temp,"/v_sfaz_fmz_bio_out.gpkg"))
log_it(" SFAZ - FMZ - Heritage saved. Cleaning up")

log_it("Cleaning up")
r_comb <- NULL
rm(r_comb)
gc()

