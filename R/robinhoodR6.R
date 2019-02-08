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
        dayChange <- data.frame("Change($)"=change, "Percent Change"=pctChange)
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
      quotes <- robinhoodr::rh_quote(tickers)
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

#' @param account Initialzied instance of Account class
get_robinhood_individual_PL<-function(account){
  orders<-rh_getRecentOrders(account$user$authToken)
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

  total_equity<-as.numeric(rh_getPortfolioEquity(account$user$authToken,account$user$accountNumber))
  equities<-sum(current_positions$Market.Value)
  cash<-total_equity-equities
  tickers<-c("CASH",tickers_owned)
  market_values<-c(cash,current_positions$Market.Value)


  allocation <- data.frame(value = market_values,
                                          Group = tickers) %>%
    # factor levels need to be the opposite order of the cumulative sum of the values
    mutate(Group = factor(Group, levels = rev(tickers)),
           label = paste0(Group, " ", round(value / sum(value) * 100, 1), "%"))

  return(list(individual_pl,current_positions,allocation,grouped_tx))
}

#'@param grouped_tx Transaction history grouped by ticker. Returned from get_robinhood_individual_pl(account)[[4]]
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

