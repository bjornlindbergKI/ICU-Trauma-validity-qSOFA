#' Bootstrap
#'
#' Bootstraps a specific statistic. Largely inspired by boot but with
#' the addition that it allows arbitrary objects to be returned in
#' addition to the bootstrapped statistics. This it supposed to
#' facilitate operations that should only be done on the original, not
#' bootstrapped, data.
#' 
#' @param original.data Data.frame. The original data to be
#'     bootstrapped. No default.
#' @param statistic Function. The function to apply to
#'     original.data. This function has to accept at least three
#'     arguments, the first being the original data, the second an
#'     index of rows that defines the bootstrap sample, and the third
#'     a logical that indicates if the data is bootstrapped or not,
#'     i.e. is FALSE when the original dat is passed to statistic and
#'     TRUE otherwise. Additional arguments can be passed as ... The
#'     function has to returned a list where the first element is a
#'     vector of statistics to bootstrap and the rest any arbitrary
#'     objects. No default.
#' @param R Numeric. The number of bootstrap samples. No default.
#' @param try.catch Logical. If TRUE statistic is wrapped in a
#'     tryCatch statement that prints the error softly but returns NA,
#'     allowing statistic to continue to be applied to boot
#'     data. This can be dangerous. Defaults to FALSE.
#' @export
bootstrap <- function(original.data, statistic, R, try.catch = FALSE) {
    n.rows <- nrow(original.data)
    bootstrap.rows <- lapply(seq_len(R), function(i) sample(1:n.rows, n.rows, replace = TRUE))
    all.rows <- c(list(original.data = 1:n.rows), bootstrap.rows)
    n.samples <- length(all.rows)
    `%dopar%` <- foreach::`%dopar%`
    results <- foreach::foreach(i = seq_len(n.samples)) %dopar% {
        rows <- all.rows[[i]]
        boot <- TRUE
        if (i == 1)
            boot <- FALSE
        result <- tryCatch(statistic(original.data, rows, boot),
                           error = function(e) {
                               if (try.catch) {
                                   warning (e$msg)
                               } else {
                                   stop (e$msg)
                               }
                               list(as.numeric(NA))
                           })
        if (!is.list(result))
            stop ("statistic has to return a list")
        if (!is.numeric(result[[1]]))
            stop ("The first element in the list returned by statistic has to be a numeric vector")
        result
    }
    boot.list <- list(t0 = results[[1]][[1]],
                      t = do.call(rbind, lapply(results[-1], function(x) x[[1]])),
                      R = R)
    class(boot.list) <- "boot"
    arbitrary <- lapply(results, function(x) if (length(x[-1]) == 1) x[-1][[1]] else x[-1])
    arbitrary <- lapply(arbitrary, function(x) if (length(x) == 0) NULL else x)
    arbitrary <- arbitrary[!sapply(arbitrary, is.null)]
    return.list <- list(boot.list = boot.list, arbitrary = arbitrary)
    return (return.list)
}

test_statistic <- function(original.data, rows, boot) {
    current.data <- original.data[rows, ]
    return.list <- list(result = mean(current.data[, 1]))
    if (!boot)
        return.list$arbitrary.object <- original.data
    return (return.list)
}

test_params <- function() {
    list(original.data = data.frame(a = 1:100, b = rev(1:100)), R = 3, statistic = test_statistic, 
         i = 1)
}
