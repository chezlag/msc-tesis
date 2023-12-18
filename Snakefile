# Main Workflow - MRW Replication
# Contributors: @lachlandeer, @julianlanger, @bergmul

import glob

# --- Importing Configuration Files --- #
configfile: "paths.yaml"

# --- PROJECT NAME --- #
PROJ_NAME = "CFE Spillovers"

# --- Variable Declarations ---- #
runR = "Rscript --no-save --no-restore --verbose"
runStata = "stata-mp -q -b"
logAll = "2>&1"

# --- Main Build Rule --- #
## all            : build paper and slides that are the core of the project
rule all:
    input:
        html  = PROJ_NAME + "_slides.pdf"

# --- Cleaning Rules --- #
## clean_all      : delete all output and log files for this project
rule clean_all:
    shell:
        "rm -rf out/ logs/ *.log *.pdf *.html"


# --- Help Rules --- #
## help_main      : prints help comments for Snakefile in ROOT directory. 
##                  Help for rules in other parts of the workflows (i.e. in rules/)
##                  can be called by `snakemake help_<workflowname>`
rule help_main:
    input: "Snakefile"
    shell:
        "sed -n 's/^##//p' {input}"

# --- Sub Rules --- #
# Include all other Snakefiles that contain rules that are part of the project
# 1. project specific
include: config["rules"] + "data_mgmt.smk"
include: config["rules"] + "analysis.smk"
include: config["rules"] + "figures.smk"
#include: config["rules"] + "tables.smk"
#include: config["rules"] + "paper.smk"
include: config["rules"] + "slides.smk"
# 2. Other rules
include: config["rules"] + "clean.smk"
include: config["rules"] + "dag.smk"
include: config["rules"] + "help.smk"
include: config["rules"] + "params.smk"
include: config["rules"] + "renv.smk"

