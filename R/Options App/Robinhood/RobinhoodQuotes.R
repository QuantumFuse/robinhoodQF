RobinhoodQuotes <- R6::R6Class(
  
  classname = "RobinhoodQuotes",
  inherit = Account, 
  portable = TRUE,
  
  public = list(
    
    userAccount = NULL,
    
    initialize = function(userAccount){
      stopifnot(inherits(userAccount,"Account"))
      self$userAccount <- userAccount
    }, 
    
    get_daily_series =  function(symbol, bounds="regular"){
      
      private$build_historical_url(symbol, "day", "year", bounds)
      response <- httr::GET(url=private$urlHistorical, httr::add_headers(.headers=self$userAccount$user$authHeader))
      
      if(httr::http_error(response))
        stop(httr::content(x=response, as="text", encoding="UTF-8"), call.=FALSE)
      
      responseContent <- jsonlite::fromJSON(txt = httr::content(x = response, as = "text", encoding = "UTF-8"))
      
      historicals <- responseContent$historicals
      historicals$begins_at <- lubridate::ymd_hms(historicals$begins_at,tz = "UTC")
      historicals$open_price <- as.numeric(historicals$open_price)
      historicals$close_price <- as.numeric(historicals$close_price)
      historicals$high_price <- as.numeric(historicals$high_price)
      historicals$low_price <- as.numeric(historicals$low_price)
      dates <- historicals[,1]
      toReturn <- apply(historicals[,c(2,4,5,3,6)], 2, as.numeric)
      colnames(toReturn) <- c("open","high","low","close","volume")
      toReturn <- xts::xts(toReturn, order.by=dates)
      
      return(toReturn)
      
    },
    
    get_intraday_series =  function(symbol, span, bounds="regular"){
      
      private$build_historical_url(symbol, interval="5minute",span=span, bounds=bounds)
      response <- httr::GET(url=private$urlHistorical, httr::add_headers(.headers=self$userAccount$user$authHeader))
      
      if(httr::http_error(response))
        stop(httr::content(x=response, as="text", encoding="UTF-8"), call.=FALSE)
      
      responseContent <- jsonlite::fromJSON(txt = httr::content(x = response, as = "text", encoding = "UTF-8"))
      
      historicals <- responseContent$historicals
      historicals$begins_at <- lubridate::ymd_hms(historicals$begins_at,tz = "UTC")
      historicals$open_price <- as.numeric(historicals$open_price)
      historicals$close_price <- as.numeric(historicals$close_price)
      historicals$high_price <- as.numeric(historicals$high_price)
      historicals$low_price <- as.numeric(historicals$low_price)
      dates <- historicals[,1]
      toReturn <- apply(historicals[,c(2,4,5,3,6)], 2, as.numeric)
      colnames(toReturn) <- c("open","high","low","close","volume")
      toReturn <- xts::xts(toReturn, order.by=dates)
      
      return(toReturn)
      
    },
    
    get_daily_historicals = function(symbols, bounds="regular") {
      symbols <- as.list(symbols)
      
      if(length(symbols) == 1){
        return(self$get_daily_series(symbols[[1]], bounds))
      }
      
      toReturn <- lapply(symbols, function(x) self$get_daily_series(x, bounds))
      names(toReturn) <- symbols
      return(toReturn)
      
    }, 
    
    get_intraday_historicals = function(symbols, span, bounds="regular") {
      symbols <- as.list(symbols)
      
      if(length(symbols) == 1){
        return(self$get_intraday_series(symbols[[1]], span, bounds))
      }
      
      toReturn <- lapply(symbols, function(x) self$get_intraday_series(x, span, bounds))
      names(toReturn) <- symbols
      return(toReturn)
      
    }, 
    
    get_quotes = function(symbols){
      private$build_current_url(symbols)
      response <- httr::GET(url=private$urlCurrent,httr::add_headers(.headers=self$userAccount$user$authHeader))
      httr::stop_for_status(response)
      quotes <- jsonlite::fromJSON(txt = httr::content(x = response, as = "text", encoding = "UTF-8"))
      quotes <- quotes$results
      quotes$previous_close_date <- lubridate::ymd(quotes$previous_close_date, tz = "UTC")
      quotes$updated_at <- lubridate::ymd_hms(quotes$updated_at, tz = "UTC")
      return(quotes)
    }
  ),
  
  private = list(
    
    urlHistorical = NULL, 
    urlCurrent = NULL,
    
    build_historical_url = function(symbol, interval, span, bounds){
      url <- httr::parse_url(self$userAccount$user$endpoints$origin)
      url$path <- paste0("quotes/historicals/", symbol, "/")
      url$query <- list(interval = interval, span = span, bounds = bounds)
      private$urlHistorical <- httr::build_url(url)
    }, 
    
    build_current_url = function(symbols) {
      url <- httr::parse_url(self$userAccount$user$endpoints$quotes_base)
      url$query <- list(symbols = paste(symbols, collapse = ","))
      private$urlCurrent <- httr::build_url(url)
    }
  )
)