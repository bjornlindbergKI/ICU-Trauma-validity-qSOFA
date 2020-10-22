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
url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-limited-dataset-v1.csv"
#url <- "https://raw.githubusercontent.com/titco/titco-I/master/titco-I-full-dataset-v1.csv"
tot_data <- rio::import(url)
qSOFA_1raw <- tot_data[,c("sbp_1","rr_1","gcs_t_1")]
qSOFA_2raw <- tot_data[,c("sbp_2","rr_2","gcs_t_2")]
qSOFA_1 <- qSOFAcalc(qSOFA_1raw)
qSOFA_2 <- qSOFAcalc(qSOFA_2raw)

## Part data and as factor some of the data I though could be
## interesting
part_data = subset(tot_data, select = c(incl, age, sex, tran, moi, licu, died, sbp_1, rr_1, gcs_t_1))

## age as number,  > 89 was changed with 90 instead of NA
part_data$age[part_data$age == ">89"] <- 90
part_data$age <- as.numeric(part_data$age)

## sex, mode of injury as factor
part_data$sex <- as.factor(part_data$sex)
part_data$moi <- as.factor(part_data$moi)
part_data$died <- as.factor(part_data$died)
part_data$incl <- as.factor(part_data$incl)

## ICU as binary
part_data$licu[part_data$licu > 0] <- "Yes"
part_data$licu[part_data$licu == 0] <- "No"

## Martins lista #####

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

## exclude those who died before admission ie incl==2
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

## Table 1
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

## Calculate qSOFA score and add to study.sample.complete ####
qSOFA <- qSOFAcalc(study.sample.complete, tot = FALSE)
study.sample.complete.sofa <- data.frame(study.sample.complete, qSOFA)

## Split sample in sample.split #### 
proportion <- c(0.6,0.20,0.20)
split.names <- c("training.sample","validation.sample", "test.sample")

sample.split <- SplitDataset(study.sample.complete.sofa, events = NULL, event.variable.name = NULL,
                             event.level = NULL, split.proportions = proportion ,
                             temporal.split = NULL, remove.missing = FALSE, random.seed = NULL,
                             sample.names = split.names, return.data.frame = FALSE)

## Training #### --------------------- NY
training.sample <- sample.split$training.sample
fit <- glm(as.numeric(licu == "Yes") ~ sbp_score + rr_score + gcs_score, family = binomial, data = training.sample)

## ROCR curve
p <- predict(fit, newdata = training.sample, type="response")
pr <- prediction(p, as.numeric(training.sample$licu == "Yes"))
prf <- performance(pr, measure = "tpr", x.measure = "fpr")
plot(prf)
auc <- performance(pr, measure = "auc")
auc <- auc@y.values[[1]]
results$updated.auc <- auc

## Compile paper ####
render("study-plan.Rmd")
