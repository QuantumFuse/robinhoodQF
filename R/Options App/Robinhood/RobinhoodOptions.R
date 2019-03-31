RobinhoodOptions <- R6::R6Class(

  classname = "RobinhoodOptions",
  portable = TRUE,

  public = list(

    rhUser = NULL,
    underlyingTicker = NULL,

    chainID = NULL,
    chainInstrumentLinks = NULL,
    chainChunkedParams = NULL,
    optionsContractSpecs = NULL,

    initialize = function(ticker, robinhoodUserList) {

      self$underlyingTicker <- ticker
      self$rhUser <- robinhoodUserList

      private$get_chain_id()
      private$get_chain_instrument_links()
      private$get_options_specs()

    },


    ## current numeric data for options contracts
    current_contracts_data = function() {

      contractDataList <- list()

      for(i in 1:length(self$chainChunkedParams)){

        tempRequest <- Requests$new(
          url=private$optionsEndpoints$marketData,
          parameters=list(instruments=self$chainChunkedParams[[i]]),
          headers=c(private$optionsAddedHeader, self$rhUser$login$authHeader)
        )

        contractDataList[[i]] <- tempRequest$content(results=TRUE)

      }

      contractDataList <- lapply(contractDataList, function(x)
        lapply(x, function(y)
          lapply(y, function(z)
            if(is.null(z[[1]])) NA else z
          )
        )
      )

      return(as.data.frame(do.call(cbind, private$reorganize_list(contractDataList))))

    },



    all_current_chains_unorganized = function(){

      optionsContactData <- self$current_contracts_data()

      optionsData <- suppressWarnings(
        dplyr::inner_join(x=optionsContactData,y=self$optionsContractSpecs,by=c("instrument"))
      )

      return(optionsData)

    },


    current_chains = function() {

      unorganizedData <- self$all_current_chains_unorganized()
      experies <- as.list(names(table(unorganizedData$expiration_date)))
      names(experies)<-unlist(experies)

      optionsChains <- lapply(experies, function(x) unorganizedData[unorganizedData$expiration_date==x, ])
      optionsChains <- lapply(optionsChains, function(x) list(calls=x[x$type=="call", ], puts=x[x$type=="put", ]))

      optionsChains <- lapply(optionsChains, function(x) {
        lapply(x, function(y){
          colPrefixes <- c("ask","bid","last_trade")
          deletePrices <- deleteSizes <- c()
          for(i in 1:3) {
            priceName <- paste0(colPrefixes[i], "_price")
            sizeName <- paste0(colPrefixes[i], "_size")
            temp <- trimws(paste(format(as.numeric(y[, paste0(priceName)],4), nsmall=3), y[, paste0(sizeName)], sep=" x "))
            y[, paste0(colPrefixes[i], " (price x size)")] <- temp
          }

          return(y)

        })
      })

      optionsChains <- lapply(optionsChains, function(x)
        lapply(x, function(y) {

          pricing <- c("mark_price", "adjusted_mark_price", "implied_volatility")
          orderBook <- c("ask (price x size)", "bid (price x size)", "last_trade (price x size)")
          greeks <- c("delta", "gamma", "theta", "vega", "rho")
          liquidity <- c("volume", "open_interest")
          hlc <- c("high_price", "low_price", "previous_close_price")
          misc <- c("break_even_price", "chance_of_profit_short", "chance_of_profit_long")
          dateTimes <- c("updated_at", "previous_close_date")

          toReturn <- list(

            numerical = as.data.frame(
              apply(y[ ,c("strike_price", pricing, greeks, hlc, liquidity, misc)], 2, as.numeric)
            ),

            strings = as.data.frame(
              y[ ,c("strike_price", "instrument", orderBook, dateTimes)]
            )

          )

          toReturn <- lapply(toReturn, function(z) {
            z$strike_price <- as.numeric(as.character(z$strike_price))
            sortedStrikeIndexes <- sort(z$strike_price, decreasing=TRUE, index.return=TRUE)[[2]]
            return(z[sortedStrikeIndexes, ])

          })

          toReturn$combined <- as.data.frame(dplyr::inner_join(x=toReturn$numerical, y=toReturn$strings, by="strike_price"))
          return(toReturn)

        })
      )

      return(optionsChains)

    },

    historical_chains = function(span="year") {

      requests <- list()
      possibleIntervals<-list(day="5minute",week="10minute",year="day","5year"="week")

      for(i in 1:length(self$chainChunkedParams)){
        requests[[i]] <- Requests$new(
          url=private$optionsEndpoints$historicals,
          parameters=list(span=span,interval=possibleIntervals[[span]],instruments=self$chainChunkedParams[[i]]),
          headers=c(private$optionsAddedHeader, self$rhUser$login$authHeader)
        )
      }

      results <- lapply(requests, function(x) x$content(results=TRUE))
      if(span == "day" || span == "week") return(private$organize_historicals(private$clean_historicals(results)))
      else return(private$organize_historicals(private$clean_historicals(results, intraday=FALSE)))

    }
  ),

  private = list(

    ## special header for options
    optionsAddedHeader = c(
      'Accept'='*/*',
      'Accept-Encoding'='gzip, deflate',
      'Accept-Langauge'='en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5',
      'User-Agent'='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'
    ),

    ## endpoints for options data
    optionsEndpoints = list(
      chains = "https://api.robinhood.com/options/chains/",
      instruments = "https://api.robinhood.com/options/instruments/",
      marketData = "https://api.robinhood.com/marketdata/options/",
      strategyQuotes = "https://api.robinhood.com/marketdata/options/strategy/quotes/",
      historicals = "https://api.robinhood.com/marketdata/options/historicals/"
    ),


    ## 1. get chain id for underlying ticker
    get_chain_id = function() {

      underlyingID <- strsplit(self$rhUser$quotes$get_quotes(self$underlyingTicker)$instrument,split="/")[[1]][5]

      request <- Requests$new(
        url=private$optionsEndpoints$chains,
        parameters=list(equity_instrument_ids=underlyingID),
        headers=self$rhUser$login$authHeader
      )

      results <- request$content(results=TRUE)
      results <- results[[which(unlist(lapply(results, function(x) x$symbol==self$underlyingTicker)))]]
      self$chainID <- results[c('id')][[1]]

    },


    ## 2. get links to options instruments
    get_chain_instrument_links = function(){

      optionsInstrumentLinks <- list()
      nextLink <- private$optionsEndpoints$instruments

      while(!is.null(nextLink)) {

        tempRequest <- Requests$new(
          url=nextLink,
          parameters=list(chain_id=self$chainID, tradability="tradable", state="active"),
          headers=self$rhUser$login$authHeader
        )

        optionsInstrumentLinks <- append(optionsInstrumentLinks, tempRequest$content(results=T))
        nextLink <- tempRequest$content(nextURL=TRUE)

      }


      optionsInstrumentLinks <- private$reorganize_list(optionsInstrumentLinks)
      self$chainInstrumentLinks <- optionsInstrumentLinks$url
      oiChunkedURLs <- split(optionsInstrumentLinks$url, ceiling(seq_along(optionsInstrumentLinks$url)/50))
      oiChunkParams <- lapply(oiChunkedURLs, function(x) paste0(x,collapse=","))
      names(oiChunkParams)<-NULL
      self$chainChunkedParams <- oiChunkParams

    },


    ## get contract specifications
    get_options_specs = function() {

      request <- RCurl::getURI(self$chainInstrumentLinks)

      request <- lapply(as.list(request), function(x) gsub("\\", "", strsplit(x, ","), fixed=TRUE))
      request <- lapply(request, unlist)
      request <- lapply(request, function(y) gsub("{", "", x=y, fixed=TRUE))
      request <- lapply(request, function(y) gsub("}", "", x=y, fixed=TRUE))
      request <- lapply(request, function(x) lapply(strsplit(x, ","), function(y) strsplit(y, "\"")))
      request <- lapply(request, function(x) trimws(unlist(x)))
      request <- lapply(request, function(x) x[x!=""])
      request <- lapply(request, function(x) x[-c(1,length(x))])

      toReturn <- lapply(request, function(x) t(as.data.frame(x[which(x==":")+1], row.names=x[which(x==":")-1])))
      toReturn <- lapply(toReturn, function(x) {rownames(x) <- NULL; x})
      toReturn <- as.data.frame(do.call(rbind, toReturn))
      colnames(toReturn)[which(colnames(toReturn)=="url")] <- "instrument"

      self$optionsContractSpecs <- toReturn

    },


    ## useful for organizing api output lists
    reorganize_list = function(x) {

      unlisted <- unlist(x)
      newListNames <- names(table(names(unlisted)))
      newList <- list()

      for(i in 1:length(newListNames)) {
        temp <- unlisted[names(unlisted)==newListNames[i]]
        names(temp) <- NULL
        newList[[i]] <-temp
      }

      names(newList)<-newListNames
      return(newList)

    },

    clean_historicals = function(historicalList, intraday=TRUE) {

      instrumentUrls <- lapply(historicalList, function(x)
        lapply(x, function(y)
          lapply(y$instrument, function(z)
            unlist(z)
          )
        )
      )

      ## get data points
      dataPoints <- lapply(historicalList, function(x)
        lapply(x, function(y)
          lapply(y$data_point, function(z)
            unlist(z)
          )
        )
      )

      ## create matricies inside the list
      dataPoints <- lapply(dataPoints, function(x)
        lapply(x, function(y)
          do.call(rbind, y)
        )
      )


      instrumentUrls <- lapply(instrumentUrls, unlist)

      ## name the matricies
      for(i in 1:length(dataPoints)) {
        names(dataPoints[[i]]) <- instrumentUrls[[i]]
      }

      ## create an xts object
      dataPoints <- if (intraday) {

        lapply(dataPoints, function(x)
          lapply(x, function(y){
            times <- lapply(strsplit(y[, 1], "T"), function(z) paste(z[1], z[2], sep=" "))
            times <- unlist(lapply(strsplit(unlist(times), "Z"), function(z) paste(z, "UTC", sep=" ")))
            times <- as.POSIXct(times, tz="UTC")

            seriesData <- apply(y[, c("open_price", "high_price","low_price", "close_price", "volume")], 2, as.numeric)
            seriesData <- as.data.frame(seriesData)
            colnames(seriesData) <- c("open", "high", "low", "close", "volume")

            toReturn <- xts::xts(seriesData, order.by=times, tzone=Sys.timezone())

            return(toReturn)

          })
        )
      } else {

        lapply(dataPoints, function(x)
          lapply(x, function(y){
            times <- as.Date(unlist(lapply(strsplit(y[, 1], "T"), function(z) z[1])))
            seriesData <- apply(y[, c("open_price", "high_price","low_price", "close_price", "volume")], 2, as.numeric)
            seriesData <- as.data.frame(seriesData)
            colnames(seriesData) <- c("open", "high", "low", "close", "volume")
            toReturn <- xts::xts(seriesData, order.by=times)


            return(toReturn)

          }
          )
        )

      }

      return(dataPoints)

    },


    organize_historicals = function(cleanedHistoricals) {

      temp <- lapply(cleanedHistoricals, function(x) {
        listNames <- as.list(names(x))
        matchedIndexes <- unlist(lapply(listNames, function(y) which(self$optionsContractSpecs$instrument == y)))
        toReturn <- self$optionsContractSpecs[matchedIndexes, c("strike_price", "expiration_date", "instrument", "type")]
        return(toReturn)
      })

      temp = do.call(rbind, temp)
      historicalExpiries <- as.list(names(table(temp[, 2])))
      names(historicalExpiries) <- historicalExpiries

      temp <- as.data.frame(dplyr::group_by(temp, expiration_date, type))
      historicalExpiries <- lapply(historicalExpiries, function(x) temp[temp$expiration_date == x, -2])

      historicalExpiries <- lapply(historicalExpiries, function(x) {
        strikesOrderedIndexes <- sort(as.numeric(as.character(x$strike_price)), decreasing=TRUE, index.return=TRUE)[[2]]
        return(x[strikesOrderedIndexes, ])
      })

      historicalExpiries <- lapply(historicalExpiries, function(x) {
        list(calls = x[x$type=="call", ], puts=x[x$type=="puts", ])
      })



      historicalData <- lapply(historicalExpiries, function(x) {
        lapply(x, function(y) {
          toReturn <- as.list(as.character(y$instrument))
          names(toReturn) <- as.character(y$strike_price)
          return(toReturn)
        })
      })

      cleanedHistoricals <- do.call(c, cleanedHistoricals)


      historicalData <- lapply(historicalData, function(x)
        lapply(x, function(y)
          lapply(y, function(z)
            cleanedHistoricals[which(names(cleanedHistoricals) == z)]
          )
        )
      )


      historicalData <- lapply(historicalData, function(x)
        lapply(x, function(y)
          lapply(y, function(z)
            z[[1]]
          )
        )
      )

      return(historicalData)

    }

  )

)






