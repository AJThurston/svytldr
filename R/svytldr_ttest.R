svytldr.ttest <- function(df,svyitem,svygrp,design){
  #Get all possible response options for svyitem
  res.opts <- df[,svyitem] %>%
    as.character() %>%
    na.exclude() %>%
    unique()
  res.opts <- res.opts[res.opts != "refused"]

  # Get all possible combinations of survey group
  grp.combs <- df[,svygrp] %>%
    as.character() %>%
    na.exclude() %>%
    unique() %>%
    combn(.,2) %>%
    split(., rep(1:ncol(.), each = nrow(.)))

  # Create empty results frame
  df.out = data.frame()

  for (i in res.opts) { # within each response option
    for (j in grp.combs) { # within the list of arrays
      formula <- as.formula(paste0(svyitem,"== '",i,"'"," ~ ",svygrp))
      design <- subset(dsgn, df[,svygrp] %in% j)
      t <- svyttest(formula, design = design)[[1]][[1]]
      out <- data.frame(item = svyitem,
                        response = i,
                        group1 = j[1],
                        group2 = j[2],
                        tval = t)
      df.out = rbind(df.out, out)
    }
  }
  print(as_tibble(df.out), n = Inf)
}
