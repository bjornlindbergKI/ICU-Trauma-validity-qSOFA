library(RCurl)
library(ggplot2)
library(rio)
library(assertthat)
library(dplyr)
library(rmarkdown)
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

#Data extraction
url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-limited-dataset-v1.csv"
tot_data <- rio::import(url)
#some of the data I though could be interesting
part_data <- subset(tot_data, select = c(age, sex, tran, moi, sbp_1, rr_1, gcs_t_1, sbp_2, rr_2, gcs_t_2, licu, iss, died))
time_data <- subset(tot_data, select = c(doar, doa, dodd, dom_1, dom_2, toar, toa, todd, tom_1, tom_2))
## found two messurments, if incomplete, should we combined them?
## We can use either but not mix. So if the second measurements are more complete then we can use those.
qSOFA_1raw <- tot_data[,c("sbp_1","rr_1","gcs_t_1")]
qSOFA_2raw <- tot_data[,c("sbp_2","rr_2","gcs_t_2")]

## not sure if we need all this data about the time or that this is the best way but i got carried away...

## Probably not...
days <- sapply(time_data[,c(1:5)], as.Date)
days <- days - days[,"doar"]
time <- time_data[,c(6:10)] 
icu_hours <- data.frame(tot_data[,"licu"])
names(icu_hours) <- paste("icu_hours")
icu_days <- icu_hours/24
names(icu_days) <- paste("icu_days")
icu_bin <- data.frame(as.integer(icu_days>0))
names(icu_bin) <- paste("icu_bin") # binary value of ICU admission

qSOFA_1 <- qSOFAcalc(qSOFA_1raw)
qSOFA_2 <- qSOFAcalc(qSOFA_2raw)

## Either create "global" objects that can be accessed directly from
## your R mardkown file or store everything you want to include there
## in a vector, list or other object

results <- list()
results$n.cohort <- nrow(tot_data)

## Exclude those younger than 18
younger.than.18 <- part_data$age < 18
results$n.younger.than.18 <- sum(younger.than.18)
study.sample <- part_data[!younger.than.18, ]
results$n.adults <- nrow(study.sample)

## Compile paper
render("study-plan.Rmd")
