% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/svytldr_missing.R
\name{svytldr_missing}
\alias{svytldr_missing}
\title{svy.tldr.fac_clean_missing.  A function for cleaning different missing data in factor variables simply.  Recodes factor variables to character for simple recoding with \code{gsub} and converts back to factor variables.}
\usage{
svytldr_missing(df, missing_list, clean_val_labs = F)
}
\arguments{
\item{df}{A survey dataframe consisting of some factor variable.}

\item{missing_list}{A list of strings identified as missing, for gsub function, for example, -99, -98, and -97 missing is "-9.*"}

\item{clean_val_labs}{Clean (remove) variable labels from factor variables}
}
\value{
A survey dataframe with
}
\description{
svy.tldr.fac_clean_missing.  A function for cleaning different missing data in factor variables simply.  Recodes factor variables to character for simple recoding with \code{gsub} and converts back to factor variables.
}
\examples{
svytldr(df = df, ids = id, strata = strata, weights = wt, svyitem = "svyitem", svygrp = "group")
}
