
<!-- README.md is generated from README.Rmd. Please edit that file -->

# svy.tldr

## Survey Tools for Limited Descriptive Research

<!-- badges: start -->
<!-- badges: end -->

The goal of svy.tldr is to provide basic, formatted values from complex
survey data. It is basically just a wrapper for the srvyr package. This
package is predominantly for working with factor variables.

## To-Do

-   Actually make IDS, Strata, and Weights optional, use “is.missing”
    from this answer:
    <https://stackoverflow.com/questions/28370249/correct-way-to-specifiy-optional-arguments-in-r-functions>  
-   Move away from pipes apparently

## Installation

You can install svy.tldr from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("AJThurston/svy.tldr")
```

## Dependencies

The following packages and versions are required to use `svy.tldr`:

-   survey (4.1-1)
-   srvyr (1.1.0)
-   tidyverse (1.3.2)

## Parameters

The `svy.tldr` package requires the following parameters:

-   df: A survey dataframe consisting of at minimum a survey item
    formatted as a factor variable.\[class = data.frame\]
-   ids: Survey case ids (optional) \[numeric\]
-   strata: Survey strata (optional) \[numeric\]
-   weights: Survey weights (optional) \[numeric\]
-   svyitem: A survey item with factor (or ordered factor) format
    \[factor\]

The following are optional parameters, but the `svygroup` parameter is
often used:

-   svygrp: A survey grouping variable, can be binary or multiple group,
    in factor format (optional) \[factor\]

These are other optional parameters that change the output of values:

-   fltr_refuse: Filter refusals formatted ‘refused’ (Default = TRUE)
    \[logical\]
-   fltr_nas: Filter NAs across dataframe (Default = TRUE) \[logical\]
-   flg_low_n: Flag estimates with less than n = 100 in either svyitem
    response option or svygroup (or the combination thereof) \[logical\]

Finally, this is just a simple formatting parameter to change the output
from long `tidy` format data to wide format as in typical survey
toplines or for papers:

-   fmttd_tbl: Produces a formatted table with columns for each group
    and statistic (Default = F; statistics nested w/in group)
    \[logical\]

## Example dataframe `svy.tldr.df`

The following example dataframe is the `apistrat` dataset from the
`survey` package with some minor modifications to make the output of
`svy.tldr` easier to interpret.

``` r
library(svy.tldr)
library(srvyr)
library(survey)
library(tidyverse)

load(file='data/svy.tldr.df.rda')
```

## Examples

### Example 1 - Basic Use

This example uses the minimum parameters of the `svy.tldr` to produce
the means, standard error of the means, and unweighted counts for a
factor variable survey response. Output is a `tidy` style output table
with the grouping variable (in this case, only “overall”), the response
options for the survey item, and the values mentioned above.

In this example, data from `apistrat` dataset using the `sch.wide`
variable which is a binary factor variable for whether or not the PSU
achieve its school wide goals. As in the above, I recoded it to whether
or not the school achieved or did not achieve its goals.

``` r
svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal")
#> # A tibble: 2 x 5
#> # Groups:   group [1]
#>   group   metgoal      m   m_se     n
#>   <fct>   <chr>    <dbl>  <dbl> <int>
#> 1 overall Achieved 0.818 0.0250   154
#> 2 overall Unachiev 0.167 0.0241    48
```

### Example 2 - Use with Groups with `svygrp`

This is the same as the example above, except the output is now grouped
by whether or not the school was eligible for awards
(Eligible/Ineligible). Again, the default is a `tidy` style output
table, but the grouping variable includes overall, eligible, and
ineligible.

``` r
svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib")
#> # A tibble: 6 x 5
#> # Groups:   group [3]
#>   group    metgoal       m    m_se     n
#>   <chr>    <chr>     <dbl>   <dbl> <int>
#> 1 overall  Achieved 0.818  0.0250    154
#> 2 overall  Unachiev 0.167  0.0241     48
#> 3 Eligible Achieved 0.986  0.00793   114
#> 4 Eligible Unachiev 0.0138 0.00793     3
#> 5 Ineligib Achieved 0.546  0.0588     40
#> 6 Ineligib Unachiev 0.454  0.0588     45
```

### Example 3 - Filter Refusals with `fltr_refuse`

The default behavior of `svy.tldr` is to filter refusals, but this
function can be turned off if refusals are of value to you. In this
example, there are no refusals.

``` r
svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         fltr_refuse = F)
#> # A tibble: 7 x 5
#> # Groups:   group [3]
#>   group    metgoal        m    m_se     n
#>   <chr>    <chr>      <dbl>   <dbl> <int>
#> 1 overall  Achieved 0.818   0.0250    154
#> 2 overall  Refused  0.00556 0.00397     2
#> 3 overall  Unachiev 0.167   0.0241     48
#> 4 Eligible Achieved 0.986   0.00793   114
#> 5 Eligible Unachiev 0.0138  0.00793     3
#> 6 Ineligib Achieved 0.546   0.0588     40
#> 7 Ineligib Unachiev 0.454   0.0588     45
```

### Example 4 - Flag low sample size subgroups with `flg_low_n`

If working with larger datasets, you can flag estimates from smaller (N
\< 100) sample size subgroups. The default behavior is to not flag these
estimates. Currently, the size of the flag (i.e., 100) is not
adjustable. This creates a new value where 0 = not flagged, 1 = flagged.

``` r
svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         flg_low_n = T)
#> # A tibble: 6 x 6
#> # Groups:   group [3]
#>   group    metgoal       m    m_se     n low_n_flg
#>   <chr>    <chr>     <dbl>   <dbl> <int>     <dbl>
#> 1 overall  Achieved 0.818  0.0250    154         0
#> 2 overall  Unachiev 0.167  0.0241     48         1
#> 3 Eligible Achieved 0.986  0.00793   114         0
#> 4 Eligible Unachiev 0.0138 0.00793     3         1
#> 5 Ineligib Achieved 0.546  0.0588     40         1
#> 6 Ineligib Unachiev 0.454  0.0588     45         1
```

### Example 5 - Filter NA responses or groups with `fltr_nas`

By default, all output data from `svy.tldr` with groups or responses
which are `NA` are filtered.

``` r
svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         fltr_refuse = F,
         fltr_nas = F)
#> # A tibble: 10 x 5
#> # Groups:   group [4]
#>    group    metgoal        m    m_se     n
#>    <chr>    <chr>      <dbl>   <dbl> <int>
#>  1 overall  Achieved 0.818   0.0250    154
#>  2 overall  Refused  0.00556 0.00397     2
#>  3 overall  Unachiev 0.167   0.0241     48
#>  4 overall  <NA>     0.00930 0.00733     2
#>  5 Eligible Achieved 0.986   0.00793   114
#>  6 Eligible Unachiev 0.0138  0.00793     3
#>  7 Ineligib Achieved 0.546   0.0588     40
#>  8 Ineligib Unachiev 0.454   0.0588     45
#>  9 <NA>     Refused  0.374   0.250       2
#> 10 <NA>     <NA>     0.626   0.250       2
```

### Example 6 - Present group results as columns with `fmttd_tbl`

This parameter changes the output from tidy format to wide format.

``` r
fmttd <- svy.tldr(df = svy.tldr.df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         fmttd_tbl = T)

fmttd %>%
  kbl() %>%
  kable_classic(full_width = F)
```

![](https://github.com/AJThurston/svy.tldr/man/figures/ex6.PNG)
