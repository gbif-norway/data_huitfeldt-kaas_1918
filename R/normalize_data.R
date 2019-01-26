#######################################
#
# Normalize data
#
#######################################

# load packages 
library(dplyr)

# load data
inndata <- read.csv("./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")

# create fieldNumber to use as temporary match between occurrence and event table
inndata$fieldNumber <- paste0("NTNU-VM_HK_2019_",inndata$locationID)

# create event tabel 

event <- inndata %>%
  select(locality,fieldNumber,project,verbatimElevation,footprintWKT,locationID,fieldNumber)