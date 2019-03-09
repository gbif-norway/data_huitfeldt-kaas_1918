###########################################
#
# Download data from Dugnadsportalen and 
# store in tabular format (.csv) for further
# processing
#
###########################################

# load packages 
library(jsonlite)   
library(dplyr)   
library(stringr)
library(googlesheets)

# downlad issue-table
# NOTE: currently only contains "delte" in form of a list of occurrenceIDs to be deleted
issue_resolver <- gs_key("1ly4nQ26Acs2A9hTmEvpcNhPnV-eJfC12RQbeE0XZlzc")
resolved <- gs_read(ss=issue_resolver,ws = "response")

# download data and parse json to data.frame 

prosjektid <- "huitfeldt-kaas"
tmp <- tempfile()
download.file(url=paste0("https://dugnad.gbif.no/nb_NO/project/",prosjektid,"/export.json"),
              destfile = tmp)

inndata <- fromJSON(tmp,flatten = TRUE)

# remove prefix "data.*" from data.frame 
names(inndata) <-  sub("data.","",names(inndata))

# tagg locationID with prefix NVE:vatnLnr:
# locationID later used to create fieldNumbers/eventIDs and should 
# be cept stabel throughout the rest of the workflow.
inndata$locationID <- str_replace(inndata$locationID,":",":vatnLnr:")


# remove occurrenceIDs tagget with delete from issue_resolver
delete_id <- str_sub(resolved$occurrenceID,start=-36L,end=-1L)
inndata <- inndata %>%
  filter(!id %in% delete_id)


# store as .zip file in folder ~/data/raw_data/
write.csv(inndata,"./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv",row.names = FALSE)

zip(zipfile = "./data/raw_data/transcriptions_huitfeldt-kaas_1918", 
    files = "./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")
file.remove("./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")


                    