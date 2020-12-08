library(ggplot2)
library(rio)
library(assertthat)
library(dplyr)
library(rmarkdown)
library(tableone)
library(tinytex)
library(DiagrammeR)
library(DiagrammeRsvg)
## Might need to run sudo apt install libv8-dev libnode-dev
library(networkD3)
library(webshot)
library(knitr)
library(rsvg)
library("bengaltiger")
library(ROCR)
library(cutpointr)
library(boot)

## Source functions
source("R/qSOFAcalc.R")
source("R/create_figure1.R")
source("R/calculate_auc.R")
source("R/bootstrap.R")

set.seed(719)

# Data extraction
#url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-limited-dataset-v1.csv"
url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-full-dataset-v1.csv"
tot_data <- rio::import(url)

## Part data and as factor
part_data <- subset(tot_data, select = c(incl, age, sex, tran, moi, licu, died, sbp_1, rr_1, gcs_t_1))

## age as number,  > 89 was changed with 90 instead of NA
part_data$age[part_data$age == ">89"] <- 90
part_data$age <- as.numeric(part_data$age)

## sex, mode of injury etc as factor
part_data$sex <- as.factor(part_data$sex)
part_data$moi <- as.factor(part_data$moi)
part_data$died <- as.factor(part_data$died)
part_data$incl <- as.factor(part_data$incl)

## ICU as binary
part_data$licu[part_data$licu > 0] <- "Yes"
part_data$licu[part_data$licu == 0] <- "No"

## Define function that runs study
run_study <- function(original.data, rows, boot) {
    sample.data <- original.data[rows, ]
    
    ## Create lists to store results. Statistics that you only want to
    ## calculate on the original data should go into
    ## results. Statistics for which you want confidence intervals
    ## should go into boot.results
    results <- list()
    boot.results <- list()
    results$n.cohort <- nrow(tot_data)

    ## Exclude those younger than 18
    younger.than.18 <- sample.data$age < 18 
    results$n.younger.than.18 <- sum(younger.than.18)
    study.sample <- sample.data[!younger.than.18, ]
    results$n.adults <- nrow(study.sample)

    ## Exclude those who died before admission ie incl==2
    results$n.incl2 <- sum(study.sample$incl == 2)
    study.sample <- study.sample[!study.sample$incl == 2,]
    results$n.included <- nrow(study.sample)

    ## exclude NA's
    results$n.NA_TOT <- sum(is.na(study.sample$rr_1)|is.na(study.sample$sbp_1)|is.na(study.sample$gcs_t_1)|is.na(study.sample$licu))
    results$n.NA_ICU <- sum(is.na(study.sample$licu))
    results$n.NA_SBP <- sum(is.na(study.sample$sbp_1))
    results$n.NA_RR <- sum(is.na(study.sample$rr_1))
    results$n.NA_GCS <- sum(is.na(study.sample$gcs_t_1))

    ## delete all patients containing missing data in SBP, GCS or ICU
    study.sample.complete <- study.sample[!is.na(study.sample$rr_1)& !is.na(study.sample$sbp_1)& !is.na(study.sample$gcs_t_1)& !is.na(study.sample$licu),]
    results$n.complete <- nrow(study.sample.complete)
    boot.results$n.complete <- nrow(study.sample.complete)

    ## Table 1 ####
    data.table1 <- study.sample.complete
    data.table1$incl <- NULL

    ## change names
    names(data.table1) <- c("Age", "Sex", "Transported", "Mode of injury", "Admitted to the ICU", "Died after admission", "SBP", "RR", "GCS")

    ## combine road traffic injury to one category
    data.table1$`Mode of injury` <- as.character(data.table1$`Mode of injury`)
    RTI <- grepl('traffic', data.table1$`Mode of injury`)
    data.table1$`Mode of injury`[RTI] <- "Road traffic injury"
    results$data.table1 <- data.table1

    ## Figure 1 flowchart ####
    if (!boot) {
        ##    figure1 <- create_figure1(results)        
    }

    ## Split sample in sample.split #### 
    proportion <- c(0.6,0.20,0.20)
    split.names <- c("training.sample","validation.sample", "test.sample")
    sample.split <- SplitDataset(study.sample.complete, split.proportions = proportion,
                                 remove.missing = FALSE, sample.names = split.names,
                                 return.data.frame = FALSE)

    ## cutoff cutpointr Training sample ####

    training.sample <- sample.split$training.sample
    ## RR
    opt_cut.rr <- cutpointr(training.sample, rr_1, licu, direction = ">=",
                            method = maximize_metric, metric = youden, pos_class = "Yes")
    results$cut.rr <- opt_cut.rr$optimal_cutpoint
    boot.results$cut.rr <- results$cut.rr

    ## GCS 
    opt_cut.gcs <- cutpointr(training.sample, gcs_t_1, licu, direction = "<=",
                             method = maximize_metric, metric = youden,
                             pos_class = "Yes")
    results$cut.gcs <- opt_cut.gcs$optimal_cutpoint
    boot.results$cut.gcs <- results$cut.gcs

    ## SBP
    opt_cut.sbp <- cutpointr(training.sample, sbp_1, licu, direction = "<=",
                             method = maximize_metric, metric = youden,
                             pos_class = "Yes")
    results$cut.sbp <- opt_cut.sbp$optimal_cutpoint
    boot.results$cut.sbp <- results$cut.sbp


    ## Validation  ####
    validation.sample <- sample.split$validation.sample
    validation.qSOFA.original <- qSOFAcalc(raw = validation.sample,tot = TRUE)
    names(validation.qSOFA.original) <- c("org.sbp_score", "org.rr_score", "org.gcs_score", "org.qSOFA_score")

    validation.qSOFA.new <- qSOFAcalc(raw = validation.sample, rr_cut = results$cut.rr, sbp_cut = results$cut.sbp)
    names(validation.qSOFA.new) <- c("new.sbp_score", "new.rr_score", "new.gcs_score", "new.qSOFA_score")
    validation.sample <- data.frame(validation.sample, validation.qSOFA.original, validation.qSOFA.new)

    ## new logistic regression model ####
    fit <- glm(as.numeric(licu == "Yes") ~ new.sbp_score + new.rr_score + new.gcs_score, family = binomial, data = validation.sample)
    coeff <- fit$coefficients
    boot.results$updated.coefs <- coeff
    boot.results$updated.ors <- exp(coeff)
    
    
    ## estimating probabilities of the sum of qSOFA new
    
    val.new.prob.calc <- predict(fit, newdata = validation.sample, type = "response")
    val.est.prob.sum.new <- list()
    val.est.prob.sum.new$none <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==0 ])
    val.est.prob.sum.new$one <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==1 ])
    val.est.prob.sum.new$two <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==2 ])
    ## since there can be cases where there are no datapoints with sum 3 and it can only go one way:
    ## the probability is calculated using the general formula instead of predict().
    ## but yields the same result as predict if there where one with sum 3.
    beta <- coeff[1] + coeff[2]*1 + coeff[3]*1 + coeff[4]*1
    val.est.prob.sum.new$three <-  as.numeric(exp(beta)/(1+exp(beta)))

    ## OR
    boot.results$est.OR.sum.new.one <- (val.est.prob.sum.new$one/(1-val.est.prob.sum.new$one))/(val.est.prob.sum.new$none/(1-val.est.prob.sum.new$none))
    boot.results$est.OR.sum.new.two  <- (val.est.prob.sum.new$two/(1-val.est.prob.sum.new$two))/(val.est.prob.sum.new$none/(1-val.est.prob.sum.new$none))
    boot.results$est.OR.sum.new.three <- (val.est.prob.sum.new$three/(1-val.est.prob.sum.new$three))/(val.est.prob.sum.new$none/(1-val.est.prob.sum.new$none))
    
    
    ## estamating probabilities of the sum of qSOFA old

    ## eFigure 3 gives 1 % ie log(odds) ~ -4.6
    
    ## i just saw a figure and couldn't extract an exact value, how should i do?
    coeff <- c(-4.6, log(2.61), log(3.18), log(4.31))
    beta <- coeff[1] + coeff[2]*validation.sample$org.sbp_score + coeff[3]*validation.sample$org.rr_score + coeff[4]*validation.sample$org.gcs_score
    val.org.prob.calc <- exp(beta)/(1+exp(beta))

    val.est.prob.sum.org <- list()
    val.est.prob.sum.org$none <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==0 ])
    val.est.prob.sum.org$one <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==1 ])
    val.est.prob.sum.org$two <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==2 ])
    ## since there were no cases with sum 3 and it can only go one way:
    beta <- coeff[1] + coeff[2]*1 + coeff[3]*1 + coeff[4]*1
    val.est.prob.sum.org$three <-  as.numeric(exp(beta)/(1+exp(beta)))
    
    ## OR
    boot.results$est.OR.sum.org.one <- (val.est.prob.sum.org$one/(1-val.est.prob.sum.org$one))/(val.est.prob.sum.org$none/(1-val.est.prob.sum.org$none))
    boot.results$est.OR.sum.org.two  <- (val.est.prob.sum.org$two/(1-val.est.prob.sum.org$two))/(val.est.prob.sum.org$none/(1-val.est.prob.sum.org$none))
    boot.results$est.OR.sum.org.three <- (val.est.prob.sum.org$three/(1-val.est.prob.sum.org$three))/(val.est.prob.sum.org$none/(1-val.est.prob.sum.org$none))
    

    ## test sample and performance #### 

    test.sample <- sample.split$test.sample

    test.qSOFA.original <- qSOFAcalc(raw = test.sample,tot = TRUE)
    names(test.qSOFA.original) <- c("org.sbp_score", "org.rr_score", "org.gcs_score", "org.qSOFA_score")

    test.qSOFA.new <- qSOFAcalc(raw = test.sample,rr_cut = results$cut.rr, sbp_cut = results$cut.sbp)
    names(test.qSOFA.new) <- c("new.sbp_score", "new.rr_score", "new.gcs_score", "new.qSOFA_score")


    test.sample <- data.frame(test.sample,test.qSOFA.original,test.qSOFA.new )
   
    ## estamating new probabilties 
    new.prob.calc <- predict(fit, newdata = test.sample, type = "response")

    ## finding the real observed probabilities for different groups
    real.prob.new <- list()
    real.prob.new$none <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0] =="Yes"))
    real.prob.new$rr <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0] =="Yes"))
    real.prob.new$sbp <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0] =="Yes"))
    real.prob.new$gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1] =="Yes"))
    real.prob.new$sbp.rr <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0] =="Yes"))
    real.prob.new$rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1] =="Yes"))
    real.prob.new$sbp.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1] =="Yes"))
    real.prob.new$sbp.rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1] =="Yes"))

    ## estimated probabileties for the same groups 
    est.prob.new <- list()
    est.prob.new$none <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0])
    est.prob.new$rr <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0])
    est.prob.new$sbp <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0])
    est.prob.new$gcs <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1])
    est.prob.new$sbp.rr <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0])
    est.prob.new$rr.gcs <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1])
    est.prob.new$sbp.gcs <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1])
    est.prob.new$sbp.rr.gcs <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1])

    ## sum of qSOFA new
    real.prob.sum.new <- list()
    real.prob.sum.new$none <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==0 ] =="Yes"))
    real.prob.sum.new$one <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==1 ] =="Yes"))
    real.prob.sum.new$two <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==2 ] =="Yes"))
    real.prob.sum.new$three <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==3 ] =="Yes"))

    ## using the estimate probabilities from the validation sample
    est.prob.sum.new <- list()
    est.prob.sum.new$none <-val.est.prob.sum.new$none
    est.prob.sum.new$one <- val.est.prob.sum.new$one
    est.prob.sum.new$two <- val.est.prob.sum.new$two
    est.prob.sum.new$three <-val.est.prob.sum.new$three

    #plot(est.prob.sum.new, real.prob.sum.new, xlim=c(0,1), ylim=c(0,1), main= "Sum of qSOFA new")
    #lines(c(0,1),c(0,1))
    
    ## return values in results for plots
    boot.results$real.prob.sum.new <- real.prob.sum.new
    boot.results$est.prob.sum.new <- est.prob.sum.new
    boot.results$real.prob.new <- real.prob.new
    boot.results$est.prob.new <- est.prob.new
    
    ## ICI code new ####
    ## separate
    ICI <- data.frame(test.sample$licu, new.prob.calc)
    loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes") ~ new.prob.calc, ICI)
    p.calibrate <- predict(loess.calibrate, newdata = new.prob.calc)
    results$ICI.new <- mean(abs(p.calibrate - new.prob.calc))
    boot.results$ICI.new <- results$ICI.new
    
    ## as a sum
    ## could be anything just wanted it to be the same length as licu
    sum.new.prob.calc <- as.numeric(test.sample$licu== "Yes")
    sum.new.prob.calc[test.sample$new.qSOFA_score==0] <-  val.est.prob.sum.new$none
    sum.new.prob.calc[test.sample$new.qSOFA_score==1] <-  val.est.prob.sum.new$one
    sum.new.prob.calc[test.sample$new.qSOFA_score==2] <-  val.est.prob.sum.new$two
    sum.new.prob.calc[test.sample$new.qSOFA_score==3] <-  val.est.prob.sum.new$three

    ICI <- data.frame(test.sample$licu,sum.new.prob.calc)
    loess.calibrate <- loess(as.numeric(test.sample$licu=="Yes")~ sum.new.prob.calc, ICI)
    p.calibrate <- predict(loess.calibrate, newdata = sum.new.prob.calc)
    results$ICI.sum.new <- mean(abs(p.calibrate - sum.new.prob.calc))
    boot.results$ICI.sum.new <- results$ICI.sum.new
    
    

    ## AUC
    results$auc.new <- calculate_auc(new.prob.calc, as.numeric(test.sample$licu=="Yes"))
    boot.results$auc.new <- results$auc.new
    
    ## original model ####
    
    ## From eFigure 3 the mortality for score=0 was approx 1 %
    ## this gives a log(odds) of -4.595 or aprox -4.6

    coeff <- c(-4.6, log(2.61), log(3.18),log(4.31))
    beta <- coeff[1] + coeff[2]*test.sample$org.sbp_score + coeff[3]*test.sample$org.rr_score + coeff[4]*test.sample$org.gcs_score
    org.prob.calc <- exp(beta)/(1+exp(beta))

    ## finding the real observed probabilities for different groups
    real.prob.org <- list()
    real.prob.org$none <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0] =="Yes"))
    real.prob.org$rr <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0] =="Yes"))
    real.prob.org$sbp <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0] =="Yes"))
    real.prob.org$gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1] =="Yes"))
    real.prob.org$sbp.rr <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0] =="Yes"))
    real.prob.org$rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1] =="Yes"))
    real.prob.org$sbp.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1] =="Yes"))
    real.prob.org$sbp.rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1] =="Yes"))

    ## estimated probabileties for the same groups
    est.prob.org <- list()
    est.prob.org$none <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0])
    est.prob.org$rr <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0])
    est.prob.org$sbp <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0])
    est.prob.org$gcs <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1])
    est.prob.org$sbp.rr <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0])
    est.prob.org$rr.gcs <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1])
    est.prob.org$sbp.gcs <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1])
    est.prob.org$sbp.rr.gcs <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1])

    ## sum of qSOFA org
    real.prob.sum.org <- list()
    real.prob.sum.org$none <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==0 ] =="Yes"))
    real.prob.sum.org$one <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==1 ] =="Yes"))
    real.prob.sum.org$two <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==2 ] =="Yes"))
    real.prob.sum.org$three <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==3 ] =="Yes"))

    ## estamated probabilities of the qSOFA sum from the validation sample is used
    est.prob.sum.org  <- list()
    est.prob.sum.org$none <- val.est.prob.sum.org$none
    est.prob.sum.org$one <- val.est.prob.sum.org$one
    est.prob.sum.org$two <- val.est.prob.sum.org$two
    est.prob.sum.org$three <- val.est.prob.sum.org$three 
    
    ## return values in reuslt for plots
    boot.results$real.prob.sum.org <- real.prob.sum.org
    boot.results$est.prob.sum.org <- est.prob.sum.org
    boot.results$real.prob.org <- real.prob.org
    boot.results$est.prob.org <- est.prob.org

    ## ICI original ####
    ## separate
    ICI <- data.frame(test.sample$licu,org.prob.calc)
    loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes") ~ org.prob.calc, ICI)
    p.calibrate <- predict(loess.calibrate, newdata = org.prob.calc)
    results$ICI.org <- mean(abs(p.calibrate - org.prob.calc))
    boot.results$ICI.org <- results$ICI.org

    ## as a sum for ICI plot
    sum.org.prob.calc <- as.numeric(test.sample$licu== "Yes")
    sum.org.prob.calc[test.sample$new.qSOFA_score==0] <-  val.est.prob.sum.org$none
    sum.org.prob.calc[test.sample$new.qSOFA_score==1] <-  val.est.prob.sum.org$one
    sum.org.prob.calc[test.sample$new.qSOFA_score==2] <-  val.est.prob.sum.org$two
    sum.org.prob.calc[test.sample$new.qSOFA_score==3] <-  val.est.prob.sum.org$three

    ICI <- data.frame(test.sample$licu,sum.org.prob.calc)
    loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes")~ sum.org.prob.calc, ICI)
    p.calibrate <- predict(loess.calibrate, newdata = sum.org.prob.calc)
    results$ICI.sum.org <- mean(abs(p.calibrate - sum.org.prob.calc))
    boot.results$ICI.sum.org <- results$ICI.sum.org
    
    ## AUC
    results$auc.org <- calculate_auc(org.prob.calc, as.numeric(test.sample$licu=="Yes"))
    boot.results$auc.org <- results$auc.org
    
    ## Calculate differences
    results$diff.ici.qsofa <- results$ICI.new - results$ICI.org
    results$diff.ici.qsofa.sum <- results$ICI.sum.new - results$ICI.sum.org
    results$diff.auc.qsofa <-results$auc.new - results$auc.org
    boot.results$diff.ici.qsofa <- results$diff.ici.qsofa
    boot.results$diff.ici.qsofa.sum <- results$diff.ici.qsofa.sum
    boot.results$diff.auc.qsofa <- results$diff.auc.qsofa

    ## Return results
    return.list <- list(boot.results = unlist(boot.results))
    if (!boot)
        return.list <- c(return.list, results)
    return (return.list)
}


## Bootstrap
n.bootstraps <- 1000
bootstrap.results <- bootstrap(part_data, run_study, n.bootstraps)
results <- bootstrap.results$arbitrary[[1]]
boot.list <- bootstrap.results$boot.list
## The code to estimate confidence intervals does not work if there
## are NAs in any of the bootstrap replications. Therefore NAs are now
## replaced with the value that deviates the most from the mean of
## bootstrap values. The rationale for choosing the value that
## deviates the most is to avoid the reduction in uncertainty that
## would result from replacing missing with for example the mean or
## median value.
t.colnames <- colnames(boot.list$t)
boot.list$t <- apply(boot.list$t, 2, function(values) {
    mean.value <- mean(values, na.rm = TRUE)
    differences <- abs(mean.value - values)
    max.difference <- max(differences, na.rm = TRUE)
    new.value <- unique(values[differences == max.difference & !is.na(differences)])
    values[is.na(values)] <- new.value
    values
})
colnames(boot.list$t) <- t.colnames
## Estimate confidence intervals
boot.cis <- lapply(seq_len(length(boot.list$t0)), function(i) {
    ci <- boot.ci(boot.list, type = "norm", index = i)
    if(!is.null(ci)){
        pe <- ci$t0
        ci <- ci$normal[, c(2, 3)]
        formatted.ci <- sprintf("%.3f", c(pe, ci[1], ci[2]))
        names(formatted.ci) <- c("pe", "lb", "ub")
    } else {
        formatted.ci <- round(boot.list$t[1,i], digits = 3)
        names(formatted.ci) <- c("pe") 
    }
    formatted.ci
})
names(boot.cis) <- names(boot.list$t0)


## Create objects to facilitate reporting
ors <- boot.cis[grep("updated.ors.", names(boot.cis))]
names(ors) <- sub("updated.ors.", "", names(ors))
ors <- lapply(ors, function(or) paste0(or[1], " (", or[2], " - ", or[3], ")"))

CIs <- boot.cis
CIs <- lapply(CIs, function(or){
    if(!is.na(or[2])){
        paste0(or[1], " (", or[2], " - ", or[3], ")")
    }else{
        paste0(or[1])
    }
}) 

## plots ####

# ICI sum new ----
est.sum.new <- c(boot.cis$est.prob.sum.new.none[["pe"]], boot.cis$est.prob.sum.new.one[["pe"]] , boot.cis$est.prob.sum.new.two[["pe"]], boot.cis$est.prob.sum.new.three[["pe"]]) 
est.sum.new <- as.numeric(est.sum.new)
obs.sum.new <- c(boot.cis$real.prob.sum.new.none[["pe"]], boot.cis$real.prob.sum.new.one[["pe"]] , boot.cis$real.prob.sum.new.two[["pe"]],boot.cis$real.prob.sum.new.three[["pe"]]) 
obs.sum.new <- as.numeric(obs.sum.new)
plot(est.sum.new, obs.sum.new, xlim=c(0,1), ylim=c(0,1),main= "Sum of qSOFA new")
lines(c(0,1),c(0,1))
 # ICI sum org -------
est.sum.org <- c(boot.cis$est.prob.sum.org.none[["pe"]], boot.cis$est.prob.sum.org.one[["pe"]] , boot.cis$est.prob.sum.org.two[["pe"]], boot.cis$est.prob.sum.org.three[["pe"]]) 
est.sum.org <- as.numeric(est.sum.org)
obs.sum.org <- c(boot.cis$real.prob.sum.org.none[["pe"]], boot.cis$real.prob.sum.org.one[["pe"]] , boot.cis$real.prob.sum.org.two[["pe"]],boot.cis$real.prob.sum.org.three[["pe"]]) 
obs.sum.org <- as.numeric(obs.sum.org)
plot(est.sum.org, obs.sum.org, xlim=c(0,1), ylim=c(0,1),main= "Sum of qSOFA org")
lines(c(0,1),c(0,1))

## table one ---- 

## I suggest that you stratify this table based on whether patients
## were admitted to the ICU or not
tabOne <- CreateTableOne(data=results$data.table1)

common <- function(variable, index, data = globalenv()$results$data.table1) {
    tab <- table(data[, variable])
    tab <- sort(tab, decreasing = TRUE)
    most.common <- names(tab[index])
    most.common
}
most_common <- function(variable, index = 1) common(variable, index)
second_most_common <- function(variable, index = 2) common(variable, index)
third_most_common <- function(variable, index = 3) common(variable, index)
most.common.sex <- most_common("Sex")
sex.table <- tabOne$CatTable$Overall$Sex
p.sex <- round(sex.table[sex.table$level == most.common.sex, "percent"])
most.common.mechanism <- most_common("Mode of injury")
second.most.common.mechanism <- second_most_common("Mode of injury")
third.most.common.mechanism <- third_most_common("Mode of injury")
mechanism.table <- tabOne$CatTable$Overall$`Mode of injury`
p.mechanism <- round(mechanism.table[mechanism.table$level == most.common.mechanism, "percent"])
p.mechanism.second <- round(mechanism.table[mechanism.table$level == second.most.common.mechanism, "percent"])
p.mechanism.third <- round(mechanism.table[mechanism.table$level == third.most.common.mechanism, "percent"])
transport.table <- tabOne$CatTable$Overall$Transported
p.transported <- round(transport.table[transport.table$level =="Yes","percent"])
ICU.table <- tabOne$CatTable$Overall$`Admitted to the ICU`
p.ICU <- round(ICU.table[ICU.table$level =="Yes","percent"])

## Compile paper ####
render("study-plan.Rmd")

