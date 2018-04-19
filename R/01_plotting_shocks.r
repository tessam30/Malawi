# Project: Malawi CDCS Geographic Trends Analysis
# Date: 2018_04_18
# Author: Tim Essam
# Dependencies: Stata output that is from the shock modules; District averages splayed 


# reshape shock data for plotting

library(tidyverse)
library(haven)
library(here)
library(readxl)
library(llamar)
#devtools::install_github("flaneuse/llamar")


shocks_2011 <- read_csv(here("Dataout/shocks_district_2011.csv"))
#shocks_2016 <- read_csv(here("Dataout/shocks_district_2016.csv"))

shocks_2011_long <- shocks_2011 %>% 
  gather(ag:foodprice, key = "shock", value = "value") %>% 
  mutate(district_fct = factor(district))

# Checking levels to ensure that districts are sorted in the order you want -- think about this for upstream processing too
levels(shocks_2011_long$district_sort)
str(shocks_2011_long)


shocks_2011_long %>% 
  mutate(sortvar = fct_reorder(district_fct, value)) %>% 
  ggplot(., aes(x = value, y = sortvar, colour = shock)) +
  geom_point() +
  facet_wrap(~shock) +
 theme_bw()
