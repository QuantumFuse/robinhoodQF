### Add an options P/L function

#' Orders R6 Class
#'
#' Create an instance of the R6 Orders Class. Retrieve all transation history and profit/loss summary.
#' @param account Initialzied instance of Account class (robinhoodUser$account)
Orders <- R6::R6Class(
  
  classname = "Orders",  
  inherit = Account, 
  portable = TRUE,
  
  public = list(
    
    account = NULL,
    orders=NULL,
    options_orders=NULL,

    initialize = function(account){
      stopifnot(inherits(account,"Account"))
      self$account <- account
      private$get_order_history()
      private$get_options_history()
    },
    get_trade_timeline = function(ticker,orders){
      
      grouped_tx<-orders[[4]]
      DF<-as.data.frame(grouped_tx)
      tickers<-DF$Ticker
      tickers<-as.character(tickers)
      return_idx<-which(tickers==ticker)
      DF<-DF[return_idx,]
      dates<-as.character.Date(DF$Date)
      ticker<-as.character(ticker)
      buy_style<-c("color:green;")
      sell_style<-c("color: red;")
      price<-NULL
      order_type<-NULL
      group_style<-NULL
      for (i in 1:length(dates)){
        if(DF$Shares[i]<0){
          order_type[i]<-"BUY"
          price[i]<-round((DF$values[i]/DF$Shares[i]),digits=2)
          group_style[i]<-buy_style
          
        }
        else{
          order_type[i]<-"SELL"
          price[i]<-round((DF$values[i]/DF$Shares[i]),digits=2)
          group_style[i]<-sell_style
        }
      }
      shares<-DF$Shares
      shares<-abs(shares)
      proceeds<-DF$values
      
      content<-paste(order_type,": ",shares, "shares, at",paste("$",as.character(price),sep=""),"Proceeds:",paste("$",proceeds,sep=""),sep=" ")
      dataWeeklyT <- data.frame(
        id = 1:length(dates),
        start = c(dates),
        content = c(content),
        style=group_style,
        className="QFTClass"
        
      )
      
      return(dataWeeklyT)
    }
    
  ),
  

  private=list(
    get_order_history = function(){
      header<-self$account$user$authHeader
      Price<-NULL
      State<-NULL
      Shares<-NULL
      Ticker<-NULL
      Type<-NULL
      cumulative_quantity<-NULL
      Trigger<-NULL
      last_transacted<-NULL
      updated<-NULL
      created<-NULL
      avg_price<-NULL
      stop_price<-NULL
      response_category<-NULL
      NEXTURL<-"https://api.robinhood.com/orders/"
      while(is.null(NEXTURL)!=T){
        res <- httr::GET(NEXTURL, httr::add_headers(.headers=header))
        NEXTURL<-httr::content(res)$`next`
        
        
        for (result in httr::content(res)$results) {
          instrumentResponse <- httr::GET(result$url, httr::add_headers(.headers=header))
          instrumentInfoResponse <- httr::GET(httr::content(instrumentResponse)$instrument, httr::add_headers(.headers=header))
          State<-c(State,result$state)
          if(result$state=="filled"){
            if(result$response_category=="success"||result$response_category=="unknown"){
              
              
              Ticker<-c(Ticker,httr::content(instrumentInfoResponse)$symbol)
              Price<-c(Price,result$price)
              
              Shares<-c(Shares,result$quantity)
              Type<-c(Type,result$side)
              last_transacted<-c(last_transacted,result$last_transaction_at)
              updated<-c(updated,result$updated_at)
              created<-c(created,result$created_at)
              avg_price<-c(avg_price,result$average_price)
              stop_price<-c(stop_price,result$stop_price)
              response_category<-c(response_category,result$response_category)
              cumulative_quantity<-c(cumulative_quantity,result$cumulative_quantity)
              Trigger<-c(Trigger,result$trigger)
              
            }
            
          }
          
        }
      }
      
      Price<-avg_price
      Date<-last_transacted
      orders<-data.frame(Type=Type,Ticker=Ticker,Price=Price,Shares=Shares,Date=Date)
      
      tx_DF<-orders
      tx_DF$Type<-as.character(tx_DF$Type)
      tx_DF$Date<-as.Date(as.character(tx_DF$Date))
      
      values<-NULL
      grouped_tx_DF<-ddply(tx_DF,"Ticker",rbind)
      grouped_tx_DF$Type<-as.character(grouped_tx_DF$Type)
      grouped_tx_DF$Ticker<-as.character(grouped_tx_DF$Ticker)
      grouped_tx_DF$Price<-as.numeric(as.character(grouped_tx_DF$Price))
      grouped_tx_DF$Shares<-as.numeric(as.character(grouped_tx_DF$Shares))
      
      
      for (i in 1:length(grouped_tx_DF$Type)){
        if (grouped_tx_DF$Type[i]=="buy"){
          order_type=-1
        }
        else {
          order_type=1
        }
        grouped_tx_DF$Shares[i]<-grouped_tx_DF$Shares[i]*order_type
        values[i]<-grouped_tx_DF$Price[i]*grouped_tx_DF$Shares[i]
        
      }
      grouped_tx_DF<-cbind(grouped_tx_DF,values)
      grouped_tx<-grouped_tx_DF
      grouped_tx_DF<-ddply(grouped_tx_DF,"Ticker",numcolwise(sum))
      tickers_owned<-grouped_tx_DF$Ticker[which(grouped_tx_DF$Shares!=0)]
      shares_owned<-abs(grouped_tx_DF$Shares[which(grouped_tx_DF$Shares!=0)])
      
      current_value<-NULL
      last_price<-NULL
      for (i in 1:length(tickers_owned)){
        data<-rh_quote(tickers_owned[i],header)
        last_price[i]<-data
        current_value[i]<-last_price[i]*shares_owned[i]
      }
      current_positions<-data.frame(Ticker=tickers_owned,Shares=shares_owned,"Last Price"=last_price,"Market Value"=current_value)
      individual_pl<-grouped_tx_DF
      individual_pl$values[which(individual_pl$Shares!=0)]<-individual_pl$values[which(individual_pl$Shares!=0)]+current_positions$Market.Value
      individual_pl$Shares<-abs(individual_pl$Shares)
      colnames(individual_pl)[4]<-"Profit/Loss"
      
      day_stats<-self$account$day_stats
      total_equity<-as.numeric(day_stats$Equity)
      
      equities<-sum(current_positions$Market.Value)
      cash<-total_equity-equities
      tickers<-c("CASH",tickers_owned)
      market_values<-c(cash,current_positions$Market.Value)
      
      
      allocation <- data.frame(value = market_values,
                               Group = tickers) %>%
        # factor levels need to be the opposite order of the cumulative sum of the values
        mutate(Group = factor(Group, levels = rev(tickers)),
               label = paste0(Group, " ", round(value / sum(value) * 100, 1), "%"))
      return_list<-list(individual_pl,current_positions,allocation,grouped_tx,orders)
      names(return_list)<-c("Individual_PL","Current_Positions","Allocation","Grouped_History","Transactions")
      self$orders <- return_list
    },
    
    get_options_history = function(){
      header <- self$account$user$authHeader
      
      Price<-NULL
      Premium<-NULL
      State<-NULL
      Quantity<-NULL
      Ticker<-NULL
      Type<-NULL
      cumulative_quantity<-NULL
      Trigger<-NULL
      last_transacted<-NULL
      updated<-NULL
      created<-NULL
      avg_price<-NULL
      stop_price<-NULL
      response_category<-NULL
      Direction<-NULL
      NEXTURL<-"https://api.robinhood.com/options/orders/"
      while(is.null(NEXTURL)!=T){
        res <- httr::GET(NEXTURL, httr::add_headers(.headers=header))
        NEXTURL<-httr::content(res)$`next`
        
        results<-httr::content(res)$results
        for (i in 1:length(results)) {
          result<-results[[i]]
          
          if(result$state=="filled"){
            if(result$response_category=="success"||result$response_category=="unknown"){
              State<-c(State,result$state)
              
              Ticker<-c(Ticker,result$chain_symbol)
              Price<-c(Price,result$price)
              Premium<-c(Premium,result$premium)
              Direction<-c(Direction,result$direction)
              Quantity<-c(Quantity,result$quantity)
              if (is.null(result$opening_strategy)){
                Type<-c(Type,result$closing_strategy)
              }
              else{
                Type<-c(Type,result$opening_strategy)
              }
              updated<-c(updated,result$updated_at)
              created<-c(created,result$created_at)
              response_category<-c(response_category,result$response_category)
              Trigger<-c(Trigger,result$trigger)
            }
          }
        }
      }
      Date<-updated
      ORDERS<-data.frame(Type=Type,Ticker=Ticker,Price=Price,Premium=Premium,Quantity=Quantity,Date=Date,Direction=Direction)
      
      options_history<-ORDERS
      
      options_history$Premium<-as.numeric(as.character(options_history$Premium))
      options_history$Quantity<-as.numeric(as.character(options_history$Quantity))
      for (i in 1:length(options_history$Direction)){if (options_history$Direction[i]=="debit"){options_history$Premium[i]<-options_history$Premium[i]*-1}}
      Value<-options_history$Premium*options_history$Quantity
      options_history<-cbind(options_history,Value)
      #######################################################
      
      values<-NULL
      grouped_tx_DF<-ddply(options_history,"Ticker",rbind)
      
      grouped_tx_DF$Shares<-grouped_tx_DF$Quantity
      
      for (i in 1:length(grouped_tx_DF$Value)){
        if (grouped_tx_DF$Value[i] < 0){
          order_type=-1
        }
        else {
          order_type=1
        }
        grouped_tx_DF$Quantity[i]<-grouped_tx_DF$Quantity[i]*order_type
      }
      
      grouped_tx_DF<-ddply(grouped_tx_DF,"Ticker",numcolwise(sum))
      
      ###########################################################
      # * insert code to get quotes for contracts currently owned
      ###########################################################
      idx_owned<-which(grouped_tx_DF$Ticker%in%self$account$optionsPositionsTable$ticker)
      tickers_owned<-grouped_tx_DF$Ticker[idx_owned]
      # * doesn't account for options that opened with multiple legs in the order but closed with each leg in a separate order  
      expired_idx<-which(grouped_tx_DF$Quantity!=0 & (grouped_tx_DF$Ticker%in%tickers_owned==FALSE))
      current_value<-NULL
      
      ### Manual fix
      #grouped_tx_DF[idx_owned,]$Value<-grouped_tx_DF[idx_owned,]$Value+*current_value_of_contracts_owned*
      #grouped_tx_DF[idx_owned,]$Value<-grouped_tx_DF[idx_owned,]$Value+263
      
      
      individual_options_pnl<-grouped_tx_DF[,c(1,4)]
      toReturn<-list("transactions"=options_history,"pnl"=individual_options_pnl)
      self$options_orders <- toReturn
      
    }
    
  )

)

##################
##################
# Convert to R6 ##
### Add in legs processing logic -- currently returns duplicate rows
rh_getOptionsOrders <- function(header) {
  
  Ticker<-NULL
  Direction<-NULL
  Premium<-NULL
  processed_quantity<-NULL
  pending_quantity<-NULL
  Quantity<-NULL
  Price<-NULL
  Trigger<-NULL
  State<-NULL
    
  Date<-NULL
  
  opening_strategy<-NULL
  closing_strategy<-NULL
  leg_side<-NULL
  leg_position_effect<-NULL
  leg_execution_time<-NULL
  leg_execution_price<-NULL
  leg_execution_quantity<-NULL
  
  NEXTURL<-"https://api.robinhood.com/options/orders/"
  
  while(is.null(NEXTURL)!=T){
    res <- GET(NEXTURL, add_headers(.headers=header))
    NEXTURL<-content(res)$`next`

    results<-httr::content(res)$results
    for (i in 1:length(results)) {

      State<-c(State,results[[i]]$state)
      if(results[[i]]$state=="filled"){
        if(results[[i]]$response_category=="success"||results[[i]]$response_category=="unknown"){
          open_strat<-results[[i]]$opening_strategy
          if(is.null(open_strat)){open_strat<-"None"}
          opening_strategy<-c(opening_strategy,open_strat)
          close_strat<-results[[i]]$closing_strategy
          if(is.null(close_strat)){close_strat<-"None"}
          closing_strategy<-c(closing_strategy,close_strat)
          legs<-results[[i]]$legs
          for (j in 1:length(legs)){
            leg<-legs[[j]]
            for (k in 1:length(leg)){
              leg_side<-c(leg_side,leg$side)
              leg_position_effect<-c(leg_position_effect,leg$position_effect)
              leg_execution_price<-c(leg_execution_price,leg$executions[[1]]$price)
              leg_execution_time<-c(leg_execution_time,leg$executions[[1]]$timestamp)
              leg_execution_quantity<-c(leg_execution_quantity,leg$executions[[1]]$quantity)
            }
          }
          Ticker<-c(Ticker,results[[i]]$chain_symbol)
          Direction<-c(Direction,results[[i]]$direction)
          Premium<-c(Premium,results[[i]]$premium)
          processed_quantity<-c(processed_quantity,results[[i]]$processed_quantity)
          pending_quantity<-c(pending_quantity,results[[i]]$pending_quantity)
          Quantity<-c(Quantity,results[[i]]$quantity)
          Date<-c(Date,results[[i]]$updated_at)
          
          Price<-c(Price,results[[i]]$price)
          Trigger<-c(Trigger,results[[i]]$trigger)

        }

      }

    }
  }


  options_df<-data.frame(Date=Date,Ticker=Ticker,Direction=Direction,Premium=Premium,Price=Price,Quantity=Quantity,Open=opening_strategy,Close=closing_strategy)
  options_df<-options_df%>%mutate_at(vars(Premium,Price,Quantity),funs(as.numeric(.)))
  
  Value<-NULL
  for (i in 1:length(options_df$Ticker)){
    if(options_df$Direction[i]=="debit"){
      Value[i]<-options_df$Quantity[i]*options_df$Premium[i]*(-1)
    }
    else{Value[i]<-options_df$Quantity[i]*options_df$Premium[i]}
  }
  options_df<-cbind(options_df,Value)
  
  values<-NULL
  grouped_tx_DF<-ddply(options_df,"Ticker",rbind)
  
  grouped_tx_DF$Shares<-as.numeric(as.character(grouped_tx_DF$Quantity))
  
  for (i in 1:length(grouped_tx_DF$Value)){
    if (grouped_tx_DF$Value[i] < 0){
      order_type=-1
    }
    else {
      order_type=1
    }
    grouped_tx_DF$Quantity[i]<-grouped_tx_DF$Quantity[i]*order_type
  }

  grouped_tx_DF<-ddply(grouped_tx_DF,"Ticker",numcolwise(sum))
  
  ###########################################################
  # * insert code to get quotes for contracts currently owned
  ###########################################################
  idx_owned<-which(grouped_tx_DF$Ticker%in%robinhoodUser$account$optionsPositionsTable$ticker)
  tickers_owned<-grouped_tx_DF$Ticker[idx_owned]
  expired_idx<-which(grouped_tx_DF$Quantity!=0 & (grouped_tx_DF$Ticker%in%tickers_owned==FALSE))
  current_value<-NULL
  
  ### Manual fix
  #grouped_tx_DF[idx_owned,]$Value<-grouped_tx_DF[idx_owned,]$Value+*current_value_of_contracts_owned*
  grouped_tx_DF[idx_owned,]$Value<-grouped_tx_DF[idx_owned,]$Value+263
  
    
  individual_pnl<-grouped_tx_DF[,c(1,5)]
  
  
  # Effect<-NULL
  # for(i in 1:length(ORDERS$Ticker)){
  #   if(ORDERS$Open[i]=="None"){
  #     Effect[i]<-"close"
  #   }
  #   else if (ORDERS$Close[i]=="None"){
  #     Effect[i]<-"open"
  #   }
  # }
  # ORDERS<-cbind(ORDERS,Effect)
  return(list(orders=options_df,individual_pnl=individual_pnl))
}

get_robinhood_options_trades<-function(options_history){
  
  option_trade_groups<-NULL
  credit_trades<-NULL
  debit_trades<-NULL
  ticker_trades<-NULL
  tickers<-as.character(options_history$Ticker)
  for (i in 1:length(options_history)){
    row_idx<-which(options_history$Ticker==tickers[i])
    
    option_trade_groups[[i]]<-options_history[row_idx,]
    credit_trades_idx<-which((option_trade_groups[[i]]$position_effect=="open"&option_trade_groups[[i]]$direction=="credit")|(option_trade_groups[[i]]$position_effect=="close"&option_trade_groups[[i]]$direction=="credit"))
    debit_trades_idx<-which((option_trade_groups[[i]]$position_effect=="close"&option_trade_groups[[i]]$direction=="debit")|(option_trade_groups[[i]]$position_effect=="open"&option_trade_groups[[i]]$direction=="debit"))
    credit_trades[[i]]<-option_trade_groups[[i]][credit_trades_idx,]
    credit_trades[[i]]<-credit_trades[[i]][credit_trades[[i]]$side=="sell",]
    debit_trades[[i]]<-option_trade_groups[[i]][debit_trades_idx,]
    debit_trades[[i]]<-debit_trades[[i]][debit_trades[[i]]$side=="buy",]
    ticker_trades[[i]]<-rbind(debit_trades[[i]],credit_trades[[i]])
  }
  names(ticker_trades)<-options_history
  return(ticker_trades)
}




#' Place immediate buy order.
#'
#' Place an immediate trigger market/limit buy order.
#' @param account       Initialized instance of the R6 Account class. Generated by Account$new(login).
#' @param ticker        Equity ticker symbol. All caps string.
#' @param orderType     "market" or "limit"
#' @param orderPrice    numeric limit price (needed for market order because collared on price)
#' @param numShares     number of shares. Numeric class integer only.
rh_placeImmediateBuyOrder <- function(account, ticker, orderType, orderPrice, numShares) {
  header <- account$user$authHeader
  creds = list(
    account = paste("https://api.robinhood.com/accounts/", account$user$accountNumber, "/", sep=""),
    instrument = rh_getInstrumentURL(ticker),
    symbol = ticker,
    type = orderType,
    time_in_force = "gtc",
    trigger = "immediate",
    price = orderPrice,
    quantity = numShares,
    side = "buy"
  )
  res <- httr::POST("https://api.robinhood.com/orders/", encode = "json", body=creds, httr::add_headers(.headers=header))
  print(httr::content(res)$state)
  orderStatus <- list()
  orderStatus$order_id <- httr::content(res)$id
  orderStatus$order_state <- httr::content(res)$state
  return(orderStatus)
}

#' Place stop buy order.
#'
#' Place a stop trigger market/limit buy order.
#' @param account       Initialized instance of the R6 Account class. Generated by Account$new(login).
#' @param ticker        Equity ticker symbol. All caps string.
#' @param orderType     "market" or "limit"
#' @param orderPrice    numeric limit price (needed for market order because collared on price)
#' @param numShares     number of shares. Numeric class integer only.
#' @param stopPrice     numeric stop price
rh_placeStopBuyOrder <- function(account, ticker, orderType, orderPrice, numShares, stopPrice) {
  header <- account$user$authHeader
  creds = list(
    account = paste("https://api.robinhood.com/accounts/", account$user$accountNumber, "/", sep=""),
    instrument = rh_getInstrumentURL(ticker),
    symbol = ticker,
    type = orderType,
    time_in_force = "gtc",
    trigger = "stop",
    price = orderPrice,
    stop_price = stopPrice,
    quantity = numShares,
    side = "buy"
  )
  res <- httr::POST("https://api.robinhood.com/orders/", encode = "json", body=creds, httr::add_headers(.headers=header))
  orderStatus <- list()
  orderStatus$order_id <- httr::content(res)$id
  orderStatus$order_state <- httr::content(res)$state
  return(orderStatus)
}

#' Place stop sell order.
#'
#' Place a stop trigger market/limit sell order.
#' @param account       Initialized instance of the R6 Account class. Generated by Account$new(login).
#' @param ticker        Equity ticker symbol. All caps string.
#' @param orderType     "market" or "limit"
#' @param orderPrice    numeric limit price (needed for market order because collared on price)
#' @param numShares     number of shares. Numeric class integer only.
#' @param stopPrice     numeric stop price
rh_placeStopSellOrder <- function(account, ticker, orderType, orderPrice, numShares, stopPrice) {
  header <- account$user$authHeader
  creds = list(
    account = paste("https://api.robinhood.com/accounts/", account$user$accountNumber, "/", sep=""),
    instrument = rh_getInstrumentURL(ticker),
    symbol = ticker,
    type = orderType,
    time_in_force = "gtc",
    trigger = "stop",
    price = orderPrice,
    stop_price = stopPrice,
    quantity = numShares,
    side = "sell"
  )
  res <- httr::POST("https://api.robinhood.com/orders/", encode = "json", body=creds, httr::add_headers(.headers=header))
  orderStatus <- list()
  orderStatus$order_id <- httr::content(res)$id
  orderStatus$order_state <- httr::content(res)$state
  return(orderStatus)
}

#' Place immediate sell order.
#'
#' Place an immediate trigger market/limit sell order.
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
#' @param accountNumber 8-digit account number generated by rh_getAccountNumber.
#' @param ticker        Equity ticker symbol. All caps string.
#' @param orderType     "market" or "limit"
#' @param orderPrice    numeric limit price (needed for market order because collared on price)
#' @param numShares     number of shares. Numeric class integer only.
rh_placeImmediateSellOrder <- function(account, ticker, orderType, orderPrice, numShares) {
  header <- account$user$authHeader
  creds = list(
    account = paste("https://api.robinhood.com/accounts/", account$user$accountNumber, "/", sep=""),
    instrument = rh_getInstrumentURL(ticker),
    symbol = ticker,
    type = orderType,
    time_in_force = "gtc",
    trigger = "immediate",
    price = orderPrice,
    quantity = numShares,
    side = "sell"
  )
  res <- httr::POST("https://api.robinhood.com/orders/", encode = "json", body=creds, httr::add_headers(.headers=header))
  orderStatus <- list()
  orderStatus$order_id <- httr::content(res)$id
  orderStatus$order_state <- httr::content(res)$state
  return(orderStatus)
}
