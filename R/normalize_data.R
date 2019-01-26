#######################################
#
# Normalize data
#
#######################################

# load packages 
library(dplyr)
library(uuid)
library(stringr)
library(rgbif)

#...............................................................................
# 1. load data
#...............................................................................
tmp <- tempdir()
inndata <- read.csv(unzip("./data/raw_data/transcriptions_huitfeldt-kaas_1918.zip",
                          exdir=tmp),stringsAsFactors=FALSE)

# create fieldNumber to use as temporary match between occurrence and event table
inndata$fieldNumber <- paste0("NTNU-VM_HK_2019_",inndata$locationID)

#.................................................................................
# 2. Normalize data
#................................................................................

# create event and occurrence data

event <- inndata %>%
  select(locality,project,verbatimElevation,footprintWKT,locationID,fieldNumber) %>%
  distinct()
occurrence <- inndata %>%
  select(-locality,-project,-verbatimElevation,-footprintWKT,-locationID)

#.................................................................................
# 3. Add GUID (uri:uuid) as eventID
#................................................................................

# import eventID table
# check if fieldNumber is present in eventIDs table,
# if not, add UUID

eventIDs <- read.csv("./data/raw_data/eventIDs.csv",stringsAsFactors=FALSE)
eventID_existing <- eventIDs$eventID
fieldNumber_existing <- eventIDs$fieldNumber

for(i in 1:dim(event)[1]){
  if(event$fieldNumber[i] %in% fieldNumber_existing==FALSE) {
    
    fieldNumber_existing <- append(fieldNumber_existing,event$fieldNumber[i])
    eventID_temp <- UUIDgenerate()
    eventID_existing <- append(eventID_existing,eventID_temp)
    
  }
}
new_eventIDs <- data.frame(eventID=eventID_existing,fieldNumber=fieldNumber_existing)

# add new eventIDs to event table
event <- left_join(event,new_eventIDs,by="fieldNumber")


#.................................................................................
# 4. resolving scientific names 
#................................................................................
datasetKeyUUID="a6c6cead-b5ce-4a4e-8cf5-1542ba708dec" # using Artsnavnebasen as source

# first clean up name list in input data with some known errors, and 
# store orginal names in dwc:taxonRemarks
occurrence$taxonRemarks <- paste0("Named '", occurrence$scientificName, "' in source")
occurrence <- occurrence %>% 
  mutate(
    scientificName=case_when(
    scientificName == "Salmo alpinus" ~ "Salvelinus alpinus",
    scientificName == "æøå" ~ "",
    scientificName == "" ~ "",
    TRUE ~ scientificName
    )
) %>%
  rename(scinames=scientificName)

scinames <- unique(occurrence$scinames) # vector of unique sci-names in dataset
scinames <- scinames[!scinames==""]



resolved_names <- data.frame() # empty data.frame to put output from resolved names in

for(i in 1:length(scinames)){
  output <- name_lookup(query=scinames[i],datasetKey = datasetKeyUUID,limit=1,
                        return="data")
  resolved_names <- bind_rows(resolved_names,as.data.frame(output))
}
resolved_names$scinames <- scinames

resolved_names <- resolved_names %>% 
  select(scientificName,kingdom,phylum,order,family,genus,taxonID,scinames)

occurrence <- left_join(occurrence,resolved_names)


#.................................................................................
# 5. Mapp 
#................................................................................



# Events........................................................................

# add lat/long
lake_centroids <- read.csv("./data/raw_data/lakes_NO_centroids.csv",stringsAsFactors = FALSE) 
event2 <- left_join(event,lake_centroids,by="fieldNumber")

# adding terms with values replicated throughout dataset
event2$year <- "1918"
event2$eventDate <- "1902/1918"
event2$recordedBy <- "Huitfelt-Kaas"
event2$samplingProtocol <- "survey_questionary"
event2$countryCode <- "NO"
event2$geodeticDatum <- "EPSG:4326"
event2$footprintSRS <- 'GEOGCS["GCS_WGS_1984", DATUM["D_WGS_1984", SPHEROID["WGS_1984",6378137,298.257223563]], PRIMEM["Greenwich",0], UNIT["Degree",0.0174532925199433]]'
event2$georeferenceProtocol <- "Occurrence represent presence/absence in waterbody. Coordinates are centroid of waterbody. Source of geometries are The Norwegian Water Resources and Energy Directorate"





# Occurrences......................................................................


#.................................................................................
# X. save and exit  
#................................................................................

write.csv(eventIDs,"./data/raw_data/eventIDs.csv",row.names = FALSE)
write.csv(occurrence,"./data/mapped_data/occurrence.csv",row.names = FALSE)
write.csv(event,"./data/mapped_data/event.csv",row.names = FALSE)



