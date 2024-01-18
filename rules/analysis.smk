# rules: analysis

# --- Dictionaries --- #

EST_LIST = ["S1.bal.base", "S1.bal.ctrl", "S1.bal.wt", "S2.bal.base", "S3.unbal.base"]
SAMPLE_LIST = [0, 1, 2, 3]
SPEC_LIST = ["base", "ctrl", "wt"]
PANEL_LIST = ["bal", "unbal"]

# --- Target rules --- #

rule Tdid:
    input:
        expand("out/analysis/did_yearly_{estimates}.RDS", estimates = EST_LIST)

# --- Build rules --- #

rule estimate_did_yearly:
    input:
        script = "src/analysis/" + "estimate_did_yearly.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
        params_panel = "src/model_specs/" + "panel_{panel}.json"
    output:
        "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}.RDS",
        "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_S{sample}.{panel}.{spec}.log"
    threads: 8
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST)
        spec = "|".join(SPEC_LIST), 
    shell:
        "{runR} {input.script} \
        --sample {input.params_sample} \
        --panel {input.params_panel} \
        --spec {input.params_spec} \
         > {log} {logAll}"