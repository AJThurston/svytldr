
<!-- README.md is generated from README.Rmd. Please edit that file -->

# svytldr

## Survey Tools for Limited Descriptive Research

<!-- badges: start -->
<!-- badges: end -->

The goal of svytldr is to provide basic, formatted values from complex
survey data. It is basically just a wrapper for the srvyr package. This
package is predominantly for working with factor variables.

## To-Do

- Actually make IDS, Strata, and Weights optional, use “is.missing” from
  this answer:
  <https://stackoverflow.com/questions/28370249/correct-way-to-specifiy-optional-arguments-in-r-functions>  
- Move away from pipes apparently

## Installation

You can install svytldr from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("AJThurston/svytldr")
```

## Dependencies

The following packages and versions are required to use `svytldr`:

- survey (4.1-1)
- srvyr (1.1.0)
- tidyverse (1.3.2)

## Arguments

The `svytldr` function requires the following arguments:

- df: A survey dataframe consisting of at minimum a survey item
  formatted as a factor variable.\[class = data.frame\]
- ids: Survey case ids (optional) \[numeric\]
- strata: Survey strata (optional) \[numeric\]
- weights: Survey weights (optional) \[numeric\]
- svyitem: A survey item with factor (or ordered factor) format, or list
  of factor variables \[factor\]

The following are optional arguments, but the `svygroup` argument is
often used:

- svygrp: A survey grouping variable, can be binary or multiple group,
  in factor format, or list of factor variables (optional) \[factor\]

These are other optional arguments that change the output of values:

- fltr_refuse: Filter refusals formatted ‘refused’ (Default = TRUE)
  \[logical\]
- fltr_nas: Filter NAs across dataframe (Default = TRUE) \[logical\]
- flg_low_n: Flag estimates with less than n = 100 in either svyitem
  response option or svygroup (or the combination thereof) \[logical\]

Finally, this is just a simple formatting argument to change the output
from long `tidy` format data to wide format as in typical survey
toplines or for papers:

- wide: Produces a formatted table with columns for each group and
  statistic (Default = F; statistics nested w/in group) \[logical\]

## Example dataframe `svytldr_df`

The following example dataframe is the `apistrat` dataset from the
`survey` package with some minor modifications to make the output of
`svytldr` easier to interpret.

``` r
library(svytldr)
library(srvyr)
library(survey)
library(tidyverse)

data(svytldr_df)
```

## Examples - `svytldr`

### Example 1 - Basic Use

This example uses the minimum arguments of the `svytldr` to produce the
means, standard error of the means, and unweighted counts for a factor
variable survey response. Output is a `tidy` style output table with the
grouping variable (in this case, only “overall”), the response options
for the survey item, and the values mentioned above.

In this example, data from `svytldr_df` dataset using the `metgoal`
variable which is a binary factor variable for whether or not the person
met their goal.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal")
#> # A tibble: 2 x 6
#> # Groups:   group [1]
#>   question response group       m   m_se     n
#>   <chr>    <fct>    <fct>   <dbl>  <dbl> <int>
#> 1 metgoal  achieved overall 0.818 0.0250   154
#> 2 metgoal  unachiev overall 0.167 0.0241    48
```

Additionally, multiple items can be added as a list. In the latter
example, the `green` variable is a likert type item corresponding to
those who dislike the color green, are neutral on the color, or like the
color.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = c("metgoal","green"))
#> # A tibble: 5 x 6
#> # Groups:   group [1]
#>   question response group       m   m_se     n
#>   <chr>    <fct>    <fct>   <dbl>  <dbl> <int>
#> 1 metgoal  achieved overall 0.818 0.0250   154
#> 2 metgoal  unachiev overall 0.167 0.0241    48
#> 3 green    dislikes overall 0.330 0.0357    69
#> 4 green    likes    overall 0.329 0.0360    66
#> 5 green    neutral  overall 0.341 0.0361    71
```

### Example 2 - Use with Groups with `svygrp`

This is the same as the example above, except the output is now grouped
by whether or not the case was eligible (Eligible/Ineligible). Again,
the default is a `tidy` style output table, but the grouping variable
includes overall, eligible, and ineligible.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib")
#> # A tibble: 6 x 6
#> # Groups:   group [3]
#>   question response group         m    m_se     n
#>   <chr>    <fct>    <fct>     <dbl>   <dbl> <int>
#> 1 metgoal  achieved overall  0.818  0.0250    154
#> 2 metgoal  unachiev overall  0.167  0.0241     48
#> 3 metgoal  achieved eligible 0.986  0.00793   114
#> 4 metgoal  unachiev eligible 0.0138 0.00793     3
#> 5 metgoal  achieved ineligib 0.546  0.0588     40
#> 6 metgoal  unachiev ineligib 0.454  0.0588     45
```

Additionally, multiple groups can be added as a list. In this example,
the `raceeth` variable corresponds to participants reported
race/ethncity where `wnh` is White, non-Hispanic, `bnh` is Black,
non-Hispanic, `his` is Hispanic, and `anh` is Asian, non-Hispanic.

For multiple groups, groups are not combined as in the `interaction`
function; each group is tested independently.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = c("eligib","raceeth"))
#> # A tibble: 14 x 6
#> # Groups:   group [7]
#>    question response group         m    m_se     n
#>    <chr>    <fct>    <fct>     <dbl>   <dbl> <int>
#>  1 metgoal  achieved overall  0.818  0.0250    154
#>  2 metgoal  unachiev overall  0.167  0.0241     48
#>  3 metgoal  achieved eligible 0.986  0.00793   114
#>  4 metgoal  unachiev eligible 0.0138 0.00793     3
#>  5 metgoal  achieved ineligib 0.546  0.0588     40
#>  6 metgoal  unachiev ineligib 0.454  0.0588     45
#>  7 metgoal  achieved anh      0.779  0.122      10
#>  8 metgoal  unachiev anh      0.221  0.122       3
#>  9 metgoal  achieved bnh      0.841  0.0637     23
#> 10 metgoal  unachiev bnh      0.159  0.0637      7
#> 11 metgoal  achieved his      0.795  0.0585     32
#> 12 metgoal  unachiev his      0.148  0.0488     10
#> 13 metgoal  achieved wnh      0.826  0.0325     89
#> 14 metgoal  unachiev wnh      0.169  0.0323     28
```

### Example 3 - Filter Refusals with `fltr_refuse`

The default behavior of `svytldr` is to filter refusals, but this
function can be turned off if refusals are of value to you. In this
example, there are no refusals.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         fltr_refuse = F)
#> # A tibble: 9 x 6
#> # Groups:   group [3]
#>   question response group          m    m_se     n
#>   <chr>    <fct>    <fct>      <dbl>   <dbl> <int>
#> 1 metgoal  achieved overall  0.818   0.0250    154
#> 2 metgoal  refused  overall  0.00556 0.00397     2
#> 3 metgoal  unachiev overall  0.167   0.0241     48
#> 4 metgoal  achieved eligible 0.986   0.00793   114
#> 5 metgoal  refused  eligible 0       0           0
#> 6 metgoal  unachiev eligible 0.0138  0.00793     3
#> 7 metgoal  achieved ineligib 0.546   0.0588     40
#> 8 metgoal  refused  ineligib 0       0           0
#> 9 metgoal  unachiev ineligib 0.454   0.0588     45
```

### Example 4 - Filter NA responses or groups with `fltr_nas`

By default, all output data from `svytldr` with groups or responses
which are `NA` are filtered.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         fltr_refuse = F,
         fltr_nas = F)
#> # A tibble: 14 x 6
#> # Groups:   group [4]
#>    question response group          m    m_se     n
#>    <chr>    <fct>    <fct>      <dbl>   <dbl> <int>
#>  1 metgoal  achieved overall  0.818   0.0250    154
#>  2 metgoal  refused  overall  0.00556 0.00397     2
#>  3 metgoal  unachiev overall  0.167   0.0241     48
#>  4 metgoal  <NA>     overall  0.00930 0.00733     2
#>  5 metgoal  achieved eligible 0.986   0.00793   114
#>  6 metgoal  refused  eligible 0       0           0
#>  7 metgoal  unachiev eligible 0.0138  0.00793     3
#>  8 metgoal  achieved ineligib 0.546   0.0588     40
#>  9 metgoal  refused  ineligib 0       0           0
#> 10 metgoal  unachiev ineligib 0.454   0.0588     45
#> 11 metgoal  achieved <NA>     0       0           0
#> 12 metgoal  refused  <NA>     0.374   0.250       2
#> 13 metgoal  unachiev <NA>     0       0           0
#> 14 metgoal  <NA>     <NA>     0.626   0.250       2
```

### Example 5 - Flag low sample size subgroups with `flg_low_n`

If working with larger datasets, you can flag estimates from smaller (N
\< 100) sample size subgroups. The default behavior is to not flag these
estimates. Currently, the size of the flag (i.e., 100) is not
adjustable. This creates a new value where 0 = not flagged, 1 = flagged.

``` r
svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         flg_low_n = T)
#> # A tibble: 6 x 7
#> # Groups:   group [3]
#>   question response group         m    m_se     n low_n_flg
#>   <chr>    <fct>    <fct>     <dbl>   <dbl> <int>     <dbl>
#> 1 metgoal  achieved overall  0.818  0.0250    154         0
#> 2 metgoal  unachiev overall  0.167  0.0241     48         1
#> 3 metgoal  achieved eligible 0.986  0.00793   114         0
#> 4 metgoal  unachiev eligible 0.0138 0.00793     3         1
#> 5 metgoal  achieved ineligib 0.546  0.0588     40         1
#> 6 metgoal  unachiev ineligib 0.454  0.0588     45         1
```

### Example 6 - Present group results as columns with `wide`

This argument changes the output from tidy format to wide format.

``` r
fmttd <- svytldr(df = svytldr_df,
         ids = "id",
         strata = "st",
         weights = "wt",
         svyitem = "metgoal",
         svygrp = "eligib",
         wide = T)

library(kableExtra)
fmttd %>%
  kbl() %>%
  kable_classic(full_width = F)
```

![](https://github.com/AJThurston/svytldr/blob/main/man/figures/ex6.PNG)

## Example - `svytldr_missing`

This helper cleaning function is designed to help clean factor variables
from SPSS datasets when imported using the `foreign` package. These
values from these datasets sometimes come in the form of “value: value
label”. The goal of this function is to preserve the underlying factor
variable while allowing some basic cleaning.

The variable `motiv` in the `svytldr_df` is used for illustrating this
function. It contains the following possible values:

- 1: intrinsic
- 2: extrinsic
- 3: other
- -100
- -99
- -98
- -97

The `svytldr_missing` function requires the following arguments:

- df: A survey dataframe consisting of at minimum a survey item
  formatted as a factor variable.\[class = data.frame\]
- missing_list: A list of missing values, gsub strings can be included
  in the list (e.g., “-9.\*“) to remove all values starting with or
  ending with a particular value. Identified values are recoded to `NA`
  \[list\]

The following argument is optional:

- clean_val_labs = Will remove SPSS style value labels (before: “value:
  value label”) to value as factor (after: “value”), default is `FALSE`
  \[logical\]

### Before

``` r
library(summarytools)
freq(svytldr_df$motiv)
#> Frequencies  
#> svytldr_df$motiv  
#> Type: Factor  
#> 
#>                      Freq   % Valid   % Valid Cum.   % Total   % Total Cum.
#> ------------------ ------ --------- -------------- --------- --------------
#>       1: intrinsic     58     28.16          28.16     28.16          28.16
#>       2: extrinsic     91     44.17          72.33     44.17          72.33
#>           3: other     57     27.67         100.00     27.67         100.00
#>               <NA>      0                               0.00         100.00
#>              Total    206    100.00         100.00    100.00         100.00
```

### After

``` r
svytldr_df <- svytldr_df %>%
  svytldr_missing(., 
                  missing_list = c("-100","-9.*"))
freq(svytldr_df$motiv)
#> Frequencies  
#> svytldr_df$motiv  
#> Type: Factor  
#> 
#>                      Freq   % Valid   % Valid Cum.   % Total   % Total Cum.
#> ------------------ ------ --------- -------------- --------- --------------
#>       1: intrinsic     58     28.16          28.16     28.16          28.16
#>       2: extrinsic     91     44.17          72.33     44.17          72.33
#>           3: other     57     27.67         100.00     27.67         100.00
#>               <NA>      0                               0.00         100.00
#>              Total    206    100.00         100.00    100.00         100.00
```

Removing the SPSS value labels.

``` r
freq(svytldr_df$motiv)
#> Frequencies  
#> svytldr_df$motiv  
#> Type: Factor  
#> 
#>                      Freq   % Valid   % Valid Cum.   % Total   % Total Cum.
#> ------------------ ------ --------- -------------- --------- --------------
#>       1: intrinsic     58     28.16          28.16     28.16          28.16
#>       2: extrinsic     91     44.17          72.33     44.17          72.33
#>           3: other     57     27.67         100.00     27.67         100.00
#>               <NA>      0                               0.00         100.00
#>              Total    206    100.00         100.00    100.00         100.00
df <- svytldr_missing(svytldr_df, 
                missing_list = c("-100","-9.*"),
                clean_val_labs = T)
freq(df$motiv)
#> Frequencies  
#> df$motiv  
#> Type: Factor  
#> 
#>               Freq   % Valid   % Valid Cum.   % Total   % Total Cum.
#> ----------- ------ --------- -------------- --------- --------------
#>           1     58     28.16          28.16     28.16          28.16
#>           2     91     44.17          72.33     44.17          72.33
#>           3     57     27.67         100.00     27.67         100.00
#>        <NA>      0                               0.00         100.00
#>       Total    206    100.00         100.00    100.00         100.00
```
