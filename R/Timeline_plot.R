# Load timeline data, reshape and create sample plots

library(tidyverse)
library(purrr)
library(readxl)
library(gridExtra)
library(RColorBrewer)
library(scales)

excel_path <- c("Excel")
excel_sheets(file.path(excel_path, "Malawi TImelines.xlsx"))

df_bar <- read_excel(file.path(excel_path, "Malawi TImelines.xlsx"), sheet = "Bar Data")
df_line <- read_excel(file.path(excel_path, "Malawi TImelines.xlsx"), sheet = "Line Data")

map(list(df_bar, df_line), str)

df_line_long <- 
  df_line %>% 
  gather(key = "indicator", value = "value", econ_growth:ag_pct_GDP) %>% 
  mutate(country = "Malawi")

lims <- as.POSIXct(strptime(c("1964-01-01","2017-01-01"), format = "%Y-%m-%d"))   

# Set break vector

end <- max(df_line_long$date) %>% as.Date()
beg <- min(df_line_long$date) %>% as.Date()

line <- df_line_long %>% 
  ggplot(aes(x = date, y = value)) + 
  geom_line() +
  facet_wrap(~indicator, scale = "free",
             nrow =4 ) +
  theme_minimal() 



bar <- ggplot(df_bar) + 
  geom_rect(aes(xmin = Start, xmax = End, ymin = -2, ymax = 2, fill = Event)) + 
  facet_wrap(~Sector, nrow = 6) +
  theme_minimal() +
  scale_fill_brewer()
  scale_y_continuous(limits = c(-4, 4))

  
  
  

grid.arrange(bar, line)
