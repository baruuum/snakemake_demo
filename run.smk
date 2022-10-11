#!/usr/bin/env python3

## ------------------------------------------------------------------
## Libraries and paths
## ------------------------------------------------------------------

from os.path import join
from os import getcwd
from platform import node
from math import floor

# base dir
if node() == "AS-Soc-bp522-20" :
    base_dir = join("/", "Volumes", "D", "_projects", "misc", "snakemake_demo")
else :
    base_dir = os.getcwd()

# raw data
raw_dir  = join(base_dir, "rawdata")
# data
res_dir = join(base_dir, "results")
# log
log_dir  = join(base_dir, "logs")



## ------------------------------------------------------------------
## Prameters for run
## ------------------------------------------------------------------

# seeds
master_seed_model = 984601

# number of refits 
n_refit = 5

# pages (hypothetical; assuming 10 pages with names 1,...,10; but could be any other name)
pages = list(range(1, 11))

# time periods (again, hypothetial, say goes from 1 to 5)
periods = list(range(1, 6))

# number of refit runs
refits = list(range(1, n_refit + 1))



## ------------------------------------------------------------------
## Final outputs to create 
##
## Note: In this section, we just specify the paths to the files
##       we want to create. 
## ------------------------------------------------------------------

# we should save all the seeds that were used in the analysis
model_seed_list = join(res_dir, "model_seed_list.csv")

# list of all fits, where the model with max log-lik is chosen for each page-period specification
final_fits = join(res_dir, "model_fits", "fit_{page}_{period}.rds")


## ------------------------------------------------------------------
## Rules
## ------------------------------------------------------------------

# the final output
rule final_output:
    input:
        # the model seed list should be a final output
        model_seed_list,
        # this will create all combinations of the specifications,
        # aggregated over refits
        expand(final_fits, page = pages, period = periods)
    
# rule to create seeds for analysis
rule create_seeds:
    params: 
        # instead of input we add the master seed as a parameter
        master_seed = master_seed_model,
        # pages
        pages = pages,
        # periods
        periods = periods,
        # refits
        refits = refits
    output: 
        # we've specified the path to this file above
        seed_list = model_seed_list
    # make sure to leave a log
    log: join(log_dir, "create_seeds.log")
    # the object workflow.cores stores the number of cores you specify
    # when running this snakemake file
    threads: min(4, workflow.cores)
    # the last thing is just the path to the script you want to run
    # notice that paths are always relative to the sakemake file
    script: "scripts/create_random_seeds.R"

    
rule fit_models:
    input:
        # the seed list is feeded into the next rule as input
        # to make the dependency explicit, we can reference the seed_list as an output
        # of the previous rule
        seed_list = rules.create_seeds.output.seed_list
    output:
        # temporary fits, we'll need to aggreate these results later across refits
        # notice that we use the "temp" function. This tells snakemake to delete the
        # output after it's no longer used
        tmpfits = temp(join(res_dir, "tmpfits", "tmpfit_{page}_{period}_{refit}.rds"))
    log: join(log_dir, "tmpfits", "tmpfit_{page}_{period}_{refit}.rds")
    # it's important to specify threads = 1 here. So, if we provide snakemake with 10 cores
    # 10 of the models will be run in parallel
    threads: 1
    script: "scripts/fit_model.R"

rule aggregate_results:
    input:
        # I am assuming that you are familiar with the expand function. If not, let me know;
        # I'd be happy to explain it to you. In any case, notice here that we are using the
        # allow_missing = True option. This is because we want to expand only a subset
        # of the wild cards (if allow_missing = False, snakemake will complain that some
        # of the wild cards have not been specified.)
        # Another thing to notice is the following: because only the {refit} wildcard is expanded,
        # the input file will be a list. Namely, for each {page}-{period} pairs,
        # snakemake will feed into the rule a list of file paths that have the form
        # list(tmpfit_{page}_{period}_1.rds, tmpfit_{page}_{period}_2.rds, ...)
        refit_results = expand(rules.fit_models.output, refit = refits, allow_missing = True)
    output: 
        # notice that this object was defined above
        final_fit = final_fits
    log: join(log_dir, "model_fits", "aggretate_{page}_{period}.log")
    threads: 
        # we might want to specify more cores here to parallelize within each run (via data.table)
        # see "summarize_refits.R" code for how to do this (in this simple code, this might not be necessary)
        min(workflow.cores, 2)
    script: "scripts/summarize_refits.R"

### END OF CODE ###
