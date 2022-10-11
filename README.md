# `snakemake` demo

Short demo of using `snakemake` to refit model to data that have a page-period structure and where multiple refits are required

Whole workflow can be run with 

```bash
snakemake -s run.smk -j4
```

assuming you are currently in the directory where the `run.smk` file is located. The `-j4` option specifies that we'll run the workflow using 4 cores. It's always a good idea to do a dry run first, which can be accomplished by specifying the `-n` option.

