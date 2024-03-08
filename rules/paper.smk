# --- Dictionaries --- #
QMD_FILES  = glob.glob("src/paper/" + "*.qmd")
YAML_FILES = glob.glob("src/paper/" + "*.yml")
BIB_FILES  = glob.glob("src/paper/" + "*.bib")
TEX_FILES  = glob.glob("src/paper/" + "*.tex")

# --- Build Rules --- #

rule paper2root:
    input:
        pdf  = "out/paper/" + "Nuevas-tecnologías-y-evasión-de-impuestos.pdf"
    output:
        pdf  = PROJ_NAME + ".pdf",
    shell:
        "cp {input.pdf} {output.pdf}"

rule build_paper:
    input:
        text_files = QMD_FILES,
        yaml_files = YAML_FILES,
        biblo      = BIB_FILES,
        tex_style  = TEX_FILES,
        tables     = TAB_OVERALL_ATT
    output:
        "out/paper/" + "Nuevas-tecnologías-y-evasión-de-impuestos.pdf"
    log:
        "logs/paper/" + "build_paper.Rout"
    threads: 24
    shell:
        "quarto render src/paper > {log} {logAll}"
