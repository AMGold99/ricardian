library(arrow)
library(dplyr)
library(stringr)

#set parent and child directories
main_dir <- 'Land_Use_Rights'

sub_dir <- 'ricardian'

#set file path
sample <- file.path(getwd(),main_dir,sub_dir,"25017_pc.pqt")

variables = c('ls_price','slope','travel','elev','p_water')



system.time(
  panel_model <- read_parquet(sample) %>%
    select(all_of(variables)) %>%
    lm(ls_price ~ ., .) %>%
    summary(.) %>%
    coef(.) %>%
    as.data.frame(.)
)





#----------------PRACTICE---------------------------------#
practice <- read_parquet(sam_parq) %>%
  select(ls_price, ls_date, ha)

cleaned <- practice %>%
  filter(ls_date != "") %>%
  mutate(year = as.numeric(str_sub(ymd(ls_date),1,4))) %>%
  filter(year <= 2020)# %>%
  #str_split_fixed(practice$ls_date[which(str_detect(practice$ls_date,"~~")==TRUE)],"~~",n = 2)



