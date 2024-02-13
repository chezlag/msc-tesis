# --- Dictionaries --- #

TABLES = glob_wildcards("src/tables/" + "{fname}.R").fname

# --- Target rules --- #

rule tabs:
    input:
        expand("out/tables/" + "{table}.tex", table = TABLES)

# --- Build Rules --- #


rule tables:
    input:
        script = "src/tables/" + "{table}.R"
    output:
        table = "out/tables/" + "{table}.tex"
    log:
        "logs/tables/" + "{table}.Rout"
    shell:
        "{runR} {input.script} -o {output.table} > {log} {logAll}"
