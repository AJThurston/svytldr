# Survey Topline Data in R - Primary Function
# Thurston, AJ
# 2020-09-08
#
# Version notes
# 2020-01-07 Start
# 2020-01-14 Combining M,SE,N results into one table
# 2022-09-08 Added an option for reformatting as an APA table
# 2025-08-17 Added features for significance testing and Cohen's d.

#' svytldr
#'
#' @param df A survey dataframe consisting of at minimum a survey item formatted as a factor variable.
#' @param ids Survey case ids (optional)
#' @param strata Survey strata (optional)
#' @param weights Survey weights (optional)
#' @param svyitem A survey item with factor (or ordered factor) format
#' @param svygrp A survey grouping variable, can be binary or multiple group, in factor format (optional)
#' @param wide Produces a formatted table with columns for each group and statistic (Default = TRUE)
#' @param significance Provides pairwise t-tests between svygrp levels for each item/response (Default = TRUE)
#' @param spacing Adds a blank row after each question and a blank column between each group when wide = TRUE (Default = TRUE)
#' @param fltr_refuse Filter refusals formatted 'refused' (Default = TRUE)
#' @param fltr_nas Filter NAs across dataframe (Default = TRUE)
#' @param flg_low_n Flag estimates with less than n = 100 in either svyitem response option or svygroup (or the combination thereof)
#' @param drop.overall Used in conjunction w. wide, drops the overall columns (Default = FALSE)
#' @param drop.m Used in conjunction w. wide, drops the columns for mean (Default = FALSE)
#' @param drop.m_se Used in conjunction w. wide, drops the columns for se(mean) (Default = FALSE)
#' @param drop.n Used in conjunction w. wide, drops the columns for sample size n (Default = FALSE)
#'
#' @return A tibble with M, SE, and unweighted Ns for each response for svyitem (or each response for svyitem within svygroup), significance testing, and Cohen's d values.
#' @export
#'
#' @examples
#' svytldr(df = df, ids = id, strata = strata, weights = wt, svyitem = "svyitem", svygrp = "group")
svytldr <- function (df, ids, strata, weights, svyitem, svygrp, fltr_refuse = T,
                     fltr_nas = T, flg_low_n = F, wide = T, significance = T, drop.overall = F, drop.m = F, drop.m_se = F, drop.n = F, spacing = T)
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
  if (significance && !missing(svygrp) && wide) {
    des0 <- df %>% dsgn

    .clean <- function(x) {
      x <- as.character(x)
      x <- gsub("[^A-Za-z0-9]+", ".", x)
      x <- gsub("\\.+", ".", x)
      x <- gsub("^\\.|\\.$", "", x)
      trimws(x)
    }

    tt_out <- purrr::map_dfr(svyitem, function(item) {
      resp_levels <- df[[item]] %>% as.character() %>% stats::na.omit() %>% unique()
      resp_levels <- resp_levels[resp_levels != "refused"]

      purrr::map_dfr(svygrp, function(gvar) {
        glv <- if (is.factor(df[[gvar]])) levels(df[[gvar]]) else df[[gvar]] %>% as.character() %>% stats::na.omit() %>% unique()
        glv <- glv[!is.na(glv)]
        if (length(glv) < 2) return(NULL)
        grp_pairs <- utils::combn(glv, 2, simplify = FALSE)

        purrr::map_dfr(resp_levels, function(resp_val) {
          des_i <- update(des0, .ind = as.numeric(df[[item]] == resp_val))

          purrr::map_dfr(grp_pairs, function(pair) {
            idx <- df[[gvar]] %in% pair
            if (!any(idx, na.rm = TRUE)) {
              return(tibble::tibble(
                question = item, response = resp_val,
                comp <- paste0(.clean(pair[1]), ".v.", .clean(pair[2])),
                ss = NA_integer_, d = NA_real_
              ))
            }
            des_pair <- subset(des_i, idx)
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
              comp     = paste0(.clean(pair[1]), ".v.", .clean(pair[2])),
              ss       = ifelse(is.na(pval), NA_integer_, as.integer(pval < 0.05)),
              d        = ifelse(is.na(tval) | is.na(dfv), NA_real_, (2 * tval) / sqrt(dfv))
            )
          })
        })
      })
    })

    if (!is.null(tt_out) && nrow(tt_out) > 0) {
      tt_wide <- tt_out %>%
        tidyr::pivot_wider(
          names_from  = comp,
          values_from = c(ss, d),
          names_glue  = "{comp}_{.value}"
        )
      res <- dplyr::left_join(res, tt_wide, by = c("question", "response"))
    }
  }

  # ---- Spacing subchain ----
  if (wide == T && spacing == T) {
    # --- Extra row between questions ---
    res <- res %>%
      dplyr::group_split(question) %>%
      purrr::map_dfr(~ dplyr::bind_rows(.x, tibble::tibble(
        question = "", response = "", !!!setNames(rep(list(NA), ncol(.x) - 2), names(.x)[-(1:2)])
      )))
    # Remove the final blank row
    res <- res[-nrow(res), ]

    # --- Extra column between groups; put ALL stats first, then ONE set of _ss/_d per svygrp ---
    if (!is.null(svygrp)) {
      .clean <- function(x) {
        x <- gsub("[^A-Za-z0-9]+", ".", x)
        x <- gsub("\\.+", ".", x)
        gsub("^\\.|\\.$", "", x)
      }
      .esc <- function(x) gsub("([][{}()+*.^$|\\\\?])", "\\\\\\1", x)

      all_names <- names(res)
      fixed     <- res[, 1:2, drop = FALSE]

      # variable blocks appear in this order: overall (if present), then each svygrp in the order supplied
      vars <- character(0)
      if (any(grepl("^overall\\.", all_names))) vars <- c(vars, "overall")
      vars <- c(vars, svygrp)

      var_blocks <- lapply(seq_along(vars), function(i) {
        v <- vars[i]

        # levels for this variable present in the wide table
        if (v == "overall") {
          levs_in_res <- "overall"
        } else {
          levs <- if (is.factor(df[[v]])) levels(df[[v]]) else unique(stats::na.omit(as.character(df[[v]])))
          # keep only levels that actually exist as prefixes in res
          levs_in_res <- Filter(function(L) any(grepl(paste0("^", .esc(L), "\\."), all_names)), levs)
        }
        if (length(levs_in_res) == 0) return(NULL)

        # 1) ALL group estimates first (m, m_se, n for every level of v, in level order)
        stat_cols_v <- unlist(lapply(levs_in_res, function(L) {
          grep(paste0("^", .esc(L), "\\.(m|m_se|n)$"), all_names, value = TRUE)
        }), use.names = FALSE)
        block <- res[, stat_cols_v, drop = FALSE]

        # 2) ONE set of comparison columns AFTER all stats (for v only)
        if (v != "overall" && length(levs_in_res) >= 2) {
          levs_clean <- .clean(levs_in_res)
          pairs <- utils::combn(levs_clean, 2, simplify = FALSE)
          cmp_bases <- vapply(pairs, function(p) paste0(p[1], ".v.", p[2]), character(1))
          # order: ..._ss then ..._d for each pair
          want <- as.vector(rbind(paste0(cmp_bases, "_ss"), paste0(cmp_bases, "_d")))
          cmp_cols <- want[want %in% all_names]   # keep only those that exist
          if (length(cmp_cols) > 0) block <- cbind(block, res[, cmp_cols, drop = FALSE])
        }

        # spacer after the whole variable block, except last
        if (i < length(vars)) block[paste0(strrep(" ", i))] <- NA
        block
      })

      var_blocks <- Filter(Negate(is.null), var_blocks)

      # Rebuild final table: question/response + per-variable blocks
      # (append any leftover columns, if any, to avoid accidental drops)
      included <- c(names(fixed), unlist(lapply(var_blocks, colnames), use.names = FALSE))
      leftover <- setdiff(all_names, included)
      res <- do.call(cbind, c(list(fixed), var_blocks,
                              if (length(leftover)) list(res[, leftover, drop = FALSE]) else list()))
    }
  }
  return(res)
}
