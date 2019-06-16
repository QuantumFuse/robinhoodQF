


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
      xts::tzone(toReturn) <- "America/New_York"
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
      
      historicals$begins_at <- suppressMessages(lubridate::ymd_hms(historicals$begins_at))
      
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


