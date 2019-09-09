
# Custom function for resolving sci-names to be used in the script
# "2_normalize_data.R

f_name_resolving <- function(scinames){
  
  require(rgbif)
  require(dplyr)
  require(stringr)
  
  datasetKeyUUID_1="a6c6cead-b5ce-4a4e-8cf5-1542ba708dec" # using Artsnavnebasen as source
  datasetKeyUUID_2="d7dddbf4-2cf0-4f39-9b2a-bb099caae36c" # using GBIF taxonomic bacbone as source
  
  resolved_names <- data.frame() # empty data.frame to put output from resolved names in
  
  for(i in 1:length(scinames)){
    
    output_1 <- NA
    output_2 <- NA
    
    output_1 <- try(name_lookup(query=scinames[i],datasetKey = datasetKeyUUID_1,limit=1,
                                return="data"),silent=TRUE)
    output_2 <- try(name_lookup(query=scinames[i],datasetKey = datasetKeyUUID_2,limit=1,
                                return="data"),silent=TRUE)
    
    if(str_detect(output_1[1],"Error")){
      output <- output_2
    } else { 
      output <- output_1
    }
    
    resolved_names <- bind_rows(resolved_names,as.data.frame(output))
  }
  
  resolved_names$scinames <- scinames
  resolved_names$taxonRank <- resolved_names$rank
  
  resolved_names <- resolved_names %>% 
    select(scientificName,kingdom,phylum,order,family,
           genus,scinames,taxonRank)
  
  return(resolved_names)
  
}
