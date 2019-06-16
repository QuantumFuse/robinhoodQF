##############################################################################################################
#### PORTFOLIO HOLDINGS ######################################################################################

output$equity_holdings_DT<-renderDT({
  req(is.null(rv$robinhoodUser)!=T)
  if(length(rv$robinhoodUser$account$positionsTable)>0){
    portfolio_rv$equity_positions<-rv$robinhoodUser$account$positionsTable %>%
      filter(quantity!=0) %>%
      rename(Name=name,Shares=quantity,"Average Cost"=average_price)
    
    datatable(portfolio_rv$equity_positions,class="cell-border compact stripe", rownames=FALSE, extensions = c('Buttons'),fillContainer = T,escape=F,
              options = list(
                scrollX=T,
                columnDefs = list(list(className = 'dt-left', targets = "_all")),
                dom = 'Bltipr',
                buttons = list('print',list(extend='collection',buttons=c('csv','excel'),text='Download')),
                # customize the length menu
                lengthMenu = list( c(-1,10,25,100), # declare values
                                   c("All",10,25,100) # declare titles
                ), # end lengthMenu
                pageLength=-1
              ))  %>% 
      formatCurrency(c('Average Cost'))
  }
})  

output$options_holdings_DT<-renderDT({
  req(is.null(rv$robinhoodUser)!=T)
  if(length(rv$robinhoodUser$account$optionsPositionsTable)>0){
    
    portfolio_rv$options_positions<-rv$robinhoodUser$account$optionsPositionsTable %>%
      filter(quantity!=0) %>%
      rename(Ticker=ticker,Contracts=quantity,Type=type,Price=price)
    
    datatable(portfolio_rv$options_positions,class="cell-border compact stripe", rownames=FALSE, extensions = c('Buttons'),fillContainer = T,escape=F,
              options = list(
                scrollX=T,
                columnDefs = list(list(className = 'dt-left', targets = "_all")),
                dom = 'Bltipr',
                buttons = list('print',list(extend='collection',buttons=c('csv','excel'),text='Download')),
                # customize the length menu
                lengthMenu = list( c(-1,10,25,100), # declare values
                                   c("All",10,25,100) # declare titles
                ), # end lengthMenu
                pageLength=-1
              ))  %>% 
      formatCurrency(c('Price'))
  }
})  

output$portfolio_positions_box<-renderUI({
  req(!is.null(rv$robinhoodUser))
  # if(is.null(portfolio_rv$options_positions)){
  #   box(title="Current Holdings", collapsible=T,width="100%",height="100%",
  #       fluidRow(
  #         column(12,align="center",DTOutput("equity_holdings_DT"))
  #       )
  #   )
  #   
  # }
  # else{
    box(title="Current Holdings", collapsible=T,width="100%",height="100%",
        fluidRow(
          column(8,align="center",DTOutput("equity_holdings_DT")),
          column(4,align="center",DTOutput("options_holdings_DT"))
        )
    )
    
  # }
  
})

# observeEvent(input$get_order_history,{
  # confirmSweetAlert(
  #   session = session, inputId = "confirm_order_history", type = "warning",
  #   title = "Want to confirm ?", text="Downloading your full transaction history may take between 1 - 5 minutes depending on the total trades you have placed.",
  #   danger_mode = TRUE
  # )


##AFTER USER HITS CONFIRM OR CANCEL INSTANTIATE ORDER CLASS
# observeEvent(input$confirm_order_history, {
#   if (isTRUE(input$confirm_order_history)){
#    toggle(id = "get_order_history", anim = TRUE, time = 1, animType = "slide")

observeEvent(input$auth_db,{
  
    if(!is.null(rv$conn)){
      full_order_history<-dbReadTable(rv$conn,DBI::Id(table="stock_orders",schema="orders"))
      individual_pnl<-dbReadTable(rv$conn,DBI::Id(table="stock_pnl",schema="orders"))
      options_orders<-dbReadTable(rv$conn,DBI::Id(table="options_orders",schema="orders"))
      options_pnl<-dbReadTable(rv$conn,DBI::Id(table="options_pnl",schema="orders"))
      daystats<-dbReadTable(rv$conn,DBI::Id(schema="orders",table="stats"))
    # Order<-Orders$new(robinhoodUser$account)
    # 
    # portfolio_rv$orders<-Order$orders
    # individual_pnl<-portfolio_rv$orders$Individual_PL
    # current_positions<-portfolio_rv$orders$Current_Positions
    # allocation<-portfolio_rv$orders$Allocation
    # grouped_order_history<-portfolio_rv$orders$Grouped_History
    # full_order_history<-portfolio_rv$orders$Transactions
    # options_history<-Order$options_orders
    
    #############################################
    ### Portfolio Performance Summary ###########
    #############################################
    summary_PL<-individual_pnl
    profits<-summary_PL[,4]
    profits<-as.numeric(profits)
    
    profits<-currency( profits,"$",format="f",digits=2)
    tickers<-summary_PL$Ticker
    tickers<-as.character(tickers)
    colors<-NULL
    for (i in 1:length(tickers)){
      if(profits[i]<0){
        colors[i]<-'rgba(209,25,25,0.8)'
      }
      else{
        colors[i]<-'rgba(68,149,68,1)'
      }
    }
    
    x <- c(tickers)
    y <- c(profits)
    data <- data.frame(x, y)
    data$x <- factor(data$x, levels = data[["x"]])
    
    portfolio_rv$equity_performance<-plot_ly(data, x = ~y, y = ~reorder(x,y), type = 'bar', orientation = 'h', height = 2000,
                                             text = ~as.character(y), textposition = 'auto',
                                             marker = list(color = '#286090',
                                                           line = list(color = c(colors), width = 2)),
                                             source = "summary_PL",showlegend=FALSE) %>%
      config(displayModeBar = F) %>% 
      layout(title = paste0("Portfolio Performance as of ",as.character(Sys.Date())),
             margin = list(t=120),
             yaxis = list(title = ""),
             xaxis = list(title = "Gains/Losses ($)", showgrid = FALSE),
             font = list(family = 'Arial', size = 14,
                         color = 'rgba(245,246,249,1)'),
             barmode = 'relative',bargap = 0.3, 
             plot_bgcolor='transparent',paper_bgcolor='transparent'
      )
      
    #############################################
    ### Options Performance Summary #############
    #############################################
    
    # portfolio_rv$options_orders<-rh_getOptionsOrders(rv$robinhoodUser$account$user$authHeader)
    # options_pnl<-portfolio_rv$options_orders$individual_pnl
    options_profits<-options_pnl$Value
    print(options_profits)
    options_profits<-currency(options_profits,"$",format="f",digits=2)
    options_tickers<-options_pnl$Ticker

    colors<-NULL
    for (i in 1:length(options_tickers)){
      if(options_profits[i]<0){
        colors[i]<-'rgba(209,25,25,0.8)'
      }
      else{
        colors[i]<-'rgba(68,149,68,1)'
      }
    }
    x <- c(options_tickers)
    y <- c(options_profits)
    data <- data.frame(x, y)
    data$x <- factor(data$x, levels = data[["x"]])
    
    portfolio_rv$options_performance<-plot_ly(data, x = ~y, y = ~reorder(x,y), type = 'bar', orientation = 'h', height = 800,
                                              text = ~as.character(y), textposition = 'auto',
                                              marker = list(color = '#000000',
                                                            line = list(color = c(colors), width = 2)),
                                              source = "summary_PL",showlegend=FALSE) %>%
      config(displayModeBar = F) %>% 
      layout(title = paste0("Options Performance as of ",as.character(Sys.Date())),
             margin = list(t=120),
             yaxis = list(title = ""),
             xaxis = list(title = "Gains/Losses ($)", showgrid = FALSE),
             font = list(family = 'Arial', size = 14,
                         color = 'rgba(245,246,249,1)'),
             barmode = 'relative',bargap = 0.3, 
             plot_bgcolor='transparent',paper_bgcolor='transparent'
      ) 
      
      

    ################## Aggregate stacked relative bars
    x <- c(tickers,options_tickers)
    x <- unique(x)
    
    y <-vector(mode="numeric",length=length(x))
    profit_length<-c(1:length(x))
    no_idx<-which(x%in%tickers==FALSE)
    equity_idx<-which(profit_length%in%no_idx==FALSE)
    y[equity_idx]<-profits
    y[no_idx]<-0
    y<-currency(y,"$",format="f",digits=2)
    
    y2 <-vector(mode="numeric",length=length(x))
    ops_profit_length<-c(1:length(x))
    no_ops_idx<-which(x%in%options_tickers==FALSE)
    ops_idx<-which(ops_profit_length%in%no_ops_idx==FALSE)
    
    y2[ops_idx]<-options_profits
    y2[no_ops_idx]<-0
    y2<-currency(y2,"$",format="f",digits=2)
    
    group_data<-data.frame(x,y,y2)
    
    equity_colors<-NULL
    for (i in 1:length(y)){
      if(y[i]<0){
        equity_colors[i]<-'rgba(209,25,25,0.8)'
      }
      else{
        equity_colors[i]<-'rgba(68,149,68,1)'
      }
    }
    options_colors<-NULL
    for (i in 1:length(y2)){
      if(y2[i]<0){
        options_colors[i]<-'rgba(209,25,25,0.8)'
      }
      else{
        options_colors[i]<-'rgba(68,149,68,1)'
      }
    }
    
    colnames(group_data)<-c("Ticker","Equities","Options")
    group_data$Total<-group_data$Equities+group_data$Options
    portfolio_rv$aggregate_performance <- group_data %>% 
      plot_ly(height=2000) %>%
      add_trace(x = ~Equities, y = ~reorder(Ticker,Total), type = 'bar',orientation = 'h', name="Equities",
                text = ~as.character(Equities), textposition = 'auto',
                marker = list(color = '#286090',
                              line = list(color = c(equity_colors), width = 2))) %>%
      add_trace(x = ~Options, y = ~reorder(Ticker,Total), type = 'bar', orientation = 'h', name = "Options",
                text = ~as.character(Options), textposition = 'auto',
                marker = list(color = '#000000',
                              line = list(color = c(options_colors), width = 2))) %>%
      layout(title = paste0("Equities & Options Performance as of ",as.character(Sys.Date())),
             margin = list(t=120),
             yaxis = list(title = ""),
             xaxis = list(title = "Gains/Losses ($)", showgrid = FALSE),
             font = list(family = 'Arial', size = 14,
                         color = 'rgba(245,246,249,1)'),
             barmode = 'relative',bargap = 0.3, 
             legend = list(x = 1, y = 1, orientation = 'h',
                           font = list(
                             family = "sans-serif",
                             size = 14,
                             color = 'rgba(245,246,249,1)'),
                           bgcolor = 'transparent', bordercolor = 'rgba(255, 255, 255, 0)'),
             plot_bgcolor='transparent',paper_bgcolor='transparent'
      ) 
    
    x_pnl<-daystats$timestamp
    y_pnl<-daystats$Equity
    pnl<-data.frame(Time=x_pnl,Equity=y_pnl)
    if(pnl$Equity[1]>pnl$Equity[length(pnl$Equity)]){
      pnl_color<-'rgba(209,25,25,0.8)'
    }
    else{
      pnl_color<-'rgba(68,149,68,1)'
    }
    portfolio_rv$daily_stats<-plot_ly(pnl, x = ~x_pnl, y = ~y_pnl,type = 'scatter', mode='lines',
                                      line = list(color = pnl_color, width = 2)) %>% 
                              layout(title = paste0("Daily Equities & Options Performance (",as.Date(pnl$Time[1])," - ",as.character(Sys.Date()),")"),
                                     margin = list(t=120),
                                     yaxis = list(title = "", showgrid = FALSE),
                                     xaxis = list(title = "", type = "category", zeroline = FALSE,
                                                  showline = FALSE, showticklabels = FALSE,showgrid = FALSE),
                                     font = list(family = 'Arial', size = 14,
                                                 color = 'rgba(245,246,249,1)'),
                                     plot_bgcolor='transparent',paper_bgcolor='transparent'
                              )
    

    
}
},priority=-1)

output$daily_performance_plotly<-renderPlotly({
  req(is.null(portfolio_rv$daily_stats)!=T)
  portfolio_rv$daily_stats
})


output$equity_performance_plotly<-renderPlotly({
  req(is.null(portfolio_rv$equity_performance)!=T)
  portfolio_rv$equity_performance
})

output$options_performance_plotly<-renderPlotly({
  req(is.null(portfolio_rv$options_performance)!=T)
  portfolio_rv$options_performance
})

output$subplot_performance_plotly<-renderPlotly({
  req(is.null(portfolio_rv$equity_performance)!=T)
  req(is.null(portfolio_rv$options_performance)!=T)
  subplot(portfolio_rv$equity_performance,portfolio_rv$options_performance)
})

output$aggregate_performance_plotly<-renderPlotly({
  ######################## GROUPED BAR CHART
  req(is.null(portfolio_rv$equity_performance)!=T)
  req(is.null(portfolio_rv$options_performance)!=T)
  portfolio_rv$aggregate_performance
  
})

output$portfolio_performance_ui<-renderUI({
  req(!is.null(rv$conn))
  box(collapsible=TRUE,title="Historical Performance",width="100%",height="100%",
      radioGroupButtons(inputId = "performance_view",label = "",
                        choices = c("Equities","Options","Aggregate","Side-by-side"), selected = "Equities",
                        justified = T,status="primary",width="100%"),
      uiOutput("performance_plotlys")
  )
      
})

output$performance_plotlys<-renderUI({
  req(input$performance_view)
  if(input$performance_view=="Equities"){
    plotlyOutput("equity_performance_plotly")
  }
  else if(input$performance_view=="Options"){
    plotlyOutput("options_performance_plotly")
  }
  else if (input$performance_view=="Aggregate"){
    plotlyOutput("aggregate_performance_plotly")
  }
  else{
    plotlyOutput("subplot_performance_plotly")
  }

})
