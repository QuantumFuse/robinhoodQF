BasicChartBuilder<-R6::R6Class(
  
  classname="PlotlyDailyChartBuilder",
  portable=TRUE,
  
  public=list(
    
    priceData=NULL,
    tickerSymbol=NULL,
    
    rangeSelect=NULL,
    yButtons=NULL,
    
    pricePlot=NULL,
    volumePlot=NULL,
    volumeCombinedPlot=NULL,
    
    
    initialize=function(ohlcvData,tickerSymbol){
      
      self$tickerSymbol <- tickerSymbol
      
      priceDataTemp <- data.frame(ohlcvData,date=as.Date(time(ohlcvData)),stringsAsFactors=FALSE)
      priceDataTemp$direction<-NA
      
      for (i in 1:nrow(priceDataTemp)) {
        priceDataTemp$direction[i]<-if(priceDataTemp$close[i] >= priceDataTemp$open[i]) "Increasing" else "Decreasing"
      }
      
      self$priceData<-priceDataTemp
      
      ## initialize range selection for x-axis
      self$rangeSelect<-list(
        visible=TRUE,x=0.5,y=0.94,xanchor='right',yref='paper',font=list(size=9),
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
    

    plot_price=function(chartType){
      
      self$pricePlot<-if(chartType=="line"){
        
        self$priceData %>%  plot_ly(x=~date,y=~close,type="scatter",mode="lines",
                                    name=self$tickerSymbol, line=list(color="#008000")) %>%
          layout(xaxis=list(title="Select Minimum Charting Price",titlefont=list(size=8),
                            tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE))
        
      } else if(chartType=="candlestick"){
        
        self$priceData %>% plot_ly(x=~date,type="candlestick",open=~open,close=~close,
                                   high=~high,low=~low,name=self$tickerSymbol) %>%
          layout(xaxis=list(title="Select Minimum Charting Price",titlefont=list(size=8),
                            tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE))
        
      }
      
    },
    
    
    
    ## create y-axis range selection buttons
    create_main_yaxis_buttons=function(){
      
      priceSets<-lapply(
        list("1 year", "252 days", "126 days", "63 days", "21 days", "5 days"), 
        function(x) xts::last(xts::xts(self$priceData$close, order.by=as.Date(rownames(self$priceData))), x)
      )
      
      minPrices<-lapply(priceSets, function(x) max(floor(min(as.numeric(x)))-1, 0))
      minPrices<-unlist(minPrices[!duplicated(minPrices)])
      minPrices<-seq(0,max(minPrices),max(minPrices)/4)
      minPrices<-sort(minPrices-(minPrices %% 5),decreasing=FALSE)
      minPrices<-minPrices[!duplicated(minPrices)]
      buttonList<-vector("list", length(minPrices))
      
      for(i in 1:length(minPrices)) {
        buttonList[[i]] <- list(method="relayout",args=list("yaxis.range[0]",minPrices[i]),
                                label=paste0("$",minPrices[i]))
      }
      
      self$yButtons<-buttonList
      
    }, 
    
    # create_subplot_buttons=function(){
    #   
    #   priceSets<-lapply(
    #     list("MACD(9,12,26)", "RSI", "126 days", "63 days", "21 days", "5 days"), 
    #     function(x) xts::last(xts::xts(self$priceData$close, order.by=as.Date(rownames(self$priceData))), x)
    #   )
    #   
    #   minPrices<-lapply(priceSets, function(x) max(floor(min(as.numeric(x)))-1, 0))
    #   minPrices<-unlist(minPrices[!duplicated(minPrices)])
    #   minPrices<-seq(0,max(minPrices),max(minPrices)/4)
    #   minPrices<-sort(minPrices-(minPrices %% 5),decreasing=FALSE)
    #   minPrices<-minPrices[!duplicated(minPrices)]
    #   buttonList<-vector("list", length(minPrices))
    #   
    #   for(i in 1:length(minPrices)) {
    #     buttonList[[i]] <- list(method="relayout",args=list("yaxis.range[0]",minPrices[i]),
    #                             label=paste0("$",minPrices[i]))
    #   }
    #   
    #   self$yButtons<-buttonList
    #   
    # }, 
    
    ## create plot layout
    add_main_layout=function(){
      
      self$pricePlot<-self$pricePlot %>% layout(
        title="",xaxis=list(rangeslider=list(visible=FALSE)),
        yaxis=list(title="Price (USD)",titlefont=list(size=12),tickfont=list(size=8)),
        updatemenus=list(
          list(y=-0.1,x=.5,font=list(size=8),xanchor="center",borderwidth=0.25,
               type="buttons",direction="right",buttons=self$yButtons)
        ),
        annotations=list(
          list(text=paste0('<b>',self$tickerSymbol),font=list(size=16),xref='paper',yref='paper',
               x='1.0',y='1.0',showarrow = FALSE),
          list(text='<b>Adjust Price Range',font=list(size=8),xref='paper',yref='paper',
               x='0.5',y='-0.275',showarrow=F)
        )
      ) 
      
    },
    
    create_volume_plot=function(){
      self$volumePlot<-self$priceData %>%
        plot_ly(x=~date,y=~volume,type='bar',name="Volume",color=~direction,
                colors=c('#FF0000','#006400'),showlegend=FALSE) %>%
        layout(yaxis=list(title = "Volume", titlefont=list(size=11), tickfont=list(size=8)))
    },
    
    
    combine_plots=function(){
      
      self$volumeCombinedPlot<-subplot(self$pricePlot,self$volumePlot,heights=c(0.8,0.2),margin=0.035,
                                       widths=c(1.0),nrows=2,shareX=TRUE,titleY=TRUE) %>%
        layout(xaxis=list(title="Select Minimum Charting Price",titlefont=list(size=6),
                          tickfont=list(size=8),rangeselector=self$rangeSelect,showspikes=TRUE),
               yaxis=list(rangemode="match", showspikes=TRUE),
               legend=list(orientation='v',x=1.05,y=1,xanchor='left',yref='paper',font=list(size=8),
                           bgcolor='transparent',tracegroupgap=5)) %>%
        config(displayModeBar = T)
      
    },
    
    
    create_plot=function(chartType){
      
      self$plot_price(chartType)
      self$create_main_yaxis_buttons()
      self$add_main_layout()
      self$create_volume_plot()
      self$combine_plots()
      
    },
    
    
    create_initial_plot=function(chartType){
      self$plot_price(chartType);
      self$create_main_yaxis_buttons();
      self$add_main_layout();
    }
  )
)
