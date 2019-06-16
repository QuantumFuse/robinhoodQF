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

            width = 3,
            align = "center",

            selectizeInput(
              inputId = "tickerSelectize1",
              label = "",
              choices = tickerOptionsNN,
              multiple = TRUE,
              options = list(placeholder = "Select a ticker",  maxItems = 1)
            ),

            br(),

            uiOutput("viewOptions1")

          ),

          column(

            width = 8,
            align = "center",

            plotlyOutput(outputId = "plotlyStockDaily1", height = "600px") %>%
              withSpinner(color="#1eb9ed",type=4)

          ),

          column(

            width = 1,
            align = "center",

            radioGroupButtons(
              inputId = "researchChartType1", label = "Chart Type",
              choices = c("candlestick", "line"), selected = "candlestick",
              justified = TRUE, status = "info", direction = "vertical"
            ),

            br(),

            materialSwitch(inputId = "intradaySwitch1", label = "Intraday", status = "info"),

            conditionalPanel(

              condition = 'input.intradaySwitch1',

              uiOutput(outputId = "intradayDateSelectConditional1")

            )
          )

        ),

        uiOutput("researchOptionsTabBox1UI")



      )


    )
  )

)


