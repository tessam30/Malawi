# Load in LAPA data and process for visualization in Talbeau
# Author: Tim Essam, PhD / GeoCenter
# Date: 2018_12_20



# Load data  --------------------------------------------------------------
df_raw <- read_excel(file.path(datapath, "LAPA District councils Results.xlsx"), 
                     sheet = "TOTALS FOR ALL COUNCILS") %>% 
  select(-X__1, 
         -X__2,
         scores_descrip = "DISTRICT COUNCIL PERFORMANCE ASSESSMENT BASELINE SCORES", 
         everything()) %>% 
  mutate(category = ifelse(str_detect(scores_descrip, "Key Performance Area"), 1, 0),
         area = gsub("Key Performance Area", "", scores_descrip)) %>% 
  
  # Set up text flag to use as a fill down that will allow for creating rollups
  mutate(score_category = ifelse(category == 1, area, NA_character_),
         score_category= sub("\\S+", "", score_category)) %>%
  fill(score_category) %>% 
  select(-(Nkhatabay:Nsanje), everything()) %>% 
  select(-X__1, -X__2) %>% 
  
  # Reshape long to spot check averages, totals, etc
  gather(., key = "district", value = "lapa_score", Nkhatabay:Nsanje) %>%
  mutate(df_names = ifelse(category == 1, "lapa_tot", "lapa_dist")) %>% 
  left_join(., mwi_geo_df, by = c("district" = "lapa_dist"))

df_raw %>% 
  split(., .$df_names) %>% 
  list2env(., envir = .GlobalEnv)

lapa_dist_geo <- 
  lapa_dist %>% 
  left_join(., mwi_geo_df, by = c("district" = "NAME_1"))






s# Extract just totals
lapa_totals <- df_raw %>% 
  filter(category == 1)

# Notes - for each scores the max value is four. There are 28 districts in the data
