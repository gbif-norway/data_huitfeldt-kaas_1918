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
# 1. load data (if not already existing in memory)
#...............................................................................
if(!exists("inndata")) {
  tmp <- tempdir()
  inndata <- read.csv(unzip("./data/raw_data/transcriptions_huitfeldt-kaas_1918.zip",
                            exdir=tmp),stringsAsFactors=FALSE)
}


# create fieldNumber to use as temporary match between occurrence and event table
inndata$fieldNumber <- paste0("NTNU-VM_HK_2019_",inndata$locationID)


#...............................................................................
# 2. Some data-cleaning before further processing 
#...............................................................................

# remove some bogus occurrences 
inndata <- inndata %>%
  filter(!scientificName %in% c("-","æøå",""))

# remove records with missing location
inndata <- inndata %>%
  filter(!locationID=="")

# remove dupclited occurrences (i.e. duplicated transcriptions of a species in a given location)
tmp <- inndata %>%
  select(locationID,scientificName) %>%
  mutate(not_unique = duplicated(.))

inndata$remove_not_unique <- tmp$not_unique

inndata <- inndata %>%
  filter(remove_not_unique==FALSE) %>%
  select(-remove_not_unique)

#.................................................................................
# 2. Normalize data
#................................................................................

# create event and remove duplicatates from events

event <- inndata %>%
  select(locality,project,verbatimElevation,footprintWKT,locationID,fieldNumber) %>%
  distinct()

# remove duplicated locations (lakes)
remove <- event %>%
  select(locationID) %>%
  mutate(duplicates=duplicated(.)) 

event$duplicated <- remove$duplicates

event <- event %>%
  filter(duplicated==FALSE)


#.................................................................................
# 3. Add GUID (uri:uuid) as eventID
#................................................................................



# import eventID table
# The event ID table is pre-sett with a fixed / immutable eventID for every possible fieldNumber/location 
# (i.e. every lake in Norway)

event_id_url <- "https://api.loke.aws.unit.no/dlr-gui-backend-resources-content/v2/contents/links/3540f83d-14b4-406b-896a-faf54eaf404300ddf118-d773-4f53-b220-a5c3c861ebe56738f141-d8f8-45e7-bc1f-7dbf8652e50d"
eventIDs <- read.csv(event_id_url,stringsAsFactors = FALSE)

# add new eventIDs to event table
event <- left_join(event,eventIDs)


#.................................................................................
# 4. DwC-mapping events  
#................................................................................

# add lat/long
lake_centroids_url <- "https://api.loke.aws.unit.no/dlr-gui-backend-resources-content/v2/contents/links/5c76e109-dc2b-4a0b-98ee-dc65dd77e169f1b7589f-bfa2-4c75-bd0b-1aa13d2ec3bf820dbc79-0bd3-4252-9e89-935498b3445a"
lake_centroids <- read.csv(lake_centroids_url,stringsAsFactors = FALSE) 

event <- left_join(event,lake_centroids)

# adding terms with values replicated throughout dataset
event$year <- "1918"
event$eventDate <- "1902/1918"
event$recordedBy <- "Huitfelt-Kaas"
event$samplingProtocol <- "survey_inventory_questionary"
event$countryCode <- "NO"
# event$coordinateUncertaintyInMeters <- May be estimated as a function of maximum lake fetch?
event$geodeticDatum <- "EPSG:4326"
event$footprintSRS <- 'GEOGCS["GCS_WGS_1984", DATUM["D_WGS_1984", SPHEROID["WGS_1984",6378137,298.257223563]], PRIMEM["Greenwich",0], UNIT["Degree",0.0174532925199433]]'
event$georeferenceProtocol <- "Occurrence represent presence/absence in a given waterbody. Coordinates are centroid of that waterbody. Source of geometries are The Norwegian Water Resources and Energy Directorate, innsjødatabasen"
event$institutionCode <- "NTNU-VM"
event$collectionCode <- "LFI"

# add prefix to eventID
event$eventID <- paste0("urn:uuid:",event$eventID)


#.................................................................................
# 5. DwC-mapping occurrences  
#................................................................................

# create base of occurrence data table from inndata
occurrence <- inndata %>%
  select(-locality,-project,-verbatimElevation,-footprintWKT,-locationID)

# Add eventIDs
occurrence <- left_join(occurrence,event[c("eventID","fieldNumber")])

# rename id to occurrenceID, and add namespace
occurrence$occurrenceID <- paste0("urn:uuid:",occurrence$id)

# Resolve scientific names.......................................................


# first clean up name list in input data with some known errors, and 
# store orginal names in dwc:taxonRemarks
occurrence$taxonRemarks <- paste0("Named '", occurrence$scientificName, "' in source")
occurrence <- occurrence %>% 
  mutate(
    scientificName=case_when(
      scientificName == "Salmo alpinus" ~ "Salvelinus alpinus",
      scientificName == "Leuciscus erythropthalmus" ~ "Scardinius erythrophthalmus",
      scientificName == "Lucioperca lucioperca" ~ "Sander lucioperca", 
      scientificName == "Leuciscus grislagine" ~ "Leuciscus leuciscus", 
      scientificName == "Aspius alburnus" ~ "Alburnus alburnus", 
      scientificName == "Cottus gobio v. poecilopus" ~ "Cottus", 
      scientificName == "Abramis blicca" ~ "Blicca bjoerkna", 
      scientificName == "Leuciscus ritulus" ~ "Rutilus rutilus", 
      scientificName == "Gastoresteus pingitius" ~ "Pungitius pungitius",
      scientificName == "Phoxinus aphya" ~ "Phoxinus phoxinus",
      scientificName == "Petromyzon fluviatilis" ~ "Lampetra fluviatilis",
      scientificName == "Cyprinus carassius" ~ "Carassius carassius",
      scientificName == "Micropterus salmonides" ~ "Micropterus salmoides",
      scientificName == "æøå" ~ "",
      scientificName == "-" ~ "",
      TRUE ~ scientificName
    )
  ) 

occurrence <- occurrence %>%
  rename(scinames=scientificName)

scinames <- unique(occurrence$scinames) # vector of unique sci-names in dataset
scinames <- scinames[!scinames==""]

# Run below if changing taxon list... and update remove repro

#source("./R/f_name_resolving.R") # in the following, use artsnavnebasen as primary source, if not match, then use GBIF backbone
#resolved_names <- f_name_resolving(scinames)
#write.csv(resolved_names,"./data/mapped_data/resolved_names.csv",row.names = FALSE)

resolved_names_URL <- "https://api.loke.aws.unit.no/dlr-gui-backend-resources-content/v2/contents/links/0fda1811-3b47-4acc-8547-2171054db6232340604d-a7a4-4c04-8757-9624cc118b64102065ea-c600-468d-a133-870937fc8fc3"
resolved_names <- read.csv(resolved_names_URL, stringsAsFactors = FALSE)

occurrence <- left_join(occurrence,resolved_names,by="scinames")


# clean occurrence table
occurrence <- occurrence %>% 
  dplyr::select(eventID,occurrenceID,scientificName,taxonRank, 
         kingdom, phylum, order, genus, family, canoncialName=scinames,
         verbatimLocality,
         locationRemarks,introduced) %>% 
  filter(!is.na(scientificName))

occurrence$occurrenceStatus <- "present"

#.................................................................................
# 5. Add absence information 
#
# NB! need to be sure all lakes have been transcribed before exectuting
# Current implementation is experimental - adjust taxonomic_scope to restrict
#................................................................................

# load absence_occurrenceIDs
URL <- "https://api.loke.aws.unit.no/dlr-gui-backend-resources-content/v2/contents/links/c3ec5565-caf5-4304-bc49-1b2d9f0f6c10883ae673-3e5f-4ee8-8f93-01eb381baeec49ff9e69-c788-42a4-87dc-ebb4fd839efa"
temp <- tempdir()
download.file(URL,paste0(temp,"/absence_occurrenceIDs.csv"))
absence_occurrenceIDs <- read.csv(paste0(temp,"/absence_occurrenceIDs.csv"),stringsAsFactors = FALSE)

# add prefix to eventID and occurrenceID
absence_occurrenceIDs$eventID <- paste0("urn:uuid:",absence_occurrenceIDs$eventID)
absence_occurrenceIDs$occurrenceID <- paste0("urn:uuid:",absence_occurrenceIDs$occurrenceID)

# filter out absence_occurrenceIDs which have a registred eventID
absence_occurrenceIDs2 <- absence_occurrenceIDs %>%
  filter(eventID %in% event$eventID)

# rename sciname to canonicalName and add scientificName
absence_occurrenceIDs2 <- absence_occurrenceIDs2 %>%
  rename(canoncialName=scinames)

# remove existing occurrences (presences from occurrences)
absence_occurrenceIDs2 <- left_join(absence_occurrenceIDs2,occurrence[c("eventID","canoncialName","occurrenceStatus")])
absence_occurrenceIDs2 <- absence_occurrenceIDs2 %>%
  filter(is.na(occurrenceStatus))


##############################################################################################
# add missing taxon information to absencedata 
resolved_names2 <- resolved_names %>%
  rename(canoncialName=scinames)
absence_occurrenceIDs2 <- left_join(absence_occurrenceIDs2,resolved_names2)

# declear absence data as absence 
absence_occurrenceIDs2$occurrenceStatus <- "absent"

# add verbatimLocality and locationRemarks data

occurrence$verbatimLocality[occurrence$verbatimLocality==""] <- NA
occurrence$locationRemarks[occurrence$locationRemarks==""] <- NA
tmp <- occurrence %>%
  select(eventID,verbatimLocality,locationRemarks) %>%
  group_by(eventID) %>%
  summarize(verbatimLocality = paste0(na.omit(unique(verbatimLocality)), collapse = " | "),
         locationRemarks = paste0(na.omit(unique(locationRemarks)), collapse = " | ")) 
  

absence_occurrenceIDs2 <- left_join(absence_occurrenceIDs2,tmp)

# merge absences with occurrence table

occurrence3 <- bind_rows(occurrence,absence_occurrenceIDs2)        
occurrence <- occurrence3




#...................................................................................
# 6. Add terms and clean occurrence table
#.....................................................................................
occurrence$basisOfRecord <- "HumanObservation"
occurrence$recordedBy <- "Hartvig Huitfeldt-Kaas"

occurrence$informationWithheld <- "Name of person transcribing the record witheld due to data privacy legislations"

occurrence$bibliographicCitation  <- paste0("Huitfeldt-Kaas, H. (1918). Ferskvandsfiskenes utbredelse og indvandring i Norge: Med et tillæg om krebsen. Kristiania: Centraltrykkeriet. In Norwegian. URL:https://urn.nb.no/URN:NBN:no-nb_digibok_2006120500031. Page: ",
                                            occurrence$currentPage)
occurrence$occurrenceRemarks <- occurrence$annotationRemarks

occurrence$establishmentMeans <- ifelse(occurrence$introduced=="on",
                                       "introduced","native")

occurrence$recordedBy <- "Hartvig Huitfeldt-Kaas"
occurrence$collectionCode <- "LFI"

# clean occurrence table
occurrence <- occurrence %>% 
  dplyr::select(eventID,occurrenceID,scientificName,taxonRank, 
                kingdom, phylum, order, genus, family,
                basisOfRecord,recordedBy,verbatimLocality,
                locationRemarks,bibliographicCitation,
                occurrenceStatus,establishmentMeans,
                informationWithheld,recordedBy,collectionCode) %>% 
  filter(!is.na(scientificName)) 




#.................................................................................
# X. check, clean up, save and exit  
#................................................................................

event2 <- event[duplicated(event$eventID)==FALSE,] # some duplicted eventIDs due to test-records
occurrence2 <- occurrence[duplicated(occurrence$occurrenceID)==FALSE,] # some duplicted eventIDs due to test-records
event2 <- event[event$eventID!="urn:uuid:NA",]
occurrence2 <- occurrence[occurrence$eventID!="urn:uuid:NA",]

dim(event2)
length(unique(event2$eventID))
dim(occurrence2)
length(occurrence2$occurrenceID[occurrence2$eventID %in% event2$eventID])
length(unique(occurrence2$occurrenceID))
occurrence <- occurrence2
event <- event2

# Save mapped data, create folder "./data/mapped_data" if not existing

if(!"mapped_data" %in% (list.files("./data/"))) {
  dir.create(file.path("./data/mapped_data"))
}

write.csv(occurrence,"./data/mapped_data/occurrence.csv",
          row.names = FALSE, na = "")
write.csv(event,"./data/mapped_data/event.csv",
          row.names = FALSE, na = "")



