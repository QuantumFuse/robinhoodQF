PlotlyTechnicalAnalysis<-R6::R6Class(

  classname="PlotlyTechnicalAnalysis",
  portable=TRUE,

  public=list(

    simpleMovingAverages=NULL,
    movingAverageCD=NULL,
    relativeStrengthIndex=NULL,
    bollingerBands=NULL,

    tickerSymbol=NULL,
    ohlcvPrices=NULL,
    taDf=NULL,
    intraday = FALSE,

    as_date_object = function(timeVector) {

      if(self$intraday) {
        return(as.POSIXct(timeVector, tz = Sys.timezone()))
      } else {

        return(as.Date(timeVector))
      }
    },

    simple_moving_averages=function(){
      nValues<-list(5,10,20,50,100,200)
      smaDf<-lapply(nValues, function(x) TTR::SMA(self$ohlcvPrices[,4], n=x))
      smaDf<-as.data.frame(do.call(cbind,smaDf))
      colnames(smaDf)<-as.character(nValues)
      self$simpleMovingAverages<-smaDf
    },

    macd=function(){
      macdTemp<-as.data.frame(TTR::MACD(self$ohlcvPrices[,4]))
      macdTemp$difference<-macdTemp$macd-macdTemp$signal
      self$movingAverageCD<-macdTemp
    },


    rsi=function(){
      self$relativeStrengthIndex<-as.data.frame(TTR::RSI(self$ohlcvPrices[,4]))
    },


    bollinger_bands=function(){
      self$bollingerBands<-as.data.frame(TTR::BBands(self$ohlcvPrices[,-c(1,5)]))
    },

    initialize=function(ohlcvPrices,tickerSymbol, intraday){
      self$tickerSymbol<-tickerSymbol
      self$ohlcvPrices<-ohlcvPrices
      self$ohlcvPrices[,4]<-ohlcvPrices[,4]

      self$intraday <- intraday
      if(!self$intraday) {
        self$simple_moving_averages()
        self$macd()
        self$rsi()
        self$bollinger_bands()
      }


      self$wrangle()
    },

    wrangle=function() {

      taDf<-if(!self$intraday){
        data.frame(
          self$ohlcvPrices,
          self$simpleMovingAverages,
          self$movingAverageCD,
          self$relativeStrengthIndex,
          self$bollingerBands
        )
      } else {
        data.frame(
          self$ohlcvPrices
        )
      }


      if(!self$intraday) {

        startDate<-as.POSIXlt(Sys.Date())
        startDate$year<-startDate$year-5
        startDate <- substring(as.character(as.Date(startDate)), 0 ,10)

        taXts<-window(xts::xts(taDf,order.by=as.Date(rownames(taDf))), startDate = as.Date(startDate))

      } else {

        taXts<-window(xts::xts(taDf,order.by=as.POSIXct(rownames(taDf), tz=Sys.timezone())))

      }

      self$taDf<-taXts
    }
  )
)


PlotlyDailyChartBuilder<-R6::R6Class(

  classname="PlotlyDailyChartBuilder",
  inherit=PlotlyTechnicalAnalysis,
  portable=TRUE,

  public=list(

    plotData=NULL,

    rangeSelect=NULL,
    yButtons=NULL,

    pricePlot=NULL,
    macdPlot=NULL,
    rsiPlot=NULL,
    volumePlot=NULL,

    volumeCombinedPlot=NULL,
    macdCombinedPlot=NULL,
    rsiCombinedPlot=NULL,

    plot_price=function(chartType){

      self$pricePlot<-if(chartType=="line"){
        self$plotData %>%
          plot_ly(x=~date,y=~close,type="scatter",mode="lines",name=self$tickerSymbol, line=list(color="#008000"))
      } else if(chartType=="candlestick"){
        self$plotData %>%
          plot_ly(x=~date,type="candlestick",open=~open,close=~close,high=~high,low=~low,name=self$tickerSymbol)
      }
    },


    ## create y-axis range selection buttons
    create_main_yaxis_buttons=function(){
      priceSets<-lapply(
        list("5 years","3 years","1 years", "252 days", "126 days", "63 days", "21 days", "5 days"),
        pd <-
        function(x) xts::last(xts::xts(self$plotData$close,order.by=self$as_date_object(time(self$taDf))), x)
      )
      minPrices<-lapply(priceSets, function(x) max(floor(min(as.numeric(x)))-1, 0))
      minPrices<-unlist(minPrices[!duplicated(minPrices)])
      minPrices<-seq(0,max(minPrices),max(minPrices)/4)
      minPrices<-sort(minPrices-(minPrices %% 5),decreasing=FALSE)
      minPrices<-minPrices[!duplicated(minPrices)]
      buttonList<-vector("list", length(minPrices))
      for(i in 1:length(minPrices)) {
        buttonList[[i]] <- list(method="relayout",args=list("yaxis.range[0]",minPrices[i]),label=paste0("$",minPrices[i]))
      }
      self$yButtons<-buttonList
    },

    ## create plot layout
    add_main_layout=function(){
      self$pricePlot<-self$pricePlot %>%
        layout(
          title="", xaxis=list(rangeslider=list(visible=FALSE)),
          yaxis=list(title="Price (USD)",titlefont=list(size=12),tickfont=list(size=8)),
          updatemenus=list(
            list(y=-0.1,x=.5,font=list(size=8),xanchor="center",borderwidth=0.25,
                 type="buttons",direction="right",buttons=self$yButtons)
          ),
          annotations=list(
            list(text='<b>Adjust Price Range',font=list(size=8),xref='paper',yref='paper',
                 x='0.5',y='-0.275',showarrow=F)
          )
        )
    },

    ## range selection for x axis
    get_range_selecter=function(){
      self$rangeSelect<-list(
        visible=TRUE,x=0.5,y=1.05,xanchor='center',yref='paper',font=list(size=9),
        buttons=list(
          list(count=7,label='1 Week',step='day',stepmode='backward'),
          list(count=1,label='1 Month',step='month',stepmode='backward'),
          list(count=3,label='3 Month',step='month',stepmode='backward'),
          list(count=6,label='6 Month',step='month',stepmode='backward'),
          list(count=1,label='YTD',step='year',stepmode='todate'),
          list(count=12,label='1 Year',step='month',stepmode='backward')
        )
      )
    },

    add_simple_moving_averages=function(){
      self$pricePlot<-self$pricePlot %>%
        add_lines(x=~date,y=~X5,name="5-Day SMA",line=list(color="#000080",width=0.5),
                  legendgroup="Simple Moving Average 1",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~X10,name="10-Day SMA",line=list(color="#00FFFF",width=0.5),
                  legendgroup="Simple Moving Average 2",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~X20,name="20-Day SMA",line=list(color="#D2691E",width=0.5),
                  legendgroup="Simple Moving Average 3",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~X50,name="50-Day SMA",line=list(color="#8A2BE2",width=0.5),
                  legendgroup="Simple Moving Average 4",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~X100,name="100-Day SMA",line=list(color="#8B008B",width=0.5),
                  legendgroup="Simple Moving Average 5",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~X200,name="200-Day SMA",line=list(color="#4B0082",width=0.5),
                  legendgroup="Simple Moving Average 6",inherit=FALSE,visible="legendonly")
    },

    add_bollinger_bands=function(){
      self$pricePlot<-self$pricePlot %>%
        add_lines(x=~date,y=~up,name="Bolling Bands",line=list(color="#2F4F4F",width=0.5),
                  legendgroup="Bolling Bands",inherit=FALSE,visible="legendonly") %>%
        add_lines(x=~date,y=~dn,name="Bolling Bands",line=list(color="#2F4F4F",width=0.5),
                  legendgroup="Bolling Bands",inherit=FALSE,visible="legendonly",showlegend=FALSE) %>%
        add_lines(x=~date,y=~mavg,name="Bolling Bands",line=list(color="#000000",width=0.5),
                  legendgroup="Bolling Bands",inherit=FALSE,visible="legendonly",showlegend=FALSE)
    },

    create_macd_plot=function(){
      self$macdPlot<-self$plotData %>%
        plot_ly(x=~date,y=~macd,type='scatter',mode="lines",name="MACD",
                line=list(color='#0000FF',width=0.5),legendgroup="MACD") %>%
        layout(yaxis=list(title="MACD",titlefont=list(size=11),tickfont=list(size=8))) %>%
        add_lines(x=~date,y=~signal,name="Signal",line=list(color="#FFD700",width=0.5),
                  legendgroup="MACD",inherit=FALSE) %>%
        add_bars(x=~date,y=~difference,name="Difference",colors="#696969",
                 legendgroup="MACD",inherit=FALSE,showlegend=FALSE)
    },

    create_rsi_plot=function(){
      self$rsiPlot<-self$plotData %>%
        plot_ly(x=~date,y=~rsi,type='scatter',mode="lines",name="RSI",line=list(color='#2F4F4F',width=0.5)) %>%
        layout(yaxis=list(title="RSI",titlefont=list(size=11),tickfont=list(size=8)))
    },


    create_volume_plot=function(){
      self$volumePlot<-self$plotData %>%
        plot_ly(x=~date,y=~volume,type='bar',name="Volume",color=~direction,
                colors=c('#FF0000','#006400'),showlegend=FALSE) %>%
        layout(yaxis=list(title = "Volume", titlefont=list(size=11), tickfont=list(size=8)))

      self$volumeCombinedPlot<-subplot(self$pricePlot,self$volumePlot,heights=c(0.7,0.3),margin=0.035,
                                       widths=c(1.0),nrows=2,shareX=TRUE,titleY=TRUE) %>%
        layout(xaxis=list(title="Select Minimum Charting Price",titlefont=list(size=6),
                          tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE),
               yaxis=list(rangemode="match", showspikes=TRUE),
               legend=list(orientation='v',x=1.05,y=1,xanchor='left',yref='paper',font=list(size=8),
                           bgcolor='transparent',tracegroupgap=5)) %>%
        config(displayModeBar = F)

    },


    combine_plots=function(){

      self$volumeCombinedPlot<-subplot(self$pricePlot,self$volumePlot,heights=c(0.7,0.3),margin=0.035,
                                       widths=c(1.0),nrows=2,shareX=TRUE,titleY=TRUE) %>%
        layout(xaxis=list(title="Select Minimum Charting Price",titlefont=list(size=6),
                          tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE),
               yaxis=list(rangemode="match", showspikes=TRUE),
               legend=list(orientation='v',x=1.05,y=1,xanchor='left',yref='paper',font=list(size=8),
                           bgcolor='transparent',tracegroupgap=5)) %>%
        config(displayModeBar = F)

      self$macdCombinedPlot<-subplot(self$pricePlot,self$macdPlot,heights=c(0.7,0.3),margin=0.035,widths=c(1.0),
                                     nrows=2,shareX=TRUE,titleY=TRUE) %>%
        layout(xaxis=list(title=NULL,tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE),
               yaxis=list(rangemode="match", showspikes=TRUE),
               legend=list(orientation='v',x=1.05,y=1,xanchor='left',yref='paper',font=list(size=8),
                           bgcolor='transparent',tracegroupgap=5)) %>%
        config(displayModeBar = F)

      self$rsiCombinedPlot <- subplot(self$pricePlot,self$rsiPlot,heights=c(0.7,0.3),widths=c(1.0),
                                    nrows=2,shareX=TRUE,titleY=TRUE) %>%
        layout(xaxis=list(title=NULL,tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE),
               yaxis=list(rangemode="match", showspikes=TRUE),
               legend=list(orientation='v',x=1.05,y=1,xanchor='left',yref='paper',font=list(size=8),
                           bgcolor='transparent',tracegroupgap=5)) %>%
        config(displayModeBar = F)
    },


    data_wrangle = function() {

      plotDataTemp<-as.data.frame(self$taDf)
      plotDataTemp<-data.frame(plotDataTemp,date=self$as_date_object(time(self$taDf)),stringsAsFactors=FALSE)
      plotDataTemp$direction<-NA
      for (i in 1:nrow(plotDataTemp)) {
        plotDataTemp$direction[i]<-if(plotDataTemp$close[i] >= plotDataTemp$open[i]) "Increasing" else "Decreasing"
      }
      self$plotData<-plotDataTemp

    },


    intraday = FALSE,

    initialize = function(tickerSymbol, ohlcvPrices, chartType){

      if(length(unique(as.Date(time(ohlcvPrices)))) < nrow(ohlcvPrices)) {
        self$intraday <- TRUE
      }

      super$initialize(ohlcvPrices = ohlcvPrices, tickerSymbol = tickerSymbol, intraday = self$intraday)
      self$data_wrangle()
      self$create_initial_plot(chartType)



    },


    create_full_plots=function(chartType,includeSMA,includeBBands){

      self$plot_price(chartType);
      self$create_main_yaxis_buttons();
      self$add_main_layout();

      if(!intraday) self$get_range_selecter();
      if(includeSMA) self$add_simple_moving_averages()
      if(includeBBands) self$add_bollinger_bands()

      if(!self$intraday) {
        self$create_macd_plot();
        self$create_volume_plot();
        self$create_rsi_plot()
        self$combine_plots()
      }

    },


    create_initial_plot=function(chartType){
      self$plot_price(chartType);
      self$create_main_yaxis_buttons();
      self$add_main_layout();
      if(!self$intraday) self$get_range_selecter();
    }
  )
)
