# Purpose: Load LAPA data and clean up
# Author: Tim Essam, Ph.D | USAID GeoCenter
# Date: 2018_12_20
# Audience: USAID Malawi


# Load data and any packages needed ---------------------------------------
pacman::p_load("tidyverse", "lubridate", "sf", "extrafont", "readxl", "measurements", "pdftools", "purrr", "styler", "scales", "llamar", "haven", "data.table")


datapath <- "Data"
dataout <- "Data/Dataout"
dhspath <- "DHS"
gispath <- "Data/GIS"
excelpath <- "Excel"
graphpath <- "Graph"
rpath <- "R"


#Source helper functions
file_list <- list("strip_geom.R", 
                  "helper_functions.R",
                  "MWI_geo_cw.R")

# Source custom scripts and data needed for project
file_list %>% 
  map(~source(file.path(rpath, .)))
rm(file_list)



# Set up base GIS file and establish ISO-numeric crosswalk codes for districts

mwi_geo <- read_sf(file.path(gispath, "gadm36_MWI_shp", "gadm36_MWI_1.shp")) %>% 
  mutate(CID = gsub("MWI.", "", GID_1), 
         CID = gsub("_1", "", CID), 
         CID = as.numeric(CID))

mwi_geo %>% 
  ggplot() +
  geom_sf(aes(fill = REGCODE))

mwi_geo_df <- strip_geom(mwi_geo, everything()) %>% 
  left_join(., mwi_cw, by = c("CID" = "CID"))
