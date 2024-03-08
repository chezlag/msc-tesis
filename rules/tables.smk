# --- Dictionaries --- #

TAB_OVERALL_ATT = expand(
    "out/tables/did.y.all.overall_att_{subset}.{estimates}.tex",
    estimates = ["S1_bal_ctrl_nyt16", "S2_bal_ctrl_nyt16", "S3_bal_ctrl_nyt16"],
    subset = ["1", "2"]
)

# --- Target rules --- #

rule tabs:
    input:
        TAB_OVERALL_ATT

# --- Build Rules --- #

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
        subset = "|".join(["1", "2"])
    shell:
        "{runR} {input.script} \
            --input {input.est} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.table} \
            > {log} {logAll}"
