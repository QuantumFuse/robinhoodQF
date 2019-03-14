source("functions.R")
source("PlotlyCharting.R")
library(data.table)

#############################################
### Login & initialize robinhoodUser class ## 
#############################################

access_robinhood(rstudioapi::showPrompt(title = "Username", message = "Username", default = ""),
                 rstudioapi::askForPassword(prompt = 'Password: '))

#############################################
### Get current equity and positions ######## 
#############################################

robinhoodUser$account$positionsTable
robinhoodUser$account$optionsPositionsTable
robinhoodUser$account$portfolioEquity
### Get watch list tickers 
mySymbols<-get_watchlist_tickers()
mySymbols<-mySymbols[-which(mySymbols%in%c("VXX","TSRO","SODA"))]

#############################################
### Get intraday and daily OHLCV data ####### 
#############################################
data_intraday<-robinhood_intraday_historicals(symbols=mySymbols,span="week")
data_frame<-lapply(data_intraday, as.data.frame)
for(i in 1:length(mySymbols)){
  data_name<-mySymbols[i]
  data<-robinhood_intraday_historicals(mySymbols[i],span="week")
  assign(data_name,data)
}

mySymbols <- c("AAPL","GOOG","AMZN")
robinhood_quotes(mySymbols)

data_daily<-robinhood_daily_historicals(symbols=mySymbols)
data_intraday<-robinhood_intraday_historicals(symbols=mySymbols,span="week")
dataHead <- lapply(data_intraday, head)

dataHead$AAPL
dataHead$GOOG
dataHead$AMZN

#############################################
### Plotly Charting with TA ################# 
#############################################
myChart <- create_chart(tickerSymbol="AAPL", ohlcvData=data_daily$AAPL)
myChart$create_plot("candlestick")
p2<-myChart$volumeCombinedPlot


myta <- PlotlyTechnicalAnalysis$new(ohlcvPrices = data_daily$AAPL, tickerSymbol = "AAPL")
cb<-PlotlyDailyChartBuilder$new(myta)
cb$create_full_plots(chartType="candlestick",includeSMA=TRUE,includeBBands = TRUE)
cb$macdCombinedPlot

#############################################
### Orders Class: order history and summary # 
#############################################

Order<-Orders$new(robinhoodUser$account)

orders<-Order$orders
individual_pnl<-orders$Individual_PL
current_positions<-orders$Current_Positions
allocation<-orders$Allocation
grouped_order_history<-orders$Grouped_History
full_order_history<-orders$Transactions
options_history<-Order$options_orders

#############################################
### Portfolio Performance Summary ###########
#############################################
summary_PL<-individual_pnl
profits<-summary_PL[,4]
profits<-as.numeric(profits)

# profit_total<-sum(profits)+commission
# profits<-c(profits,commission)
profits<-currency( profits,"$",format="f",digits=2)
tickers<-summary_PL$Ticker
tickers<-as.character(tickers)
# tickers<-c(tickers,"Commission*")
colors<-NULL
for (i in 1:length(tickers)){
  if(profits[i]<0){
    colors[i]<-'rgba(209,25,25,0.8)'
  }
  else{
    colors[i]<-'rgba(68,149,68,1)'
  }
}

# colors[length(tickers)]<-'rgba(177,188,192,0.8)'
x <- c(tickers)
y <- c(profits)
data <- data.frame(x, y)
data$x <- factor(data$x, levels = data[["x"]])

portfolio_performance_plot<-plot_ly(data, x = ~x, y = ~y, type = 'bar',
        text=x, textposition='auto',
        marker = list(color = c(colors),
                      line = list(color = 'rgb(8,48,107)', width = 1.5)),
        source = "summary_PL") %>%
  layout(title = paste0("Portfolio Performance as of ",as.character(Sys.Date())),
         xaxis = list(title = "Security"),
         yaxis = list(title = "$"))

#############################################
### Options Performance Summary #############
#############################################

options_orders_list<-rh_getOptionsOrders(robinhoodUser$account$user$authHeader)
options_pnl<-options_orders_list$individual_pnl
options_profits<-options_pnl$Value
options_tickers<-options_pnl$Ticker

options_profits<-currency(options_profits,"$",format="f",digits=2)
colors<-NULL
for (i in 1:length(options_tickers)){
  if(options_profits[i]<0){
    colors[i]<-'rgba(209,25,25,0.8)'
  }
  else{
    colors[i]<-'rgba(68,149,68,1)'
  }
}
x <- c(options_tickers)
y <- c(options_profits)
data <- data.frame(x, y)
data$x <- factor(data$x, levels = data[["x"]])

options_performance_plot<-plot_ly(data, x = ~x, y = ~y, type = 'bar',
        text=x, textposition='auto',
        marker = list(color = c(colors),
                      line = list(color = 'rgb(8,48,107)', width = 1.5)),
        source = "summary_PL") %>%
  layout(title = paste0("Options Performance as of ",as.character(Sys.Date())),
         xaxis = list(title = "Contract Ticker"),
         yaxis = list(title = "$"))

#############################################
### Visualize timeline of trades for ticker #
#############################################
library(timevis)
AMZN_trade_timeline<-Order$get_trade_timeline("AMZN",orders)
timevis(AMZN_trade_timeline)




