# Load in LAPA data and process for visualization in Talbeau
# Author: Tim Essam, PhD / GeoCenter
# Date: 2018_12_20



# Load data  --------------------------------------------------------------



# Captain's log 2018_12_21: Data appear to be wrong in the final spreadsheet.
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
  unnest()

  
  lapa_raw %>% filter(sheetname = ) 

%>% 
  rename(district = sheetname,
         lapa_categ = `Nkatabay Local Authority Performance Assessment Scores`) %>% 
  select(district, lapa_categ, X__13, X__14) %>% 
  mutate(score_line = ifelse(str_detect(X__13, "Consensus Score"), 1, 0),
         performance_area = ifelse(str_detect(lapa_categ, "Key Performance Area "), 1, 0),
         remove_flag = ifelse(str_detect(lapa_categ, "Description:"), 1, 0),
         lapa_fill = ifelse(performance_area == 1, lapa_categ, NA_character_), 
         district = trimws(district)) 

%>% 
  fill(lapa_fill)

%>% 
  # because X__13 is missing for a few rows, the score_line flag is missing as well
  filter(score_line != 1 | is.na(score_line)) %>% 
  filter(remove_flag !=1 | is.na(remove_flag))

lapa_raw %>% 
  mutate(df_names = ifelse(performance_area == 1, "key_perform", "key_perform_subcateg")) %>% 
  split(., .$df_names) %>% 
  list2env(., envir = .GlobalEnv)

lapa_full <- 
  key_perform_subcateg %>% 
  mutate(X__13 = as.numeric(X__13)) %>% 
  mutate(lapa_score = rowSums(select(., contains("__1")), na.rm = TRUE)) %>% 
  select(district, 
         lapa_categ,
         key_perform = lapa_fill, 
         lapa_score,
         everything())

write_csv(lapa_full, file.path(dataout, "tmp.csv"))

lapa_full %>% group_by(district) %>% summarise(tmp = sum(lapa_score))


%>% 
  group_by(district) %>% 
  mutate(lapa_score_total = sum(lapa_score, na.rm = TRUE))
        
lapa_full %>% 
  group_by(district) %>% 
  summarise_at(vars(lapa_score), sum, na.rm = TRUE) %>% 
  print(n = Inf)


str(lapa_raw)






r

# Need to only read columms A, N and O
# Write everything into a list
lapa_raw <- excel_sheets(read_path) %>%
  set_names() %>%
  map(read_excel, path = read_path)

# Remove last element of the list b/c the data are wrong
lapa_raw$`TOTALS FOR ALL COUNCILS` <- NULL
lapa_raw %>% reduce(rbind)




# Discarded code due to data entry issues ---------------------------------


df_raw <- read_excel(file.path(datapath, "LAPA District councils Results.xlsx"), 
                     sheet = "TOTALS FOR ALL COUNCILS") %>% 
  select(-X__1, 
         -X__2,
         scores_descrip = "DISTRICT COUNCIL PERFORMANCE ASSESSMENT BASELINE SCORES", 
         everything()) %>% 
  mutate(category = ifelse(str_detect(scores_descrip, "Key Performance Area"), 1, 0),
         dist_tot = ifelse(str_detect(scores_descrip, "TOTAL DISTRICT SCORES"), 1, 0),
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
  left_join(., mwi_geo_df, by = c("district" = "lapa_dist")) %>% 
  select(CID, district, everything()) %>% 
  select(-(GID_0:HASC_1))

# Set aside district totals for checking numbers
dist_totals_df <- df_raw %>% filter(dist_tot == 1)

df_raw %>% 
  filter(dist_tot != 1) %>% 
  split(., .$df_names) %>% 
  list2env(., envir = .GlobalEnv)


# Flag any lapa scores that are greater than 4 for any row-category
# M'Mbelwa and Karonga are wrong so we can throw out all the aggregated data
# as it will be incorrect as well
lapa %>% select(district, area, district, lapa_score) %>% 
  filter(lapa_score > 4)


lapa <- lapa_dist %>% 
  mutate(lapa_score_flag = ifelse(lapa_score > 4, 1, 0),
         lapa_score_mod = case_when(
           district == "Karonga" & lapa_score_flag == 1 ~ 2,
           district == "M'Mbelwa" & lapa_score_flag == 1 ~ 
         )) 

%>% 
  group_by(district, score_category) %>% 
  mutate(categ_totals = sum(lapa_score, na.rm = TRUE)) %>% 
  ungroup() %>% 
  group_by(district) %>% 
  mutate(district_score = sum(lapa_score, na.rm = TRUE)) %>% 
  group_by(area) %>% 
  mutate(individ_score_tot = sum(lapa_score, na.rm = TRUE)) %>% 
  ungroup()

# Take a look at LAPA scores by category, sorting from overall greatest to smallest
lapa %>% 
  mutate(district_sort = fct_reorder(district, district_score)) %>% 
  ggplot(aes(x = district, y = categ_totals)) +
  geom_col() +
  coord_flip() +
  facet_wrap(vars(score_category))





s# Extract just totals
lapa_totals <- df_raw %>% 
  filter(category == 1)

# Notes - for each scores the max value is four. There are 28 districts in the data
