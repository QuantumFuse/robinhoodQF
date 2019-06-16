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







