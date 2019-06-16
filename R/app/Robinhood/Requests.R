Requests = R6::R6Class(

  classname = "Requests",
  portable = TRUE,

  public = list(

    response = NULL,

    initialize = function(url, parameters=NULL, headers=NULL) {

      self$response <- httr::GET(url=url,query=parameters,httr::add_headers(.headers=headers))

    },

    content = function(results=FALSE, nextURL=FALSE) {
      tempContent <- httr::content(self$response)
      if(results) return(tempContent$results)
      else if(nextURL) return(tempContent$'next')
      else return(tempContent)

    }

  )
)
