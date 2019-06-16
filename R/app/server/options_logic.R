output$db_option_ticker_select<-renderUI({
  req(!is.null(rv$robinhoodUser))
  mySymbols<-get_watchlist_tickers()
  
  mySymbols<-mySymbols[-which(mySymbols%in%c("VXX","TSRO","SODA","LOGC","MGTX","AVRO","ORTX",
                                             "ARKR","IZRL","ARKQ","ARKG","ARKW","ARKK","SGH",
                                             "SMI","ASX"))]
  
  selectizeInput(inputId = "db_option_ticker",
                 label = "Select a Ticker",
                 choices = sort(mySymbols), selected="AAPL",
                 width="100%",
                 multiple=TRUE,
                 options = list(maxItems = 1,placeholder='Search by name or symbol')
  )
})
output$expiry_select_db<-renderUI({
  req(input$db_option_ticker)
  req(!is.null(rv$conn))
  
  db_ops_rv$quote<-robinhood_quotes(isolate(input$db_option_ticker))
  ###############
  ticker<-isolate(input$db_option_ticker)

  #qry<-build_sql('SELECT * from options_now.',ident(ticker))
  # new_qry<-sql('SELECT * from options_now.CRON_TEST')
  # CRON_TEST<-tbl(connection,qry)%>%arrange(desc(test_time))%>%filter(test_time = max(test_time))%>%show_query()
  # CRON<-tbl(connection,qry)%>%collect()%>%as.data.frame()
   grouping<-c("Expiry","Strike","timestamp","Type")
  
  
  qry<-build_sql('SELECT * FROM options_now.', ident(ticker),
            ' where timestamp = (select max(timestamp) from options_now.', ident(ticker), ')')
  
  
  currentQuotes <- tbl(rv$conn,qry) %>% as.data.frame() %>% filter(Expiry>=Sys.Date())
  
  options_chain <- options_instruments_in_chain(ticker,rv$robinhoodUser$account$user$authHeader)
  # last_stamp<-tbl(connection,qry)%>%arrange(desc(timestamp))%>%filter(timestamp = max(timestamp))%>%show_query()
  #   last_stamp<-tbl(connection,qry)%>%distinct(timestamp)%>%arrange(desc(timestamp))%>%head(1)%>%collect()%>%select(timestamp)
  #   last_stamp<-last_stamp$timestamp%>%as.POSIXct(tz="UTC")
  urls<-options_chain$urls
  options_chain<-cbind(options_chain$options_in_chain,urls)
  options_chain<-options_chain%>%filter(Expiry%in%currentQuotes$Expiry)%>%filter(Strike%in%currentQuotes$Strike)
  joined_chain<-semi_join(options_chain,currentQuotes)
  #to_remove<-anti_join(options_chain,currentQuotes)
  instrument<-joined_chain$urls
  currentQuotes<-cbind(currentQuotes,instrument)
  db_ops_rv$currentQuotes<-currentQuotes
  
  expiry_options<-sort(unique(currentQuotes$Expiry))
  selectizeInput("expiry_select","Contract Expiry Date",choices=expiry_options)
  
})



##############################################################################################################
#### OPTIONS TABLES ##########################################################################################
output$filtered_options_data_DT<-renderDT({
  req(is.null(rv$robinhoodUser)!=T)
  req(is.null(db_ops_rv$currentQuotes)!=T)
  req(input$db_option_ticker)
  req(input$expiry_select)
  req(input$contract_type)

  db_ops_rv$data<-db_ops_rv$currentQuotes%>%filter(Type==tolower(isolate(input$contract_type)))%>%filter(Expiry==isolate(input$expiry_select))
  columns_to_rm<-c("Ticker","Expiry","Type","previous_close_date","timestamp")
  rm_cols_idx<-which(colnames(db_ops_rv$data)%in%columns_to_rm)
  ops_prep<-db_ops_rv$data[,-rm_cols_idx]
  
  
  db_ops_rv$render_data<-ops_prep%>%
    mutate_all(funs(replace(., is.na(.), 0))) %>%
    arrange(.,desc(Strike)) %>%
    mutate_at(vars(Strike,adjusted_mark_price,ask_price,ask_size,bid_price, bid_size,
                   break_even_price,high_price,low_price,volume,last_trade_price, last_trade_size, 
                   mark_price,previous_close_price, chance_of_profit_short,chance_of_profit_long,
                   open_interest, implied_volatility,delta,gamma,theta,vega,rho), 
              funs(as.numeric(.,na.rm=T))) %>%
    mutate_at(vars(Strike,adjusted_mark_price,ask_price,bid_price,
                   break_even_price,high_price,last_trade_price,low_price,
                   mark_price,previous_close_price), 
              funs(round(., 3))) 

  ops_dat<-db_ops_rv$render_data%>%
    filter(volume!=0)
  last_price<-if(is.na(db_ops_rv$quote$last_extended_hours_trade_price)){
    as.numeric(db_ops_rv$quote$last_trade_price)
  } else {
    as.numeric(db_ops_rv$quote$last_extended_hours_trade_price)
  }
  ops_dat$bid_price<-paste0("$",ops_dat$bid_price," x ",ops_dat$bid_size)
  ops_dat$ask_price<-paste0("$",ops_dat$ask_price," x ",ops_dat$ask_size)
  ops_dat$break_even_price<-paste0("$",ops_dat$break_even_price,br()," (",percent((ops_dat$break_even_price-last_price)/last_price),")")
  ops_dat$mark_price<-paste0("$",ops_dat$mark_price,br()," (",percent((ops_dat$mark_price-ops_dat$previous_close_price)/ops_dat$previous_close_price),")")
  ops_dat$last_trade_price<-paste0("$",ops_dat$last_trade_price," x ",ops_dat$last_trade_size)
  ops_dat<-ops_dat[,-which(colnames(ops_dat)%in%c("bid_size","ask_size","previous_close_price","last_trade_siZe"))]
  ops_dat<-ops_dat%>%select(Strike,mark_price,adjusted_mark_price,
                            implied_volatility,delta,gamma,theta,vega,rho,
                            high_price,low_price,volume,open_interest,
                            break_even_price,chance_of_profit_short,chance_of_profit_long,
                            ask_price,bid_price,last_trade_price,instrument
                            )
    
  colnames(ops_dat) <- columns_to_keep
  
  
  
  db_ops_rv$DT_dat<-ops_dat
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

output$strategy_options_DT<-renderDT({
  req(!is.null(db_ops_rv$DT_dat))
  ops_dat<-db_ops_rv$DT_dat
  ops_dat<-ops_dat[,-which(colnames(ops_dat)=="instrument")]
  
  datatable(ops_dat,class="cell-border compact stripe", filter = 'top',rownames=FALSE, 
            extensions = c('Buttons'),fillContainer = T,escape=F,
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

output$shelf_options_DT<-renderDT({
  req(input$strategy_options_DT_rows_selected)
  ops_dat<-db_ops_rv$DT_dat[req(input$strategy_options_DT_rows_selected),]
  db_ops_rv$shelf_DT<-ops_dat
  columns_rm<-c("instrument","Price","High","Low",'Chance of Profit Long','Chance of Profit Short')
  ops_dat<-ops_dat[,-which(colnames(ops_dat)%in%columns_rm)]
  
  datatable(ops_dat,class="cell-border compact stripe", rownames=FALSE, 
            fillContainer = T,escape=F,
            options = list(
              scrollX=T,
              columnDefs = list(list(className = 'dt-left', targets = "_all")),
              dom = 'rtip',
              pageLength=-1
            )) %>% 
    formatCurrency(c('Strike', "Mark")) %>% 
    formatPercentage(c('Implied Vol'), 2)
})

observeEvent(input$add_to_shelf,{
  req(isolate(input$shelf_options_DT_rows_selected))
  new_positions<-db_ops_rv$shelf_DT[req(input$shelf_options_DT_rows_selected),]
  Type=rep(isolate(input$contract_type),length(new_positions$Strike))
  Side<-rep(isolate(input$shelf_trade_side),length(new_positions$Strike))
  new_positions<-cbind(Side,Type,new_positions)
  if(input$add_to_shelf==1){
    db_ops_rv$queud_positions<-new_positions    
  }
  else{db_ops_rv$queud_positions<-full_join(db_ops_rv$queud_positions,new_positions)}

})
output$queue_options_DT<-renderDT({
  req(!is.null(db_ops_rv$queud_positions))
  print(db_ops_rv$queud_positions)
  dat<-db_ops_rv$queud_positions%>%select(Strike,Mark,Bid,Ask,Volume)
  datatable(dat, class="cell-border compact stripe",
            escape = FALSE, rownames=FALSE, options = list(
              dom='t',columnDefs = list(list(className = 'dt-left', targets = "_all"))))
  
  
})

output$shelf_payoff<-renderPlotly({
  req(is.null(rv$robinhoodUser)!=T)
  req(!is.null(db_ops_rv$queud_positions))
  
  
  if(is.na(db_ops_rv$quote$last_extended_hours_trade_price)){S<-as.numeric(db_ops_rv$quote$last_trade_price)}
  else{S<-as.numeric(db_ops_rv$quote$last_extended_hours_trade_price)}
  
  
  option_row<-db_ops_rv$queud_positions

  K<-as.numeric(option_row$Strike)
  
  start_s<-K[1]*.75
  end_s<-K[1]*1.25
  s_axis<-seq(from = start_s, to = end_s, by=.1)
  
  premium<-as.numeric(option_row$Price)
  expiry<-isolate(input$expiry_select)
  y_vals<-NULL
    for(i in 1:length(s_axis)){
      K_vals<-NULL
      for (j in 1:length(K)){
        if(option_row$Type[j]=="Call"){
          if(option_row$Side[j]=="Buy"){
            K_vals[j]<-max(s_axis[i]-K[j],0)-premium[j]
          }
          else{
            K_vals[j]<-premium[j]-max(s_axis[i]-K[j],0)
          }
        
        }
        else{
          if(option_row$Side[j]=="Buy"){
            K_vals[j]<-max(K[j]-s_axis[i],0)-premium[j]
          }
          else{K_vals[j]<-premium[j]-max(K[j]-s_axis[i],0)}
        }
      }
      y_vals[i]<-sum(K_vals)
  }

  payoff = data.frame(S = s_axis, Payoff = y_vals)
  plot_ly(payoff, x = ~S, y = ~Payoff, type = "scatter", mode = "lines",line = list(color = 'rgba(68,149,68,1)', width = 2)) %>% 
    layout(title = "",
           yaxis = list(title = "P/L per Share", showgrid = FALSE),
           xaxis = list(title = "S", zeroline = FALSE,
                        showline = FALSE, showticklabels = FALSE,showgrid = FALSE),
           font = list(family = 'Arial', size = 14,
                       color = 'rgba(245,246,249,1)'),
           plot_bgcolor='transparent',paper_bgcolor='transparent'
    )
  
  
})

output$shelf_ui<-renderUI({
req(input$strategy_options_DT_rows_selected)
  fluidRow(column(12,align="center",
                div(box(title=NULL,width = "100%", height="100%",collapsible=T,
                        fluidRow(column(3,""),
                                 column(6,align="center",
                                        prettyRadioButtons(
                                          inputId="shelf_trade_side",label=NULL,
                                          choices=c("Buy","Sell"),
                                          selected="Buy",
                                          status="primary",shape="round",outline=FALSE,fill=TRUE,thick=TRUE,animation=NULL,
                                          icon=tags$i(class="fa fa-circle",style="color:steelblue;"),plain=FALSE,bigger=TRUE,inline=TRUE,
                                          width="100%")
                                 
                                 )
                                 # column(3,align="center",
                                 #        radioGroupButtons(
                                 #          inputId = "shelf_chartType",
                                 #          label = NULL, 
                                 #          choices = c(`<i class='fa fa-line-chart'></i>` = "line", 
                                 #                      `<i class='fa fa-bar-chart'></i>` = "candlestick"),
                                 #          justified = TRUE, status="primary"
                                 #        )
                                 # )
                        ),
                        fluidRow(column(6,align="center",div(DTOutput("queue_options_DT"),style="color:black;")),
                                 column(6,align="center",plotlyOutput("shelf_payoff")
                                        )),
                        uiOutput("shelf_options_plot_ui"),
                        DTOutput("shelf_options_DT")
                        #fluidRow(column(12,plotOutput("stock_chartSeries")))
                        ))))  

})



output$options_box<-renderUI({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$db_option_ticker)
  
  
  if(is.na(db_ops_rv$quote$last_extended_hours_trade_price)){last_price<-as.numeric(db_ops_rv$quote$last_trade_price)}
  else{last_price<-as.numeric(db_ops_rv$quote$last_extended_hours_trade_price)}
  
  last_close<-as.numeric(db_ops_rv$quote$adjusted_previous_close)
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
  noVol_data<-db_ops_rv$render_data%>%
    filter(volume==0)
  last_price<-if(is.na(db_ops_rv$quote$last_extended_hours_trade_price)){
    as.numeric(db_ops_rv$quote$last_trade_price)
  } else {
    as.numeric(db_ops_rv$quote$last_extended_hours_trade_price)
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
                  plotlyOutput("options_payoff"),
                  plotOutput("options_chartSeries")
  ))
  
})


output$options_payoff<-renderPlotly({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$db_option_ticker)
  req(input$expiry_select)
  req(input$contract_type)
  req(input$filtered_options_data_DT_rows_selected)
  
  
  if(is.na(db_ops_rv$quote$last_extended_hours_trade_price)){S<-as.numeric(db_ops_rv$quote$last_trade_price)}
  else{S<-as.numeric(db_ops_rv$quote$last_extended_hours_trade_price)}
 
  
  option_row<-db_ops_rv$DT_dat[req(input$filtered_options_data_DT_rows_selected),]
  print(option_row)

  K<-option_row$Strike
  start_s<-K*.75
  end_s<-K*1.25
  s_axis<-seq(from = start_s, to = end_s, by=.1)

  premium<-as.numeric(option_row$Price)
  expiry<-isolate(input$expiry_select)
  y_vals<-NULL
  if(tolower(isolate(input$contract_type))=="call"){
    for(i in 1:length(s_axis)){
      y_vals[i]<-max(s_axis[i]-K,0)-premium
    }
  }
  else{
    for(i in 1:length(s_axis)){
      y_vals[i]<-max(K-s_axis[i],0)-premium
    }
    
  }
  payoff = data.frame(S = s_axis, Payoff = y_vals)
  plot_ly(payoff, x = ~S, y = ~Payoff, type = "scatter", mode = "lines",line = list(color = 'rgba(68,149,68,1)', width = 2)) %>% 
  layout(title = "",
         yaxis = list(title = "P/L per Share", showgrid = FALSE),
         xaxis = list(title = "S", zeroline = FALSE,
                      showline = FALSE, showticklabels = FALSE,showgrid = FALSE),
         font = list(family = 'Arial', size = 14,
                     color = 'rgba(245,246,249,1)'),
         plot_bgcolor='transparent',paper_bgcolor='transparent'
  )

  
})

output$options_chartSeries<-renderPlot({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$db_option_ticker)
  req(input$expiry_select)
  req(input$contract_type)
  req(input$hist_span)
  req(input$filtered_options_data_DT_rows_selected)
  
  
  ohlcv<-historical_options_quotes(db_ops_rv$DT_dat$instrument[req(input$filtered_options_data_DT_rows_selected)],
                                   span=as.character(input$hist_span),
                                   header=rv$robinhoodUser$account$user$authHeader)
  chartSeries(ohlcv[[1]],
              name = isolate(input$db_option_ticker), type = req(input$chartType))
})


output$vol_surface_plotly<-renderPlotly({
  req(is.null(rv$robinhoodUser)!=T)
  req(input$db_option_ticker)
  req(is.null(db_ops_rv$currentQuotes)!=T)
  
  currentStockP <- as.numeric(rv$robinhoodUser$quotes$get_quotes(isolate(input$db_option_ticker))$last_trade_price)
  
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