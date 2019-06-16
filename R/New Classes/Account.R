
Account <- R6::R6Class(

  classname = "Account",
  inherit = UserAuth,
  portable = TRUE,

  public = list(

    watchlist = NULL,
    accountInfo = NULL,
    positions = NULL,
    marginBalances = NULL,
    portfolioInfo = NULL,

    initialize = function(){

      super$initialize()

      request.accounts <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm("https://api.robinhood.com/accounts/", .opts=list(httpheader=self$header)))
      )

      request.portfolio <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(request.accounts$results$portfolio, .opts=list(httpheader=self$header)))
      )

      request.positions <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(request.accounts$results$positions, .opts=list(httpheader=self$header)))
      )

      private$positionsRR.equity <- request.positions$results
      private$portfolioRR <- request.portfolio
      private$accountRR <- request.accounts$results

      self$positions = list(equity = NULL, options = NULL, crypto = NULL)

      private$get_account_summary()
      private$get_portfolio_info()

    },


    get_equity_holdings = function() {

      self$positions$equity <- private$positionsRR.equity[as.numeric(private$positionsRR.equity$quantity) != 0, ] %>%
        private$add_instrument_names() %>%
        suppressWarnings()



    },


    get_watchlist = function() {

      self$watchlist <- private$positionsRR.equity[as.numeric(private$positionsRR.equity$quantity) == 0, ] %>%
        private$add_instrument_names() %>% suppressWarnings()

    },






    get_options_holdings = function() {

      optionsPositionsEndpoint <- "https://api.robinhood.com/options/positions/"

      request <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(optionsPositionsEndpoint, .opts=list(httpheader=self$header)))
      )

      toReturn <- request$results

      toReturn <- data.frame(
        ticker = toReturn$chain_symbol,
        average_price = toReturn$average_price,
        quantity = toReturn$quantity,
        type = toReturn$type,
        pending_buy_quantity = toReturn$pending_buy_quantity,
        pending_sell_quantity = toReturn$pending_sell_quantity,
        id = toReturn$id,
        updated_at = toReturn$updated_at
      )

      self$positions$options <- toReturn[sort(as.numeric(toReturn$quantity), index.return=TRUE, decreasing=TRUE)[[2]], ]


    },


    get_crypto_holdings = function() {

      return(NULL)

    },


    get_day_stats = function(){

      return(NULL)

    },

    get_instrument = function(instrumentURL) {

      toReturn <- suppressWarnings(jsonlite::fromJSON(RCurl::getForm(instrumentURL)))

      toReturn <- data.frame(
        ticker = toReturn$symbol,
        simple_name = if(is.null(toReturn$simple_name)) toReturn$name else toReturn$simple_name,
        name = toReturn$name,
        instrument = instrumentURL
      )

      return(toReturn)

    }


  ),


  private=list(

    portfolioRR = NULL,
    positionsRR.equity = NULL,
    accountRR = NULL,


    add_instrument_names = function(instrumentDF) {

      temp <- vector("list", nrow(instrumentDF))

      for(i in 1:length(temp)) {
        temp[[i]] <- self$get_instrument(instrumentDF$instrument[i])
      }

      names(temp) <- unlist(lapply(temp, function(x) x["ticker"]))
      temp <- suppressWarnings(dplyr::bind_rows(temp))

      toReturn <- suppressMessages(dplyr::inner_join(as.data.frame(temp), instrumentDF))
      return(toReturn)

    },


    get_portfolio_info = function () {

      requestResults <- private$portfolioRR
      requestResults <- requestResults[!(names(requestResults) %in% c("start_date", "account", "url"))]
      requestResults <- as.numeric(unlist(requestResults))
      names(requestResults) <- names(private$portfolioRR)[!(names(private$portfolioRR) %in% c("start_date", "account", "url"))]

      self$portfolioInfo <- data.frame(start_date = as.Date(private$portfolioRR$start_date), t(requestResults))

    },


    get_account_summary = function() {

      requestResults <- private$accountRR
      requestResults <- requestResults[, !(names(requestResults) %in% c("instant_eligibility", "margin_balances"))]
      requestResults <- t(requestResults) %>% as.data.frame()
      colnames(requestResults) <- " "

      self$accountInfo <- requestResults
      self$marginBalances <- private$accountRR$margin_balances

    }


  )

)
