library(RCurl)
library(ggplot2)
library(rio)
library(assertthat)
library(dplyr)
##function evaluation qSOFA on input.

## This absolutely gets the job done. If you're interested in
## writing it in a more R-ish way then this is a suggestion:
qSOFAcalc <- function(raw, tot = TRUE, sbp_cut = 100, rr_cut = 22) {
    ## Check arguments
    assert_that(is.data.frame(raw))
    assert_that(ncol(raw) == 3)
    assert_that(is.logical(tot))
    assert_that(is.numeric(sbp_cut))
    assert_that(is.numeric(rr_cut))

    ## Calculate score
    sc_sbp <- select(raw, starts_with("sbp_")) <= sbp_cut
    sc_rr <- select(raw, starts_with("rr_")) >= rr_cut
    sc_gcs <- select(raw, starts_with("gcs_")) < 15
    score <- data.frame(sbp_score = sc_sbp, rr_score = sc_rr, gcs_score = sc_gcs) %>%
        mutate(across(.fns = as.integer))
    if (tot)
        score <- data.frame(score, qSOFA_score = sc_sbp + sc_rr + sc_gcs)
    score
}
## Note that R likes vectorized code and almost any operation that can
## be run on single elements can also be run on vectors. 

qSOFAcalc <- function(raw, tot=TRUE, sbp_cut=100, rr_cut=22) {
  # raw, dataframe, is the input of sbp, rr and gcs in that order
  # tot,boolean, is if a summation should be done and returned
  # _cut,integer, is if you'd want to change the cutoff points


  
  #Only accepts input of length 3
  if(length(raw)==3){
    #create empty dataframe
    
    if(tot==TRUE){
      score <- data.frame(integer(),integer(),integer(),integer()) # empty dataframe length 4
    }
    else{
      score <- data.frame(integer(),integer(),integer()) # empty dataframe length 3
    }
    
    #for every element in input calculate the sofa score
    for(i in 1:dim(raw)[1]){
      
      sbp <- raw[i,1]
      rr  <- raw[i,2]
      gcs <- raw[i,3]
      
      sc_sbp <- as.integer(sbp<=sbp_cut) 
      sc_rr <- as.integer(rr>=rr_cut)
      sc_gcs <- as.integer(gcs<15)
      
      if(tot==TRUE){
        sc_tot <- sum(na.omit(c(sc_sbp,sc_rr,sc_gcs))) # sum of the qSOFA score omiting NA 
        score <- rbind(score,data.frame(sc_sbp,sc_rr,sc_gcs,sc_tot))
      }
      else{
        score <- rbind(score,data.frame(sc_sbp,sc_rr,sc_gcs))
      }
      
      
    }
    
    if(tot==TRUE){
      names(score)=c("sbp_score","rr_score","gcs_score","qSOFA_score")
    }
    else{
      names(score)=c("sbp_score","rr_score","gcs_score")
    }
    
    score
  }
  #if not three by x return error
  else{
    stop("Wrong dimensions on input")
  }
  
}



#Data extraction#####


url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-limited-dataset-v1.csv"
tot_data <- rio::import(url)
#some of the data I though could be interesting
part_data = subset(tot_data, select = c(age, sex, tran, moi, sbp_1, rr_1, gcs_t_1, sbp_2, rr_2, gcs_t_2, licu, iss, died))
time_data = subset(tot_data, select = c(doar, doa, dodd, dom_1, dom_2, toar, toa, todd, tom_1, tom_2))
## found two messurments, if incomplete, should we combined them?
## We can use either but not mix. So if the second measurements are more complete then we can use those.
qSOFA_1raw= tot_data[,c("sbp_1","rr_1","gcs_t_1")]
qSOFA_2raw= tot_data[,c("sbp_2","rr_2","gcs_t_2")]

## not sure if we need all this data about the time or that this is the best way but i got carried away...

## Probably not...
days <- sapply(time_data[,c(1:5)], as.Date)
days <- date - date[,"doar"]
time <- time_data[,c(6:10)] 
icu_hours <- data.frame(tot_data[,"licu"]); names(icu_hours) <- paste("icu_hours")
icu_days <- icu_hour/24 ; names(icu_days) <- paste("icu_days")
icu_bin <- data.frame(as.integer(icu_days>0)); names(icu_bin) <- paste("icu_bin") # binary value of ICU admission

qSOFA_1 <- qSOFAcalc(qSOFA_1raw)
qSOFA_2 <- qSOFAcalc(qSOFA_2raw)
