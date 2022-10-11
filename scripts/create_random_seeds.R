#!/bin/env/Rscript

## ------------------------------------------------------------------
## Setup
## ------------------------------------------------------------------

# flag for debugging or not
DEBUG = FALSE

## Note
##
## Whatever you specify in the snakemake file will be available as a
## S4 object called "snakemake" if you use the "script" prompt to
## run your code (instead of using "shell"). The slots of the S4
## object 
##  (a) will be named according to the names you specify in the
##      snakemake script and 
##  (b) will be a list object
## you'll see how this works below
##
## If you want to debug your code that you'll feed into snakemake,
## it's often convenient to create the same S4 object as snakemake
## would do for you. For example, here we can do the following:


if (DEBUG) {

    #' define snakemake S4 object
    setClass(
        "snakemake",
        representation(
            threads = "integer",
            input = "list",
            params = "list",
            output = "list",
            log = "list"
        )
    )

    # create a snakemake object used for debugging
    snakemake = new(
        "snakemake",
        threads = 2L,
        params = list(
            master_seed = 42,
            pages = 1:2, # toy numbers for pages, periods, and refits
            periods = 1:5,
            refits = 1:10
        ),
        input = list(),
        output = list(
            seed_list = file.path(
                "results",
                "model_seed_list.csv"
            )
        ),
        log = list(
            file.path("logs", "create_seeds.log")
        )
    )

} else {

    # if not in debugging mode, just open a log and go

    # as we've specified a "log:" in the snakemake script, a 
    # "log" slot is available in the "snakemake" object, which contains
    # the path to where the log should be stored
    # Notice that each slot is a "list" (except for the "threads" slot),
    # so we access the path via "log[[1]]"" and not just "log"

    log_file = file(snakemake@log[[1]], open = "wt")
    sink(log_file, type = "output")
    sink(log_file, type = "message")

}

# load packages you need
library("data.table")

## ------------------------------------------------------------------
## Creating random seeds
## ------------------------------------------------------------------

# create whatever messages you'd like, you can also use the "message" function
logger::log_info("Creating random seeds ...")

# we access the "params: master_seed" slot here
set.seed(snakemake@params[["master_seed"]])

# we want all combinations of pages, periods, and refits, so the "expand.grid" function comes in handy
fit_list = expand.grid(
    page   = snakemake@params[["pages"]],
    period = snakemake@params[["periods"]],
    refit  = snakemake@params[["refits"]]
) |> # i love data.table...so, we'll work with data.tables
    setDT()

# number of rows of dataset
n_rows = NROW(fit_list)

# we should, of course, check our results
stopifnot(
    # check dimensions
    n_rows == length(snakemake@params[["pages"]]) *
                      length(snakemake@params[["periods"]]) *
                      length(snakemake@params[["refits"]]),
    # check uniqueness of rows
    n_rows == NROW(unique(fit_list)),
    # check inclusiveness
    all(unique(snakemake@params[["pages"]]) %in% unique(fit_list$page)),
    all(unique(snakemake@params[["periods"]]) %in% unique(fit_list$period)),
    all(unique(snakemake@params[["refits"]]) %in% unique(fit_list$refit))
)

# create random seeds
fit_list[, seed := sample.int(1e8, .N, replace = FALSE)]


if (!DEBUG) {

    # saving file
    logger::log_info("Saving seeds ...")
    fwrite(fit_list, snakemake@output[["seed_list"]])

    # print session 
    sessionInfo()

    # close log
    sink()

}


### END OF CODE ###
