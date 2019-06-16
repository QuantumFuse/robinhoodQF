


UserAuth <- R6::R6Class(
  
  classname = "UserAuth",
  portable = TRUE,
  
  public = list(
    
    header = NULL,
    client = NULL,
    
    initialize = function() {
      
      username_ <- rstudioapi::showPrompt(title = "Username", message = "Username", default = "")
      password_ <- rstudioapi::askForPassword(prompt = 'Password: ')
      private$user_login(username = username_, password = password_)
      
    }
    
  ),
  
  private = list(
    
    user_authenticate = function(username, password) {
      
      endpoint <- "https://api.robinhood.com/oauth2/token/"
      client <- list(api_grant_type = "password", api_client_id = "c82SH0WZOsabOXGP2sxqcj34FxkvfnWRZBKlBjFS")
      
      
      detail <- paste("?grant_type=", client$api_grant_type, "&client_id=", client$api_client_id,
                      "&username=", username, "&password=", password, sep = "")
      
      
      auth <- jsonlite::fromJSON(
        rawToChar(
          httr::content(httr::POST(paste(endpoint, detail, sep = "")), type = "json")
        )
      )
      
      if (is.null(auth$access_token)) {
        cat("\nAuthentication Failed. Please check username and password.\n\n")
        return(NULL)
      }
      
      return(list(auth = auth, client = client))
      
    },
    
    
    user_login = function(username, password) {
      
      auth <- private$user_authenticate(username = username, password = password)
      
      client <- auth$client
      auth <- auth$auth
      
      if(is.null(auth)) {
        return(NULL)
      }
      
      self$header <- c(Authorization = paste(auth$token_type, auth$access_token))
      client <- c(client, tokens = list(access_token = auth$access_token, refresh_token = auth$refresh_token))
      accounts <- suppressWarnings(RobinHood::api_accounts(client)) ## need to make our own api_accounts function
      
      client <- c(client, url = list(positions = accounts$positions, accountID = accounts$url))
      names(client) <- c("grantType", "ID", "accessToken", "refreshToken", "positions.url", "accountID.url")
      self$client <- client
      cat("\n Authentication Complete \n \n")
      
    }
    
  )
  
)
