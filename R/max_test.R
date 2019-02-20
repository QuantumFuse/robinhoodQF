source("functions.R")
source("PlotlyCharting.R")

access_robinhood(rstudioapi::showPrompt(title = "Username", message = "Username", default = ""),
                 rstudioapi::askForPassword(prompt = 'Password: '))

mySymbols <- c("AAPL","GOOG","AMZN")
robinhood_quotes(mySymbols)

data<-robinhood_daily_historicals(symbols=mySymbols)
data<-robinhood_intraday_historicals(symbols=mySymbols)
dataHead <- lapply(data, head)

dataHead$AAPL
dataHead$GOOG
dataHead$AMZN

robinhoodUser$account$positionsTable
robinhoodUser$account$optionsPositionsTable
robinhoodUser$account$portfolioEquity

myta <- PlotlyTechnicalAnalysis$new(ohlcvPrices = data$AAPL, tickerSymbol = "AAPL")
cb<-PlotlyDailyChartBuilder$new(myta)
cb$create_full_plots(chartType="candlestick",includeSMA=TRUE,includeBBands = TRUE)
cb$macdCombinedPlot


