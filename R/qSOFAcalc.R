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
