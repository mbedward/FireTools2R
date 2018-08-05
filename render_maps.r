# Render maps
library(tidyverse)
library(sf)
library(raster)
library(tmap)
library(tmaptools)
library(htmlwidgets)

source("../config/global_config.r")
source("../config/config_linux.r")
source("fire_cell_function.r")

# Set up output folders
dir.create(paste0(rast_temp,"/maps"))

# Plot biodiversity map
v = read_sf(paste0(rast_temp,"/v_vegout.gpkg"))
v = dplyr::select(v,BioStatus)
v <-v %>%  mutate(color = case_when(BioStatus=="NoFireRegime" ~ "#ffffff22",
                              BioStatus=="TooFrequentlyBurnt" ~ "#ff000099",
                              BioStatus=="Vulnerable" ~ "#ff660099",
                              BioStatus=="WithinThreshold" ~ "#99999999",
                              BioStatus=="LongUnburnt" ~ "#00ffff99",
                              BioStatus=="Unknown" ~ "#cccccc99"
                              ))

            
tm = tm_shape(v,name="Heritage Threshold Status") +
  tm_fill(col="color",
          style="cat",
          alpha = 0.7,
          title=paste0("Heritage Threshold Status ",current_year))+
  tm_add_legend(type="fill",labels=c("NoFireRegime","TooFrequentlyBurnt","Vulnerable","WithinThreshold","LongUnburnt",
                                     "Unknown","Recently Treated","Monitor OFH In the Field","Priority for Assessment and Treatment"),
                col=c("white","red","orange","grey","cyan","grey20","lightgreen","darkgreen","green"))+
  tm_view(view.legend.position=c("right","top"))+ 
  tm_basemap(server = c(NSW="http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/tile/{z}/{y}/{x}",
                        Aerial = "http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Imagery/MapServer/tile/{z}/{y}/{x}"))



lf = tmap_leaflet(tm)


out_path = paste0(rast_temp,"/maps/heritage.html")
saveWidgetFix(lf, file=out_path,selfcontained = FALSE)



# Plot fmz map
v = read_sf(paste0(rast_temp,"/v_fmzout.gpkg"))
v = dplyr::select(v,FMZStatus)
v <-v %>%  mutate(color = case_when(FMZStatus=="NoFireRegime" ~ "#ffffff22",
                                    FMZStatus=="TooFrequentlyBurnt" ~ "#ff000099",
                                    FMZStatus=="Vulnerable" ~ "#ff660099",
                                    FMZStatus=="WithinThreshold" ~ "#99999999",
                                    FMZStatus=="LongUnburnt" ~ "#00ffff99",
                                    FMZStatus=="Unknown" ~ "#cccccc99"
))


tm = tm_shape(v,name="Fire Management Blocks Threshold Status") +
  tm_fill(col="color",
          style="cat",
          alpha = 0.7,
          title=paste0("Fire Management Blocks Threshold Status ",current_year))+
  tm_add_legend(type="fill",labels=c("NoFireRegime","TooFrequentlyBurnt","Vulnerable","WithinThreshold","LongUnburnt",
                                     "Unknown","Recently Treated","Monitor OFH In the Field","Priority for Assessment and Treatment"),
                col=c("white","red","orange","grey","cyan","grey20","lightgreen","darkgreen","green"))+
  tm_view(view.legend.position=c("right","top"))+ 
  tm_basemap(server = c(NSW="http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/tile/{z}/{y}/{x}",
                        Aerial = "http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Imagery/MapServer/tile/{z}/{y}/{x}"))



lf = tmap_leaflet(tm)



out_path = paste0(rast_temp,"/maps/fmz.html")
saveWidgetFix(lf, file=out_path,selfcontained = FALSE)




# Plot SFAZ map
v = read_sf(paste0(rast_temp,"/v_tsl_sfaz.gpkg"))
v = dplyr::select(v,SFAZStatusText)
v <-v %>%  mutate(color = case_when(SFAZStatusText=="NoFireRegime" ~ "#ffffff22",
                                    SFAZStatusText=="TooFrequentlyBurnt" ~ "#ff000099",
                                    SFAZStatusText=="Vulnerable" ~ "#ff660099",
                                    SFAZStatusText=="WithinThreshold" ~ "#99999999",
                                    SFAZStatusText=="LongUnburnt" ~ "#00ffff99",
                                    SFAZStatusText=="Unknown" ~ "#cccccc99",
                                    SFAZStatusText=="Recently Treated" ~ "#99FF9999",
                                    SFAZStatusText=="Monitor OFH In the Field" ~ "#22662299",
                                    SFAZStatusText=="Priority for Assessment and Treatment" ~ "#00ff0099"
))


tm = tm_shape(v,name="SFAZ Treatment Status") +
  tm_fill(col="color",
          style="cat",
          alpha = 0.7,
          title=paste0("SFAZ Treatment Status ",current_year))+
  tm_add_legend(type="fill",labels=c("NoFireRegime","TooFrequentlyBurnt","Vulnerable","WithinThreshold","LongUnburnt",
                                     "Unknown","Recently Treated","Monitor OFH In the Field","Priority for Assessment and Treatment"),
                col=c("white","red","orange","grey","cyan","grey20","lightgreen","darkgreen","green"))+
  tm_view(view.legend.position=c("right","top"))+ 
  tm_basemap(server = c(Topography="http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/tile/{z}/{y}/{x}",
                        Aerial = "http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Imagery/MapServer/tile/{z}/{y}/{x}"))



lf = tmap_leaflet(tm)


out_path = paste0(rast_temp,"/maps/sfaz.html")
saveWidgetFix(lf, file=out_path,selfcontained = FALSE)


# Plot SFAZ + fmz + bio map
v = read_sf(paste0(rast_temp,"/v_sfaz_fmz_bio_out.gpkg"))
v = dplyr::select(v,FinalStatus)
v <-v %>%  mutate(color = case_when(FinalStatus=="NoFireRegime" ~ "#ffffff22",
                                    FinalStatus=="TooFrequentlyBurnt" ~ "#ff000099",
                                    FinalStatus=="Vulnerable" ~ "#ff660099",
                                    FinalStatus=="WithinThreshold" ~ "#99999999",
                                    FinalStatus=="LongUnburnt" ~ "#00ffff99",
                                    FinalStatus=="Unknown" ~ "#cccccc99",
                                    FinalStatus=="Recently Treated" ~ "#99FF9999",
                                    FinalStatus=="Monitor OFH In the Field" ~ "#22662299",
                                    FinalStatus=="Priority for Assessment and Treatment" ~ "#00ff0099"
))


tm = tm_shape(v,name="Heritage Fire Blocka and SFAZ Status") +
  tm_fill(col="color",
          style="cat",
          alpha = 0.7,
          title=paste0("Heritage Fire Block and SFAZ Status ",current_year))+
  tm_add_legend(type="fill",labels=c("NoFireRegime","TooFrequentlyBurnt","Vulnerable","WithinThreshold","LongUnburnt",
                                     "Unknown","Recently Treated","Monitor OFH In the Field","Priority for Assessment and Treatment"),
                col=c("white","red","orange","grey","cyan","grey20","lightgreen","darkgreen","green"))+
  tm_view(view.legend.position=c("right","top"))+ 
  tm_basemap(server = c(NSW="http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/tile/{z}/{y}/{x}",
                        Aerial = "http://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Imagery/MapServer/tile/{z}/{y}/{x}"))



lf = tmap_leaflet(tm)


out_path = paste0(rast_temp,"/maps/sfaz_fmz_bio.html")
saveWidgetFix(lf, file=out_path,selfcontained = FALSE)


