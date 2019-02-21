# part III visualization 
library(dplyr)

# 1. load and merge occurrence and event tables

occurrence <- read.csv("./data/mapped_data/occurrence.csv")
event <- read.csv("./data/mapped_data/event.csv")

HK_data <- left_join(occurrence,event,by="eventID")

# HK_data <- HK_data %>% select("variables of interest") # reducing number of variables for plotting 
write.csv(HK_data,"./data/mapped_data/HK_data.csv",
          row.names = FALSE, na = "")
