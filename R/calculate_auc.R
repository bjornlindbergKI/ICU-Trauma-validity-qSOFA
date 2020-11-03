calculate_auc <- function(probabilities, labels) {
    pred <- ROCR::prediction(probabilities, labels)
    perf <- ROCR::performance(pred, measure = "auc")
    auc <- perf@y.values
    unlist(auc)
}
