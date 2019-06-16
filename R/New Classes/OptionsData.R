


OptionsData <- R6::R6Class(

  classname = "OptionsData",
  portable = TRUE,

  public = list(

    tickerSymbol = NULL,
    header = NULL,
    chainID = NULL,
    optionsMarketData = NULL,
    expirationDates = NULL,


    ticker_info = function(tickerSymbol) {

      endpoint <- paste0("https://api.robinhood.com/instruments/?symbol=", tickerSymbol)
      toReturn <- httr::content(httr::GET(url = endpoint))[[2]][[1]]
      return(toReturn)

    },




    options_chain_id = function(tickerSymbol) {

      toReturn <- self$ticker_info(tickerSymbol)
      if(length(toReturn[["tradable_chain_id"]]) == 0) return(NA)
      return(toReturn[["tradable_chain_id"]])

    },


    initialize = function(tickerSymbol, userAuthentication) {

      self$tickerSymbol <- tickerSymbol
      self$header <- userAuthentication$header

      self$chainID <- self$options_chain_id(tickerSymbol = tickerSymbol)
      if(is.na(self$chainID)) {

        cat("\n\n")
        cat(tickerSymbol, "does not appear to have a tradable options chain. \n")
        cat("Please try another ticker.\n\n")

        return(0)
      }

      contractSpecs <- private$get_specifications()

      specsByTypeByExpiry <- lapply(contractSpecs[[1]], function(x) {

        toReturn <- lapply(as.list(contractSpecs$expirationDates), function(y) x[x$expiration_date == y, ])
        names(toReturn) <- contractSpecs$expirationDates
        return(toReturn)

      })

      private$specsByTypeByExpiry <- specsByTypeByExpiry
      self$expirationDates <- contractSpecs$expirationDates
      private$contractSpecs <- contractSpecs[[1]]

    },


    market_quotes = function(type, expiry) {

      private$get_market_quote(type, expiry)


    },


    historical_data = function(type, expiry, span="year") {
      private$options_historicals_query(type, expiry, span)
    }


  ),




  private = list(

    specsByTypeByExpiry = NULL,
    contractSpecs = NULL,
    optionsMarketQuotes= NULL,

    optionsAddedHeader = c(
      'Accept'='*/*',
      'Accept-Encoding'='gzip, deflate',
      'Accept-Langauge'='en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5',
      'User-Agent'='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'
    ),


    get_specifications = function() {

      optionsSpecs <- list()
      nextURL <- "https://api.robinhood.com/options/instruments/"
      requestCounter <- 0

      while(!is.null(nextURL)) {

        requestCounter <- requestCounter + 1

        request <- suppressWarnings(
          jsonlite::fromJSON(
            RCurl::getForm(
              nextURL, .params = list(
                chain_id = self$chainID ,
                rhs_tradability="tradable",
                tradability="tradable",
                state="active"
              )
            )
          )
        )


        optionsSpecs[[requestCounter]] <- request$results
        nextURL <- request$`next`

      }

      optionsSpecs <- as.data.frame(do.call(rbind, lapply(optionsSpecs, as.matrix)))
      colnames(optionsSpecs)[which(colnames(optionsSpecs)=="url")] <- "instrument"

      expirationDates <- levels(optionsSpecs$expiration_date)

      optionsSpecs <- list(
        call = optionsSpecs[optionsSpecs$type == "call", ],
        put = optionsSpecs[optionsSpecs$type == "put", ]
      )

      return(list(specifications = optionsSpecs, expirationDates = expirationDates))

    },


    get_market_quote = function(type, expiry) {

      optionsMarketDataEndpoint <- "https://api.robinhood.com/marketdata/options/"

      chainQuote <- suppressWarnings(jsonlite::fromJSON(RCurl::getForm(
        optionsMarketDataEndpoint, .opts = list(httpheader = c(private$optionsAddedHeader, self$header)),
        .params = list(instruments = paste0(as.character(private$specsByTypeByExpiry[[type]][[expiry]]$instrument), collapse=","))
      )))

      chainQuote <- suppressWarnings(dplyr::inner_join(x = chainQuote$results, y = private$specsByTypeByExpiry[[type]][[expiry]], by="instrument"))

      return(chainQuote)


    },


    options_historicals_query = function(type, expiry, span) {

      possibleIntervals<-list(day="5minute",week="10minute",year="day","5year"="week")
      optionsHistoricalsEndpoint = "https://api.robinhood.com/marketdata/options/historicals/"

      results <- suppressWarnings(
        jsonlite::fromJSON(
          RCurl::getForm(
            optionsHistoricalsEndpoint, .opts = list(httpheader = c(private$optionsAddedHeader, self$header)),
            .params = list(
              span = span,
              interval = possibleIntervals[[span]],
              instruments = paste0(as.character(private$specsByTypeByExpiry[[type]][[expiry]]$instrument), collapse=",")
            )
          )
        )
      )

      results <- results[[1]]
      historicalInstrumentIDs <- results$instrument
      results <- results[[1]]
      names(results) <- as.numeric(as.character(private$specsByTypeByExpiry[[type]][[expiry]]$strike_price))
      return(results)

    }


  )


)
