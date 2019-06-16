


UserAuth <- R6::R6Class(

  classname = "UserAuth",
  portable = TRUE,

  public = list(

    header = NULL,
    client = NULL,

    initialize = function() {

      username_ <- rstudioapi::showPrompt(title = "Username", message = "Username", default = "")
      password_ <- rstudioapi::askForPassword(prompt = 'Password: ')
      private$user_login(username = username_, password = password_)

    }

  ),

  private = list(

    user_authenticate = function(username, password) {

      endpoint <- "https://api.robinhood.com/oauth2/token/"
      client <- list(api_grant_type = "password", api_client_id = "c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS")


      detail <- paste("?grant_type=", client$api_grant_type, "&client_id=", client$api_client_id,
                      "&username=", username, "&password=", password, sep = "")


      auth <- jsonlite::fromJSON(
        rawToChar(
          httr::content(httr::POST(paste(endpoint, detail, sep = "")), type = "json")
        )
      )

      if (is.null(auth$access_token)) {
        cat("\nAuthentication Failed. Please check username and password.\n\n")
        return(NULL)
      }

      return(list(auth = auth, client = client))

    },


    user_login = function(username, password) {

      auth <- private$user_authenticate(username = username, password = password)

      client <- auth$client
      auth <- auth$auth

      if(is.null(auth)) {
        return(NULL)
      }

      self$header <- c(Authorization = paste(auth$token_type, auth$access_token))
      client <- c(client, tokens = list(access_token = auth$access_token, refresh_token = auth$refresh_token))
      accounts <- suppressWarnings(RobinHood::api_accounts(client)) ## need to make our own api_accounts function

      client <- c(client, url = list(positions = accounts$positions, accountID = accounts$url))
      names(client) <- c("grantType", "ID", "accessToken", "refreshToken", "positions.url", "accountID.url")
      self$client <- client
      cat("\n Authentication Complete \n \n")

    }

  )

)



EquityData <- R6::R6Class(

  classname = "EquityData",
  portable = TRUE,

  public = list(

    tickerSymbols = NULL,
    authHeader = NULL,


    initialize = function(userAuthentication) {

      self$authHeader <- userAuthentication$header

    },


    ohlcv_historicals = function(tickerSymbols, interval="day", bounds = "regular") {

      if(length(tickerSymbols) == 1){
        return(private$get_historical_series(tickerSymbols, interval, bounds))
      }

      toReturn <- lapply(as.list(tickerSymbols), function(x)
        private$get_historical_series(x, interval, bounds)
      )

      names(toReturn) <- tickerSymbols
      return(toReturn)

    },


    market_quote = function(tickerSymbols) {

      return(private$get_quote(tickerSymbols))

    },


    equity_instrument_id = function(tickerSymbols) {

      toReturn <- private$get_quote(tickerSymbols)
      toReturn <- toReturn$instrument
      toReturn <- unlist(strsplit(toReturn, "/"))
      return(toReturn[5])

    }


  ),



  private = list(

    get_quote = function(tickerSymbols) {

      ### get quotes
      url <- httr::parse_url("https://api.robinhood.com/quotes/")
      url$query <- list(symbols = paste(tickerSymbols, collapse = ","))

      rawQuote <- suppressWarnings(
        jsonlite::fromJSON(
          RCurl::getForm(
            httr::build_url(url), .opts=list(httpheader=self$authHeader)
          )
        )
      )

      rawQuote <- rawQuote[[1]]

      ### clean quotes
      colnames(rawQuote) <- gsub("_", ".", colnames(rawQuote))
      rawQuote[, 1:8] <- apply(rawQuote[, 1:8], 1, as.numeric)
      rawQuote[, 9] <- as.Date(rawQuote[, 9])
      rawQuote[, c(10,13,15)] <- apply(rawQuote[, c(10,13,15)], 2, as.character)
      rawQuote[, 11:12] <- apply(rawQuote[, 11:12], 1, as.logical)
      rawQuote[, 14] <- as.POSIXct(gsub("T", " ", rawQuote[, 14]), tz="UTC")

      return(rawQuote)

    },


    get_historical_series = function(tickerSymbol, interval="day", bounds = "regular") {


      if(interval != "day") {

        span <- "week"
        intraDay <- TRUE

      } else {

        span = "year"
        intraDay = FALSE

      }


      ### get historicals
      url <- httr::parse_url("https://api.robinhood.com/")
      url$path <- paste0("quotes/historicals/", tickerSymbol, "/")
      url$query <-   url$query <- list(interval = interval, span = span, bounds = bounds)

      historicals <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(httr::build_url(url), .opts=list(httpheader=self$authHeader)))
      )

      historicals <- historicals$historicals

      historicals$begins_at <- suppressMessages(lubridate::ymd_hms(historicals$begins_at, tz = Sys.timezone()))

      if(!intraDay) historicals$begins_at <- as.Date(historicals$begins_at)

      historicals$open_price <- as.numeric(historicals$open_price)
      historicals$close_price <- as.numeric(historicals$close_price)
      historicals$high_price <- as.numeric(historicals$high_price)
      historicals$low_price <- as.numeric(historicals$low_price)

      toReturn <- apply(historicals[,c(2,4,5,3,6)], 2, as.numeric)
      colnames(toReturn) <- c("open","high","low","close","volume")
      toReturn <- xts::xts(toReturn, order.by=historicals[,1])

      return(toReturn)

    }


  )

)





##### OptionsDataCollector #####


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
      return(toReturn[["tradable_chain_id"]])

    },


    initialize = function(tickerSymbol, userAuthentication) {

      self$tickerSymbol <- tickerSymbol
      self$header <- userAuthentication$header

      self$chainID <- self$options_chain_id(tickerSymbol = tickerSymbol)
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





##### Account #####

Account <- R6::R6Class(

  classname = "Account",
  inherit = UserAuthentication,
  portable = TRUE,

  public = list(

    accountMarginBalances = NULL,
    accountSummary = NULL,
    equityPositions = NULL,
    optionsPositions = NULL,
    portfolioOverview = NULL,
    dayStats=NULL,


    initialize = function(username, password){

      super$initialize(username=username, password=password)

    },


    collect_account_data = function() {

      private$get_account_summary_table()
      self$equityPositions <- private$positions_table()
      self$portfolioOverview <- private$portfolio_overview_table()
      self$optionsPositions <- private$options_positions_table()
      private$get_day_stats()

    }


  ),


  private=list(

    portfolioEndpoint = NULL,
    positionsEndpoint = NULL,
    specificAccountEndpoint = NULL,


    get_account_summary_table = function() {

      accountEndpoint <- "https://api.robinhood.com/accounts/"

      request <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(accountEndpoint, .opts=list(httpheader=self$header)))
      )

      toReturn <- request$results

      self$accountMarginBalances <- toReturn$margin_balances
      private$portfolioEndpoint <- toReturn$portfolio
      private$positionsEndpoint <- toReturn$positions
      private$specificAccountEndpoint <- toReturn$url

      irrelevantColumns <- c("margin_balances", "portfolio", "positions", "url", "instant_eligibility", "option_level",
                             "deactivated", "created_at", "is_pinnacle_account", "can_downgrade_to_cash", "user",
                             "withdrawal_halted", "state", "type", "sweep_enabled", "deposit_halted", "account_number",
                             "rhs_account_number",  "active_subscription_id", "only_position_closing_trades",
                             "sma_held_for_orders", "max_ach_early_access_amount", "sma", "cash_balances")

      relevantColumns <- c("buying_power", "cash", "cash_available_for_withdrawal", "cash_held_for_orders",
                           "unsettled_funds", "unsettled_debit", "uncleared_deposits", "updated_at")
      toReturn <- toReturn[, which(colnames(toReturn) %in% relevantColumns)]
      toReturn <- toReturn[, c(3, 5, 2, 4, 8, 6, 7, 1)]

      self$accountSummary <- toReturn

    },


    positions_table = function() {

      request <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getURI(private$positionsEndpoint, .opts=list(httpheader=self$header)))
      )

      irrelevantColumns <- c("shares_held_for_stock_grants", "account", "shares_held_for_options_events",
                             "created_at", "shares_pending_from_options_events", "url")

      toReturn <- request$results[, -which(colnames(request$results) %in% irrelevantColumns)]

      instrumentInfo <- list()

      for(i in 1:nrow(toReturn)) {
        tempInfo <- suppressWarnings(jsonlite::fromJSON(RCurl::getForm(toReturn$instrument[i])))
        instrumentInfo[[i]] <- lapply(list("symbol", "simple_name", "name", "type"), function(x) tempInfo[[x]])
      }

      instrumentInfo <- do.call(rbind, lapply(instrumentInfo, c))
      colnames(instrumentInfo) <- c("ticker", "short_name", "full_name", "type")
      instrumentInfo <- as.data.frame(instrumentInfo, stringsAsFactors = FALSE)
      toReturn <- cbind(instrumentInfo, toReturn)
      positionsOrderQuantity <- sort(as.numeric(toReturn$quantity), index.return=TRUE, decreasing=TRUE)[[2]]
      toReturn <- toReturn[positionsOrderQuantity, c(1, 10, 14, 6, 12, 5, 9, 13, 7, 4, 2, 3, 11, 8)] ### positions table

      return(toReturn)

    },


    portfolio_overview_table = function () {

      request <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(private$portfolioEndpoint, .opts=list(httpheader=self$header)))
      )

      toReturn <- as.data.frame(request)
      toReturn <- toReturn[, -c(1, 2, 4)]
      return(toReturn)


    },



    options_positions_table = function() {

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

      toReturn <- toReturn[sort(as.numeric(toReturn$quantity), index.return=TRUE, decreasing=TRUE)[[2]], ]

      return(toReturn)

    },


    get_day_stats = function(){

      portfolioURL <- paste("https://api.robinhood.com/accounts/", self$accountNumber, "/portfolio/", sep = "")
      request <- suppressWarnings(
        jsonlite::fromJSON(RCurl::getForm(private$portfolioEndpoint, .opts=list(httpheader=self$header)))
      )
      response <- request$results
      lastEquity <- response$adjusted_equity_previous_close
      equity <- response$equity

      if(is.null(equity)){
        equity <- response$extended_hours_equity
      }

      equity <- as.numeric(equity)
      lastEquity <- as.numeric(lastEquity)
      change <- equity-lastEquity
      pctChange <- (change/lastEquity)*100
      dayChange <- data.frame("Change($)"=change, "Percent Change"=pctChange,"Equity"=equity)
      self$dayStats <- dayChange

    }


  )

)









