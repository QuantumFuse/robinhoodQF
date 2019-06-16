source("functions.R")
source("PlotlyCharting.R")
library(data.table)

#############################################
### Login & initialize robinhoodUser class ##
#############################################

access_robinhood(
  rstudioapi::showPrompt(title = "Username", message = "Username", default = ""),
  rstudioapi::askForPassword(prompt = 'Password: ')
)


source("Requests.R")
source("RobinhoodOptions.R")


ticker_ <- "CRON"
optionsData = RobinhoodOptions$new(ticker_,robinhoodUser)
currentQuotes <- optionsData$current_chains()
currentStockPrice <- as.numeric(robinhoodUser$quotes$get_quotes(ticker_)$last_trade_price)


par(mfrow=c(3,3))
for(i in 1:9) {
  callMoneyness <- currentQuotes[[i]]$calls$numerical
  putMoneyness <- currentQuotes[[i]]$puts$numerical
  callMoneyness<-callMoneyness[complete.cases(callMoneyness), ]
  putMoneyness<-putMoneyness[complete.cases(putMoneyness), ]
  callMoneyness$strike_price <- log(callMoneyness$strike_price/currentStockPrice)/(callMoneyness$implied_volatility*sqrt(dtm[[i]]))
  putMoneyness$strike_price <- log(putMoneyness$strike_price/currentStockPrice)/(putMoneyness$implied_volatility*sqrt(dtm[[i]]))

  impliedVolDelta <- rbind(putMoneyness[putMoneyness$strike_price >= 0, c("implied_volatility", "strike_price")],
                           callMoneyness[callMoneyness$strike_price <= 0, c("implied_volatility", "strike_price")])

  expi=names(currentQuotes)[i]
  plot(impliedVolDelta$strike_price, impliedVolDelta$implied_volatility, type="l", lwd=2, yaxt="n",
       ylim=c(min(impliedVolDelta$implied_volatility)-.1,max(impliedVolDelta$implied_volatility)+.1),
       xlim=c(min(impliedVolDelta$strike_pric)-.1,max(impliedVolDelta$strike_pric)+.1),
       xlab="Moneyness", ylab="Implied Volatility", main=paste("Volatility Smile \n",expi))
  axis(side=2, at=seq(0,2,.1),labels=seq(0,2,.1))
}

# j=1
# callMoneyness <- currentQuotes[[j]]$calls$numerical[complete.cases(currentQuotes[[j]]$calls$numerical), ]
# putMoneyness <- currentQuotes[[j]]$puts$numerical[complete.cases(currentQuotes[[j]]$puts$numerical), ]
# cqc <- currentQuotes[[j]]$calls$numerical[complete.cases(currentQuotes[[j]]$calls$numerical), ]
# cqp <- currentQuotes[[j]]$puts$numerical[complete.cases(currentQuotes[[j]]$puts$numerical), ]
#
#
# callMoneyness$strike_price <- log(callMoneyness$strike_price/currentStockPrice)/(callMoneyness$implied_volatility*sqrt(dtm[[i]]))
# putMoneyness$strike_price <- log(putMoneyness$strike_price/currentStockPrice)/(putMoneyness$implied_volatility*sqrt(dtm[[i]]))
#
# otmCallComparison <- dplyr::inner_join(by="strike_price",
#   x=cqp[putMoneyness$strike_price >= 0, c("implied_volatility", "strike_price", "vega", "delta")],
#   y=cqc[callMoneyness$strike_price >=0, c("implied_volatility", "strike_price", "vega", "delta")])
#
#
# otmPutComparison <- dplyr::inner_join(by="strike_price",
#   y=cqp[putMoneyness$strike_price <=0, c("implied_volatility", "strike_price", "vega", "delta")],
#   x=cqc[callMoneyness$strike_price <= 0, c("implied_volatility", "strike_price", "vega", "delta")])
#
# otmCallComparison[otmCallComparison$implied_volatility.x > otmCallComparison$implied_volatility.y,] ## cheap calls
# otmPutComparison[otmPutComparison$implied_volatility.x > otmPutComparison$implied_volatility.y,] ## cheap puts
#
# otmCallComparison[otmCallComparison$implied_volatility.x < otmCallComparison$implied_volatility.y,] ## expenvsive calls
# otmPutComparison[otmPutComparison$implied_volatility.x < otmPutComparison$implied_volatility.y,] ## expensive puts
#
# ###

currentQuotes <- optionsData$current_chains()
currentStockPrice <- as.numeric(robinhoodUser$quotes$get_quotes(ticker_)$last_trade_price)
nearestChain <- currentQuotes[[1]]

shorts <- do.call(rbind, lapply(
  nearestChain, function(x)
    x$numerical[which.min(abs(x$numerical$strike_price-currentStockPrice)), ]))

shorts[, c(2,3, 5, 6, 7, 8,9)] <- -shorts[, c(2,3, 5, 6, 7, 8,9)]

longs <- rbind(
  nearestChain$calls$numerical[which(nearestChain$calls$numerical$strike_price==25), ],
  nearestChain$puts$numerical[which(nearestChain$puts$numerical$strike_price==17), ]
)

longs[, c(2,3, 5, 6, 7, 8,9)] <- 3*longs[, c(2,3, 5, 6, 7, 8,9)]
earningsPosition <- rbind(shorts, longs)
earningsPosition <- earningsPosition[sort(earningsPosition$strike_price, index.return=T, decreasing=T)[[2]], ]

colSums(earningsPosition)
earningsPosition

###
dtm <- as.list(as.Date(names(currentQuotes))- Sys.Date())
names(dtm) <- names(currentQuotes)
strikesAndVol <-lapply(currentQuotes, function(x) x$calls$numerical[,c("strike_price", "implied_volatility")])

volSurfaceData <- lapply(as.list(names(currentQuotes)), function(x) {
  y <- strikesAndVol[[x]]
  y$delta <-dtm[[x]]
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



stickyDelta <- as.data.frame(do.call(rbind, lapply(strikesAndVol[1:3], function(x) x[which.min(abs(currentStockP-x$strike_price)), ])))
plot(strikesAndVol[[1]]$strike_price, strikesAndVol[[1]]$implied_volatility, type="l")
plot(strikesAndVol[[1]]$delta, strikesAndVol[[1]]$implied_volatility, type="l")
plot(stickyDelta$delta, stickyDelta$implied_volatility, type="l")
plot(stickyDelta$strike, stickyDelta$implied_volatility, type="l")
cor(volSurfaceData$DTM, volSurfaceData$IV)



