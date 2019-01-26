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

# download data and parse json to data.frame 
prosjektid <- "huitfeldt-kaas"
inndata <- fromJSON(paste0("https://dugnad.gbif.no/nb_NO/project/",prosjektid,"/export.json"),
                    flatten = TRUE)

# remove prefix "data.*" from data.frame 
names(inndata) <-  sub("data.","",names(inndata))

# store as .zip file in folder ~/data/raw_data/
write.csv(inndata,"./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv",row.names = FALSE)

zip(zipfile = "./data/raw_data/transcriptions_huitfeldt-kaas_1918", 
    files = "./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")
file.remove("./data/raw_data/transcriptions_huitfeldt-kaas_1918.csv")


                    