##############################################################
# Visualization 
#
# Small script to flatten occurrences and events and visualize
##############################################################

library(dplyr)
library(mapview)
library(sf)

# 1. load and merge occurrence and event tables if not existing in memory
if(!exists("occurrence")) {
  occurrence <- read.csv("./data/mapped_data/occurrence.csv")
}

if(!exists("event")) {
  event <- read.csv("./data/mapped_data/event.csv")
}

# flatten file and remove occurrences missing coordinates (caused by lakes missing in gazzeteer)
HK_data_flattend <- left_join(occurrence,event,by="eventID") %>%
  filter(!is.na(decimalLatitude) | !is.na(decimalLongitude))

# HK_data <- HK_data %>% select("variables of interest") # reducing number of variables for plotting 
write.csv(HK_data_flattend,"./data/mapped_data/HK_data_flattend.csv",
          row.names = FALSE, na = "")

# select variables for viewing in map... 
HK_data_tmp <- HK_data_flattend %>% select(decimalLongitude,decimalLatitude,occurrenceID,eventID,
                                           genus,scientificName,bibliographicCitation,establishmentMeans,
                                           occurrenceStatus,locationRemarks,tmp_vatnLnr,verbatimLocality,
                                           establishmentMeans,locality,bibliographicCitation)

HK_sf = st_as_sf(HK_data_tmp, coords = c("decimalLongitude", "decimalLatitude"), 
                 crs = 4326)
saveRDS(HK_sf, file = "./data/mapped_data/HK_sf.rds")


# View map - species by species - replace sci name with what you want
# see list of species names by running unique(HK_sf$scientificName)
mapview::mapview(HK_sf[HK_sf$scientificName=="Salvelinus alpinus",],zcol=c("occurrenceStatus"))









