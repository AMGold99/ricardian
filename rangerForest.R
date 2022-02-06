#============================
#
#    Ranger Random Forest
#
#============================




#### Preamble ####

#load packages

#library(caret) # an aggregator package for performing many machine learning models
  
library(arrow)
library(h2o) # parallel computing for faster hyperparameter tuning
library(rsample)
library(ranger)
library(prob)
library(dplyr)
library(tidyverse)
library(stats)
library(missRanger)


# specify data file location
sample <- file.path(getwd(),"Land_Use_Rights","ricardian","25017_pc.pqt")

# load property data (1.326 sec)
system.time(
  places_df <- arrow::read_parquet(sample)
)
 


#### Cleaning ####

# remove character features 
places_numeric <- places_df[, sapply(places_df, class) != "character"]



system.time(
  
  places_full <- missRanger::missRanger(places_numeric[1:10000, 1:100],
                                        pmm.k = 1,
                                        num.trees = 50, 
                                        sample.fraction = 0.1,
                                        splitrule = "extratrees",
                                        maxiter = 2,
                                        max.depth = 6
                                        )
)

input_features <- prob::setdiff(names(places_full),"ls_price")



#### Random Forest Model ####


#set seed for later replication
seed <- 150
set.seed(seed)


#split data into training and test subsets
places_split <- rsample::initial_split(places_full, prop = .7)
places_train <- rsample::training(places_split)
places_test  <- rsample::testing(places_split)



#RF w/ Ranger (faster)
places_ranger <- ranger::ranger(
  formula   = ls_price ~ ., 
  data      = places_train, 
  num.trees = 500,
  mtry      = floor(length(input_features) / 3)
)

print(places_ranger)






#### Tune Hyperparameters ####

# Advanced tuning w/ Ranger
# Construct hyperparameter grid to search diff combos of parameters
hyper_grid <- expand.grid(
  mtry = seq(20, 30, by = 2),
  node_size = seq(3, 9, by = 2),
  sample_size = c(.55,.632,.70,.80),
  OOB_RMSE = 0 #empty now, will be filled later
)

# perform grid search to compare parameters' performance

for(i in 1:nrow(hyper_grid)) {
  
  # train model
  model <- ranger(
    formula = ls_price~.,
    data = places_train,
    num.trees = 500, #500 trees was enough to stabilize error
    mtry = hyper_grid$mtry[i],
    min.node.size = hyper_grid$node_size[i],
    sample.fraction = hyper_grid$sample_size[i],
    seed = seed #same as above but arbitrary
  )
  
  # extract OOB error from 'model' and add to 'hyper_grid'
  hyper_grid$OOB_RMSE[i] <- sqrt(model$prediction.error)
}

# View OOB errors added to hyper_grid to compare hyperparameter tunings

hyper_grid <- hyper_grid %>%
  arrange(OOB_RMSE)

# rerun random forest in ranger using optimal parameters found via grid search
optimal_ranger <- ranger(
  formula = ls_price~.,
  data = places_train,
  num.trees = 500,
  mtry = hyper_grid$mtry[1],
  min.node.size = hyper_grid$node_size[1],
  sample.fraction = hyper_grid$sample_size[1],
  seed = seed, #same as above but arbitrary
  importance = 'impurity'
) 

print(optimal_ranger) # we can see that OOB is smaller and R^2 is greater




#### Variable Importance Plot ####

# top n most important variables
n = 11

# create plot
data.frame('values' = optimal_ranger$variable.importance,
                      'names' = names(optimal_ranger$variable.importance)) %>%
  
  dplyr::arrange(desc(values)) %>%
  
  dplyr::top_n(n) %>%
  
  ggplot2::ggplot(aes(stats::reorder(names,values),values))+
  
  geom_point(shape = 21, size = 2.5, fill = "white", colour = "black", stroke = 0.5)+
  
  coord_flip()+
  
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))+
  
  ggtitle(paste0("Highest Importance Variables (Top ",n,")"))+
  
  ylab("Mean Gini Impurity Decrease")+
  xlab("")+
  
  theme_bw()



#### Model Testing ####

predictions <- stats::predict(optimal_ranger, data = places_test)
summary(predictions$predictions - places_test$ls_price)


