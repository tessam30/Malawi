# Load in LAPA data and process for visualization in Talbeau
# Author: Tim Essam, PhD / GeoCenter
# Date: 2018_12_20

# Load data  --------------------------------------------------------------

# Captain's log, datadate: 2018_12_21: Data appear to be wrong in the final spreadsheet.
# Data that were "vetted" appear to be incorrect and deeply flawed.
# Aborting attempt to work w/ final table and will begin reconstruction process
# from the district data. 

read_path <- file.path(datapath, "LAPA District councils Results.xlsx")

# Here's the workflow we want
# 1. read in all the sheets using excel_sheets
# 2. store the name of the sheet in a dataframe column
# 3. use the sheet name in a purrr:map call to pass the name of the sheet to read
# 4. then use the read_path to point to the original file source
# 5. drop the TOTALS table as it's wrong, then clean up names and recalculate scores

lapa_raw <- data_frame(sheetname = excel_sheets(read_path)) %>% 
  mutate(file_contents = map(sheetname, ~read_excel(path = read_path, sheet = .x))) %>% 
  filter(sheetname != "TOTALS FOR ALL COUNCILS") %>% 
  unnest() %>% 
  
  # Drop empty cells because they provide no value
  select(-(X__1:X__12), -(X__14:X__18)) %>%
  rename(lapa_description = `DISTRICT COUNCIL PERFORMANCE ASSESSMENT AND MONITORING TOOL`,
         district = sheetname,
         score = `Consensus Score (CS)`) %>% 
  mutate(row_type = case_when(
    str_detect(lapa_description, "Description:") ~ "description",
    str_detect(lapa_description, "Key Performance Area") ~ "key_perform",
    str_detect(lapa_description, "Performance Standard") ~ "perf_standard",
    TRUE ~ lapa_description
  )) %>% 
  filter(row_type != "description") %>% 
  mutate(district = trimws(district)) %>% 
  
  # merge in district crosswalk info
  left_join(., mwi_cw, by = c("district" = "lapa_district")) %>% 
  
  # Need a filter so we are not double counting scores for districts where two columns
  # have values (Dedza)
  mutate(score_flag = ifelse(score == X__13 & !is.na(score) & score != 0, 1, 0),
         lapa_score = case_when(
           (score != X__13 & score_flag != 1) ~ rowSums(select(., score:X__13)),
           (is.na(score)) ~ X__13,
           TRUE ~ score),
         lapa_score = replace_na(lapa_score, 0),
         lapa_area = ifelse(row_type == "key_perform", lapa_description, NA_character_ )) 
# Some bug will not let me pipe after the case_when call, but code above works fine w/out %>%

lapa_raw_df <- 
  lapa_raw %>% 
  fill(lapa_area) %>% 
  select(CID, district, lapa_description, lapa_area, lapa_score, everything())

  # Start flagging strings to separate out categories
lapa_key_perform <- 
  lapa_raw_df %>% 
  filter(row_type == "key_perform") 
  
lapa_full_dist <- 
  lapa_raw_df %>% 
  filter(row_type == "perf_standard") %>% 
  group_by(lapa_area, district) %>% 
  mutate(lapa_area_score = sum(lapa_score, na.rm = TRUE)) %>% 
  ungroup() %>% 
  group_by(district) %>% 
  mutate(lapa_total_score = sum(lapa_score, na.rm = TRUE)) %>% 
  ungroup()

# plot the results in a map
lapa_full_dist %>% 
  group_by(district, CID) %>% 
  summarise(lapa = mean(lapa_total_score)) %>% 
  left_join(., mwi_geo, by = c("CID")) %>% 
  ggplot() +
  geom_sf(aes(fill = lapa), colour = "white", size = 0.5) +
  scale_fill_viridis_c(direction = -1, option = "A")

lapa_full_dist %>% 
  group_by(district, CID) %>% 
  summarise(lapa = mean(lapa_total_score)) %>% 
  ungroup() %>% 
  mutate(dist_sort = fct_reorder(district, lapa)) %>% 
  ggplot(aes(x = dist_sort, y = lapa, fill = lapa)) +
  geom_col() + coord_flip() +
  scale_fill_viridis_c(direction = -1, option = "A")

# Plot the Key performance results
lapa_full_dist %>%
  mutate(lapa_area_short = str_remove_all(lapa_area, "Key Performance Area")) %>% 
  group_by(district, lapa_area, lapa_area_short, CID) %>% 
  summarise(lapa_score = sum(lapa_score, na.rm = TRUE)) %>% 
  mutate(dist_sort = fct_reorder(district, lapa_score)) %>% 
  ggplot(aes(x = dist_sort, y = lapa_score, fill = lapa_score)) +
  geom_col() + coord_flip() +
  facet_wrap(~ lapa_area_short) +
  scale_fill_viridis_c(direction = -1, option = "A")
  
  
  left_join(., mwi_geo, by = c("CID")) %>% 
  ggplot() +
  geom_sf(aes(fill = lapa_score), colour = "white", size = 0.5) +
  scale_fill_viridis_c(direction = -1, option = "A") +
  facet_wrap(~lapa_area_short, nrow = 2)
  
  
  # Toggle below for bar graph
  mutate(dist_sort = fct_reorder(district, lapa_score)) %>% 
  ggplot(aes(x = dist_sort, y = lapa_score, fill = lapa_score)) +
    geom_col() + coord_flip() +
  facet_wrap(~ lapa_area_short) +
  scale_fill_viridis_c(direction = -1, option = "A")


# Write to a shapefile for Brent in case shut down goes on and on
lapa_sf <- lapa_full_dist %>%
    mutate(lapa_area_short = str_remove_all(lapa_area, "Key Performance Area")) %>% 
    group_by(district, lapa_area, lapa_area_short, CID) %>% 
    summarise(lapa_score_categ = sum(lapa_score, na.rm = TRUE)) %>% 
    group_by(district) %>% 
  mutate(lapa_score_total = sum(lapa_score_categ)) %>% 
  left_join(., mwi_geo, by = c("CID")) 
  
st_write(lapa_sf, file.path(gispath, "MWI_lapascores_full.shp"))
  
lapa_full_dist %>% 
  write_csv(., file.path(dataout, "MWI_LAPA_full_district.csv"))
 



# Discarded code due to data entry issues ---------------------------------

# 
# df_raw <- read_excel(file.path(datapath, "LAPA District councils Results.xlsx"), 
#                      sheet = "TOTALS FOR ALL COUNCILS") %>% 
#   select(-X__1, 
#          -X__2,
#          scores_descrip = "DISTRICT COUNCIL PERFORMANCE ASSESSMENT BASELINE SCORES", 
#          everything()) %>% 
#   mutate(category = ifelse(str_detect(scores_descrip, "Key Performance Area"), 1, 0),
#          dist_tot = ifelse(str_detect(scores_descrip, "TOTAL DISTRICT SCORES"), 1, 0),
#          area = gsub("Key Performance Area", "", scores_descrip)) %>% 
#   
#   # Set up text flag to use as a fill down that will allow for creating rollups
#   mutate(score_category = ifelse(category == 1, area, NA_character_),
#          score_category= sub("\\S+", "", score_category)) %>%
#   fill(score_category) %>% 
#   select(-(Nkhatabay:Nsanje), everything()) %>% 
#   select(-X__1, -X__2) %>% 
#   
#   # Reshape long to spot check averages, totals, etc
#   gather(., key = "district", value = "lapa_score", Nkhatabay:Nsanje) %>%
#   mutate(df_names = ifelse(category == 1, "lapa_tot", "lapa_dist")) %>% 
#   left_join(., mwi_geo_df, by = c("district" = "lapa_dist")) %>% 
#   select(CID, district, everything()) %>% 
#   select(-(GID_0:HASC_1))
# 
# # Set aside district totals for checking numbers
# dist_totals_df <- df_raw %>% filter(dist_tot == 1)
# 
# df_raw %>% 
#   filter(dist_tot != 1) %>% 
#   split(., .$df_names) %>% 
#   list2env(., envir = .GlobalEnv)
# 
# 
# # Flag any lapa scores that are greater than 4 for any row-category
# # M'Mbelwa and Karonga are wrong so we can throw out all the aggregated data
# # as it will be incorrect as well
# lapa %>% select(district, area, district, lapa_score) %>% 
#   filter(lapa_score > 4)
# 
# 
# lapa <- lapa_dist %>% 
#   mutate(lapa_score_flag = ifelse(lapa_score > 4, 1, 0),
#          lapa_score_mod = case_when(
#            district == "Karonga" & lapa_score_flag == 1 ~ 2,
#            district == "M'Mbelwa" & lapa_score_flag == 1 ~ 
#          )) 
# 
# %>% 
#   group_by(district, score_category) %>% 
#   mutate(categ_totals = sum(lapa_score, na.rm = TRUE)) %>% 
#   ungroup() %>% 
#   group_by(district) %>% 
#   mutate(district_score = sum(lapa_score, na.rm = TRUE)) %>% 
#   group_by(area) %>% 
#   mutate(individ_score_tot = sum(lapa_score, na.rm = TRUE)) %>% 
#   ungroup()
# 
# # Take a look at LAPA scores by category, sorting from overall greatest to smallest
# lapa %>% 
#   mutate(district_sort = fct_reorder(district, district_score)) %>% 
#   ggplot(aes(x = district, y = categ_totals)) +
#   geom_col() +
#   coord_flip() +
#   facet_wrap(vars(score_category))
# 
# 
# 
# 
# 
# s# Extract just totals
# lapa_totals <- df_raw %>% 
#   filter(category == 1)
# 
# # Notes - for each scores the max value is four. There are 28 districts in the data
