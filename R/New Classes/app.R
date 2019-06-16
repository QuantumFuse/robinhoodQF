

source('C:/Dev/robinhoodQF/R/New Classes/AuthUser.R')
source('C:/Dev/robinhoodQF/R/New Classes/EquityData.R')
source('C:/Dev/robinhoodQF/R/New Classes/OptionsData.R')
source('C:/Dev/robinhoodQF/R/New Classes/Account.R')
source('C:/Dev/robinhoodQF/R/PlotlyCharting.R')



library(magrittr)           ### MIT
library(ygdashboard)        ### GPL 2
library(shinycssloaders)    ### GPL 3
library(plotly)
library(shinyWidgets)

client <- UserAuth$new()
equityDataQuery <- EquityData$new(userAuthentication = client)

shiny::runApp(
  
  list(
    
    ui = dashboardPage(
      
      
      title = "robinhoodQF", 
      skin = "blue",
      
      
      header = dashboardHeader(
        
        titleWidth = "200px",
        title = htmltools::HTML(paste0(
          '<span class = "logo-lg"><b> robinhoodQF </b></span>',
          '<span class = "logo-mini"><b> QF</b> </span>'
        ))
        
      ),
      
      
      sidebar = dashboardSidebar(width = "200px", sidebarMenuOutput("sidebar1")),
      
      
      footer = footerOutput(outputId = "dynamicFooter"),
      
      
      dashboardControlbar(),
      
      
      body = dashboardBody(
        
        dashboardthemes::shinyDashboardThemes(theme = "grey_dark"),
        
        tabItems(
          
          
          ##### Portfolio #####
          
          tabItem(
            
            tabName = "portfolio_tab", 
            
            fluidRow(
              
              column(
                
                width = 6,
                align = "center", 
                
                h3("Daily Performance"), 
                
                br(),
                
                box(
                  title = "", 
                  footer = NULL, 
                  solidHeader = TRUE, 
                  background = NULL, 
                  width = 12, 
                  collapsible = TRUE, 
                  collapsed = FALSE
                )
                
              ),
              
              column(
                
                width = 6,
                align = "center", 
                
                h3("Allocation"),
                
                br(),
                
                box(
                  title = "", 
                  footer = NULL, 
                  solidHeader = TRUE, 
                  background = NULL, 
                  width = 12, 
                  collapsible = TRUE, 
                  collapsed = FALSE
                )
                
              )
              
              
            ),
            
            
            
            
            
            h3("Holdings"), 
            
            br(),
            
            box(
              title = "Shares", 
              footer = NULL, 
              status = "info", 
              solidHeader = TRUE, 
              background = NULL, 
              width = 12, 
              collapsible = TRUE, 
              collapsed = FALSE
            ),
            
            box(
              title = "Options", 
              footer = NULL, 
              status = "info", 
              solidHeader = TRUE, 
              background = NULL, 
              width = 12, 
              collapsible = TRUE, 
              collapsed = FALSE
            ), 
            
            box(
              title = "Crypto", 
              footer = NULL, 
              status = "info", 
              solidHeader = TRUE, 
              background = NULL, 
              width = 12, 
              collapsible = TRUE, 
              collapsed = FALSE
            )
            
            
            
          ), 
          
          
          tabItem(
            
            tabName = "research_tab", 
            
            box(
              title = "", 
              footer = NULL, 
              status = "info", 
              solidHeader = TRUE, 
              background = NULL, 
              width = 12, 
              collapsible = TRUE, 
              collapsed = FALSE,
              
              column(
                
                width = 6, 
                align = "center", 
                
                selectizeInput(
                  inputId = "tickerSelectize1", 
                  label = "Select a ticker",
                  choices = list("Select a ticker", "MU", "AAPL", "MSFT", "AMZN")
                ), 
                
                br(),
                
                actionButton(inputId = "loadOptions1", "Load Options Data")
                
              ), 
              
              column(
                
                width = 6, 
                align = "center", 
                
                checkboxGroupButtons(
                  inputId = "somevalue", label = "Make a choice :", 
                  choices = c("Daily", "Intraday"), 
                  justified = TRUE, status = "info"
                  # checkIcon = list(yes = icon("ok", lib = "glyphicon"), no = icon("remove", lib = "glyphicon"))
                ),
                plotlyOutput(outputId = "plotlyStockDaily1", height = "600px") %>% 
                  withSpinner(color="#1eb9ed",type=4)
                
              )
              
              
              
            )
            
            
          )
        )
        
      )
      
    ),
    
    
    
    server = function(input, output) {
      
      
      output$sidebar1 <- renderMenu({
        
        sidebarMenu(
          id = "tabs", ## setting id makes input$tabs give tabName of current  tab
          menuItem("Portfolio",icon = icon("folder-open"),tabName = "portfolio_tab"),
          menuItem("Performance",icon = icon("area-chart"),tabName ="performance_tab"),
          menuItem("Trade",icon = icon("usd"),tabName = "trade_tab"),
          menuItem("Account", icon = icon("lock"), tabName = "account_tab"),
          menuItem("Research", icon = icon("book"), tabName = "research_tab"),
          menuItem(
            "Tools", icon = icon("wrench"), tabName = "tools_tab", 
            menuItem("Technical Analysis", tabName = "ta_tab"),
            menuItem("Volatility Surface", tabName = "vs_tab"),
            menuItem("Options Strategy Builder", tabName = "osb_tab")
         )
        )
      })
      
      
      
      
      output$plotlyStockDaily1 <- renderPlotly({
        
        tickerHistoricals.daily <-  equityDataQuery$ohlcv_historicals(tickerSymbols = input$tickerSelectize1)
        
        dailyPlot <- PlotlyDailyChartBuilder$new(
          tickerSymbol = input$tickerSelectize1, 
          ohlcvPrices = tickerHistoricals.daily, 
          chartType = "candlestick"
        )
        
        dailyPlot$create_volume_plot()
        dailyPlot$volumeCombinedPlot
        
      })
      
      
    }
  )
)


