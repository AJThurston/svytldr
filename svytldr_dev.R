library(devtools)

# create_package(""C:\\Users\\AJ Thurston\\Documents\\GitHub\\svy.tldr"")

load_all()

document()

library(survey)
library(haven)
library(summarytools)
library(tidyverse)
library(srvyr)



# Original YRBSS data 2019, bless the SAScii package for overcoming this format...



# install_github("ajdamico/lodown")
library(lodown)
# http://asdfree.com/youth-risk-behavior-surveillance-system-yrbss.html

# lodown( "yrbss" , output_dir = file.path( path.expand( "~" ) , "YRBSS" ) )

yrbss_cat <-
  get_catalog( "yrbss" ,
               output_dir = file.path( path.expand( "~" ) , "YRBSS" ) )
yrbss_cat <- subset( yrbss_cat , year == 2019 )
yrbss_cat <- lodown( "yrbss" , yrbss_cat )


yrbss_df <- readRDS( file.path( path.expand( "~" ) , "YRBSS" , "2019 main.rds" ) )

colnames(yrbss_df)

print(dfSummary(yrbss_df), method = "browser")

yrbs <- yrbss_df %>%
  select(., psu, stratum, weight, age, sex, race4, race7, q8, q67, q77)
# set.seed(12345)
# yrbs <- yrbs[sample(nrow(yrbs), size= 5000), ]



yrbs$sex <- yrbs$sex %>%
  recode_factor(.,
                `1` = "Female",
                `2` = "Male")

yrbs$race <- yrbs$race4 %>%
  recode_factor(.,
                `1` = "White",
                `2` = "Black",
                `3` = "Hispanic",
                `4` = "Other")

yrbs$age <- yrbs$age %>%
  recode_factor(.,
                `1` = "12 years old and younger",
                `2` = "13 years old",
                `3` = "14 years old",
                `4` = "15 years old",
                `5` = "16 years old",
                `6` = "17 years old",
                `7` = "18 years old or older")

yrbs$q8 <- yrbs$q8 %>%
  recode_factor(.,
                `1` = "Rarely or Never",
                `2` = "Rarely or Never",
                `3` = "Sometimes",
                `4` = "Most of the time",
                `5` = "Always")

yrbs$q67 <- yrbs$q67 %>%
  recode_factor(.,
                `1` = "Very underweight",
                `2` = "Slightly underweight",
                `3` = "About the right weight",
                `4` = "Slightly overweight",
                `5` = "Very overweight")

yrbs$q77 <- yrbs$q77 %>%
  recode_factor(.,
                `1` = "0 days",
                `2` = "1 day",
                `3` = "2 days",
                `4` = "3 days",
                `5` = "4 days",
                `6` = "5 days",
                `7` = "6 days",
                `8` = "7 days")

head(yrbs)


# write.csv(yrbs, "C:\\Users\\AJ Thurston\\Desktop\\yrbs.csv")


dsgn <-
  svydesign(
    ids = ~psu,
    strata = ~stratum,
    data = yrbs,
    weights = ~ weight,
    nest = TRUE
  )



options( survey.lonely.psu = "adjust" )

res <- yrbs %>%
  as_survey_design(ids = psu, strata = stratum, weights = weight, nest = T) %>%
  group_by(sex, q8, .drop = FALSE) %>%
  summarize(m = survey_mean(), n = unweighted(n())) %>%
  filter(q8 == "Rarely or Never")


svyby( ~ q8 , ~ sex , dsgn , svymean , na.rm = TRUE )

print(res, n = Inf)

