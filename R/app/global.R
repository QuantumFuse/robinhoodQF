setwd("C:/Dev/robinhoodQF/R/app")
source('C:/Dev/robinhoodQF/R/New Classes/AuthUser.R')
source('C:/Dev/robinhoodQF/R/New Classes/Account.R')
source('C:/Dev/robinhoodQF/R/New Classes/EquityData.R')
source('C:/Dev/robinhoodQF/R/New Classes/OptionsData.R')
source('C:/Dev/robinhoodQF/R/New Classes/PlotlyCharting.R')


suppressMessages(library(magrittr))           ### MIT
suppressMessages(library(future))
suppressMessages(library(promises))
suppressMessages(library(shiny))              ### GPL 3
suppressMessages(library(shinyWidgets))
suppressMessages(library(shinycssloaders))    ### GPL 3
suppressMessages(library(ygdashboard))        ### GPL 2
suppressMessages(library(plotly))
suppressMessages(library(DT))




client <- Account$new()
equityDataQuery <- EquityData$new(userAuthentication = client)

tickerOptions <- readRDS('C:/Dev/robinhoodQF/R/app/globalvars/tickerOpts.rds')
tickerOptionsNN <- readRDS('C:/Dev/robinhoodQF/R/app/globalvars/tickerOpts_no_name.rds') %>%
  sort(index.return = TRUE)

tickerOptions <- tickerOptions[tickerOptionsNN$ix]
tickerOptionsNN <- tickerOptionsNN$x

