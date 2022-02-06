sample <- file.path(getwd(),"Land_Use_Rights","ricardian","25017_pc.pqt")
# sample edit 3
#randomForest implementation below (w/ ranger and h2o) is adapted from https://uc-r.github.io/random_forests

#load packages
library(arrow)
#install.packages('rsample')
library(rsample)      # data splitting 
#install.packages('randomForest')
library(randomForest) # basic implementation
#install.packages('ranger')
#devtools::install_github("imbs-hl/ranger")
library(ranger)       # a faster implementation of randomForest
library(caret)        # an aggregator package for performing many machine learning models
library(h2o)          # java-based platform; NOTE: needs JRE installed
#install.packages("prob")
library(prob)
library(dplyr)
library(tidyverse)



# load property data
system.time(
  places_df <- arrow::read_parquet(sample)
)

# subset df
places_ex <- places_df[1:500,1:100]

places_ex <- places_ex[, sapply(places_ex, class) != "character"] #  remove char vars




#split data into training and test subsets
places_split <- rsample::initial_split(places_ex, prop = .7)
places_train <- rsample::training(places_split)
places_test  <- rsample::testing(places_split)


#set seed for later replication
set.seed(150)

#basic Random Forest
rf1 <- randomForest(formula = ls_price~., data = places_train, na.action=na.roughfix)
print(rf1)

plot(rf1) #plot OOB error against no. of trees

which.min(rf1$mse) #find what forest size mins OOB


#Tuning

# get names of explanatory variables (features)
features <- setdiff(names(places_train), "ls_price")

#tune parameters
m2 <- tuneRF(
  x          = places_train[features],
  y          = places_train$ls_price,
  ntreeTry   = 500,
  mtryStart  = 5,
  stepFactor = 1.4,
  improve    = 0.001,
  trace      = FALSE 
) #why is optimal mtry not features/3? It's closer to sqrt(features). Does tuneRF think this is a classification rf?


#predict on train data
rf2_train <- predict(rf1,places_train)
rf2_train

#predict on test data
rf2_test <- predict(rf1,places_test)

#Var Importance
varImpPlot(rf1,
           sort = TRUE,
           n.var = ncol(places_train)-60,
           main = "Variable Importance")
importance(rf1)
varUsed(rf1, by.tree = FALSE, count = TRUE)

varImpPlot()


#RF w/ Ranger (faster)
places_ranger <- ranger::ranger(
  formula   = ls_price ~ ., 
  data      = places_train, 
  num.trees = 500,
  mtry      = floor(length(features) / 3)
)


#Advanced tuning w/ Ranger
#Construct hyperparameter grid to search diff combos of parameters
hyper_grid <- expand.grid(
  mtry = seq(20, 30, by = 2),
  node_size = seq(3, 9, by = 2),
  sampe_size = c(.55,.632,.70,.80),
  OOB_RMSE = 0 #empty now, will be filled later
)

#perform grid search to compare parameters' performance

for(i in 1:nrow(hyper_grid)) {
  
  # train model
  model <- ranger(
    formula = ls_price~.,
    data = places_train,
    num.trees = 500, #500 trees was enough to stabilize error
    mtry = hyper_grid$mtry[i],
    min.node.size = hyper_grid$node_size[i],
    sample.fraction = hyper_grid$sampe_size[i],
    seed = 150 #same as above but arbitrary
  )
  
  #extract OOB error from 'model' and add to 'hyper_grid'
  hyper_grid$OOB_RMSE[i] <- sqrt(model$prediction.error)
}

#View OOB errors added to hyper_grid to compare hyperparameter tunings

hyper_grid <- hyper_grid %>%
  arrange(OOB_RMSE)

#rerun random forest in ranger using optimal parameters found via grid search
optimal_ranger <- ranger(
  formula = ls_price~.,
  data = places_train,
  num.trees = 500,
  mtry = hyper_grid$mtry[1],
  min.node.size = hyper_grid$node_size[1],
  sample.fraction = hyper_grid$sampe_size[1],
  seed = 150, #same as above but arbitrary
  importance = 'impurity'
) 

print(optimal_ranger)#we can see that OOB is smaller and R-sq'd is greater (compared to rf1)!
print(rf1)#original, basic random forest model

#Variable importance plot
optimal_ranger$variable.importance %>%
  tidy() %>%
  arrange(desc(x)) %>%
  top_n(20) %>%
  ggplot(aes(reorder(names,x),x))+
  geom_col()+
  coord_flip()+
  scale_y_discrete(expand = expansion(mult = c(0, 0.05)))+
  ggtitle("Highest Importance Variables (Top 25)")


#find RMSE by hand
ranger_pred <- as.data.frame(ranger::predictions(optimal_ranger)) %>%
  tibble::rowid_to_column("ID")

places_train1 <- places_train %>%
  tibble::rowid_to_column("ID") %>%
  select(ID,ls_price)

ranger_error <-left_join(ranger_pred,places_train1,"ID") %>%
  rename(ranger = "ranger::predictions(optimal_ranger)") %>%
  mutate(sq_error = (ranger - ls_price)^2)

mean(ranger_error$sq_error)#RMSE (same as ranger's prediction error)

