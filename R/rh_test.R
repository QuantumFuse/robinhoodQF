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
#########################################################
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

### Get options data
source("Requests.R")
source("RobinhoodOptions.R")

optionsData = RobinhoodOptions$new("MU",robinhoodUser)
currentQuotes <- optionsData$current_chains()
currentStockP <- as.numeric(robinhoodUser$quotes$get_quotes("MU")$last_trade_price)

dtm <- as.list(as.Date(names(currentQuotes))- Sys.Date())
names(dtm) <- names(currentQuotes)
strikesAndVol <-lapply(currentQuotes, function(x) x$puts$numerical[,c("strike_price", "implied_volatility")])

volSurfaceData <- lapply(as.list(names(currentQuotes)), function(x) {
  y <- strikesAndVol[[x]]
  y$dtm <-dtm[[x]]
  return(y)
})

volSurfaceData <- do.call(rbind, volSurfaceData)
volSurfaceData <- volSurfaceData[volSurfaceData$strike_price < ceiling(currentStockP*1.15), ]
volSurfaceData <- volSurfaceData[volSurfaceData$strike_price > floor(currentStockP*.85), ]
colnames(volSurfaceData)<-c("K", "IV", "DTM")
volSurfaceData<-volSurfaceData[complete.cases(volSurfaceData), ]

library(plotly)
plot_ly() %>%
  add_trace(data = volSurfaceData,  x=~K, y=~DTM, z=~IV, type="mesh3d",
            intensity = seq(0, 1, length = nrow(volSurfaceData)),
            color = seq(0, 1, length = nrow(volSurfaceData)),
            colors = colorRamp(rainbow(nrow(volSurfaceData))))

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


x <- c(tickers,options_tickers)
y <- c(profits,options_profits)
colors<-NULL
for (i in 1:length(y)){
  if(y[i]<0){
    colors[i]<-'rgba(209,25,25,0.8)'
  }
  else{
    colors[i]<-'rgba(68,149,68,1)'
  }
}

type <- c(rep("Equities",length(tickers)),rep("Options",length(options_tickers)))
data <- data.frame(x,y,type)
data$x <- factor(data$x, levels = data[["x"]])

p1<-data%>%
  plot_ly(x=~x,y=~y, type='bar',name=~type,height=800, 
          #colors='Paired',
          text=x, textposition='auto',
          marker = list(color = c(colors),
                        line = list(color = ~type, width = 1.5)),
          source = "aggregate_summary_PL"
          ) %>%
  layout(title = paste0("Equities & Options Performance as of ",as.character(Sys.Date())),
         xaxis = list(title = "Ticker"),
         yaxis = list(title = "$"),
         barmode='stack')

total_summary<-data %>%
  group_by(x)%>%
  summarise(total=sum(y,na.rm=TRUE))%>%
  as.data.frame()

p<-p1%>%
  add_trace(inherit = FALSE, x = total_summary$x, y = total_summary$total, 
            name = 'Total', type = 'scatter', mode = 'markers',
            marker =list(color = '#a8c8ea'))
# %>%
#   layout(yaxis=list(title='USD Millions'),barmode='relative',xaxis=xform,plot_bgcolor='transparent',paper_bgcolor='transparent')
p


######################## GROUPED BAR CHART
x <- c(tickers,options_tickers)
x <- unique(x)

y <-vector(mode="numeric",length=length(x))
profit_length<-c(1:length(x))
no_idx<-which(x%in%tickers==FALSE)
equity_idx<-which(profit_length%in%no_idx==FALSE)
y[equity_idx]<-profits
y[no_idx]<-0
y<-currency(y,"$",format="f",digits=2)

y2 <-vector(mode="numeric",length=length(x))
ops_profit_length<-c(1:length(x))
no_ops_idx<-which(x%in%options_tickers==FALSE)
ops_idx<-which(profit_length%in%no_ops_idx==FALSE)

y2[ops_idx]<-options_profits
y2[no_ops_idx]<-0
y2<-currency(y2,"$",format="f",digits=2)

group_data<-data.frame(x,y,y2)

equity_colors<-NULL
for (i in 1:length(y)){
  if(y[i]<0){
    equity_colors[i]<-'rgba(209,25,25,0.8)'
  }
  else{
    equity_colors[i]<-'rgba(68,149,68,1)'
  }
}
options_colors<-NULL
for (i in 1:length(y2)){
  if(y2[i]<0){
    options_colors[i]<-'rgba(209,25,25,0.8)'
  }
  else{
    options_colors[i]<-'rgba(68,149,68,1)'
  }
}


colnames(group_data)<-c("Ticker","Equities","Options")

p3 <- group_data %>% 
  plot_ly(height=2000) %>%
  add_trace(x = ~Equities, y = ~Ticker, type = 'bar',orientation = 'h', name="Equities",
            text = ~Equities, textposition = 'auto',
            marker = list(color = '#FFFFFF',
                          line = list(color = c(equity_colors), width = 2))) %>%
  add_trace(x = ~Options, y = ~Ticker, type = 'bar', orientation = 'h', name = "Options",
            text = ~Options, textposition = 'auto',
            marker = list(color = '#cccccc',
                          line = list(color = c(options_colors), width = 2))) %>%
  layout(title = paste0("Equities & Options Performance as of ",as.character(Sys.Date())),
         yaxis = list(title = ""),
         xaxis = list(title = "$"),
         barmode = 'group',bargap = 0.3, 
         legend = list(x = 0, y = 1, orientation = 'h',
                       font = list(
                         family = "sans-serif",
                         size = 12,
                         color = "#000"),
                       bgcolor = 'transparent', bordercolor = 'rgba(255, 255, 255, 0)'),
         plot_bgcolor='transparent',paper_bgcolor='transparent'
         ) %>%
  add_annotations(xref = 'x', yref = 'y',
                  x = x1 / 2, y = y,
                  text = paste(data[,"x1"], '%'),
                  font = list(family = 'Arial', size = 12,
                              color = 'rgb(248, 248, 255)'),
                  showarrow = FALSE) %>%
  add_annotations(xref = 'x', yref = 'y',
                  x = x1 / 2, y = y,
                  text = paste(data[,"x1"], '%'),
                  font = list(family = 'Arial', size = 12,
                              color = 'rgb(248, 248, 255)'),
                  showarrow = FALSE)

p3


p1<-data%>%
  plot_ly(x=~x,y=~y, type='bar',name=~type,height=800, 
          #colors='Paired',
          text=x, textposition='auto',
          marker = list(color = c(colors),
                        line = list(color = ~type, width = 1.5)),
          source = "aggregate_summary_PL"
  ) %>%
  layout(title = paste0("Equities & Options Performance as of ",as.character(Sys.Date())),
         xaxis = list(title = "Ticker"),
         yaxis = list(title = "$"),
         barmode='stack')

group_data$Total<-group_data$Equities+group_data$Options
p4 <- group_data %>% 
  plot_ly(height=2000) %>%
  add_trace(x = ~Equities, y = ~reorder(Ticker,Total), type = 'bar',orientation = 'h', name="Equities",
            text = ~as.character(Equities), textposition = 'auto',
            marker = list(color = '#FFFFFF',
                          line = list(color = c(equity_colors), width = 2))) %>%
  add_trace(x = ~Options, y = ~reorder(Ticker,Total), type = 'bar', orientation = 'h', name = "Options",
            text = ~as.character(Options), textposition = 'auto',
            marker = list(color = '#cccccc',
                          line = list(color = c(options_colors), width = 2))) %>%
  layout(title = paste0("Equities & Options Performance as of ",as.character(Sys.Date())),
         yaxis = list(title = ""),
         xaxis = list(title = "$"),
         font = list(family = 'Arial', size = 14,
                     color = 'rgba(245,246,249,1)'),
         barmode = 'relative',bargap = 0.3, 
         legend = list(x = 1, y = 1, orientation = 'h',
                       font = list(
                         family = "sans-serif",
                         size = 14,
                         color = 'rgba(245,246,249,1)'),
                       bgcolor = 'transparent', bordercolor = 'rgba(255, 255, 255, 0)'),
         plot_bgcolor='transparent',paper_bgcolor='transparent'
  ) 

p4
# %>%
#   add_annotations(xref = '', yref = 'y',
#                   x = ~(Equities/2), y = ~Ticker,
#                   text = ~as.character(Equities),
#                   font = list(family = 'Arial', size = 12,
#                               color = 'rgb(248, 248, 255)'),
#                   showarrow = FALSE) %>%
#   add_annotations(xref = 'x', yref = 'y',
#                   x = ~(Options/2), y = ~Ticker,
#                   text = ~as.character(Options),
#                   font = list(family = 'Arial', size = 12,
#                               color = 'rgb(248, 248, 255)'),
#                   showarrow = FALSE)





grouped_data<-total_summary$x

data %>%
  group_by_at(vars(x,type))


#############################################
### Visualize timeline of trades for ticker #
#############################################
library(timevis)
AMZN_trade_timeline<-Order$get_trade_timeline("AMZN",orders)
timevis(AMZN_trade_timeline)




