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

# create event and occurrence data and remove duplicatates from events

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
# 4. DwC-mapping events  
#................................................................................



# Events........................................................................

# add lat/long
lake_centroids <- read.csv("./data/raw_data/lakes_NO_centroids.csv",stringsAsFactors = FALSE) 
event$tmp_vatnLnr <- as.numeric(str_split_fixed(event$locationID,":",n=3)[,3]) # create tmp variable with vatnLnr
event <- left_join(event,lake_centroids,by=c("tmp_vatnLnr" = "vatnLnr"))

# adding terms with values replicated throughout dataset
event$year <- "1918"
event$eventDate <- "1902/1918"
event$recordedBy <- "Huitfelt-Kaas"
event$samplingProtocol <- "survey_inventory_questionary"
event$countryCode <- "NO"
# event$coordinateUncertaintyInMeters <- May be estimated as a function of maximum lake fetch?
event$geodeticDatum <- "EPSG:4326"
event$footprintSRS <- 'GEOGCS["GCS_WGS_1984", DATUM["D_WGS_1984", SPHEROID["WGS_1984",6378137,298.257223563]], PRIMEM["Greenwich",0], UNIT["Degree",0.0174532925199433]]'
event$georeferenceProtocol <- "Occurrence represent presence/absence in waterbody. Coordinates are centroid of waterbody. Source of geometries are The Norwegian Water Resources and Energy Directorate"
event$institutionCode <- "NTNU-VM"
event$collectionCode <- "LFI"

# add prefix to eventID
event$eventID <- paste0("urn:uuid:",event$eventID)


#.................................................................................
# 5. DwC-mapping occurrences  
#................................................................................

# Add eventIDs
occurrence <- left_join(occurrence,event[c("eventID","fieldNumber")])

# rename id to occurrenceID, and add namespace
occurrence$occurrenceID <- paste0("urn:uuid:",occurrence$id)

# Resolve scientific names.......................................................
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
  select(scientificName,kingdom,phylum,order,family,
         genus,taxonID,scinames,rank) %>%
  rename(taxonRank=rank)

occurrence <- left_join(occurrence,resolved_names)

# Add terms 
occurrence$basisOfRecord <- "HumanObservation"
occurrence$recordedBy <- "Hartvig Huitfeldt-Kaas"
occurrence$occurrenceStatus <- "present"
occurrence$informationWithheld <- "Name of person transcribing the record witheld due to data privacy legislations"

occurrence$bibliographicCitation  <- paste0("Huitfeldt-Kaas, H. (1918). Ferskvandsfiskenes utbredelse og indvandring i Norge: Med et tillæg om krebsen. Kristiania: Centraltrykkeriet. In Norwegian. URL:https://urn.nb.no/URN:NBN:no-nb_digibok_2006120500031. Page: ",
                                            occurrence$currentPage)
occurrence$occurrenceRemarks <- occurrence$annotationRemarks
  
  
occurrence$establishmentMeans <- ifelse(occurrence$introduced=="on",
                                        "introduced","native")
# clean occurrence table
occurrence2 <- occurrence %>% 
  dplyr::select(eventID,occurrenceID,scientificName, taxonID, taxonRank, 
         kingdom, phylum, order, genus, family,
         basisOfRecord,recordedBy,verbatimLocality,
         locationRemarks,bibliographicCitation,
         occurrenceStatus,establishmentMeans,
         informationWithheld,occurrenceRemarks) %>% 
  filter(!is.na(scientificName))



#.................................................................................
# 6. Add absence information 
#
# NB! need to be sure all lakes in an area have been transcribed before exectuting
# Current implementation is on test-basis - adjust taxonomic_scope to restrict
#................................................................................

# First define taxonomic_scope and generate absence information
# stored in data.frame "occ_absent"
taxonomic_scope <- data.frame(scientificName=c(unique(occurrence2$scientificName)))
taxonomic_scope$scientificName <- as.character(taxonomic_scope$scientificName)

occurrence_tmp <- occurrence2 %>%
  dplyr::select(taxonID, scientificName, taxonRank, 
         kingdom, phylum, order, genus, family,
         basisOfRecord,recordedBy,
         informationWithheld) %>%
  distinct()
occ_absent <- left_join(taxonomic_scope,occurrence_tmp,by="scientificName")
occ_absent <- bind_rows(replicate(length(event$eventID), occ_absent, simplify = FALSE))

occ_absent$eventID <- sort(rep(event$eventID,dim(taxonomic_scope)[1]))
occ_absent$occurrenceStatus <- "absent"                             

# Check for existing occurrenceIDs for absences.
# Relevant when adding new species to taxonomic_scope or
# adding new events (= new lakes) 
occurrenc_absence_IDs <- read.csv("./data/raw_data/occurrenc_absence_IDs.csv",stringsAsFactors=FALSE)
eventID_existing <- occurrenc_absence_IDs$eventID
scientificName_existing <- occurrenc_absence_IDs$scientificName
occurrenceID_existing <- occurrenc_absence_IDs$occurrenceID

new_occurrence_IDs <- as.character()
new_event_IDs <- as.character()
new_sciNames <- as.character()

for(i in 1:dim(occ_absent)[1]){
  if(occ_absent$scientificName[i] %in% scientificName_existing==FALSE |
     occ_absent$eventID[i] %in% eventID_existing==FALSE) {
     
    new_occurrence_IDs <- append(new_occurrence_IDs,
                                 paste0("urn:uuid:",UUIDgenerate()))
    new_event_IDs <- append(new_event_IDs,occ_absent$eventID[i])
    new_sciNames <- append(new_sciNames,occ_absent$scientificName[i])
  }
}

new_occurrence_absenceIDs <- data.frame(eventID=new_event_IDs,
                             occurrenceID=new_occurrence_IDs,
                             scientificName=new_sciNames)

occurrenc_absence_IDs <- bind_rows(occurrenc_absence_IDs,new_occurrence_absenceIDs)

# Add occurrenceID to occ_absent 
occ_absent <- left_join(occ_absent,occurrenc_absence_IDs)

# store occurrenceIDs, sciNames and eventIDs for later lookup
occurrenc_absence_IDs <- occ_absent %>%
  dplyr::select(occurrenceID,eventID,scientificName)

# merge absences with occurrence table, first filter
# away those existing in occurrence table

occ_absent$tmp <- paste0(occ_absent$eventID,occ_absent$scientificName)
tmp_exist <- paste0(occurrence$eventID,occurrence$scientificName)  

occ_absent <- occ_absent %>% 
  filter(!tmp %in% tmp_exist) %>%
  select(-tmp)

occurrence2 <- bind_rows(occurrence2,occ_absent)        
        
#.................................................................................
# X. save and exit  
#................................................................................

write.csv(new_eventIDs,"./data/raw_data/eventIDs.csv",row.names = FALSE)
write.csv(occurrenc_absence_IDs,"./data/raw_data/occurrenc_absence_IDs.csv",row.names = FALSE)

write.csv(occurrence2,"./data/mapped_data/occurrence.csv",
          row.names = FALSE, na = "")
write.csv(event,"./data/mapped_data/event.csv",
          row.names = FALSE, na = "")



