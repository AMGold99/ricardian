####-------------------SCRATCHWORK, NOT RUN--------------####

# install.packages(c('arrow','dplyr','stats'))
library(arrow)
library(dplyr)
library(stats)


####-----------NOT FINAL, PATHS WILL CHANGE ONCE DATA IS AVAILABLE-----------####

# --NOT VALID-- set file path to data
sample <- file.path(getwd(),main_dir,sub_dir,"25017_pc.pqt")

# --NOT VALID-- specify all variables to be included in the model
model_variables = c('ls_price','slope','travel','elev','p_water')

####-------------------------------------------------------------------####



system.time(
  ols_model <- arrow::read_parquet(sample) %>%
    dplyr::select(all_of(model_variables)) %>%
    stats::lm(ls_price ~ ., .) %>%
    summary(.) %>%
    stats::coef(.) %>%
    as.data.frame(.)
)

panel_model



