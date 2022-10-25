# Survey Topline Data in R - Clean Factor Variables
# Thurston, AJ
# 2022-10-24
#
# Version notes
# 2022-10-24 Start

#' svy.tldr.fac_clean_missing.  A function for cleaning different missing data in factor variables simply.  Recodes factor variables to character for simple recoding with `gsub` and converts back to factor variables.
#'
#' @param df A survey dataframe consisting of some factor variable.
#' @param missing_list A list of strings identified as missing, for gsub function, for example, -99, -98, and -97 missing is "-9.*"
#' @param clean_val_labs Clean (remove) variable labels from factor variables

#' @return A survey dataframe with
#' @export
#'
#' @examples
#' svytldr(df = df, ids = id, strata = strata, weights = wt, svyitem = "svyitem", svygrp = "group")
svytldr_missing <- function(df, missing_list, clean_val_labs = F){

  missing_list <- paste(missing_list, collapse = "|")

    if(clean_val_labs == F){
      replace_factor_na <- function(var){
        var <- as.character(var)
        var <- gsub(missing_list, NA_character_, var)
        var <- as.factor(var)
      }
    }
    if(clean_val_labs == T){
      replace_factor_na <- function(var){
        var <- as.character(var)
        var <- gsub(missing_list, NA_character_, var)
        var <- gsub(":.*","", var)
        var <- as.factor(var)
      }
    }
    df <- df %>%
      mutate_if(is.factor, replace_factor_na)
  return(df)
}
