#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#

library(shiny)
library(dplyr)
library(mapview)
library(sf)
library(leaflet)
library(stringr)
library(DT)
library(rio)

#-----------------------------------------------------------
# Download and pre-process data 
#---------------------------------------------------------
# 1. download DWC-A and extract occurrence and events
URL <- "https://gbif.vm.ntnu.no/ipt/archive.do?r=huitfeldt-kaas_1918" # latest version 
temp <- tempdir()
download.file(URL,paste0(temp,"/huitfeldt-kaas_1918.zip"))
unzip(zipfile=paste0(temp,"/huitfeldt-kaas_1918.zip"),exdir=temp)
occurrence <- rio::import(paste0(temp,"/occurrence.txt"))
event <- rio::import(paste0(temp,"/event.txt"))

# 2. flatten file and remove occurrences missing coordinates (caused by lakes missing in gazzeteer) and footprintSRS (large character vector)
HK_data_flattend <- left_join(occurrence,event,by="eventID") %>%
  filter(!is.na(decimalLatitude) | !is.na(decimalLongitude)) %>%
  select(-footprintSRS)

# 3. add vatnLnr as variable for convinience viewing
HK_data_flattend$tmp_vatnLnr <- as.integer(str_split_fixed(HK_data_flattend$locationID,":",n=3)[,3])

# 3. select variables for viewing in map... 
HK_data_tmp <- HK_data_flattend %>% select(decimalLongitude,decimalLatitude,occurrenceID,eventID,
                                           genus,scientificName,bibliographicCitation,establishmentMeans,
                                           occurrenceStatus,locationRemarks,tmp_vatnLnr,verbatimLocality,
                                           establishmentMeans,locality,bibliographicCitation)

HK_sf = st_as_sf(HK_data_tmp, coords = c("decimalLongitude", "decimalLatitude"), 
                 crs = 4326)

HK_species <- as.character(unique(HK_sf$scientificName))
HK_species <- HK_species[HK_species!=""]



#-----------------------------------------------------------
# Define UI for application 
#---------------------------------------------------------
ui <- navbarPage("Ferskvassfisk i Noreg anno 1918", id="nav",
                 
                 tabPanel("Kart",
                          div(class="outer",
                              
                              tags$head(
                                # Include our custom CSS
                                includeCSS("styles.css")
                              ),
  
  # map
  leafletOutput("test", width = "100%", height = "100%"),
   
   # input
  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                draggable = TRUE, top = 100, left = "auto", right = 20, bottom = "auto",
                width = 330, height = "auto",
                h2("Visning"),
        selectInput("Velg_art", 
                    label = "Vel art",
                    choices = HK_species,
                    selected = "Esox lucius"),
        br(),
        tags$p("Output from digitalization of", tags$a(href="https://urn.nb.no/URN:NBN:no-nb_digibok_2006120500031", "Huitfelt-Kaas 1918"), "using",
        tags$a(href="https://dugnad.gbif.no/nb_NO/project/huitfeldt-kaas", "dugnadsportalen"))
        
      )
                          ),
  tags$div(id="cite",
           'Data frå ', tags$em('Ferskvandsfiskenes utbredelse og indvandring i Norge: med et tillæg om krebsen'), ' av Hartvig Huitfeldt-Kaas (Centraltrykkeriet, Krisistiania 1918).'
  )
                 ),
  tabPanel("Data",
           # table
           DT::dataTableOutput("table")),
  tabPanel("Info",
           tags$p("Beskrivelse kommer....")
  )
)

#--------------------------------------------------------------------------
# Define server logic
#--------------------------------------------------------------------------

server <- function(input, output) {
  
  # create DT table for output 
  output$table <- DT::renderDataTable(DT::datatable(
    {
      data <- HK_sf
      data
    }
    ,rownames= FALSE))
  
  # create leaflet map
  output$test <- renderLeaflet({
    
    # filter on species
    HK_sf_tmp <- HK_sf[HK_sf$scientificName==input$Velg_art,]
    HK_sf_tmp <- HK_sf_tmp %>% 
      arrange(occurrenceStatus)
    
    # make pop-up
    
    HK_sf_tmp$fravaer <- ifelse(HK_sf_tmp$occurrenceStatus=="absent","Ikkje registrert","Tilstades")
    HK_sf_tmp$side <- str_sub(HK_sf_tmp$bibliographicCitation,start=-3,end=-1)
                                      
    HK_sf_tmp$popup <- ifelse(HK_sf_tmp$occurrenceStatus=="present",
                              paste0("<strong>",HK_sf_tmp$locality,"</strong>",
                              "<br><i>",HK_sf_tmp$scientificName," - ",HK_sf_tmp$fravaer,"</i>",
                              "<br><i>Vatn_lnr: </i>",HK_sf_tmp$tmp_vatnLnr,
                              "<br><i>Orginalt lokalitetsnavn: </i>",HK_sf_tmp$verbatimLocality,
                              "<br><i>Kommentar lokalitet: </i>",HK_sf_tmp$locationRemarks,
                              "<br><i>Siderefferanse: </i>",HK_sf_tmp$side,
                              "<br><i>observasjonsID: </i>",HK_sf_tmp$occurrenceID,
                              "<br><strong>Klikk <a href=","https://goo.gl/forms/M9mZ5FtORB97K6dx2 target=blank",">her</a> for og raportere feil</strong>"),
                              paste0("<strong>",HK_sf_tmp$locality,"</strong>",
                                     "<br><i>",HK_sf_tmp$scientificName," - ",HK_sf_tmp$fravaer,"</i>",
                                     "<br><i>Vatn_lnr: </i>",HK_sf_tmp$tmp_vatnLnr,
                                     "<br><i>observasjonsID: </i>",HK_sf_tmp$occurrenceID)
    )
                              
   
    
    # colour palette for points
    pal <- colorFactor(c("grey", "red"), domain = c("Ikkje registrert", "Tilstades"))
    
    # create leaflet map
    leaflet(data = HK_sf_tmp) %>% addTiles() %>%
    addCircleMarkers(popup = ~as.character(popup), 
                     radius = ~ifelse(fravaer == "Ikkje registrert", 5, 5),
                     label = ~as.character(locality),
                     color = ~pal(fravaer),
                      stroke = FALSE, 
                      fillOpacity = ~ifelse(fravaer == "Ikkje registrert", 1, 1)) %>%
      addLegend(position = c("bottomright"), pal = pal, 
                values = ~as.character(fravaer), 
                opacity = 1,
                title = "Tilstades")
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

