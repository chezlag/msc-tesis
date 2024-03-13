# --- Dictionaries --- #

SIMPLE_TABLES = [
    "sample_summary"
]
TL0 = expand("out/tables/{table}.tex", table = SIMPLE_TABLES)
TL1 = expand(
    "out/tables/did.y.all.overall_att_{subset}.{estimates}.tex",
    estimates = PREFFERED_SPEC,
    subset = ["1", "2"]
)

TABLIST = TL0 + TL1

# --- Target rules --- #

rule tabs:
    input:
        TABLIST

# --- Build Rules --- #

rule tables:
    input:
        script = "src/tables/" + "{table}.R"
    output:
        table = "out/tables/" + "{table}.tex"
    log:
        "logs/tables/" + "{table}.Rout"
    wildcard_constraints:
        table = "|".join(TL0)
    shell:
        "{runR} {input.script} -o {output.table} > {log} {logAll}"

rule tab_overall_att:
    input:
        script = "src/tables/" + "did.y.all.overall_att_{subset}.R",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json",
        est = "out/analysis/" + "did.y.all.S{sample}_{panel}_{spec}_{group}.RDS"
    output:
        table = "out/tables/" + "did.y.all.overall_att_{subset}.S{sample}_{panel}_{spec}_{group}.tex"
    log:
        "logs/tables/" + "did.y.all.overall_att_{subset}.S{sample}_{panel}_{spec}_{group}.Rout"
    wildcard_constraints:
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST),
        subset = "1|2"
    shell:
        "{runR} {input.script} \
            --input {input.est} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.table} \
            > {log} {logAll}"
