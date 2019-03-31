output$expiry_select_ui<-renderUI({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$option_ticker)
  
  ### REPLACE ###
  ops_rv$quote<-robinhood_quotes(isolate(input$option_ticker))
  ###############
  optionsData <- RobinhoodOptions$new(isolate(input$option_ticker),rv$robinhoodUser)
  currentQuotes <- optionsData$current_chains()
  ops_rv$currentQuotes<-currentQuotes
  expiry_options<-sort(unique(names(currentQuotes)))
  selectizeInput("expiry_select","Contract Expiry Date",choices=expiry_options)
})

##############################################################################################################
#### OPTIONS TABLES ##########################################################################################
output$filtered_options_data_DT<-renderDT({
  req(is.null(rv$robinhoodUser)!=T)
  req(is.null(ops_rv$currentQuotes)!=T)
  req(input$option_ticker)
  req(input$expiry_select)
  req(input$contract_type)
  
  ops_rv$data<-ops_rv$currentQuotes[[isolate(input$expiry_select)]][[tolower(isolate(input$contract_type))]]$combined
  columns_to_rm<-c("updated_at","previous_close_date")
  rm_cols_idx<-which(colnames(ops_rv$data)%in%columns_to_rm)
  ops_prep<-ops_rv$data[,-rm_cols_idx]
  
  
  ops_rv$render_data<-ops_prep%>%
    mutate_all(funs(replace(., is.na(.), 0)))
  
  ops_dat<-ops_rv$render_data%>%
    filter(volume!=0)
  last_price<-if(is.na(ops_rv$quote$last_extended_hours_trade_price)){
    as.numeric(ops_rv$quote$last_trade_price)
  } else {
    as.numeric(ops_rv$quote$last_extended_hours_trade_price)
  }
  colnames(ops_dat) <- columns_to_keep
  ops_dat$Bid<-paste0("$",ops_dat$Bid)
  ops_dat$Ask<-paste0("$",ops_dat$Ask)
  ops_dat$`Break Even`<-paste0("$",ops_dat$`Break Even`,br()," (",percent((ops_dat$`Break Even`-last_price)/last_price),")")
  ops_dat$Price<-paste0("$",ops_dat$Price,br()," (",percent((ops_dat$Mark-ops_dat$`Previous Close`)/ops_dat$`Previous Close`),")")
  ops_dat$`Last Trade`<-paste0("$",ops_dat$`Last Trade`)
  ops_rv$DT_dat<-ops_dat
  ops_dat<-ops_dat[,-which(colnames(ops_dat)=="instrument")]
  
  datatable(ops_dat,class="cell-border compact stripe", filter = 'top',rownames=FALSE, 
            extensions = c('Buttons'),fillContainer = T,escape=F,selection='single',
            options = list(
              scrollX=T,
              columnDefs = list(list(className = 'dt-left', targets = "_all")),
              dom = 'Blfrtip',
              buttons = list('print',list(extend='collection',buttons=c('csv','excel'),text='Download'),I('colvis')),
              # customize the length menu
              lengthMenu = list( c(-1,10,25,100), # declare values
                                 c("All",10,25,100) # declare titles
              ), # end lengthMenu
              pageLength=-1
            )) %>% 
    formatCurrency(c('Strike', "Mark","High","Low")) %>% 
    formatPercentage(c('Implied Vol','Chance of Profit Long','Chance of Profit Short'), 2)
  
})

output$options_box<-renderUI({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$option_ticker)
  
  
  if(is.na(ops_rv$quote$last_extended_hours_trade_price)){last_price<-as.numeric(ops_rv$quote$last_trade_price)}
  else{last_price<-as.numeric(ops_rv$quote$last_extended_hours_trade_price)}
  
  last_close<-as.numeric(ops_rv$quote$adjusted_previous_close)
  percent_change<-percent((last_price-last_close)/last_close)
  change<-paste0("$",abs(round((last_price-last_close),2)))
  
  if(percent_change<0){
    text_style<-"color:red; font-weight:bold"
    direction<-"DOWN"
  }
  else{
    text_style<-"color:#198c19; font-weight:bold"
    direction<-"UP"
  }
  change_text<-paste0(direction," ",change," ","(",abs(percent_change),")")
  box_title<-tags$div(HTML(paste(tags$b("Share Price: $"),tags$b(round(last_price,2)),br(),tags$span(style=text_style,change_text),sep = "")))
  
  box(title=box_title,height = "100%",width="100%",collapsible=FALSE,
      div(div(loadingLogo('eclipse_loader.svg',height="25%",width="25%",alt="Options Table"),class="overlay"),
          DTOutput("filtered_options_data_DT")
      ))
})

output$noVol_data_DT<-renderDT({
  noVol_data<-ops_rv$render_data%>%
    filter(volume==0)
  last_price<-if(is.na(ops_rv$quote$last_extended_hours_trade_price)){
    as.numeric(ops_rv$quote$last_trade_price)
  } else {
    as.numeric(ops_rv$quote$last_extended_hours_trade_price)
  }
  colnames(noVol_data)<-columns_to_keep
  
  noVol_data$`Break Even`<-paste0("$",noVol_data$`Break Even`,br()," (",percent((noVol_data$`Break Even`-last_price)/last_price),")")
  noVol_data$Price<-paste0("$",noVol_data$Price,br()," (",percent((noVol_data$Mark-noVol_data$`Previous Close`)/noVol_data$`Previous Close`),")")
  noVol_data$`Last Trade Price`<-paste0("$",noVol_data$`Last Trade Price`," x ",noVol_data$`Last Trade Size`)
  colnames(noVol_data)[which(colnames(noVol_data)=="Last Trade Price")]<-"Last Trade"
  noVol_data<-noVol_data[,-which(colnames(noVol_data)%in%c("Bid Size","Ask Size","Previous Close","Last Trade Size"))]
  
  datatable(noVol_data,class="cell-border compact stripe", filter = 'top',rownames=FALSE, extensions = c('Buttons'),fillContainer = T,escape=F,
            options = list(
              scrollX=T,
              columnDefs = list(list(className = 'dt-left', targets = "_all")),
              dom = 'Blfrtip',
              buttons = list('print',list(extend='collection',buttons=c('csv','excel'),text='Download'),I('colvis')),
              # customize the length menu
              lengthMenu = list( c(-1,10,25,100), # declare values
                                 c("All",10,25,100) # declare titles
              ), # end lengthMenu
              pageLength=-1
            ))  %>% 
    formatCurrency(c('Strike', "Mark","High","Low")) %>% 
    formatPercentage(c('Implied Vol','Chance of Profit Long','Chance of Profit Short'), 2)
  
})
##############################################################################################################
#### OPTIONS PLOTS ###########################################################################################
output$options_plot_ui<-renderUI({
  req(input$filtered_options_data_DT_rows_selected)
  fluidRow(column(12,align="center",
                  plotOutput("options_chartSeries")
  ))
  
})

output$options_chartSeries<-renderPlot({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$option_ticker)
  req(input$expiry_select)
  req(input$contract_type)
  req(input$hist_span)
  req(input$filtered_options_data_DT_rows_selected)
  
  ohlcv<-historical_options_quotes(ops_rv$DT_dat$instrument[req(input$filtered_options_data_DT_rows_selected)],
                                   span=as.character(input$hist_span),
                                   header=rv$robinhoodUser$account$user$authHeader)
  chartSeries(ohlcv[[1]],
              name = isolate(input$option_ticker), type = req(input$chartType))
})


output$vol_surface_plotly<-renderPlotly({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$option_ticker)
  req(is.null(ops_rv$currentQuotes)!=T)
  
  currentStockP <- as.numeric(rv$robinhoodUser$quotes$get_quotes(isolate(input$option_ticker))$last_trade_price)
  
  dtm <- as.list(as.Date(names(ops_rv$currentQuotes))- Sys.Date())
  names(dtm) <- names(ops_rv$currentQuotes)
  strikesAndVol <-lapply(ops_rv$currentQuotes, function(x) x$puts$numerical[,c("strike_price", "implied_volatility")])
  
  volSurfaceData <- lapply(as.list(names(ops_rv$currentQuotes)), function(x) {
    y <- strikesAndVol[[x]]
    y$dtm <-dtm[[x]]
    return(y)
  })
  
  volSurfaceData <- do.call(rbind, volSurfaceData)
  volSurfaceData <- volSurfaceData[volSurfaceData$strike_price < ceiling(currentStockP*1.15), ]
  volSurfaceData <- volSurfaceData[volSurfaceData$strike_price > floor(currentStockP*.85), ]
  colnames(volSurfaceData)<-c("K", "IV", "DTM")
  volSurfaceData<-volSurfaceData[complete.cases(volSurfaceData), ]
  
  plot_ly(height=800) %>%
    add_trace(data = volSurfaceData,  x=~K, y=~DTM, z=~IV, type="mesh3d",
              intensity = seq(0, 1, length = nrow(volSurfaceData)),
              color = seq(0, 1, length = nrow(volSurfaceData)),
              colors = colorRamp(rainbow(nrow(volSurfaceData)))) %>%
    layout(plot_bgcolor='transparent',paper_bgcolor='transparent')
  
})