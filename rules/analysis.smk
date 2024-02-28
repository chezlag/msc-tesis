# rules: analysis

# --- Dictionaries --- #

SAMPLE_LIST = ["0", "1", "2", "3", "B1", "B2"]
SPEC_LIST = ["base", "ctrl", "wt"]
PANEL_LIST = ["bal", "unbal"]
GROUP_LIST = ["nyt16", "nyt15", "nytInf", "nt"]

DID_YEARLY = expand(
    "out/analysis/did.y.all.{estimates}_{group}.RDS",
    estimates = ["S1_bal_ctrl", "SB1_bal_ctrl"],
    group = GROUP_LIST
)
DID_YEARLY_BYV = expand(
    "out/analysis/did.y.by_{byvar}.{estimates}_{group}.RDS",
    byvar = ["size", "industry"],
    estimates = ["S1_bal_base", "S1_bal_ctrl", "S2_bal_ctrl"],
    group = GROUP_LIST
)
DID_YEARLY_SURV = expand(
    "out/analysis/did.y.ext_survival.{estimates}_{group}.RDS",
    estimates = ["S3_bal_base", "S3_bal_ctrl"],
    group = GROUP_LIST
)
DID_QUARTERLY = expand(
    "out/analysis/did.q.all.{estimates}_{group}.RDS",
    estimates = ["S1_bal_ctrl", "S1_bal_base"],
    group = ["nyt16"]
)

# --- Target rules --- #

rule did:
    input:
        DID_YEARLY,
        DID_YEARLY_BYV,
        DID_YEARLY_SURV,
        DID_QUARTERLY

# --- Build rules --- #

rule estimate_did_yearly:
    input:
        script = "src/analysis/" + "estimate_did.y.all.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        cohorts = "out/data/" + "cohorts.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"
    output:
        est = "out/analysis/" + "did.y.all.S{sample}_{panel}_{spec}_{group}.RDS"
    log:
        "logs/analysis/" + "estimate_did.y.all.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints:
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"

rule estimate_did_yearly_by_size:
    input:
        script = "src/analysis/" + "estimate_did.y.by_size.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"
    output:
        est = "out/analysis/" + "did.y.by_size.S{sample}_{panel}_{spec}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.by_size.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"

rule estimate_did_yearly_by_industry:
    input:
        script = "src/analysis/" + "estimate_did.y.by_industry.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"

    output:
        est = "out/analysis/" + "did.y.by_industry.S{sample}_{panel}_{spec}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.by_industry.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
             > {log} {logAll}"

rule estimate_did_yearly_ext_survival:
    input:
        script = "src/analysis/" + "estimate_did.y.ext_survival.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"

    output:
        est = "out/analysis/" + "did.y.ext_survival.S{sample}_{panel}_{spec}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.ext_survival.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"


rule estimate_did_yearly_ext_bracket:
    input:
        script = "src/analysis/" + "estimate_did.y.ext_bracket.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"

    output:
        est = "out/analysis/" + "did.y.ext_bracket.S{sample}_{panel}_{spec}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.ext_bracket.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"


rule estimate_did_yearly_ext_real:
    input:
        script = "src/analysis/" + "estimate_did.y.ext_real.R",
        data = "out/data/" + "firms_yearly_filled.fst",
        samples = "out/data/" + "samples.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"

    output:
        est = "out/analysis/" + "did.y.ext_real.S{sample}_{panel}_{spec}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did/y.ext_real.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"

rule estimate_did_quarterly:
    input:
        script = "src/analysis/" + "estimate_did.q.all.R",
        data = "out/data/" + "firms_quarterly.fst",
        samples = "out/data/" + "samples.fst",
        cohorts = "out/data/" + "cohorts.fst",
        params_sample = "src/model_specs/" + "sample_{sample}.json",
        params_panel = "src/model_specs/" + "panel_{panel}.json",
        params_spec = "src/model_specs/" + "spec_{spec}.json",
        params_group = "src/model_specs/" + "group_{group}.json"

    output:
        est = "out/analysis/" + "did.q.all.S{sample}_{panel}_{spec}_{group}.RDS"
    log:
        "logs/analysis/" + "estimate_did.q.all.S{sample}_{panel}_{spec}_{group}.Rout"
    threads: 16
    wildcard_constraints:
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --group {input.params_group} \
            --output {output.est} \
            > {log} {logAll}"
