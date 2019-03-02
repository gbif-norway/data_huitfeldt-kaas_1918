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

HK_sf <- readRDS(file = "../data/mapped_data/HK_sf.rds")
HK_sf_tmp <- HK_sf[HK_sf$scientificName=="Esox lucius",]
HK_species <- as.character(unique(HK_sf$scientificName))

# Define UI for application that draws a histogram
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


# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # plot data
  output$test <- renderLeaflet({
    
    HK_sf_tmp <- HK_sf[HK_sf$scientificName==input$Velg_art,]
    HK_sf_tmp <- HK_sf_tmp %>% 
      arrange(occurrenceStatus)
    
    pal <- colorFactor(c("grey", "red"), domain = c("absent", "present"))
    
    leaflet(data = HK_sf_tmp) %>% addTiles() %>%
    addCircleMarkers(popup = ~as.character(occurrenceID), 
                     radius = ~ifelse(occurrenceStatus == "absent", 5, 5),
                     label = ~as.character(occurrenceStatus),
                     color = ~pal(occurrenceStatus),
                      stroke = FALSE, 
                      fillOpacity = ~ifelse(occurrenceStatus == "absent", 1, 1)) %>%
      addLegend(position = c("bottomright"), pal = pal, 
                values = ~as.character(occurrenceStatus), 
                opacity = 1,
                title = "presence/absence")
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

