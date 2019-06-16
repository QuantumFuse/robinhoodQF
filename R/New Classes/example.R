
#'
#'     06/01/2019
#'
#'          + Fixed user authentication and UserAuth now prompts you with the RStudio API automatically
#'          + Rewrote options class. OptionsData now does queries by contract type and expiry
#'
#'     Next Steps
#'          + clean data.table output
#'          + Add validation for expiry date inputs
#'          + Orders Classes
#'          + Improve and clean up account class
#'          + Performance class
#'
#'     Required CRAN Packages:
#'          + R6
#'          + magrittr
#'          + dyplyr
#'          + httr
#'          + jsonlite
#'          + rstudioapi
#'          + RobinHood
#'          + RCurl
#'          + lubridate
#'


suppressMessages(library(tidyverse))
suppressMessages(library(magrittr))

source('C:/Dev/robinhoodQF/R/New Classes/AuthUser.R')
source('C:/Dev/robinhoodQF/R/New Classes/EquityData.R')
source('C:/Dev/robinhoodQF/R/New Classes/OptionsData.R')
source('C:/Dev/robinhoodQF/R/New Classes/Account.R')
source('C:/Dev/robinhoodQF/R/BasicChartBuilder.R')

client <- Account$new()
equityDataQuery <- EquityData$new(userAuthentication = client)

tickerSymbol <- "MU"

tickerQuote <- equityDataQuery$market_quote(tickerSymbols = tickerSymbol)
tickerHistoricals.daily <- equityDataQuery$ohlcv_historicals(tickerSymbols = tickerSymbol)
tickerHistoricals.intraday <- equityDataQuery$ohlcv_historicals(tickerSymbols = tickerSymbol, interval = "5minute")

print(tickerHistoricals)
print(tickerHistoricals.daily)
print(tickerHistoricals.intraday)

tickerOptions <- OptionsData$new(tickerSymbol = "OKTA", userAuthentication = client)

print(tickerOptions$expirationDates)

type <- "call"
expiry <- tickerOptions$expirationDates[1]

selectedChainQuotes <- tickerOptions$market_quotes(type = type, expiry = expiry)
selectedChainHistoricals.daily <- tickerOptions$historical_data(type = type, expiry = expiry)
selectedChainHistoricals.intraday <- tickerOptions$historical_data(type = type, expiry = expiry, span = "day")

atmStrike <- if(type == "call") floor(tickerQuote$last.trade.price) else ceiling(tickerQuote$last.trade.price)

print(selectedChainQuotes)
print(selectedChainHistoricals.daily[[as.character(atmStrike)]])
print(selectedChainHistoricals.intraday[[as.character(atmStrike)]])


client$accountInfo
client$portfolioInfo
client$marginBalances

client$get_watchlist()
client$get_equity_holdings()
client$get_options_holdings()

client$watchlist
client$positions$equity
client$positions$options
client$positions$crypto











