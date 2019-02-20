library(plotly)
library(xts)

#' Gain access to the robinhood API
#'
#' @param username Your robinhood account username.
#' @param password Your robinhood account password.
access_robinhood <- function(username, password){
  
  source("BaseEndpoints.R")
  source("Login.R")
  source("Account.R")
  source("RobinhoodQuotes.R")
  
  userLogin=Login$new(username=username,password=password)
  userAccount=Account$new(userLogin)
  userQuotes=RobinhoodQuotes$new(userAccount)
  
  toReturn<-list(account=userAccount,quotes=userQuotes)
  
  assign("robinhoodUser", toReturn, envir=.GlobalEnv)
  
  rm(BaseEndpoints,envir=.GlobalEnv)
  rm(Login,envir=.GlobalEnv)
  rm(Account,envir=.GlobalEnv)
  rm(RobinhoodQuotes,envir=.GlobalEnv)
  
}

#' Get your watch list tickers
#'
get_watchlist_tickers <- function() {
  toReturn <- robinhoodUser$account$positionsTable
  toReturn <- toReturn[toReturn$quantity == 0, ]
  return(rownames(toReturn))
}

#' Get your equity portfolio holdings with average prices.
#' 
#' @param tickersOnly logical. If TRUE, returns character vector of ticker names currently held in your portfolio
get_equity_holdings <- function(tickersOnly=FALSE) {
  toReturn <- robinhoodUser$account$positionsTable
  toReturn <- toReturn[toReturn$quantity > 0, ]
  if(tickersOnly) 
    return(rownames(toReturn))
  else 
    return(list(table = toReturn[-1,], tickers = rownames(toReturn)))
}

##### Quotes and Historicals #####

#' Dowload one year of OHLCV daily data from robinhood 
#'
#' @param symbols A character vector or list specifying the names of each symbol to download
robinhood_daily_historicals <- function(symbols){
  return(robinhoodUser$quotes$get_daily_historicals(symbols))
}

#' Dowload one week of OHLCV 5 minute intraday data from robinhood 
#'
#' @param symbols A character vector or list specifying the names of each symbol to download
robinhood_intraday_historicals <- function(symbols){
  return(robinhoodUser$quotes$get_intraday_historicals(symbols))
}

#' Dowload current quote data from robinhood 
#'
#' @param symbols A character vector or list specifying the names of each symbol to download
robinhood_quotes <-function(symbols){
  return(robinhoodUser$quotes$get_quotes(symbols))
}

##### Charting #####

#' Build a plotly chart.
#' 
#' @param tickerSymbol short hand ticker symbol 
#' @param ohlcvData an xts object with OHLCV data
create_chart <- function(tickerSymbol=NULL, ohlcvData){
  source("BasicChartBuilder.R")
  return(BasicChartBuilder$new(ohlcvData=ohlcvData, tickerSymbol=tickerSymbol))
}
