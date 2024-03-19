filtering <- function(data_raw){
  # check if NA values in filtered columns
  
  tmp <- data_raw %>% 
    select(Potential.contaminant,Reverse,Only.identified.by.site) %>%
    select_if(function(x) any(is.na(x))) %>% 
    summarise_each(funs(sum(is.na(.))))
  if (ncol(tmp) > 0){
    print("!NA values detected!")
    print(tmp)}
  
  # filter data
  
  data_raw %>% filter( 
    is.na(Potential.contaminant)|Potential.contaminant != "+",
    is.na(Reverse)|Reverse != "+",
    is.na(Only.identified.by.site)|Only.identified.by.site != "+")
}

