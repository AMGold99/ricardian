####-------------------SCRATCHWORK, NOT RUN--------------####

# install.packages(c('arrow','dplyr','stringr'))
library(arrow)
library(dplyr)
library(stringr)


####-----------NOT FINAL, PATHS WILL CHANGE ONCE DATA IS AVAILABLE-----------####

# --NOT VALID-- set file path to data
sample <- file.path(getwd(),main_dir,sub_dir,"25017_pc.pqt")

# --NOT VALID-- specify all variables to be included in the model
variables = c('ls_price','slope','travel','elev','p_water')

####-------------------------------------------------------------------####



system.time(
  panel_model <- read_parquet(sample) %>%
    select(all_of(variables)) %>%
    lm(ls_price ~ ., .) %>%
    summary(.) %>%
    coef(.) %>%
    as.data.frame(.)
)




