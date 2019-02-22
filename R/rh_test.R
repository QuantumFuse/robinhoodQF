# ##Login sequence
# ##Examples
#
# login<-Login$new(username_ = username,password_ = pwd)
#
# account<-Account$new(login=login)
#
# account$authToken<-account$user$authToken
# account$private$create_auth_header()
# account$private$get_account_id()
# account$private$get_account_number()
# account$private$get_balances()
#
# authToken<-account$authToken
# authHeader<-account$authHeader
# accountID<-account$accountID
# accountNumber<-account$accountNumber
# balances<-account$balances
# day_stats<-account$get_day_PnL()
# options_positions<-account$optionsPositions
# positions<-account$positions
#
#
# order<-Orders$new(account = robinhoodUser$account)
# 
# options_history<-order$options_orders
# order_history<-order$orders
# 
# order$ticker<-"AMZN"
# trade_timeline<-order$private$get_trade_timeline(ticker=order$ticker,orders=order$orders)
# #
# #
# # ##Add options hist P/L func
# 
# 
# 
# summary_PL<-get_robinhood_PL()
# summary_PL<-summary_PL[1]
# summary_PL<-as.data.frame(summary_PL)
# 
# profits<-summary_PL[,2]
# 
# profits<-as.numeric(profits)
# 
# commission<-(-5.95*35)
# profit_total<-sum(profits)+commission
# profits<-c(profits,commission)
# profits<-currency( profits,"$",format="f",digits=2)
# tickers<-summary_PL$Ticker
# tickers<-as.character(tickers)
# tickers<-c(tickers,"Commission*")
# colors<-NULL
# for (i in 1:length(tickers)){
#   if(profits[i]<0){
#     colors[i]<-'rgba(209,25,25,0.8)'
#   }
#   else{
#     colors[i]<-'rgba(68,149,68,1)'
#   }
#   
# }
# #colors[length(tickers)-1]<-'rgba(177,188,192,0.8)'
# colors[length(tickers)]<-'rgba(177,188,192,0.8)'
# x <- c(tickers)
# y <- c(profits)
# data <- data.frame(x, y)
# data$x <- factor(data$x, levels = data[["x"]])
# 
# plot_ly(data, x = ~x, y = ~y, type = 'bar',
#         text=x, textposition='auto',
#         marker = list(color = c(colors),
#                       line = list(color = 'rgb(8,48,107)', width = 1.5)),
#         source = "summary_PL") %>%
#   layout(title = paste0("Portfolio Performance as of ",as.character(Sys.Date())),
#          xaxis = list(title = "Security"),
#          yaxis = list(title = "$"))
