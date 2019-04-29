#######################################################%####
#                                                          #
####     Malawi Timeline Project                        ####
#                                                          #
##%######################################################%##

# Purpose: Gather, reshape and plot basic time events and stats
# Author: Tim Essam (code), Brent McCusker (data)
# Date: 2019_02_02
# Audience: Malawi Mission


# Load timeline data, reshape and create sample plots

# Load, injest and examine data -------------------------------------------

library(tidyverse)
library(rlang)
library(purrr)
library(readxl)
library(gridExtra)
library(RColorBrewer)
library(scales)
library(ggpubr)
library(ggrepel)
library(lubridate)
library(llamar)
library(extrafont)

excel_path <- c("Excel")
graph_path <- c("Graph")
excel_sheets(file.path(excel_path, "Malawi TImelines.xlsx"))

#df_bar <- read_excel(file.path(excel_path, "Malawi TImelines.xlsx"), sheet = "Bar Data")
#df_line <- read_excel(file.path(excel_path, "Malawi TImelines.xlsx"), sheet = "Line Data")
df_bar <- read_excel(file.path(excel_path, "Malawi TImelines_2019_02_11.xlsx"), sheet = "Bar Data")
df_line <- read_excel(file.path(excel_path, "Malawi TImelines_2019_02_11.xlsx"), sheet = "Line Data")

map(list(df_bar, df_line), str)

# Turn off scientific notation for now
options(scipen = 999)


# Basic function to do grouped summaries
group_count <- function(df, ...) {
  grouping <- enquos(...)
  
  df %>% group_by(!!!grouping) %>% 
    count() %>% 
    print(n = Inf)
  }


# Mutate and plot ---------------------------------------------------------
df_line_long <- 
  df_line %>% 
  select(date, everything()) %>% 
  mutate(MW_pop = MW_pop/1e6) %>% 
  gather(key = "indicator", value = "value", MW_econ_growth:MZ_ag_pct_GDP) %>% 
  
  # Use the 'extra' option within separate to keep indicator name together
  separate(indicator, into = c("Country", "Indicator"), extra = "merge") %>%
  mutate(Country = case_when(
    Country == "MW" ~ "Malawi", 
    Country == "ZB" ~ "Zambia",
    Country == "MZ" ~ "Mozambique",
    TRUE ~ NA_character_),
  flag = ifelse(Country == "Malawi", 1, 0))
  
df_line_long %>% group_by(Country, Indicator) %>%  count() %>% arrange(Indicator)


# Set break vector and limits so plots can be aligned
dat_seq <- seq(as.POSIXct("1960-01-01"),
               as.POSIXct("2020-01-01"), "10 years")
lims <- as.POSIXct(strptime(c("1960-01-01", "2020-01-01"), 
                            format = "%Y-%m-%d"))

# Check w/ a Gantt chart any potential overlap in events
bar_long <- df_bar %>%
  select(Start, End, everything()) %>% 
  mutate(Start = ymd(Start),
         End = ymd(End)) %>%
  gather(date_node, event_date, -c(Sector:Description2)) %>%
  arrange(date_node, event_date) %>%
  mutate(Event = fct_reorder(Event, event_date))

#Where to put dotted lines
bar_long %>% 
  filter(Sector == "AG POLICY") %>% # Ag POLICY has 16 overlapping events
ggplot(aes(x = Event, y = event_date, colour = Sector)) + 
  geom_line(size = 6) + 
  guides(colour = guide_legend(title = NULL)) +
  labs(x = NULL, y = NULL) + 
  coord_flip() +
  scale_y_date(date_breaks = "10 years", labels = date_format("%b ‘%y")) +
  facet_wrap(~Sector, scales = "free") 


# General line plot function ----------------------------------------------
# General function to make line plots of individual indicators in case they are needed
line_plot <- function(df, ...) {
  F <- quos(...)
  df %>% filter(!!!F) %>% 
    mutate(ylim = min(value)) %>% 
    ggplot(aes(x = date, y = value)) +
    geom_line(colour = grey50K) +
    scale_x_datetime(limits = lims,
                     labels = date_format("%Y")) +
    theme_minimal()
}
# Create plots of each indicator
df_line_long %>% split(.$Indicator) %>% 
  map(., ~line_plot(.))




# population is just of Malawi, so it will get a separate graph
line_plot(df_line_long, Indicator == "pop")

line_p <- df_line_long %>% 
  mutate(Country = fct_rev(Country)) %>% # Reversing order to Malawi is plotted last
  ggplot(., aes(x = date, y = value, group = Country)) +
  geom_line(aes(colour = Country)) +
  scale_x_datetime(
    breaks = seq(as.POSIXct("1960-01-01"), as.POSIXct("2020-01-01"), "10 years"),
    limits = lims,
    labels = date_format("%Y")
    ) +
  scale_color_manual(values = c(grey30K, grey30K, grey90K)) +
  facet_wrap(~Indicator, nrow = 4, scales = "free") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(caption = "Source: USAID GeoCenter gathered facts and figures")


# Bar plot of the events stacked - This will be combined w/ line graphs to form basis for graphic
bar_p <- df_bar %>% 
  ggplot(.) + 
  geom_rect(aes(xmin = Start, 
                xmax = End, 
                ymin = ymin, 
                ymax = ymax, 
                fill = Sector), 
            colour = "white") + 
  facet_wrap(~Sector, nrow = 6) +
  geom_text_repel(aes(x = Start + (End - Start)/2, 
                      y = ymin + (ymax - ymin)/2, 
                      label = Event_abbr), 
                  size = 3,
                  point.padding = NA,
                  family = "Lato Light") +
  theme_timeline() +
    scale_fill_viridis_d(alpha = 0.45) +
  scale_x_datetime(
    breaks = seq(as.POSIXct("1960-01-01"),
                 as.POSIXct("2020-01-01"), "10 years"),
    labels = date_format("%Y"),
    expand = c(0.05, 0.05),
    limits = lims) 
  
  
  
                   
# First iteration
mwi_tl <- ggarrange(bar_p, line_p, nrow = 2,
        align = "v") %>% 
  annotate_figure(., top = text_grob("Malawi: Historical Events Summarized"))  

  ggsave(file.path(graph_path, "MWI_timeline.pdf"), plot = mwi_tl,
                      dpi = 300, width = 18, height = 12, units = "in",
                      device = "pdf", scale = 2)
  
write_csv(df_bar, file.path("Data", "MWI_bar_graphdata.csv"))
write_csv(df_line_long, file.path("Data", "MWI_line_graphdata.csv"))

# Makes more sense to align some of the events with the indicator data. First
# let's align the economic events to the economic growth data

group_count(df_line_long, Indicator)

tst <- df_line_long %>% 
  left_join(., df_bar, by = c("date" = "Start", "Indicator" = "Sector")) %>% 
  # Fill in missing values so we can group by sector and replace min and max to match graph bounds
  fill(ymin, ymax) %>% 
  group_by(Indicator) %>% 
  mutate(ind_min = min(value), 
         ind_max = max(value)) %>% 
  ungroup()

# Try overlaying the bar plot on the indicator plot
tst %>% 
  filter(Indicator == "econ_growth") %>% 
  mutate(ymin = min(Indicator), 
         ymax = max(Indicator)) %>% 
  ggplot(.) + 
  geom_rect(aes(xmin = date, 
                xmax = End, 
                ymin = ind_min, 
                ymax = ind_max, 
                fill = Event), 
            colour = "white") +
  geom_line(aes(x = date, y = value)) +
  theme_minimal() +
  scale_fill_viridis_d(alpha = 0.25) +
  scale_x_datetime(
    breaks = seq(as.POSIXct("1960-01-01"),
                 as.POSIXct("2020-01-01"), "10 years"),
    labels = date_format("%Y"),
    expand = c(0.05, 0.05),
    limits = lims)
  
