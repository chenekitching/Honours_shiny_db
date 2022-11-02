library(shiny)
library(shiny.router)
library(DT)
library(shiny.semantic)
library(bslib)
library(DBI)
library(RSQLite)


source("database_global.R")

thematic::thematic_shiny(font = "auto")

# This generates menu in user interface with links.
menu <- (
  div(class = "ui vertical menu",
      div(class = "item",
          div(class = "menu",
              (a(class = "item", href = route_link("/"), "Home")),
              HTML('&nbsp;'),
              (a(class = "item", href = route_link("Variants"), "Variants page")),
              HTML('&nbsp;'),
              (a(class = "item", href = route_link("Annotations"), "Annotation page")),
              HTML('&nbsp;'),
              (a(class = "item", href = route_link("wgs"), "WGS cohort"))
          )
      )
  )
)


# This creates UI for each page.
page1 <- function(title, table1title, content1, table_id1, table2title, content2, table_id2) {
  div(
    menu,
    titlePanel(title),
    h4(table1title),
    p(content1),
    dataTableOutput(table_id1),
    h4(table2title),
    p(content2),
    dataTableOutput(table_id2)
  )
}

page <- function(title, content, table_id1) {
  div(
    menu,
    titlePanel(title),
    p(content),
    dataTableOutput(table_id1)
  )
}


# Both sample pages.
root_page <- div(menu, titlePanel("Home"),
                 br(),
                 br(),
                 br(),
                 h2("About us"), p("This database contains information on host genetic variants associated with COVID-19 susceptibility and severity. The variants were obtained through a literature search, as well as extracting information from variants used in the Axiom™ Human Genotyping SARS-CoV-2 Research Array SARS-CoV-2.", button = FALSE),
                 HTML('<center><img src="https://st.focusedcollection.com/13422768/i/650/focused_274960424-stock-photo-colored-dna-molecule-damage-white.jpg",
                  width ="500", height ="200"></center>'))
variant_page <- page1("Variants of interest", "From Literature", "This table contains information on variants that were curated through a literature search up until 28 July 2022.
                      Variant annotaions can be viewed by clicking on the RSID.
                      ", "from_literature", "
                      From Axiom array", "Variants that are included in the Axiom array COVID-19 susceptibility and severity modules. 
                      Variant annotaions can be viewed by clicking on the RSID.", "from_axiom")
annotation_page <-page1("Annotation page","Consequence", "Annotations obtained from Ensembl's Variant Effect Predictor (VEP)", "consequence_table", 
                        "Location", content2 = "","location_table")
wgs_page <- page("WGS Cohort", "Variants from a whole genome sequencing cohort that are known to be associated with COVID-19 susceptibility and severity.
                      The cohort consists of 71 participants with either severe COVID-19 or MIS-C.
                      Variant annotaions can be viewed by clicking on the RSID.", "wgs_table")
# Callbacks on the server side for
# the sample pages
annotation_callback <- function(input, output, session) {
  output$consequence_table <- renderDataTable(
    if(is.null(input$rsid)){
      datatable(data_cons <- dbGetQuery(
        conn = mydb,
        statement = "SELECT * FROM consequence"
      ), options = list(initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
        "}")), rownames = FALSE, escape= FALSE)
    }else{
      datatable(data_cons <- dbGetQuery(
        conn = mydb,
        statement = "SELECT * FROM consequence
        WHERE RSID = ?",
        params = input$rsid
      ), options = list(initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
        "}")), rownames = FALSE, escape = FALSE)
    }
  )
  
  
  
  output$location_table <- renderDataTable({
    if(is.null(input$rsid)){
      datatable(data_pos <- dbGetQuery(
        conn = mydb,
        statement = "SELECT * FROM id_pos"
      ), options = list(initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
        "}")), rownames = FALSE, escape= FALSE)
    }else{
      datatable(data_pos <- dbGetQuery(
        conn = mydb,
        statement = "SELECT * FROM id_pos
        WHERE RSID = ?",
        params = input$rsid
      ), options = list(initComplete = JS(
        "function(settings, json) {",
        "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
        "}")), rownames = FALSE, escape = FALSE)
    }})
  
}

variant_callback <- function(input, output, session) {
  output$from_literature <- renderDataTable(
    data_lit <- dbGetQuery(
      conn = mydb,
      statement = "SELECT * FROM from_lit"
    ),
    escape = FALSE,
    options = list(scrollX= TRUE, autowidth=TRUE, 
                   initComplete = JS(
                     "function(settings, json) {",
                     "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
                     "}"))
  )
  
  
  
  
  output$from_axiom <- renderDataTable(
    data_ax <- dbGetQuery(
      conn = mydb,
      statement = "SELECT * FROM axiom"
    ),
    escape = FALSE,
    options = list(scrollX= TRUE, autowidth=TRUE, 
                   initComplete = JS(
                     "function(settings, json) {",
                     "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
                     "}")))
  
  
}

wgs_callback <- function(input, output, session){
  output$wgs_table <- renderDataTable(
    data_wgs <- dbGetQuery(
      conn = mydb,
      statement = "SELECT * FROM merged"
    ),
    escape = FALSE,
    options = list(scrollX= TRUE, autowidth=TRUE, 
                   initComplete = JS(
                     "function(settings, json) {",
                     "$(this.api().table().header()).css({'background-color': '#78C2AD', 'color': '#fff'});",
                     "}")))
}
# Creates router. We provide routing path, a UI as
# well as a server-side callback for each page.
router <- make_router(
  route("/", root_page, NA),
  route("Variants", variant_page, variant_callback),
  route("Annotations", annotation_page, annotation_callback),
  route("wgs", wgs_page, wgs_callback)
)

# Make output for our router in main UI of Shiny app.
ui <- shinyUI(fluidPage(
  h1("COVID-19 Host genetic variants"),
  theme =bs_theme(version = 4, bootswatch = "minty"),
  router$ui
))

# Plug router into Shiny server.
server <- shinyServer(function(input, output, session) {
  router$server(input, output, session)
})

onStop(
  function()
  {
    dbDisconnect(mydb)
  }
)
# Run server in a standard way.
shinyApp(ui, server)