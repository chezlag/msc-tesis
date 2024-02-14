# rules: analysis

# --- Dictionaries --- #

SAMPLE_LIST = ["0", "1", "2", "3", "B1", "B2"]
SPEC_LIST = ["base", "ctrl", "wt"]
PANEL_LIST = ["bal", "unbal"]

DID_YEARLY = expand(
    "out/analysis/did_yearly_{estimates}.RDS",
    estimates = ["SB1.bal.ctrl"]
)
# DID_YEARLY_BYV = expand(
#     "out/analysis/did_yearly_by.{byvar}_{estimates}.RDS",
#     byvar = ["size", "industry"],
#     estimates = ["S1.bal.base", "S1.bal.ctrl", "S2.bal.ctrl"]
# )
DID_YEARLY_SURV = expand(
    "out/analysis/did_yearly_ext.survival_{estimates}.RDS",
    estimates = ["SB2.bal.base", "SB2.bal.ctrl"]
)
# DID_YEARLY_BCKT = expand(
#     "out/analysis/did_yearly_ext.bracket_{estimates}.RDS",
#     estimates = ["S1.bal.ctrl", "S2.bal.ctrl"]
# )
# DID_YEARLY_REAL = expand(
#     "out/analysis/did_yearly_ext.real_{estimates}.RDS",
#     estimates = ["S2.bal.ctrl"]
# )

# --- Target rules --- #

rule did:
    input:
        DID_YEARLY,
        # DID_YEARLY_BYV,
        DID_YEARLY_SURV,
        # DID_YEARLY_BCKT,
        # DID_YEARLY_REAL

# --- Build rules --- #

rule estimate_did_yearly:
    input:
        script = "src/analysis/" + "estimate_did_yearly.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        cohorts = "out/data/" + "cohorts.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_S{sample}.{panel}.{spec}.Rout"
    threads: 12
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
    threads: 12
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
    threads: 12
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

rule estimate_did_yearly_ext_survival:
    input:
        script = "src/analysis/" + "estimate_did_yearly_ext.survival.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_ext.survival_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_ext.survival_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_ext.survival_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_ext.survival_S{sample}.{panel}.{spec}.Rout"
    threads: 12
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


rule estimate_did_yearly_ext_bracket:
    input:
        script = "src/analysis/" + "estimate_did_yearly_ext.bracket.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_ext.bracket_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_ext.bracket_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_ext.bracket_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_ext.bracket_S{sample}.{panel}.{spec}.Rout"
    threads: 12
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


rule estimate_did_yearly_ext_real:
    input:
        script = "src/analysis/" + "estimate_did_yearly_ext.real.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json"
    output:
        est1 = "out/analysis/" + "did_yearly_ext.real_S{sample}.{panel}.{spec}.RDS",
        est2 = "out/analysis/" + "did_yearly_ext.real_S{sample}.{panel}.{spec}_aggte.simple.RDS",
        est3 = "out/analysis/" + "did_yearly_ext.real_S{sample}.{panel}.{spec}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_ext.real_S{sample}.{panel}.{spec}.Rout"
    threads: 12
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
