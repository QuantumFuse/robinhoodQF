library(shiny)
library(httr)
library(jsonlite)
library(R6)
library(plyr)
library(tidyverse)
library(dplyr)
library(DT)
library(shinycssloaders)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyjs)
library(shinyWidgets)
library(zoo)
library(plotly)
library(tidyr)
library(purrr)
library(rlang)
library(stringr)
library(RColorBrewer)
library(formattable)
library(quantmod)


source("Robinhood/functions.R")
source("Robinhood/PlotlyCharting.R")
source("Robinhood/OptionsData.R")
source("Robinhood/Requests.R")
source("Robinhood/RobinhoodOptions.R")


tickerOpts<-readRDS("globalvars/tickerOpts.rds")
tickerOpts_noname<-readRDS("globalvars/tickerOpts_no_name.rds")
ticker_choices<-tickerOpts_noname
names(ticker_choices)<-tickerOpts
options(scipen=999)
options(stringsAsFactors = FALSE)

columns_to_remove<-c("updated_at","previous_close_date")

columns_to_keep<-c("Strike","Mark","Price","Implied Vol",
                   "Delta","Gamma","Theta","Vega","Rho",
                   "High","Low","Previous Close",
                   "Volume","Open Interest",
                   "Break Even","Chance of Profit Short","Chance of Profit Long",
                   "instrument","Ask","Bid","Last Trade"
                   )

# c("Strike","Price",
#   "Ask","Ask Size",  "Bid", "Bid Size", 
#   "Break Even", "High", "Last Trade Price", "Last Trade Size", "Low",
#   "Mark","Open Interest","Previous Close","Volume",
#   "Chance of Profit Long","Chance of Profit Short","Delta","Gamma",
#   "Implied Vol","Rho","Theta","Vega")

loadingLogo <- function(loadingsrc, height = NULL, width = NULL, alt = NULL) {
  tagList(
    tags$head(
      tags$script(
        "setInterval(function(){
        if ($('html').attr('class')=='shiny-busy') {
        $('div.busy').show();
        $('div.notbusy').hide();
        } else {
        $('div.busy').hide();
        $('div.notbusy').show();
        }
},100)")
    ),
    
    div(class="overlay",
        div(column(4,""),
            column(4,align="center",class = "busy",style="display:table-cell; vertical-align:middle; text-align:center",
                   img(src=loadingsrc,height = height, width = width, alt = alt))),
        div(class = 'notbusy',""
        )
    )
  )
}
