##Login sequence
##Examples

login<-Login$new(username_ = username,password_ = pwd)

account<-Account$new(login=login)

account$authToken<-account$user$authToken
account$private$create_auth_header()
account$private$get_account_id()
account$private$get_account_number()
account$private$get_balances()

authToken<-account$authToken
authHeader<-account$authHeader
accountID<-account$accountID
accountNumber<-account$accountNumber
balances<-account$balances
day_stats<-account$get_day_PnL()
options_positions<-account$optionsPositions
positions<-account$positions


order<-Orders$new(account = account)

options_history<-order$options_orders
order_history<-order$orders

order$ticker<-"AMZN"
trade_timeline<-order$private$get_trade_timeline(ticker=order$ticker,orders=order$orders)


##Add options hist P/L func
