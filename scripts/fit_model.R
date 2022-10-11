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
            seed_list = file.path("results", "model_seed_list.csv")
        ),
        output = list(
            tmpfits = file.path("model_fits", "tmpfit_1_2_3.rds")
        ),
        log = list(
            file.path("logs", "tmpfits", "tmpfit_1_2_3.rds")
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

# load packages
library("data.table")

# get parameter values from output file name using regex
logger::log_info("Extracting parameter values ...")
# note: sending out messages will be very helpful when debugging!

outfile = snakemake@output[["tmpfits"]]
out_page = gsub(
    "(tmpfit_)(\\d+)(_\\d+_\\d+\\.rds)",
    "\\2",
    basename(outfile)
) |>
    as.integer()

out_period = gsub(
    "(tmpfit_\\d+_)(\\d+)(_\\d+\\.rds)",
    "\\2",
    basename(outfile)
) |>
    as.integer()

out_refit = gsub(
    "(tmpfit_\\d+_\\d+_)(\\d+)(\\.rds)",
    "\\2",
    basename(outfile)
) |>
    as.integer()

## ------------------------------------------------------------------
## Load seed list
## ------------------------------------------------------------------

logger::log_info("Loading and setting seed ...")

# get seed list
seed_list = data.table::fread(snakemake@input[["seed_list"]])

# get seed for model
model_seed = seed_list[
    page == out_page & period == out_period & refit == out_refit
]$seed

# check conditions
stopifnot(
    length(model_seed) == 1,
    is.integer(model_seed)
)

# set seed
set.seed(model_seed)



## ------------------------------------------------------------------
## Run Model
## ------------------------------------------------------------------

logger::log_info("Start running model ...")

# after setting the seed, we can run the model
fit = runif(1)

# we might also store some other results
if (fit > .5) {
    other_results = ":("
} else {
    other_results = ":)"
}

# binding everything into a list
res_list = list(
    fit = fit,
    membership = other_results
)



## ------------------------------------------------------------------
## Save Results
## ------------------------------------------------------------------

logger::log_info("Saving results ...")

if (!DEBUG) {

    # save results
    saveRDS(res_list, snakemake@output[["tmpfits"]])

    #close log
    sink()

}


### END OF CODE ###