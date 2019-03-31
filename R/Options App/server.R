server<-function(input, output, session) {
  
  source(file.path("server","options_logic.R"), local = T)
  source(file.path("server","portfolio_summary_logic.R"), local = T)
  
  ## Initialize reactiveValues list representing PostgreSQL connection and reactive results
  ## Mutable and available in global environment 
  rv<-reactiveValues(robinhoodUser=NULL)
  ops_rv<-reactiveValues(chain=NULL,instruments=NULL,data=NULL,render_data=NULL,DT_dat=NULL,quote=NULL)
  stock_rv<-reactiveValues(intradayData=NULL)
  portfolio_rv<-reactiveValues(equity_positions=NULL,options_positions=NULL,orders=NULL,options_orders=NULL,
                               equity_performance=NULL,options_performance=NULL,aggregate_performance=NULL)
  ## Render login modal
  ## Launched on browser connection
  output$home_modal<-renderUI({
    showModal(modalDialog(
      tags$div(id="welcome_div",
               tags$div(id = "img_logo",align="center",
                        tags$img(src = "logo_blue.png",height = "50%", width = "50%")),
               br(),
               fluidRow(
                 column(12,align="center",
                        textInput("username_input","Username",placeholder="Enter your username"),
                        passwordInput("user_pwd","Password",placeholder="Enter your password"),
                        actionButton("sign_in","Sign In", width="50%",style="align:left", class = "btn-primary"),
                        loadingLogo('atomicon.gif',width="25%",height="25%",alt="Financial Dashboard")
                 )
               ),
               style="align:center;"),
      easyClose=F, footer =NULL) #End modalDialog
    ) #End showModal
  })  ##End user signin modal UI element definition
  
  ## Initialize connection to robinhood and set reactiveVal
  observeEvent(input$sign_in,{
    req(input$username_input)
    req(input$user_pwd)
    access_robinhood(req(input$username_input),
                     req(input$user_pwd))
    rv$robinhoodUser<-robinhoodUser
    
    
    if(is.null(robinhoodUser)!=T){
        removeModal(session=session)  
    }
  })

stock_data<-reactive({
  req(input$option_ticker)
  req(is.null(rv$robinhoodUser)!=T)
  intradayDaily<-robinhood_intraday_historicals(as.character(isolate(input$option_ticker)),span="day")
  intradayWeekly<-robinhood_intraday_historicals(as.character(isolate(input$option_ticker)),span="week")
  
  dailyData<-robinhood_daily_historicals(as.character(isolate(input$option_ticker)))
  
  list(daily=dailyData,intraDay=intradayDaily,intraWeek=intradayWeekly)
})


output$stock_chartSeries<-renderPlot({
  req(is.null(stock_data())!=T)
  req(input$chartType)
  req(input$hist_span)
  if(input$hist_span=="day"){
    data<-tail(stock_data()$intraDay,78)
  }
  else if(input$hist_span=="week"){
    data<-tail(stock_data()$intraWeek,78*5)
  }
  else{
    data<-stock_data()$daily
  }
  chartSeries(data,
              name=isolate(input$option_ticker),
              type=input$chartType)
})


##############################
## Link the tabs defined in UI to a menu with tabName argument specified and icons to be displayed on sidebar

output$menu <- renderMenu({
  
  sidebarMenu(
    id = "tabs", # Setting id makes input$tabs give tabName of current  tab

    menuItem("Account",icon=icon("user-circle"),
             menuItem("Dashboard",icon=icon("desktop"),tabName="robinhood_dashboard_tab"),
             menuItem("News", icon=icon("newspaper-o"), tabName="robinhood_news_tab"),
             menuItem("Watch Lists", icon=icon("star"),tabName="robinhood_watchlists_tab")
             # menuItem("Investment Screener",icon=icon("filter"),tabName="investment_screener_tab"),
             # menuItem("Virtual Exchange",icon=icon("university"),tabName="virtual_exchange_tab")
    ),
    menuItem("Charts & Markets", icon=icon("area-chart"),
             menuItem("Markets",icon=icon("globe"),tabName="markets_tab"),
             menuItem("Basic Charting",icon=icon("line-chart"),tabName="main_charting_tab")
             # menuItem("Exploratory", icon=icon("magic"),tabName="advanced_charting_tab")
             )
  )
})
##END SIDEBAR MENU DEFINITION
  if (!interactive()) {
    session$onSessionEnded(function() {
      stopApp()
      q("no")
    })
  }
  
} #End server