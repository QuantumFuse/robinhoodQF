#' Login R6 Class
#'
#' Create an instance of the R6 Login Class. Get oauth2 login token, account number, and other login params. Passed to all API requests.
#' @param username_ Robinhood login username. NOT email.
#' @param password_ Robinhood login password. Can only contain letters and numbers in plaintext.
Login <- R6::R6Class(
  
  classname = "Login", 
  portable = TRUE,
  
  public = list(
    
    endpoints = NULL,
    authToken = NULL,
    authHeader = NULL,
    accountNumber = NULL,
    accountID = NULL,
    username = NULL,
    
    initialize = function(username, password){
      self$endpoints <- BaseEndpoints$new()
      clientId <- "c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS"
      creds <- list(username=username, password=password, client_id=clientId, mfa_code=NULL, grant_type="password")
      
      authResponse <- httr::POST(self$endpoints$auth, encode="json", body=creds)
      self$authToken <- httr::content(authResponse)$access_token
      self$authHeader <- c(Authorization = paste("Bearer ", self$authToken))
      
      private$request_account_number()
      private$request_account_id()
      
      self$endpoints$account <- paste0(self$endpoints$accounts_base,self$accountNumber,"/")
      self$endpoints$positions <- paste0(self$endpoints$account,"positions/")
      self$endpoints$portfolio <- paste0(self$endpoints$account,"portfolio/")
      
    }
  ),
  
  private = list(
    
    request_account_number = function() {
      response <- httr::GET(self$endpoints$accounts_base, httr::add_headers(.headers=self$authHeader))
      accountInfo <- httr::content(response)
      self$accountNumber <- accountInfo$results[[1]]$account_number
    },
    
    request_account_id = function() {
      response <- httr::GET(self$endpoints$user_id, httr::add_headers(.headers=self$authHeader))
      self$accountID <<- httr::content(response)$id
    }
    
  )
)