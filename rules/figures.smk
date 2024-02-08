# Rules: figures
#
# Contributors: @lachlandeer, @julianlanger, @bergmul

# --- Dictionaries --- #

PLOTS = glob.glob("src/figures/" + "*.R")

# --- Target rules --- #

rule figs:
    input:
        expand("out/figures/" + "{fig}.png", fig = PLOTS)

# --- Build rules --- #

rule figures:
    input:
        script = "src/figures/" + "{fig}.R"
    output:
        fig = "out/figures/" + "{fig}.png"
    log:
        "logs/figures/" + "{fig}.Rout"
    shell:
        "{runR} {input.script} -o {output.fig} > {log} {logAll}"
