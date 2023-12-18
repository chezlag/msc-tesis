# Rules: slides
#
# Contributors: @lachlandeer, @julianlanger, @bergmul

# --- Build Rules --- #
## slides2root:    move slides to root directory
rule slides2root:
    input:
        pdf  = config["out_slides"] + "slides.pdf"
    output:
        pdf  = PROJ_NAME + "_slides.pdf",
    shell:
        "cp {input.pdf} {output.pdf}"

## build_beamer: knit beamer slides
rule build_slides:
    input:
        runner    = config["src_lib"] + "build_slides.R",
        rmd_file  = config["src_slides"] + "slides.Rmd",
        preamble  = config["src_slides"] + "preamble.tex",
    output:
        pdf = config["out_slides"] + "slides.pdf"
    log:
        log = "slides.Rout"
    shell:
        "{runR} {input.runner} -i {input.rmd_file} -o {output.pdf}\
            > {log} {logAll}"
