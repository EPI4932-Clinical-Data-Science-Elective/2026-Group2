#my handy functions

boolPackagesPresent <- function(lop){
  #boolean list of which function in a given list "lop" that is already installed
  #returns a boolen iterand of which functions in "lop" are already present
  packages.present <- (lop %in% installed.packages()[,"Package"]) 
  return(packages.present)
}


installRequiredPackages <- function(lop){
  new.packages <- lop[!boolPackagesPresent(lop)] #note negation - new packages are what is NOT installed yet
  if(length(new.packages))
    install.packages(new.packages) #shortcut to run through and install the list without making explicit loop
  sapply(lop, require, character.only = TRUE) #simple "apply" is the really smart R way to loop over
  return(lop[boolPackagesPresent(lop)])
  #returns elements of "lop" that are now successfully installed
}


getDataUsingOpenApiMethod <- function(endpt, filt, struct){
  # The "httr::GET" method automatically encodes the URL and its parameters:
  httr::GET(
    url = endpt,
    # Convert the structure to JSON (ensure that "auto_unbox" is set to TRUE).
    query = list(
      filters = paste(filt, collapse = ";"), # Concatenate the filters vector using a semicolon.
      structure = jsonlite::toJSON(struct, auto_unbox = TRUE)
    ),
    # The API server will automatically reject any requests that take longer than 10 seconds to process.
    timeout(10)
  ) -> response
  
  # Handle errors messages is always a good idea if the endpoint is down or whatever:
  if (response$status_code >= 400) {
    err_msg = httr::http_status(response)
    stop(err_msg)
  }
  
  # Convert response from binary to JSON:
  json_text <- content(response, "text")
  data = jsonlite::fromJSON(json_text)
  
  # Print the encoded URL for inspection and documentation, just in case:
  print(response$url)
  
  #returns a dataframe object out of this function
  return(data$data)
}
