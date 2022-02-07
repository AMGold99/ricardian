# Ricardian Land Value
All code for Ricardian Land Value estimation paper. Authors: Gold, Binder, and Nolte.

## Panel Model

My general strategy here is to load, clean, and model the data all in one pipeline, using magrittr's pipe (%>%), which allows you to make fewer copies of your data as you go along. 

First, we load the packages and specify where the data file (or files) reside. I want to keep this part vague for now, in case we want to utilize remote database storage. If so, [RSQLite](https://www.r-project.org/nosvn/pandoc/RSQLite.html) and associated packages like DBI should be considered.

Next, we specify the names of all the variables we want to include in our model, both the outcome **y** and the vector of explanatory variables **X**.

## Random Forest Model (Basic)

More detail to come.

## Random Forest Model (Upgraded with Ranger)

More detail to come.
