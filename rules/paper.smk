# Rules: paper
#
# Compile paper as pdf using bookdown and rticles
#
# rticle-style: asa (see 'src/paper/_output.yml' for where we set the style)
# If you change the template, will need to change structure of yaml in 
# `src/paper/index.Rmd` accordingly
#
# contributors: @lachlandeer, @julianlanger, @bergmul

# --- Dictionaries --- #
QMD_FILES  = glob.glob("src/paper/" + "*.qmd")
YAML_FILES = glob.glob("src/paper/" + "*.yml")
BIB_FILES  = glob.glob("src/paper/" + "*.bib")
TEX_FILES  = glob.glob("src/paper/" + "*.tex")

# --- Build Rules --- #
## paper2root:   copy paper to root directory
rule paper2root:
    input:
        pdf  = "out/paper/" + "Nuevas-tecnologías-y-evasión-de-impuestos.pdf"
    output:
        pdf  = PROJ_NAME + ".pdf",
    shell:
        "cp {input.pdf} {output.pdf}"

## build_paper: builds pdf using bookdown
rule build_paper:
    input:
        text_files = QMD_FILES,
        yaml_files = YAML_FILES,
        biblo      = BIB_FILES,
        tex_style  = TEX_FILES
    output:
        "out/paper/" + "Nuevas-tecnologías-y-evasión-de-impuestos.pdf"
    log:
        "logs/paper/" + "build_paper.Rout"
    shell:
        "quarto render src/paper > {log} {logAll}"
