import glob

# --- Importing Configuration Files --- #
configfile: "paths.yaml"

# --- PROJECT NAME --- #
PROJ_NAME = "CFE_Spillovers"

# --- Variable Declarations ---- #
runR = "Rscript --no-save --no-restore --verbose"
runStata = "stata-mp -q -b"
logAll = "2>&1"

# --- Main Build Rule --- #
rule all:
    input:
        pdf  = PROJ_NAME + ".pdf"

# --- Cleaning Rules --- #
rule clean_all:
    shell:
        "rm -rf out/ logs/ *.log *.pdf *.html"


# --- Help Rules --- #
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
include: config["rules"] + "tables.smk"
include: config["rules"] + "paper.smk"
# include: config["rules"] + "slides.smk"
