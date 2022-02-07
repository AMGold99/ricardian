# Ricardian Land Value
All code for Ricardian Land Value estimation paper. Authors: Gold, Binder, and Nolte.

Note: This README is an ongoing documentation of our work and should not be taken as final. I've tried to include caveats where I expect something to change significantly as we finalize data and analysis strategies. 

## Panel Model

My general strategy here is to load, clean, and model the data all in one pipeline, using magrittr's pipe (%>%), which allows you to make fewer copies of your data as you go along. 

First, we load the packages and specify where the data file (or files) reside. I want to keep this part vague for now, in case we want to utilize remote database storage. If so, [RSQLite](https://www.r-project.org/nosvn/pandoc/RSQLite.html) and associated packages like DBI should be considered.

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

## Random Forest Model (Basic -- Ignore)

randomForest.R 

## Random Forest Model (Upgraded with Ranger)

More detail to come.
