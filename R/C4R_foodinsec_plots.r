# Plot the number of food insecure by Malawi districts
# Date: 2018_06_08

library(tidyverse)
library(RColorBrewer)
library(readxl)
library(here)
library(ggridges)
library(llamar)
library(scales)
library(extrafont)
dir(here("Excel"))

df <- read_excel(str_c(here("Excel/"), "food_insecure_pop.xlsx"))

df <- df %>% 
  gather(., key = year, value = population, "2008":"2017") %>% 
  mutate(year = as.numeric(year),
         pre2014 = ifelse(year < 2014, "false", "true")) %>% 
  group_by(District) %>% 
  mutate(totals = sum(population, na.rm = TRUE)) %>% 
  ungroup() %>% 
  mutate(district_fct = as.factor(District),
         district_fct = fct_reorder(district_fct, - totals))


# Create a ridgeplot of the numbers over time, sorted by order
red2 <- "#caa099"
red1 <- "#ce7160"
p <- ggplot(df, aes(x = year, y = population)) +
  geom_bar(stat = "identity", aes(fill = pre2014)) +
  scale_fill_manual(values = c("false" = grey30K, "true" = red1)) +
  facet_wrap(~district_fct, ncol = 9) +
  scale_x_continuous(breaks = c(2008, 2012, 2016)) +
  scale_y_continuous(labels = comma) +
  labs(y = "food insecure population") +
  theme_ygrid(font_axis_label = 10,
               panel_spacing = 1) 
ggsave("MVAC_food_insecure_pop.pdf", 
       plot = p, 
       path = here("Graphics"),
       width = 10.775, 
       height = 7.27,
       units = c("in"))


