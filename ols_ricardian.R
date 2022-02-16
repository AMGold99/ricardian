####-------------------SCRATCHWORK, NOT RUN--------------####

# install.packages(c('arrow','dplyr','stats'))
library(arrow)
library(dplyr)
library(stats)
library(magrittr)
library(xtable)


####-----------NOT FINAL, PATHS WILL CHANGE ONCE DATA IS AVAILABLE-----------####

# --NOT VALID-- set file path to data
sample <- file.path("../25017_pc.pqt")

# --NOT VALID-- specify all variables to be included in the model
model_variables = c('ls_price','slope','travel','elev','p_water')

####-------------------------------------------------------------------####


# create dataframe of ols regression where cols are stats 
# (coefs, p-values, std errors, etc.) and rows are intercept and exp variables
system.time(
  
  ols_model_df <- arrow::read_parquet(sample) %>%
    
    dplyr::select(all_of(model_variables)) %>%
    
    stats::lm(ls_price ~ ., .) %>%
    
    summary(.) %>%
    
    stats::coef(.) %>%
    
    as.data.frame(.)
)


# create LaTeX regression summary table
system.time(
 
  ols_xtable <- arrow::read_parquet(sample) %>%
    
    dplyr::select(all_of(model_variables)) %>%
    
    stats::lm(ls_price ~ ., .) %>%
    
    xtable::xtable(.)
    
)