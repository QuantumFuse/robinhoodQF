server = function(input, output) {


  output$sidebar1 <- renderMenu({

    sidebarMenu(
      id = "tabs", ## setting id makes input$tabs give tabName of current  tab
      menuItem("Account", icon = icon("user-circle"), tabName = "account_tab"),
      menuItem("Trade",icon = icon("usd"),tabName = "trade_tab"),
      menuItem("Portfolio",icon = icon("folder-open"),tabName = "portfolio_tab"),
      menuItem("Performance",icon = icon("area-chart"),tabName ="performance_tab"),
      menuItem("Research", icon = icon("book"), tabName = "research_tab"),
      menuItem(
        "Tools", icon = icon("wrench"), tabName = "tools_tab",
        menuItem("Technical Analysis", tabName = "ta_tab"),
        menuItem("Volatility Surface", tabName = "vs_tab"),
        menuItem("Options Strategy Builder", tabName = "osb_tab")
      )
    )
  })


  researchTickerHistoricals1 <- reactive({

    req(input$tickerSelectize1 %in% tickerOptionsNN)
    tickerHistoricals.daily <-  equityDataQuery$ohlcv_historicals(tickerSymbols = input$tickerSelectize1)
    tickerHistoricals.intraday <- equityDataQuery$ohlcv_historicals(tickerSymbols = input$tickerSelectize1, interval = "5minute")

    # ## Check for tradable chains
    # endpoint <- paste0("https://api.robinhood.com/instruments/?symbol=", input$tickerSelectize1)
    # toReturn <- httr::content(httr::GET(url = endpoint))[[2]][[1]]


    list(
      daily = tickerHistoricals.daily,
      intraday = tickerHistoricals.intraday,
      intradayDates = as.character(time(tickerHistoricals.intraday)) %>% substring(0, 10) %>% unique(),
      # hasOptions =  if(length(toReturn[["tradable_chain_id"]]) != 0) TRUE else FALSE
      hasOptions = TRUE
    )


  })


  # tickerOptionsReactive1 <- reactiveValues({
  #
  #   req(input$tickerSelectize1 %in% tickerOptionsNN)
  #   obj <- OptionsData$new(tickerSymbol = input$tickerSelectize1, userAuthentication = client)
  #
  #   res <- vector("list", length(expirationDates))
  #
  #   for(i in 1:length(obj$expirationDates)) {
  #
  #
  #
  #   }
  #
  #
  # })

  output$viewOptions1 <- renderUI({

    if(researchTickerHistoricals1()$hasOptions)
      actionButton(inputId = "loadOptions1", "View Options")

  })


  observeEvent(input$intradaySwitch1 == TRUE, {

    intradayDateOpts <- researchTickerHistoricals1()$intradayDates

    output$intradayDateSelectConditional1 <- renderUI({

      radioGroupButtons(
        inputId = "intradayDateSelect1", label = "Select Date",
        choices = intradayDateOpts,
        justified = TRUE, status = "info", direction = "vertical"
      )

    })

  })


  output$plotlyStockDaily1 <- renderPlotly({

    ohlcv <- if(!input$intradaySwitch1) {

      researchTickerHistoricals1()$daily

    } else {

      req(input$intradayDateSelect1)
      researchTickerHistoricals1()$intraday[input$intradayDateSelect1]

    }

    dailyPlot <- PlotlyDailyChartBuilder$new(
      tickerSymbol = input$tickerSelectize1,
      ohlcvPrices = ohlcv,
      chartType = input$researchChartType1
    )

    dailyPlot$create_volume_plot()
    dailyPlot$volumeCombinedPlot

  })

  observeEvent(input$loadOptions1, {

    output$researchOptionsTabBox1UI <- renderUI({

      tabBox(

        width = 12,
        id = "researchOptionsTabBox1",
        title = paste0(input$tickerSelectize1, " Options"),
        side = "right",
        selected = "Chain",

        tabPanel(
          title = "Monte Carlo Pricer",
          textOutput("Coming Soon!")
        ),

        tabPanel(
          title = "Strategy Builder",
          textOutput("Coming Soon!")
        ),

        tabPanel(
          title = "Volatility Surface",
          textOutput("Coming Soon!")
        ),

        tabPanel(
          title = "Chain",

          column(

            width = 2,
            align = "center",

            br(),

            radioGroupButtons(
              inputId = "callPutSelect1", label = "Contract Type",
              choices = c("call", "put"), selected = "call",
              justified = TRUE, status = "info", direction = "horizontal"
            ),

            br(),

            uiOutput("expirySelectize1UI")

          ),

          column(

            width = 10,
            align = "center",
            dataTableOutput("optionsChainDT1")

          )

        )

      )


    })





    output$expirySelectize1UI <- renderUI({

      tickerOptions <- tickerOptionsReactive1()

      selectizeInput(
        inputId = "expirySelectize1",
        label = "Expiry",
        choices = tickerOptions$expirationDates,
        selected = tickerOptions$expirationDates[1],
        multiple = TRUE,
        options = list(maxItems = 1)
      )

    })

    req(input$expirySelectize1)



    output$optionsChainDT1 <- dataTableOutput({

      tickerOptions <- tickerOptionsReactive1()

      selectedChainQuotes <- tickerOptions$market_quotes(type = input$callPutSelect1, expiry = input$expirySelectize1)

      datatable(
        selectedChainQuotes,
        class = "cell-border compact stripe",
        filter = 'top',
        rownames = FALSE,
        extensions = c('Buttons'),
        fillContainer = TRUE,
        escape = FALSE,
        selection='single',
        options = list(
          scrollX = TRUE,
          columnDefs = list(list(className = 'dt-left', targets = "_all")),
          dom = 'Blfrtip',
          buttons = list(
            'print',
            list(
              extend = 'collection',
              buttons = c('csv','excel'),
              text = 'Download'
            ),
            I('colvis')),
          lengthMenu = list(
            c(-1,10,25,100), # declare values
            c("All",10,25,100) # declare titles
          ),
          pageLength=-1
        )
      )

    })


  })
}
