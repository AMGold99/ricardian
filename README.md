# Ricardian Land Value
All code for Ricardian Land Value estimation paper. Authors: Gold, Binder, and Nolte.

*Note: This README is an ongoing documentation of our work and should not be taken as final. I've tried to include caveats where I expect something to change significantly as we finalize data and analysis strategies.*

## Panel Model

My general strategy here is to load, clean, and model the data all in one pipeline, using magrittr's pipe (%>%), which allows you to make fewer copies of your data as you go along. 

First, we load the packages and specify where the data file (or files) reside. I want to keep this part vague for now, in case we want to utilize remote database storage. If so, [RSQLite](https://www.r-project.org/nosvn/pandoc/RSQLite.html) and associated packages like DBI should be considered. I assume Google Drive won't be sufficient, but that's also worth a shot, as the [googledrive package](https://googledrive.tidyverse.org/) allows for seamless integration with Drive directories.

Next, we specify the names of all the variables we want to include in our model, both the outcome **y** (ls_price) and the vector of explanatory variables **X**.

The general setup is as follows:

```r
panel_model <- arrow::read_parquet(sample) %>%
    dplyr::select(all_of(model_variables)) %>%
    stats::lm(ls_price ~ ., .) %>%
    summary(.) %>%
    stats::coef(.) %>%
    as.data.frame(.)

```

Here's a brief run-down:

1. Using the arrow package, we load the data (in parquet format);
2. We then select only the variables we specified earlier as **y** and **X**;
3. We run a basic regression of **X** on **y**. This can be replaced with a panel model specification from the [plm package](https://cran.r-project.org/web/packages/plm/index.html).
4. After calling a summary of the model, we extract the coefficients and standard errors, then coerce them into a dataframe object. This final dataframe of coefs is what gets saved as **panel_model**.
5. To present these coefs in a paper, I suggest using the **xtable** function from the [xtable package](https://www.rdocumentation.org/packages/xtable/versions/1.8-4/topics/xtable). [Stargazer](https://cran.r-project.org/web/packages/stargazer/vignettes/stargazer.pdf) is another popular R package for presenting results and summary statistics tables in HTML or LaTeX. This function takes as input a regression object (right after step 3 above). 

Note: the periods in the code above are used in pipe-based workflows to specify the object created up to that point in the pipe.

## Random Forest Model (Basic -- Ignore)

randomForest.R contains a ton of code for a basic random forest implementation with the base [randomForest package](https://cran.r-project.org/web/packages/randomForest/index.html). Unfortunately, randomForest scales poorly, quickly getting bogged down with larger datasets and more intensive forest modeling (e.g., greater numbers of features tried at each split, commonly denoted as "mtry").

To fix this problem, I've moved to the [ranger package](https://arxiv.org/pdf/1508.04409.pdf), which vastly improves performance for big data use compared to randomForest or other older packages like Rborist.

## Random Forest Model (Upgraded with Ranger)

### General workflow

1. Load packages and data;
2. Clean the data (remove character variables, impute missing values, specify vector **X** of explanatory variables);
3. Split data into test and train;
4. Run preliminary ranger random forest model;
5. Construct hypergrid of parameter options and run grid search;
6. Run ranger random forest model using optimal parameters found in grid search;
7. Build variable importance plot
8. Test model (**is this necessary?**)



