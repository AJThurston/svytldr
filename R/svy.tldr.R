svy.tldr <- function(df,ids,strata,weights,svyitem,svygrp = NULL,fltr.refuse = T,fltr.nas = T,low.n.flg = F){

  options(survey.lonely.psu="adjust")

  if(is.null(svygrp)) {
    res <- df %>%
      as_survey_design(ids = id, strata = strata, weights = wt) %>%
      group_by(as.factor("overall"), df[,svyitem], .drop = FALSE) %>%
      summarize(m = survey_mean(), n = unweighted(n()))
    colnames(res)[2] <- svyitem
    colnames(res)[1] <- "group"

  } else {
    res1 <- df %>%
      as_survey_design(ids = id, strata = strata, weights = wt) %>%
      group_by(as.factor("overall"), df[,svyitem], .drop = FALSE) %>%
      summarize(m = survey_mean(), n = unweighted(n()))
    colnames(res1)[1] <- "group"

    res2 <- df %>%
      as_survey_design(ids = id, strata = strata, weights = wt) %>%
      group_by(df[,svygrp], df[,svyitem], .drop = FALSE) %>%
      summarize(m = survey_mean(), n = unweighted(n()))
    colnames(res2)[1] <- "group"

    res <- rbind(res1,res2)
    colnames(res)[2] <- svyitem

  }

  if(low.n.flg == T){
    res$low.n.flg <- ifelse(res$n >= 100, 0, 1)
  }

  if(fltr.refuse == T){
    res <- res[!res[2] == "refused",]
  }

  if(fltr.nas == T){
    res <- res[complete.cases(res), ]
  }

  print(res, n=Inf)

}
