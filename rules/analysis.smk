# rules: analysis

# --- Dictionaries --- #

EST_LIST = ["S1.bal.base", "S1.bal.ctrl", "S1.bal.wt", "S2.bal.base", "S3.unbal.base", "S3.unbal.ctrl"]
SAMPLE_LIST = ["0", "1", "2", "3"]
SPEC_LIST = ["base", "ctrl", "wt"]
PANEL_LIST = ["bal", "unbal"]

DID_YEARLY = expand("out/analysis/did_yearly_{estimates}.RDS", estimates = EST_LIST)
DID_YEARLY_BYV = expand("out/analysis/did_yearly_by.{byvar}_{estimates}.RDS", 
    byvar = ["size", "industry"], estimates = ["S1.bal.base", "S3.unbal.base"])
DID_YEARLY_SURV = expand("out/analysis/did_yearly_survival_{estimates}.RDS", estimates = ["S1.bal.base", "S3.bal.base"])

# --- Target rules --- #

rule did:
    input:
        DID_YEARLY,
        DID_YEARLY_BYV,
        DID_YEARLY_SURV

# --- Build rules --- #

rule estimate_did_yearly:
    input:
        script = "src/analysis/" + "estimate_did_yearly.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_S{sample}.{panel}.{spec}.Rout"
    threads: 8
    wildcard_constraints:
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST)
    shell:
        "{runR} {input.script} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --output {output.est1} \
            > {log} {logAll}"

rule estimate_did_yearly_by_size:
    input:
        script = "src/analysis/" + "estimate_did_yearly_by.size.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_by.size_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_by.size_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_by.size_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_by.size_S{sample}.{panel}.{spec}.Rout"
    threads: 8
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST)
    shell:
        "{runR} {input.script} \
        --sample {input.params_sample} \
        --panel {input.params_panel} \
        --spec {input.params_spec} \
        --output {output.est1} \
         > {log} {logAll}"

rule estimate_did_yearly_by_industry:
    input:
        script = "src/analysis/" + "estimate_did_yearly_by.industry.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_by.industry_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_by.industry_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_by.industry_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_by.industry_S{sample}.{panel}.{spec}.Rout"
    threads: 8
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST)
    shell:
        "{runR} {input.script} \
        --sample {input.params_sample} \
        --panel {input.params_panel} \
        --spec {input.params_spec} \
        --output {output.est1} \
         > {log} {logAll}"

rule estimate_did_yearly_survival:
    input:
        script = "src/analysis/" + "estimate_did_yearly_survival.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_survival_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_survival_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_survival_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_survival_S{sample}.{panel}.{spec}.Rout"
    threads: 8
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST)
    shell:
        "{runR} {input.script} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --output {output.est1} \
            > {log} {logAll}"
