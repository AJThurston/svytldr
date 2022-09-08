# JAMRS SURVEY ANALYSIS CODE
# Thurston, AJ
# 2020-09-08
#
# Analysis notes:
# _f = factors for the survey library for weighted estimates
# _n = numeric -99 and -97 recoded to missing for corr & SEM estimates
# _z = z-score values for study variables
#
# Version notes
# 2020-01-07 Start
# 2020-01-14 Combining M,SE,N results into one table

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
#' @param fmttd.tbl Produces a formatted table with columns for each group and statistic (Default = F; statistics nested w/in group)
#'
#' @return A tibble with M, SE, and unweighted Ns for each response for svyitem (or each response for svyitem within svygroup)
#' @export
#'
#' @examples
#' svy.tldr(df = df, ids = "ids", strata = "strata", weights = "wt", svyitem = "svyitem", svygrp = "group")
svy.tldr <- function(df,ids,strata,weights,svyitem,svygrp,fltr.refuse=T,fltr.nas=T,low.n.flg = F, fmttd.tbl = F){
  
  options(survey.lonely.psu="adjust")
  
  if(missing(svygrp)) {
    res <- df %>%
      as_survey_design(ids = all_of(ids), strata = all_of(strata), weights = all_of(weights)) %>%
      group_by(as.factor("overall"), df[,svyitem], .drop = FALSE) %>%
      summarize(m = survey_mean(), n = unweighted(n()))
    colnames(res)[2] <- svyitem
    colnames(res)[1] <- "group"
    
  } else {
    res1 <- df %>%
      as_survey_design(ids = ids, strata = strata, weights = weights) %>%
      group_by(as.factor("overall"), df[,svyitem], .drop = FALSE) %>%
      summarize(m = survey_mean(), n = unweighted(n()))
    colnames(res1)[1] <- "group"
    
    res2 <- df %>%
      as_survey_design(ids = ids, strata = strata, weights = weights) %>%
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
    res <- res[!res[1] == "Refused",] # sometimes capitalized
    res <- res[!res[1] == "refused",] # somtimes not capitalized    
    res <- res[!res[2] == "Refused",] # sometimes capitalized
    res <- res[!res[2] == "refused",] # somtimes not capitalized
  }
  
  if(fltr.nas == T){
    res <- res[complete.cases(res), ]
  }
  
  if(fmttd.tbl == T){
    res <- res %>%
      group_by(group, res[,svyitem]) %>%
      pivot_wider(svyitem, 
                  names_from = "group", 
                  names_glue = "{group}.{.value}",
                  values_from = c("m","m_se","n"),
                  names_vary = 'slowest')
    res
  
    } else {
  
    res
  
    }
}
