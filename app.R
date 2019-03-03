#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(mapview)
library(sf)
library(leaflet)
library(stringr)

HK_sf <- readRDS(file = "../data/mapped_data/HK_sf.rds")
HK_species <- as.character(unique(HK_sf$scientificName))

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
                draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                width = 330, height = "auto",
                h2("Visning"),
        selectInput("Velg_art", 
                    label = "Vel art",
                    choices = HK_species,
                    selected = HK_species[1])
      )
                          ),
  tags$div(id="cite",
           'Data frå ', tags$em('Ferskvandsfiskenes utbredelse og indvandring i Norge: med et tillæg om krebsen'), ' av Hartvig Huitfeldt-Kaas (Centraltrykkeriet, Krisistiania 1918).'
  )
                 ),
  tabPanel("Info")
)

#--------------------------------------------------------------------------
# Define server logic
#--------------------------------------------------------------------------

server <- function(input, output) {
  
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
                              "<br><i>Kommentar lokalitet: </i>",HK_sf_tmp$occurrenceRemarks,
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

