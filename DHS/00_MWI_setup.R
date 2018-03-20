# setup for the project

# Set up directories and folders ------------------------------------------

# Directories form which data are pulled and pushed.
setwd(here())
base_dir <- '~/Users/timessam/Documents/USAID/2018_Malawi/DHS/'
dhs2010 <- 'MW_2010_DHS/'
dhs2015 <- 'MW_2015-16_DHS/'
out_dir <- 'Dataout/'
gis_dir <- 'GIS/'



# Libraries for project ---------------------------------------------------

library(tidyverse)
library(haven) # for loading Stata data
library(sf) # for working with spatial data
library(stringr)
library(readxl)
library(data.table)
library(rlang)
library(svywrangler)
library(llamar)
library(Hmisc)
library(DT)
library(viridis)
library(Hmisc)
library(here)
library(purrr)
#devtools::install_github("rstudio/DT") # open a paginated view of data
#library(tidytext)


# Preset functions to load (geocenter package not working) ----------------
source('dhs_helpers.R')
here()
