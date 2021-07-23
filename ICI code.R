library(rms)

################################################################################
# Read in data
################################################################################

data.effect1 <- read.table("ami_1.txt",header=T,sep="")
df.effect1 <- data.frame(data.effect1)

data.effect2 <- read.table("ami_2.txt",header=T,sep="")
df.effect2 <- data.frame(data.effect2)

df.derive <- df.effect1
df.valid <- df.effect2

################################################################################
# Logistic regression
################################################################################

lr.1 <- glm(mort30 ~ age + female + cshock + acpulmed + sysbp + diasbp +
  hrtrate + resp + diabetes + highbp + smokhx + dyslip + famhxcad + cvatia +
  angina + cancer + dementia + pud + prevmi + asthma + depres + perartdis +
  prevrevasc + chf + hyprthyr + as + hgb + sod + pot + glucose + urea +
  wbc + cr, family=binomial,data=df.derive)

pred.valid.lr <- predict(lr.1,newdata=df.valid,type="response")

calibrate.lr <- val.prob(pred.valid.lr,df.valid$mort30,pl=F)

################################################################################
# Determine range of predicted probabilities for each prediction method.
# Then determine grid of values at which predictions will be obtained for the
# calibration plots.
################################################################################

pred.lr <- seq(round(min(pred.valid.lr),2),round(max(pred.valid.lr),2),by=0.01)

################################################################################
# Figure 1: Calibration plots (using loess)
################################################################################

pdf(file="figure1.pdf",width=11.5,height=8)

mort30 <- df.valid$mort30

loess.lr <- loess(mort30 ~ pred.valid.lr)

plot.loess.lr <- predict(loess.lr,pred.lr)

plot(pred.lr,plot.loess.lr,type="l",lty=1,lwd=2,col="purple",
  xlab="Predicted probability of death",ylab="Observed mortality",
  ylim=c(0,1),xlim=c(0,1) )
abline(0,1,lwd=2)

title("Figure 1. Calibration in validation sample (loess)")

################################################################################
# ICI
################################################################################

predobs.loess.lr <- predict(loess.lr,newdata=pred.valid.lr)

ICI.loess.lr <- mean(abs(predobs.loess.lr - pred.valid.lr))

################################################################################
# E50 and E90
################################################################################

E50.loess.lr <- median(abs(predobs.loess.lr - pred.valid.lr))

E90.loess.lr <- quantile(abs(predobs.loess.lr - pred.valid.lr),probs=0.9)

################################################################################
# Emax(0,1)
################################################################################

Emax.loess.lr <- max(abs(predobs.loess.lr - pred.valid.lr))
