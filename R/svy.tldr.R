#' svy.tldr
#'
#' @param df A survey dataframe consisting of at minimum a survey item formatted as a factor variable.
#' @param ids Survey case ids (optional)
#' @param strata Survey strata (optional)
#' @param weights Survey weights (optional)
#' @param svyitem A survey item with factor (or ordered factor) format
#' @param svygrp A survey grouping variable, can be binary or multiple group, in factor format (optional)
#' @param fltr.refuse Filter refusals formatted 'refused' (Default = TRUE)
#' @param fltr.nas Filter NAs across dataframe (Default = TRUE)
#' @param low.n.flg Flag estimates with less than n = 100 in either svyitem response option or svygroup (or the combination thereof)
#'
#' @return A tibble with M, SE, and unweighted Ns for each response for svyitem (or each response for svyitem within svygroup)
#' @export
#'
#' @examples
#' svy.tldr(df = df, ids = id, strata = strata, weights = wt, svyitem = "svyitem", svygrp = "group")

# TODO: Actually make IDS, Strata, and Weights optional, use "is.missing" from this answer: https://stackoverflow.com/questions/28370249/correct-way-to-specifiy-optional-arguments-in-r-functions

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
