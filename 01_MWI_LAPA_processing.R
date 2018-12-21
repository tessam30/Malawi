# Load in LAPA data and process for visualization in Talbeau
# Author: Tim Essam, PhD / GeoCenter
# Date: 2018_12_20



# Load data  --------------------------------------------------------------

df_raw <- read_excel(file.path(datapath, "LAPA District councils Results.xlsx"), 
                     sheet = "TOTALS FOR ALL COUNCILS") %>% 
  select(-X__1, 
         -X__2,
         scores = "DISTRICT COUNCIL PERFORMANCE ASSESSMENT BASELINE SCORES", 
         everything()) %>% 
  mutate(category = ifelse(str_detect(scores, "Key Performance Area"), 1, 0),
         area = gsub("Key Performance Area", "", scores)) %>% 
  select(scores, category, area, everything(), -X__1, - X__2)

# Notes - for each scores the max value is four. There are 28 districts in the data
