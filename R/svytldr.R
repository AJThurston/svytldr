# Survey Topline Data in R - Primary Function
# Thurston, AJ
# 2020-09-08
#
# Version notes
# 2020-01-07 Start
# 2020-01-14 Combining M,SE,N results into one table
# 2022-09-08 Added an option for reformatting as an APA table

#' svytldr
#'
#' @param df A survey dataframe consisting of at minimum a survey item formatted as a factor variable.
#' @param ids Survey case ids (optional)
#' @param strata Survey strata (optional)
#' @param weights Survey weights (optional)
#' @param svyitem A survey item with factor (or ordered factor) format
#' @param svygrp A survey grouping variable, can be binary or multiple group, in factor format (optional)
#' @param fltr_refuse Filter refusals formatted 'refused' (Default = TRUE)
#' @param fltr_nas Filter NAs across dataframe (Default = TRUE)
#' @param flg_low_n Flag estimates with less than n = 100 in either svyitem response option or svygroup (or the combination thereof)
#' @param wide Produces a formatted table with columns for each group and statistic (Default = FALSE; statistics nested w/in group)
#' @param drop.overall Used in conjunction w. wide, drops the overall columns (Default = FALSE)
#' @param drop.m Used in conjunction w. wide, drops the columns for mean (Default = FALSE)
#' @param drop.m_se Used in conjunction w. wide, drops the columns for se(mean) (Default = FALSE)
#' @param drop.n Used in conjunction w. wide, drops the columns for sample size n (Default = FALSE)
#'
#' @return A tibble with M, SE, and unweighted Ns for each response for svyitem (or each response for svyitem within svygroup)
#' @export
#'
#' @examples
#' svytldr(df = df, ids = id, strata = strata, weights = wt, svyitem = "svyitem", svygrp = "group")
svytldr <- function (df, ids, strata, weights, svyitem, svygrp, fltr_refuse = T,
                      fltr_nas = T, flg_low_n = F, wide = F,drop.overall = F, drop.m = F, drop.m_se = F, drop.n = F)
{
  options(survey.lonely.psu = "adjust")

  itemlist <- list() # data frame list for each survey item
  grplist <- list()

  # Subchain to identify survey design
  if (!missing(ids) && !missing(weights) && !missing(strata)){
    dsgn <- . %>% as_survey_design(ids = ids, weights = weights, strata = strata)
  }
  if (!missing(ids) && missing(weights) && !missing(strata)){
    dsgn <- . %>% as_survey_design(ids = ids, strata = strata)
    }
  if (!missing(ids) && !missing(weights) && missing(strata)){
    dsgn <- . %>% as_survey_design(ids = ids, weights = weights)
  }
  if (!missing(ids) && missing(weights) && missing(strata)){
    dsgn <- . %>% as_survey_design(ids = ids)
  }
  if (missing(ids) && !missing(weights) && !missing(strata)){
    dsgn <- . %>% as_survey_design(weights = weights, strata = strata)
  }
  if (missing(ids) && missing(weights) && !missing(strata)){
    dsgn <- . %>% as_survey_design(strata = strata)
  }
  if (missing(ids) && !missing(weights) && missing(strata)){
    dsgn <- . %>% as_survey_design(weights = weights)
  }
  if (missing(ids) && missing(weights) && missing(strata)){
    dsgn <- . %>% as_survey_design()
  }
  
  
  
  for(i in svyitem){

    if (missing(svygrp)) {

      res <- df %>%
        dsgn %>%
        group_by(as.factor("overall"), df[, i], .drop = FALSE) %>%
        summarize(m = survey_mean(), n = unweighted(n()))
      colnames(res)[1] <- "group"
      colnames(res)[2] <- "response"
      res$question <- i
      grplist[["overall"]] <- res
    }

    else {

      res <- df %>%
        dsgn %>%
        group_by(as.factor("overall"), df[, i], .drop = FALSE) %>%
        summarize(m = survey_mean(), n = unweighted(n()))
      colnames(res)[1] <- "group"
      colnames(res)[2] <- "response"
      res$question <- i
      grplist[["overall"]] <- res

      for (g in svygrp){

        res <- df %>% 
        dsgn %>%
          group_by(df[,g], df[,i], .drop = FALSE) %>%
          summarize(m = survey_mean(), n = unweighted(n()))
        colnames(res)[1] <- "group"
        colnames(res)[2] <- "response"
        res$question <- i
        grplist[[g]] <- res

      }

      res <- grplist %>%
        bind_rows() %>%
        select(question, response, group, everything())

    }
    itemlist[[i]] <- res

  }

  res <- itemlist %>%
    bind_rows() %>%
    select(question, response, everything())

  if (flg_low_n == T) {
    res$low_n_flg <- ifelse(res$n >= 100, 0, 1)
  }
  if (fltr_refuse == T) {
    res <- res[!res[1] == "Refused", ]
    res <- res[!res[1] == "refused", ]
    res <- res[!res[2] == "Refused", ]
    res <- res[!res[2] == "refused", ]
  }
  if (fltr_nas == T) {
    res <- res[complete.cases(res), ]
  }
  if (wide == T) {
    values <- names(res[, 4:ncol(res)])
    res <- res %>%
      pivot_wider(id_cols = c(question, response),
                  names_from = "group",
                  names_glue = "{group}.{.value}",
                  values_from = all_of(values),
                  names_vary = "slowest")
    res
  }
  
    if (wide == T && drop.overall == T) {
    suppressWarnings(res <- res %>% select(-starts_with("overall.")))
    res
  }
  
  
  if (wide == T && drop.m == T) {
    suppressWarnings(res <- res %>% select(-ends_with(".m")))
    res
  }
  
  if (wide == T && drop.m_se == T) {
    suppressWarnings(res <- res %>% select(-ends_with(".m_se")))
    res
  }
  
  if (wide == T && drop.n == T) {
    suppressWarnings(res <- res %>% select(-ends_with(".n")))
    res
  }
  
  else {
    res
  }
}
