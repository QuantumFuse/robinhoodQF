ui<-dashboardPagePlus(skin="black",
            header = dashboardHeaderPlus(
              title=NULL,fixed = FALSE),
            sidebar = dashboardSidebar(collapsed=TRUE,
              ##This is where the user specific name is added and the "Get Last Quote" search bar"
              # sidebarUserPanel(name=uiOutput("users_name_title"),
              #                  subtitle = a(href = "#", icon("circle", class = "text-success"), "Online"),
              #                  image = "atom-512.png"),width = 180, uiOutput("quote_search"),
              
              ##This is where the main sidebar menu is added UI side (i.e. each tabItem inside of a sidebarMenu) Each Tab has a tabName which can serve as an input ID
              sidebarMenuOutput("menu")
            ), 
          dashboardBody(
            setShadow("card"),
            ##Add a new HTML class called sidebar-mini to have the visible mini sidebar on collape
            tags$script(HTML("$('body').addClass('sidebar-mini');")), 
            shinyjs::useShinyjs(),
            tags$head(
              tags$link(rel = "stylesheet", type = "text/css", href = "app.css"),
              tags$script(src="enterBtn.js")
            ),
            uiOutput("home_modal"),
            tabItems(
              tabItem("robinhood_dashboard_tab",
                      fluidRow(
                        column(12,align="center",
                               uiOutput("portfolio_positions_box")
                        )
                      ),
                      fluidRow(column(12,align="center",
                                      fluidRow(
                                        column(3,""),
                                        column(6,align="center",
                                               actionBttn("get_order_history", label = "Historical Analysis", icon = NULL, style = "stretch",
                                                          color = "default", size = "sm", block = FALSE, no_outline = TRUE)
                                        )
                                      ),
                                      div(loadingLogo('eclipse_loader.svg',height="25%",width="25%",alt="Historical Performance"),class="overlay"),
                                      uiOutput("portfolio_performance_ui")
                      ))
                      
                      ),
              tabItem("robinhood_news_tab", div(h3("Coming Soon"),style="text-align:center;")
              ),
              tabItem("robinhood_watchlists_tab", div(h3("Coming Soon"),style="text-align:center;")
              ),
              # tabItem("investment_screener_tab",
              # ),
              # tabItem("virtual_exchange_tab",
              # ),
              tabItem("markets_tab",
                      tabsetPanel(type="pills",
                                  tabPanel("Options Contracts",
                                           absolutePanel(
                                             top = 55, left = 60, width=600,
                                             draggable = TRUE,
                                             
                                             wellPanel(
                                               box(collapsible=TRUE,title=NULL,width="100%",height="100%",
                                                   radioGroupButtons(inputId = "contract_type",label = "",
                                                                     choices = c("Calls","Puts"), selected = "Calls",
                                                                     justified = T,status="primary",width="100%"),
                                                   
                                                   fluidRow(column(6,align="center",
                                                                   selectizeInput(inputId = "option_ticker",
                                                                                  label = "Select a Ticker",
                                                                                  choices = ticker_choices, selected="AAPL",
                                                                                  width="100%",
                                                                                  multiple=TRUE,
                                                                                  options = list(maxItems = 1,placeholder='Search by name or symbol')
                                                                   )
                                                   ),
                                                   column(6,align="center",
                                                          uiOutput("expiry_select_ui"))
                                                   ),
                                                   
                                                   fluidRow(column(2,""),
                                                            column(6,align="center",
                                                                   prettyRadioButtons(
                                                                     inputId="hist_span",label=NULL,
                                                                     choiceNames=c("Day","Last Week","Last Year"),
                                                                     choiceValues=c("day","week","year"),
                                                                     selected="day",
                                                                     status="primary",shape="round",outline=FALSE,fill=TRUE,thick=TRUE,animation=NULL,
                                                                     icon=tags$i(class="fa fa-circle",style="color:steelblue;"),plain=FALSE,bigger=TRUE,inline=TRUE,
                                                                     width="100%")
                                                            ),
                                                            column(3,align="center",
                                                                   radioGroupButtons(
                                                                     inputId = "chartType",
                                                                     label = NULL, 
                                                                     choices = c(`<i class='fa fa-line-chart'></i>` = "line", 
                                                                                 `<i class='fa fa-bar-chart'></i>` = "candlestick"),
                                                                     justified = TRUE, status="primary"
                                                                   )
                                                            )
                                                   ),
                                                   
                                                   uiOutput("options_plot_ui"),
                                                   fluidRow(column(12,plotOutput("stock_chartSeries")))
                                               )),
                                             style = "z-index: 100;"
                                           ),
                                           fluidRow(
                                             column(12,align="center",br(),br(),br(),br(), uiOutput("options_box"))
                                           )
                                  ),
                                  tabPanel("Volatility Surface",
                                           fluidRow(column(12,align="center",
                                                           plotlyOutput("vol_surface_plotly")))
                                  ),
                                  tabPanel("Non-Liquid Contracts",
                                           fluidRow(column(12,align="center",
                                                           div(box(title=NULL,collapsible=F,width="100%",DTOutput("noVol_data_DT")))
                                           )))
                      )
              ),
              tabItem("main_charting_tab",div(h3("Coming Soon"),style="text-align:center;")
              )
              # tabItem("advanced_charting_tab",
              # )
              
              
            )

          ) #End dashboardBody
) #End dashboardPage