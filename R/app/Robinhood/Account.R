#' Account R6 Class
#'
#' Create an instance of the R6 Account class.
#' @param login  Initialized R6 Login class instance.
Account <- R6::R6Class(
  
  classname = "Account",  
  inherit = Login, 
  portable = TRUE,
  
  public = list(
    
    user = NULL,
    positionsList = NULL,
    positionsTable = NULL,
    optionsPositionsTable = NULL,
    portfolioEquity = NULL,
    day_stats=NULL,
    
    initialize = function(login){
      stopifnot(inherits(login,"Login"))
      self$user <- login
      private$create_positions_table()
      private$get_options_positions_table()
      private$get_portfolio_equity()
      private$get_day_PnL()
    }
    
  ),
  
  private=list(
    
    ## extract ticker and full equity security name from positions response
    get_instrument_info = function(instrumentURL) {
      responseContent <- httr::content(httr::GET(instrumentURL))
      instrumentInfo <- list(ticker=responseContent$symbol, name=responseContent$name)
      return(instrumentInfo)
    }, 
    
    ## request equity positions 
    request_positions_list = function(){
      response <- httr::GET(self$user$endpoints$positions, httr::add_headers(.headers=self$user$authHeader))
      self$positionsList <- httr::content(response)$results
    },
    
    ## create a data frame with watch list and portfolio equity positions 
    create_positions_table = function(){
      private$request_positions_list()
      extractedInfo <- lapply(self$positionsList, function(x) 
        append(private$get_instrument_info(x$instrument), list(quantity=x$quantity,average_price=x$average_buy_price))
      )
      names(extractedInfo) <- lapply(extractedInfo, function(x) x$ticker)
      extractedInfo <- lapply(extractedInfo, function(x) x[-1])
      extractedInfo <- as.data.frame(do.call(rbind,extractedInfo))
      extractedInfo[,1] <- as.character(unlist(extractedInfo[,1]))
      extractedInfo[,2] <- as.numeric(extractedInfo[,2])
      extractedInfo[,3] <- as.numeric(extractedInfo[,3])
      
      self$positionsTable <- extractedInfo
    },
    
    get_portfolio_equity = function() {
      response <- httr::GET(self$user$endpoints$portfolio, httr::add_headers(.headers=self$user$authHeader))
      extendedHours <- httr::content(response)$extended_hours_equity
      toReturn <- httr::content(response)$equity
      self$portfolioEquity <- if(length(extendedHours)>0){
        if(as.numeric(extendedHours)>=as.numeric(toReturn)) as.numeric(extendedHours)
      } else {
        as.numeric(toReturn)
      }
    },
    
    get_options_positions_table = function() {
      response <- httr::GET(self$user$endpoints$options_positions, httr::add_headers(.headers=self$user$authHeader))
      responseResults <- httr::content(response)$results
      
      quantity <- lapply(responseResults, function(x) as.numeric(x$quantity))
      responseResults <- responseResults[quantity>0]
      
      self$optionsPositionsTable <- data.frame(
        ticker = unlist(lapply(responseResults, function(x) x$chain_symbol)), 
        quantity =unlist(lapply(responseResults, function(x) x$quantity)), 
        type = unlist(lapply(responseResults, function(x) x$type)), 
        price = unlist(lapply(responseResults, function(x) as.numeric(x$average_price)))
      )
      
    },
    get_day_PnL = function(){
      portfolioURL <- paste("https://api.robinhood.com/accounts/", self$user$accountNumber, "/portfolio/", sep = "")
      response <- httr::GET(portfolioURL, httr::add_headers(.headers=self$user$authHeader))
      response <- httr::content(response)
      lastEquity <- response$adjusted_equity_previous_close
      equity <- response$extended_hours_equity
      
      if(is.null(equity)){
        equity <- response$equity
      }
      
      equity <- as.numeric(equity)
      lastEquity <- as.numeric(lastEquity)
      change <- equity-lastEquity
      pctChange <- (change/lastEquity)*100
      dayChange <- data.frame("Change($)"=change, "Percent Change"=pctChange,"Equity"=equity)
      self$day_stats <- dayChange
    }
  )
  
)

