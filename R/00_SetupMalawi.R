# Purpose: Load LAPA data and clean up
# Author: Tim Essam, Ph.D | USAID GeoCenter
# Date: 2018_12_20
# Audience: USAID Malawi


# Load data and any packages needed ---------------------------------------
pacman::p_load("tidyverse", "lubridate", "sf", "extrafont", "readxl", "measurements", "pdftools", "purrr", "styler", "scales", "llamar", "haven", "sjlabelled", "vtable", "sjmisc", "survey", "data.table")



datapath <- "Data"
dhspath <- "DHS"
gispath <- "Data/GIS"
excelpath <- "Excel"
graphpath <- "Graph"
rpath <- "R"

source(file.path(rpath , "strip_geom.R"))

# Set up base GIS file and establish ISO-numeric crosswalk codes for districts

mwi_geo <- read_sf(file.path(gispath, "gadm36_MWI_shp", "gadm36_MWI_1.shp")) %>% 
  mutate(CID = gsub("MWI.", "", GID_1), 
         CID = gsub("_1", "", CID))

mwi_geo %>% 
  ggplot() +
  geom_sf(aes(fill = REGCODE))

mwi_geo_df <- strip_geom(mwi_geo, everything())
