#' get r AuthToken.
#'
#' Get oauth2 login token. Passed to all API requests.
#' @param username_ Robinhood login username. NOT email.
#' @param password_ Robinhood login password. Can only contain letters and numbers in plaintext.
Login <- R6::R6Class(

  classname = 'Login', portable = FALSE,

  public = list(

    authToken = NULL,
    authHeader = NULL,
    accountNumber = NULL,
    accountID = NULL,
    username = NULL,
    initialize = function(username_, password_){

      clientId <- "c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS"
      creds <- list(username=username_, password=password_, client_id=clientId, mfa_code=NULL, grant_type="password")
      response <- httr::POST("https://api.robinhood.com/oauth2/token/", encode="json", body=creds)
      authToken <<- httr::content(response)$access_token

      create_auth_header()
      get_account_id()
      get_account_number()

    }
  ),

  private = list(

    create_auth_header = function() {
      preAuthHeader <- paste("Bearer ", authToken)
      names(preAuthHeader) <- "Authorization"
      authHeader <<- preAuthHeader
    },

    get_account_id = function() {
      response <- httr::GET("https://api.robinhood.com/user/id", httr::add_headers(.headers=authHeader))
      accountID <<- httr::content(response)$id
    },

    get_account_number = function() {
      response <- httr::GET("https://api.robinhood.com/accounts/", httr::add_headers(.headers=authHeader))
      accountInfo <- httr::content(response)
      accountNumber <<- accountInfo$results[[1]]$account_number
    }

  )
)

#' get r AuthToken.
#'
#' Get oauth2 login token. Passed to all API requests.
#' @param username_ Robinhood login username. NOT email.
#' @param password_ Robinhood login password. Can only contain letters and numbers in plaintext.
Account <- R6::R6Class(

  classname = "Account", portable = FALSE,

  public = list(

    user = NULL,
    positions = NULL,
    portfolioEquity = NULL,
    balances = NULL,
    optionsPositions = NULL,
    get_day_PnL = NULL,
    positionsList = NULL,

    initialize = function(username, password){

      user <<- Login$new(username_=username, password_=password)
      get_positions_list()
      positions <<- as.data.frame(do.call(rbind, lapply(positionsList, function(x) parse_position(x))))

      get_options_positions_table()
      #get_balances()

      get_day_PnL <<- function(){
        portfolioURL <- paste("https://api.robinhood.com/accounts/", user$accountNumber, "/portfolio/", sep = "")
        response <- httr::GET(portfolioURL, httr::add_headers(.headers=user$authHeader))
        response <- httr::content(response)
        lastEquity <- response$adjusted_equity_previous_close
        equity <- response$equity

        if(is.null(equity)){
          equity <- response$extended_hours_equity
        }

        equity <- as.numeric(equity)
        lastEquity <- as.numeric(lastEquity)
        change <- equity-lastEquity
        pctChange <- (change/lastEquity)*100
        dayChange <- data.frame("Change($)"=change, "Percent Change"=pctChange,"Equity"=equity)
        return(dayChange)
      }
    },

    get_instrument_info = function(instrumentURL) {
      res <- httr::GET(instrumentURL)
      instrumentTicker <- httr::content(res)$symbol
      instrumentName <- httr::content(res)$name
      instrumentInfo <- list()
      instrumentInfo$ticker <- instrumentTicker
      instrumentInfo$name <- instrumentName
      return(instrumentInfo)
    }

  ),

  private = list(

    get_positions_list = function(){
      positionsURL <- paste("https://api.robinhood.com/accounts/", user$accountNumber, "/positions/", sep = "")
      response <- httr::GET(positionsURL, httr::add_headers(.headers=user$authHeader))
      positionsList <<- httr::content(response)$results
    },

    parse_position = function(position) {
      df <- data.frame("name" = get_instrument_info(position$instrument)$name, "quantity"= position$quantity,
                       "average_price"= position$average_buy_price)
      rownames(df) <- get_instrument_info(position$instrument)$ticker
      return(df)
    },

    get_portfolio_equity = function() {
      portfolioURL <- paste("https://api.robinhood.com/accounts/", user$accountNumber, "/portfolio/", sep = "")
      response <- httr::GET(portfolioURL, httr::add_headers(.headers=user$authHeader))
      extendedHours <- httr::content(response)$extended_hours_equity
      toReturn <- httr::content(response)$equity

      portfolioEquity <<- if(length(extendedHours)>0){
        if(as.numeric(extendedHours)>=as.numeric(toReturn)){
          extendedHours
        }
      } else {
        toReturn
      }
    },

    get_options_positions_table = function() {
      positionsURL <- "https://api.robinhood.com/options/positions/"
      response <- httr::GET(positionsURL, httr::add_headers(.headers=user$authHeader))
      optionsPositions <- httr::content(response)$results

      Ticker<-NULL
      Quantity<-NULL
      Type<-NULL
      Price<-NULL

      for (i in 1:length(optionsPositions)){

        optionsPosition<-optionsPositions[[i]]

        if(as.numeric(optionsPosition$quantity)!=0){

          Ticker<-c(Ticker,optionsPosition$chain_symbol)
          Quantity<-c(Quantity,optionsPosition$quantity)
          Type<-c(Type,optionsPosition$type)
          Price<-c(Price,optionsPosition$average_price)

        }
      }

      optionsPositions<<-data.frame(Ticker=Ticker,Quantity=Quantity,Price=Price,Type=Type)
    },

    get_balances = function() {
      shares<-as.numeric(as.character(positions$quantity))
      idxOwned <- which(shares>0)
      positions <- positions[idxOwned, ]
      tickers <- rownames(positions)
      quotes <- rh_quote(tickers)
      prices <- quotes$last_extended_hours_trade_price
      naPrices <- which(is.na(quotes$last_extended_hours_trade_price)==TRUE)

      if(length(naPrices)>0){
        newQuotes<-robinhoodr::rh_quote(tickers[naPrices])
        prices[naPrices]<-newQuotes$last_trade_price
      }

      shares<-shares[idxOwned]
      prices<-as.numeric(prices)
      marketValue<-sum(shares*prices)
      equity<-as.numeric(get_portfolio_equity())
      cashBalance<-equity-marketValue
      marketValue<-shares*prices
      marketValue<-c(cashBalance,marketValue)
      tickers<-c("CASH",tickers)
      shares<-c("NA",shares)
      prices<-c("NA",prices)

      balances<<-data.frame(Ticker=tickers,Shares=shares,"Last Price"=prices,"Market Value"=marketValue)
    }






  )

)

## PORTFOLIO CALCULATOR FUNCTIONS ###################################################

##################
##################
# Convert to R6 ##


#' Get order history
#'
#' Retrieve all transation history in data.frame
#' @param account Initialzied instance of Account class
rh_order_history <- function(account) {
  header<-account$user$authHeader
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
    data<-getQuote(tickers_owned[i])
    last_price[i]<-data$Last
    current_value[i]<-last_price[i]*shares_owned[i]
  }
  current_positions<-data.frame(Ticker=tickers_owned,Shares=shares_owned,"Last Price"=last_price,"Market Value"=current_value)
  individual_pl<-grouped_tx_DF
  individual_pl$values[which(individual_pl$Shares!=0)]<-individual_pl$values[which(individual_pl$Shares!=0)]+current_positions$Market.Value
  individual_pl$Shares<-abs(individual_pl$Shares)
  colnames(individual_pl)[4]<-"Profit/Loss"

  total_equity<-as.numeric(rh_getPortfolioEquity(account))
  equities<-sum(current_positions$Market.Value)
  cash<-total_equity-equities
  tickers<-c("CASH",tickers_owned)
  market_values<-c(cash,current_positions$Market.Value)


  allocation <- data.frame(value = market_values,
                           Group = tickers) %>%
    # factor levels need to be the opposite order of the cumulative sum of the values
    mutate(Group = factor(Group, levels = rev(tickers)),
           label = paste0(Group, " ", round(value / sum(value) * 100, 1), "%"))

  return(list(individual_pl,current_positions,allocation,grouped_tx,orders))

}





#'@param grouped_tx Transaction history grouped by ticker. Returned from get_order_history(account)[[4]]
#'@param ticker Ticker of interest to view timeline of historical trades
get_robinhood_weekly_timeline<-function(grouped_tx,ticker){

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

##END Robinhood Functions
#########################



#' Place immediate buy order.
#'
#' Place an immediate trigger market/limit buy order.
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
#' @param accountNumber 8-digit account number generated by rh_getAccountNumber.
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
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
#' @param accountNumber 8-digit account number generated by rh_getAccountNumber.
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
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
#' @param accountNumber 8-digit account number generated by rh_getAccountNumber.
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



#' Get fundamentals
#'
#' Get summary fundamentals data on company ticker.
#' @param ticker  Equity ticker symbol. All caps string.
rh_getFundamentals<-function(ticker,account){
  ticker<-toupper(ticker)
  header<-account$user$authHeader
  res<-httr::GET(paste("https://api.robinhood.com/fundamentals/",ticker,"/",sep=""), httr::add_headers(.headers=header))
  fundamentals_list<-httr::content(res)
  fundamentals_list<-as.data.frame(fundamentals_list)
  return(fundamentals_list)
}



#' Get option order history
#'
#' Retrieve all options transation history in data.frame
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
rh_getOptionsOrders <- function(account) {
  header <- account$user$authHeader

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
  return(ORDERS)
}

### Add an options P/L function

#' Get the last quotes for a symbol.
#'
#' @param symbols The shorthand symbols.
rh_quote<-function(ticker,account){
  header<-account$user$authHeader
  url<-paste0("https://api.robinhood.com/quotes/",toupper(ticker),"/",sep="")
  res <- httr::GET(url, httr::add_headers(.headers=header))
  res<-as.numeric(content(res)$last_trade_price)
  return(res)
}


#' Get the historical quotes for a symbol.
#'
#' @param symbols The shorthand symbols.
#' @param interval The interval: week|day|10minute|5minute
#' @param span The span: day|week|year
#' @param bounds extended|regular|trading
#' @param keep_meta whether to keep meta data. Defaults to FALSE.
#' @param to_xts    whether to convert to xts. Defaults to TRUE.
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
rh_historicals <- function(symbols, interval = "day",
                           span = "year", bounds = "regular",
                           keep_meta = FALSE, to_xts = TRUE,account){

  # Get the data
  hist_list <- lapply(X = symbols,
                      function(x){rh_historicals_one(symbol = x,
                                                     interval = interval,
                                                     span = span,
                                                     bounds = bounds,account=account)})

  # Keep only the historical data
  if(!keep_meta){
    hist_list <- lapply(hist_list, function(x) x$historicals[[1]])
  }

  if(to_xts & !keep_meta){

    hist_list <- lapply(hist_list,
                        function(x){
                          x_converted <- xts::xts(x = x[, c("open_price", "close_price", "high_price", "low_price", "volume")],
                                                  order.by = x$begins_at)
                          attr(x_converted, "session") <- x$session
                          attr(x_converted, "interpolated") <- x$interpolated

                          x_converted
                        })
  }

  # name the list.
  names(hist_list) <- symbols

  hist_list
}

#' Historical data helper.
#'
#' @param symbol The shorthand symbols.
#' @param interval The interval: week|day|10minute|5minute
#' @param span The span: day|week|year
#' @param bounds extended|regular|trading
#' @param userAuthToken oauth2 token generated by rh_getAuthToken.
rh_historicals_one <- function(symbol, interval = interval, span = span, bounds = bounds,account=account){

  header=account$user$authHeader

  # Create the url
  #' Base url

  rh_base_url <- function(){

    httr::parse_url("https://api.robinhood.com")
  }
  rh_url <- rh_base_url()
  rh_url$path <- paste0("quotes/historicals/", symbol, "/")
  rh_url$query <- list(interval = interval,
                       span = span,
                       bounds = bounds)
  rh_url <- httr::build_url(rh_url)

  # GET the quotes
  quotes_rh <- httr::GET(url = rh_url,httr::add_headers(.headers=header))

  # Check the responce
  if (httr::http_error(quotes_rh)) {
    stop(
      httr::content(x = quotes_rh, as = "text", encoding = "UTF-8"),
      call. = FALSE)
  }

  # parse the content
  content_rh <- httr::content(x = quotes_rh, as = "text", encoding = "UTF-8")
  content_rh <- jsonlite::fromJSON(txt = content_rh)

  meta_rh <- as.data.frame(content_rh[1:6], stringsAsFactors = FALSE)

  hist_rh <- content_rh$historicals
  hist_rh$begins_at <- lubridate::ymd_hms(hist_rh$begins_at,
                                          tz = "UTC")
  hist_rh$open_price <- as.numeric(hist_rh$open_price)
  hist_rh$close_price <- as.numeric(hist_rh$close_price)
  hist_rh$high_price <- as.numeric(hist_rh$high_price)
  hist_rh$low_price <- as.numeric(hist_rh$low_price)

  meta_rh$historicals <- list(hist_rh)

  meta_rh
}



get_balances = function(account) {
  positions<-account$positions
  shares<-as.numeric(as.character(positions$quantity))
  idxOwned <- which(shares>0)
  positions <- positions[idxOwned, ]
  tickers <- rownames(positions)
  quotes <- as.numeric(lapply(tickers, function(x) rh_quote(x,account=account)))
  prices <- quotes
  naPrices <- which(is.na(quotes)==TRUE)

  if(length(naPrices)>0){
    newQuotes<- as.numeric(lapply(tickers[naPrices], function(x) rh_quote(x,account=account)))

    prices[naPrices]<-newQuotes$last_trade_price
  }
  shares<-shares[idxOwned]
  prices<-as.numeric(prices)
  marketValue<-sum(shares*prices)
  day_stats<-account$get_day_PnL()
  equity<-as.numeric(day_stats$Equity)
  cashBalance<-equity-marketValue
  marketValue<-shares*prices
  marketValue<-c(cashBalance,marketValue)
  tickers<-c("CASH",tickers)
  shares<-c("NA",shares)
  prices<-c("NA",prices)

  balances<<-data.frame(Ticker=tickers,Shares=shares,"Last Price"=prices,"Market Value"=marketValue)
  return(balances)
}

######

# rh_getOptions<-function(symbol,expiration_dates,option_type){
#   header<-rh_createAuthHeader(userAuthToken)
#   chain_id<-"912190a6-ee19-4d47-b7ea-f631c75db650"
#   instrumentURL<-rh_getInstrumentURL(symbol)
#   instrumentID<-strsplit(instrumentURL,"/")[[1]][5]
#
#
#
#   url<-paste0("https://api.robinhood.com/options/chains/?equity_instrument_ids=",instrumentID)
#   res<-GET(url,add_headers(.headers=header))
#   #api_url + "/options/instruments/?chain_id={_chainid}&expiration_dates={_dates}&state=active&tradability=tradable&type={_type}".format(_chainid=chainid, _dates=dates, _type=option_type)
#   result<-content(res)$results
#   strike_price<-NULL
#   state<-NULL
#   urls<-NULL
#   expiration_date<-NULL
#   created_at<-NULL
#   Type<-NULL
#   Ticker<-NULL
#   issue_date<-NULL
#   for (i in 1:length(result)){
#     ##Mostl likely need to iterate through all dimensions of result list
#     chainId<-result[[i]]$id
#     expiration_dates<-as.character(result[[i]]$expiration_dates)
#     chain_url<-paste0("https://api.robinhood.com/options/instruments/?chain_id=",chainId,"&expiration_dates=",expiration_dates[1],"&state=active&tradeability=tradable&type=",option_type)
#     #"/options/instruments/?chain_id={_chainid}&expiration_dates={_dates}&state=active&tradability=tradable&type={_type}".format(_chainid=chainid, _dates=dates, _type=option_type
#     res<-GET(chain_url,add_headers(.headers=header))
#     results<-content(res)$results
#
#
#     for (j in 1:length(results)){
#       result<-results[[j]]
#       issue_date<-c(issue_date,result$issue_date)
#       strike_price<-c(strike_price,result$strike_price)
#       state<-c(state,result$state)
#       urls<-c(urls,result$url)
#       expiration_date<-c(expiration_date,result$expiration_date)
#       created_at<-c(created_at,result$created_at)
#       Type<-c(Type,result$type)
#       Ticker<-c(Ticker,result$chain_symbol)
#     }
#   }
# }

####
