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


##function evaluation qSOFA on input.
qSOFAcalc <- function(raw, tot = TRUE, sbp_cut = 100, rr_cut = 22) {
    ## Check arguments
    assert_that(is.data.frame(raw))
    #assert_that(ncol(raw) == 3)
    assert_that(is.logical(tot))
    assert_that(is.numeric(sbp_cut))
    assert_that(is.numeric(rr_cut))

    ## Calculate score
    sc_sbp <- select(raw, starts_with("sbp_")) <= sbp_cut
    sc_rr <- select(raw, starts_with("rr_")) >= rr_cut
    sc_gcs <- select(raw, starts_with("gcs_")) < 15
    score <- data.frame(sbp_score = sc_sbp, rr_score = sc_rr, gcs_score = sc_gcs) %>%
        mutate(across(.fns = as.integer))
    if (tot){
      score <- data.frame(score, "qSOFA_score" = sc_sbp + sc_rr + sc_gcs)
      names(score) <- c("sbp_score", "rr_score","gcs_score","qSOFA_score" )
    }else{
      names(score) <- c("sbp_score", "rr_score","gcs_score")
    }
    score
}

#Data extraction
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
part_data$age <- as.numeric(part_data$age)
part_data$age[is.na(part_data$age)] <- 90

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

figure1 <- grViz("digraph flowchart {
      # node definitions with substituted label text
      node [fontname = Helvetica, shape = rectangle, width = 4]        
      graph [rankdir = LR]
      
      tab1 [label = '@@1']
      tab2 [label = '@@2']
      tab3 [label = '@@3']
      tab4 [label = '@@4']
      tab5 [label = '@@5']
      tab6 [label = '@@6']
      tab7 [label = '@@7']
      
      node [shape = point, style = filled ,color = black, label = '', height = 0]
      a,b,c,d,f
      
      subgraph {
      rank = same;
      tab1 -> a [arrowhead=none] 
      a-> tab2 
      tab2 -> b [arrowhead=none] 
      b -> tab3 
      tab3 -> c [arrowhead=none] 
      c -> tab4
      
      }

      # edge definitions with the node IDs
      a -> tab5 
      b -> tab6 
      c -> tab7
      }

      [1]: paste0('Participants in the TITCO cohort: ', results$n.cohort )
      [2]: paste0('Participants above age 18: ', results$n.adults)
      [3]: paste0('Participants alive at admission: ', results$n.included)
      [4]: paste0('Participants with complete data: ', results$n.complete)
      [5]: paste0('Participants below age 18: ', results$n.younger.than.18)
      [6]: paste0('Participants died before admission: ', results$n.incl2)
      [7]: paste0('Participants with missing data: ', results$n.NA_TOT, '\\n', 'Missing ICU admission: ', results$n.NA_ICU, '\\n','Missing systolic blood preassure: ', results$n.NA_SBP, '\\n', 'Missing respiratory rate: ', results$n.NA_RR, '\\n', 'Missing Glascow coma scale: ', results$n.NA_GCS)

      ")

export_svg(figure1) %>% charToRaw %>% rsvg_svg("figure1.svg")

## calculate qSOFA score and add to study.sample.complete ####
qSOFA <- qSOFAcalc(study.sample.complete, tot=FALSE)
study.sample.complete.sofa <- data.frame(study.sample.complete,qSOFA)


## split sample in sample.split #### 

proportion <- c(0.6,0.20,0.20)
split.names <- c("training.sample","validation.sample", "test.sample")

sample.split <- SplitDataset(study.sample.complete.sofa, events = NULL, event.variable.name = NULL,
                             event.level = NULL, split.proportions = proportion ,
                             temporal.split = NULL, remove.missing = FALSE, random.seed = NULL,
                             sample.names = split.names, return.data.frame = FALSE)

summary(sample.split$training.sample)
summary(sample.split$validation.sample)
summary(sample.split$test.sample)

## Training #### --------------------- NY
training.sample <- sample.split$training.sample

training.ICU <- as.numeric(training.sample$licu=="Yes")
training.died <- as.numeric(training.sample$died=="Yes")

x1 <- training.sample$sbp_score
x2 <- training.sample$rr_score
x3 <- training.sample$gcs_score
y <- training.ICU
yxxx <- data.frame(y , x1, x2, x3)

fit <- glm(y ~., family=binomial(link='logit'), data=yxxx)


## ROCR curve
library(ROCR)
p <- predict(fit, newdata=subset(sample.split$training.sample,select=c(11,12,13)), type="response")
pr <- prediction(p, as.numeric(sample.split$training.sample$licu=="Yes"))
prf <- performance(pr, measure = "tpr", x.measure = "fpr")
plot(prf)
auc <- performance(pr, measure = "auc")
auc <- auc@y.values[[1]]
auc


## Compile paper ####
render("study-plan.Rmd")
