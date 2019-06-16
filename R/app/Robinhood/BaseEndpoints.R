BaseEndpoints <- R6::R6Class(
  classname = "RobinhoodEndpoints",
  portable = FALSE, 
  public = list(
    
    origin = "https://api.robinhood.com/",
    
    accounts_base = "https://api.robinhood.com/accounts/",
    quotes_base = "https://api.robinhood.com/quotes/",
    fundamentals_base = "https://api.robinhood.com/fundamentals/",
    
    auth = "https://api.robinhood.com/oauth2/token/",
    user_id = "https://api.robinhood.com/user/id",
    options_positions = "https://api.robinhood.com/options/positions/",
    options_orders = "https://api.robinhood.com/options/orders/",
    orders = "https://api.robinhood.com/orders/",
    
    account = NULL,
    positions = NULL,
    portfolio = NULL
    
  )
)