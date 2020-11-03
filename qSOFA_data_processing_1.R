library(RCurl)
library(ggplot2)
library(rio)
library(assertthat)
library(dplyr)
library(rmarkdown)
library(tableone)
library(tinytex)
library(DiagrammeR)
library(DiagrammeRsvg)
library(networkD3)
library(webshot)
library(knitr)
library(rsvg)
library("bengaltiger")
library(ROCR)

## Source functions
source("R/qSOFAcalc.R")
source("R/create_figure1.R")

# Data extraction
#url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-limited-dataset-v1.csv"
url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-full-dataset-v1.csv"
tot_data <- rio::import(url)
qSOFA_1raw <- tot_data[,c("sbp_1","rr_1","gcs_t_1")]
qSOFA_2raw <- tot_data[,c("sbp_2","rr_2","gcs_t_2")]
qSOFA_1 <- qSOFAcalc(qSOFA_1raw)
qSOFA_2 <- qSOFAcalc(qSOFA_2raw)

## Part data and as factor
part_data = subset(tot_data, select = c(incl, age, sex, tran, moi, licu, died, sbp_1, rr_1, gcs_t_1))

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

## Create list to store results
results <- list()
results$n.cohort <- nrow(tot_data)

## Exclude those younger than 18
younger.than.18 <- part_data$age < 18
results$n.younger.than.18 <- sum(younger.than.18)
study.sample <- part_data[!younger.than.18, ]
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

## Table 1 ####
data.table1 <- study.sample.complete
data.table1$incl <- NULL

## change names
names(data.table1) <- c("Age", "Sex", "Transported", "Mode of injury", "Admitted to the ICU", "Died after admission", "SBP", "RR", "GCS")

## combine road traffic injury to one category
data.table1$`Mode of injury` <- as.character(data.table1$`Mode of injury`)
RTI <- grepl('traffic', data.table1$`Mode of injury`)
data.table1$`Mode of injury`[RTI] <- "Road traffic injury" 

## Figure 1 flowchart ####
figure1 <- create_figure1(results)

## Split sample in sample.split #### 
proportion <- c(0.6,0.20,0.20)
split.names <- c("training.sample","validation.sample", "test.sample")
sample.split <- SplitDataset(study.sample.complete, split.proportions = proportion,
                             remove.missing = FALSE, sample.names = split.names,
                             return.data.frame = FALSE)

# cutoff cutpointr #### 
# wasnt sure "minimum 0/1 distance on the area under the receiver operating characteristic curve (AUROC)" could be generalized to the youden index in all cases
# but thats what i used.
library(cutpointr)

# rr depends if we want it to be negative or positive... it's like U
# curved and to be honest quite a bad predictor
opt_cut.rr <- cutpointr(training.sample, rr_1, licu, direction = ">=",
                        method = maximize_metric, metric = youden,
                        pos_class = "Yes")
#plot_metric(opt_cut.rr)
#plot(opt_cut.rr)
results$cut.rr <- opt_cut.rr$optimal_cutpoint

# GCS 
opt_cut.gcs <- cutpointr(training.sample, gcs_t_1, licu, direction = "<=",
                         method = maximize_metric, metric = youden,
                         pos_class = "Yes")
#plot_metric(opt_cut.gcs)
#plot(opt_cut.gcs)
results$cut.gcs <- opt_cut.gcs$optimal_cutpoint

# SBP
opt_cut.sbp <- cutpointr(training.sample, sbp_1, licu, direction = "<=",
                         method = maximize_metric, metric = youden,
                         pos_class = "Yes")
#plot_metric(opt_cut.sbp)
#plot(opt_cut.sbp)
results$cut.sbp <- opt_cut.sbp$optimal_cutpoint

## So the next step now is to create new "updated" variables in the
## validtion and test samples and go on to estimate new coefficients
## for these using the validation sample. Once you have done this you
## go on to estimate the performance of your four models:
## 1. Original qSOFA probability
## 2. Original qSOFA score
## 3. Updates qSOFA probability
## 4. Updated qSOFA score
## I suggest you compare the performance of 1 and 3 and 2 and 4.

## Validation  ####

validation.sample <- sample.split$validation.sample

validation.qSOFA.original <- qSOFAcalc(raw = validation.sample,tot = TRUE)
names(validation.qSOFA.original) <- c("org.sbp_score", "org.rr_score", "org.gcs_score", "org.qSOFA_score")

validation.qSOFA.new <- qSOFAcalc(raw = validation.sample,rr_cut = results$cut.rr, sbp_cut = results$cut.rr)
names(validation.qSOFA.new) <- c("new.sbp_score", "new.rr_score", "new.gcs_score", "new.qSOFA_score")


validation.sample <- data.frame(validation.sample,validation.qSOFA.original,validation.qSOFA.new )



# new logistic regression model ####

fit <- glm(as.numeric(licu == "Yes") ~ new.sbp_score + new.rr_score + new.gcs_score, family = binomial, data = validation.sample)
coeff <- fit$coefficients

# estimating probabilities of the sum of qSOFA new

coeff <- fit$coefficients
beta <- coeff[1] + coeff[2]*validation.sample$new.sbp_score + coeff[3]*validation.sample$new.rr_score + coeff[4]*validation.sample$new.gcs_score
val.new.prob.calc <- exp(beta)/(1+exp(beta))

val.est.prob.sum.new <- list()
val.est.prob.sum.new$none <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==0 ])
val.est.prob.sum.new$one <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==1 ])
val.est.prob.sum.new$two <- mean(val.new.prob.calc[validation.sample$new.qSOFA_score==2 ])
#since there were no cases with sum 3 and it can only go one way:
beta <- coeff[1] + coeff[2]*1 + coeff[3]*1 + coeff[4]*1
val.est.prob.sum.new$three <-  as.numeric(exp(beta)/(1+exp(beta)))


# estamating probabilities of the sum of qSOFA old

# overall log(odds) for death in the whole sample was -3.11227 i just guessed that was how i was supposed to get that number of the firs coefficent.
# i didnt find anything about a base odds for patients without any points on the qSOFA but maybe there was and that would be better.


coeff <- c(-3.11227, log(2.61), log(3.18),log(4.31))

beta <- coeff[1] + coeff[2]*validation.sample$org.sbp_score + coeff[3]*validation.sample$org.rr_score + coeff[4]*validation.sample$org.gcs_score
val.org.prob.calc <- exp(beta)/(1+exp(beta))

val.est.prob.sum.org <- list()
val.est.prob.sum.org$none <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==0 ])
val.est.prob.sum.org$one <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==1 ])
val.est.prob.sum.org$two <- mean(val.org.prob.calc[validation.sample$new.qSOFA_score==2 ])
#since there were no cases with sum 3 and it can only go one way:
beta <- coeff[1] + coeff[2]*1 + coeff[3]*1 + coeff[4]*1
val.est.prob.sum.org$three <-  as.numeric(exp(beta)/(1+exp(beta)))

# test sample and performance #### 

# i'm sure there's a better way of doing this since copy+paste is never a good answer but it works and i hope 
# you can follow and see if i have misunderstood anything.

test.sample <- sample.split$test.sample

test.qSOFA.original <- qSOFAcalc(raw = test.sample,tot = TRUE)
names(test.qSOFA.original) <- c("org.sbp_score", "org.rr_score", "org.gcs_score", "org.qSOFA_score")

test.qSOFA.new <- qSOFAcalc(raw = test.sample,rr_cut = results$cut.rr, sbp_cut = results$cut.rr)
names(test.qSOFA.new) <- c("new.sbp_score", "new.rr_score", "new.gcs_score", "new.qSOFA_score")


test.sample <- data.frame(test.sample,test.qSOFA.original,test.qSOFA.new )

# estamating new probabilties 

coeff <- fit$coefficients
beta <- coeff[1] + coeff[2]*test.sample$new.sbp_score + coeff[3]*test.sample$new.rr_score + coeff[4]*test.sample$new.gcs_score
new.prob.calc <- exp(beta)/(1+exp(beta))



# finding the real observed probabilities for different groups
real.prob.new <- list()
real.prob.new$none <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0] =="Yes"))
real.prob.new$rr <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0] =="Yes"))
real.prob.new$sbp <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0] =="Yes"))
real.prob.new$gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1] =="Yes"))
real.prob.new$sbp.rr <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0] =="Yes"))
real.prob.new$rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1] =="Yes"))
real.prob.new$sbp.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1] =="Yes"))
real.prob.new$sbp.rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1] =="Yes"))


# estimated probabileties for the same groups 
est.prob.new <- list()
est.prob.new$none <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0])
est.prob.new$rr <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==0])
est.prob.new$sbp <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0])
est.prob.new$gcs <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1])
est.prob.new$sbp.rr <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==0])
est.prob.new$rr.gcs <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==0 & test.sample$new.gcs_score==1])
est.prob.new$sbp.gcs <- mean(new.prob.calc[test.sample$new.rr_score==0 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1])
est.prob.new$sbp.rr.gcs <- mean(new.prob.calc[test.sample$new.rr_score==1 & test.sample$new.sbp_score==1 & test.sample$new.gcs_score==1])

# ish ICI plot
plot(est.prob.new,real.prob.new,xlim=c(0,1), ylim=c(0,1),main= "Individual qSOFA new")


#sum of qSOFA new

real.prob.sum.new <- list()
real.prob.sum.new$none <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==0 ] =="Yes"))
real.prob.sum.new$one <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==1 ] =="Yes"))
real.prob.sum.new$two <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==2 ] =="Yes"))
real.prob.sum.new$three <- mean(as.numeric(test.sample$licu[test.sample$new.qSOFA_score==3 ] =="Yes"))


est.prob.sum.new <- list()
# using the estimate probabilities from the validation sample
est.prob.sum.new$none <-val.est.prob.sum.new$none
est.prob.sum.new$one <- val.est.prob.sum.new$one
est.prob.sum.new$two <- val.est.prob.sum.new$two
est.prob.sum.new$three <-val.est.prob.sum.new$three



plot(est.prob.sum.new,real.prob.sum.new,xlim=c(0,1), ylim=c(0,1), main= "Sum of qSOFA new")


# ICI code new ####

# separate
ICI <- data.frame(test.sample$licu,new.prob.calc)

loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes")~ new.prob.calc, ICI)
p.calibrate <- predict(loess.calibrate, newdata = new.prob.calc)
results$ICI.new <- mean(abs(p.calibrate - new.prob.calc))

# as a sum

# could be anything just wanted it to be the same length as licu
sum.new.prob.calc <- as.numeric(test.sample$licu== "Yes")
sum.new.prob.calc[test.sample$new.qSOFA_score==0] <-  val.est.prob.sum.new$none
sum.new.prob.calc[test.sample$new.qSOFA_score==1] <-  val.est.prob.sum.new$one
sum.new.prob.calc[test.sample$new.qSOFA_score==2] <-  val.est.prob.sum.new$two
sum.new.prob.calc[test.sample$new.qSOFA_score==3] <-  val.est.prob.sum.new$three


ICI <- data.frame(test.sample$licu,sum.new.prob.calc)

loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes")~ sum.new.prob.calc, ICI)
p.calibrate <- predict(loess.calibrate, newdata = sum.new.prob.calc)
results$ICI.sum.new <- mean(abs(p.calibrate - sum.new.prob.calc))


# original model ####

# overall log(odds) for death in the whole sample was -3.11227 i just guessed that was how i was supposed to get that number of the firs coefficent.
# i didnt find anything about a base odds for patients without any points on the qSOFA but maybe there was and that would be better.

coeff <- c(-3.11227, log(2.61), log(3.18),log(4.31))

beta <- coeff[1] + coeff[2]*test.sample$org.sbp_score + coeff[3]*test.sample$org.rr_score + coeff[4]*test.sample$org.gcs_score
org.prob.calc <- exp(beta)/(1+exp(beta))


# finding the real observed probabilities for different groups
real.prob.org <- list()
real.prob.org$none <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0] =="Yes"))
real.prob.org$rr <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0] =="Yes"))
real.prob.org$sbp <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0] =="Yes"))
real.prob.org$gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1] =="Yes"))
real.prob.org$sbp.rr <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0] =="Yes"))
real.prob.org$rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1] =="Yes"))
real.prob.org$sbp.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1] =="Yes"))
real.prob.org$sbp.rr.gcs <- mean(as.numeric(test.sample$licu[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1] =="Yes"))


# estimated probabileties for the same groups
est.prob.org <- list()
est.prob.org$none <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0])
est.prob.org$rr <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==0])
est.prob.org$sbp <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0])
est.prob.org$gcs <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1])
est.prob.org$sbp.rr <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==0])
est.prob.org$rr.gcs <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==0 & test.sample$org.gcs_score==1])
est.prob.org$sbp.gcs <- mean(org.prob.calc[test.sample$org.rr_score==0 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1])
est.prob.org$sbp.rr.gcs <- mean(org.prob.calc[test.sample$org.rr_score==1 & test.sample$org.sbp_score==1 & test.sample$org.gcs_score==1])

# ish ICI plot
plot(est.prob.org,real.prob.org,xlim=c(0,1), ylim=c(0,1),main= "Individual qSOFA original")


#sum of qSOFA new

real.prob.sum.org <- list()
real.prob.sum.org$none <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==0 ] =="Yes"))
real.prob.sum.org$one <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==1 ] =="Yes"))
real.prob.sum.org$two <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==2 ] =="Yes"))
real.prob.sum.org$three <- mean(as.numeric(test.sample$licu[test.sample$org.qSOFA_score==3 ] =="Yes"))

# estamated probabilities of the qSOFA sum from the validation sample is used
est.prob.sum.org  <- list()
est.prob.sum.org$none <- val.est.prob.sum.org$none
est.prob.sum.org$one <- val.est.prob.sum.org$one
est.prob.sum.org$two <- val.est.prob.sum.org$two
est.prob.sum.org$three <- val.est.prob.sum.org$three

plot(est.prob.sum.org,real.prob.sum.org,xlim=c(0,1), ylim=c(0,1),main= "Sum of qSOFA original")

# ICI original ####

# separate

ICI <- data.frame(test.sample$licu,org.prob.calc)

loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes")~ org.prob.calc, ICI)
p.calibrate <- predict(loess.calibrate, newdata = org.prob.calc)

results$ICI.org <- mean(abs(p.calibrate - org.prob.calc))

# as a sum

sum.org.prob.calc <- as.numeric(test.sample$licu== "Yes")
sum.org.prob.calc[test.sample$new.qSOFA_score==0] <-  val.est.prob.sum.org$none
sum.org.prob.calc[test.sample$new.qSOFA_score==1] <-  val.est.prob.sum.org$one
sum.org.prob.calc[test.sample$new.qSOFA_score==2] <-  val.est.prob.sum.org$two
sum.org.prob.calc[test.sample$new.qSOFA_score==3] <-  val.est.prob.sum.org$three


ICI <- data.frame(test.sample$licu,sum.org.prob.calc)

loess.calibrate <- loess(as.numeric(test.sample.licu=="Yes")~ sum.org.prob.calc, ICI)
p.calibrate <- predict(loess.calibrate, newdata = sum.org.prob.calc)

results$ICI.sum.org <- mean(abs(p.calibrate - sum.org.prob.calc))

## Compile paper ####
render("study-plan.Rmd")
