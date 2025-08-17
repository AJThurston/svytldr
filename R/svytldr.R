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
#' @param wide Produces a formatted table with columns for each group and statistic (Default = TRUE)
#' @param ttests Provides pairwise t-tests between svygrp levels for each item/response (Default = TRUE)
#' @param spacing Adds a blank row after each question and a blank column between each group when wide = TRUE (Default = TRUE)
#' @param fltr_refuse Filter refusals formatted 'refused' (Default = TRUE)
#' @param fltr_nas Filter NAs across dataframe (Default = TRUE)
#' @param flg_low_n Flag estimates with less than n = 100 in either svyitem response option or svygroup (or the combination thereof)
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
                     fltr_nas = T, flg_low_n = F, wide = T, ttests = T, drop.overall = F, drop.m = F, drop.m_se = F, drop.n = F, spacing = T)
{

  # ---- Dependency check ----

  needed_pkgs <- c("tidyverse", "survey", "srvyr")
  missing <- needed_pkgs[!sapply(needed_pkgs, requireNamespace, quietly = TRUE)]

  if (length(missing) > 0) {
    stop("The following packages are required but not installed: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  # ---- Adjust Primary Sampling Units

  options(survey.lonely.psu = "adjust")

  # ---- Functions ----

  itemlist <- list() # data frame list for each survey item
  grplist <- list()

  # ---- Survey design subchain ----
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

  # ---- Data analysis funcion ----

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

  res$question <- factor(res$question, levels = svyitem, ordered = TRUE)

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

  # ---- t-test functions ----
  if (ttests && !missing(svygrp) && wide) {
    des0 <- df %>% dsgn  # reuse your survey design subchain

    .clean <- function(x) {
      x <- as.character(x)
      x <- gsub("[^A-Za-z0-9]+", "_", x)
      x <- gsub("_+", "_", x)
      x <- gsub("^_|_$", "", x)
      trimws(x)
    }

    tt_out <- purrr::map_dfr(svyitem, function(item) {
      resp_levels <- df[[item]] %>% as.character() %>% stats::na.omit() %>% unique()
      resp_levels <- resp_levels[resp_levels != "refused"]

      purrr::map_dfr(svygrp, function(gvar) {
        glv <- if (is.factor(df[[gvar]])) levels(df[[gvar]])
        else df[[gvar]] %>% as.character() %>% stats::na.omit() %>% unique()
        glv <- glv[!is.na(glv)]
        if (length(glv) < 2) return(NULL)
        grp_pairs <- utils::combn(glv, 2, simplify = FALSE)

        purrr::map_dfr(resp_levels, function(resp_val) {
          # indicator for this response level (use un-namespaced update for S3 dispatch)
          des_i <- update(des0, .ind = as.numeric(df[[item]] == resp_val))

          purrr::map_dfr(grp_pairs, function(pair) {
            # subset with logical index to avoid NSE issues
            idx <- df[[gvar]] %in% pair
            if (!any(idx, na.rm = TRUE)) {
              return(
                tibble::tibble(
                  question = item, response = resp_val,
                  comp = paste0(.clean(pair[1]), "_v_", .clean(pair[2])),
                  ss = NA_integer_, d = NA_real_
                )
              )
            }

            des_pair <- subset(des_i, idx)
            # ensure both levels present in the subset
            present <- unique(df[[gvar]][idx])
            if (length(intersect(present, pair)) < 2) {
              tval <- NA_real_; dfv <- NA_real_; pval <- NA_real_
            } else {
              fmla <- stats::reformulate(termlabels = gvar, response = ".ind")
              tt <- tryCatch(survey::svyttest(fmla, design = des_pair), error = function(e) NULL)
              if (is.null(tt)) {
                tval <- NA_real_; dfv <- NA_real_; pval <- NA_real_
              } else {
                tval <- as.numeric(tt$statistic)
                dfv  <- as.numeric(tt$parameter)
                pval <- as.numeric(tt$p.value)
              }
            }

            tibble::tibble(
              question = item,
              response = resp_val,
              comp     = paste0(.clean(pair[1]), "_v_", .clean(pair[2])),
              ss       = ifelse(is.na(pval), NA_integer_, as.integer(pval < 0.05)),
              d        = ifelse(is.na(tval) | is.na(dfv), NA_real_, (2 * tval) / sqrt(dfv))  # Cohen's d from t
            )
          })
        })
      })
    })

    if (!is.null(tt_out) && nrow(tt_out) > 0) {
      # pivot to wide once; columns like "<comp>.ss" and "<comp>.d"
      tt_wide <- tt_out %>%
        tidyr::pivot_wider(
          names_from  = comp,
          values_from = c(ss, d),
          names_glue  = "{comp}.{.value}"
        )

      # append to your already-wide res (adds columns at the end)
      res <- dplyr::left_join(res, tt_wide, by = c("question", "response"))
    }
  }


    if (wide == F && spacing == T) {
      warning("Spacing is only available for wide format, set wide = TRUE for spacing.")
    }
    if (wide == T && spacing == T) {
      # --- Extra row between questions ---
      res <- res %>%
        dplyr::group_split(question) %>%
        purrr::map_dfr(~ dplyr::bind_rows(.x, tibble::tibble(
          question = "", response = "", !!!setNames(rep(list(NA), ncol(.x) - 2), names(.x)[-(1:2)])
        )))
      # Remove the final blank row
      res <- res[-nrow(res), ]

      # --- Extra column between groups, preserving non "^group\\." columns at the end ---
      if (!is.null(svygrp)) {
        # prefixes for grouped stats (e.g., overall., eligib., raceeth.)
        groups <- unique(gsub("\\..*$", "", names(res)[-c(1, 2)]))
        fixed  <- res[, 1:2, drop = FALSE]

        # columns belonging to any group block
        group_cols <- unlist(lapply(groups, function(g)
          grep(paste0("^", g, "\\."), names(res), value = TRUE)
        ), use.names = FALSE)

        # everything else (e.g., eligible_v_ineligible.ss / .d)
        other_cols <- setdiff(names(res), c(names(fixed), group_cols))

        group_blocks <- lapply(seq_along(groups), function(i) {
          g <- groups[i]
          cols <- grep(paste0("^", g, "\\."), names(res), value = TRUE)
          block <- res[, cols, drop = FALSE]
          if (i < length(groups)) block[paste0(strrep(" ", i))] <- NA
          block
        })

        # rebuild: question/response + grouped blocks + comparison columns at END
        res <- do.call(cbind, c(list(fixed), group_blocks, list(res[, other_cols, drop = FALSE])))
      }
    }
    return(res)
  }
