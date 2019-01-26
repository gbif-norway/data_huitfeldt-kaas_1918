###########################################
#
# Download data from Dugnadsportalen and 
# and parse to DwC-A format 
#
###########################################

# load packages 
library(jsonlite)   
library(dplyr)     

# download data and parse json to data.frame 

prosjektid <- "huitfeldt-kaas"
inndata <- fromJSON(paste0("https://dugnad.gbif.no/nb_NO/project/",prosjektid,"/export.json"))

                    