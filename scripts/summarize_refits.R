#!/bin/env/Rscript

## ------------------------------------------------------------------
## Setup
## ------------------------------------------------------------------

# flag for debugging or not
DEBUG = FALSE

if (DEBUG) {

    # as before, this is only useful when debugging...

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
        params = list(),
        input = list(
            refit_results = lapply(
                1:3,
                function(x) file.path(
                    "results",
                    "tmpfits",
                    paste0("tmpfit_1_2_", x, ".rds")
                )
            )
        ),
        output = list(file.path("results", "model_fits", "fit_1_2.rds")),
        log = list(file.path("logs", "model_fits", "fit_1_2_3.log"))
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

# load packages
library("data.table")

# if you want to use within-script parallelism using data.table
# (or for that sake any other package), you can utilize the threads
# slot
data.table::setDTthreads(snakemake@threads)


## ------------------------------------------------------------------
## Aggregating across lists
## ------------------------------------------------------------------

logger::log_info("Selecting model with highest objective function value ")

# read data
refit_list = lapply(snakemake@input[["refit_results"]], readRDS)

# recall that each dataset loaded will be a list with two elements:
# (a) fit: a random number between 0 and 1 which we treat as the objective fun
# (b) membership: some other arbitrary object

# extract the first element of list-entry and get index of max-element
ll = sapply(refit_list, `[[`, 1L)
max_ll_indx = which.max(ll)

# get the data for fit with highgest obj fun
max_fit = refit_list[[max_ll_indx]]
max_ll = max_fit$fit

logger::log_info("Highest obj. fun val: ", round(max_ll, 3))

# check results
stopifnot(max(ll) == max_ll)


## ------------------------------------------------------------------
## Save Results
## ------------------------------------------------------------------

logger::log_info("Saving results ...")

if (!DEBUG) {

    # save results
    saveRDS(max_fit, snakemake@output[["final_fit"]])

    #close log
    sink()

}


### END OF CODE ###