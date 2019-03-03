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


# store as .zip file in folder ~/data/raw_data/
write.csv(inndata,"./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv",row.names = FALSE)

zip(zipfile = "./data/raw_data/transcriptions_huitfeldt-kaas_1918", 
    files = "./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")
file.remove("./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")


                    