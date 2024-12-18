# rules: analysis

# --- Dictionaries --- #

SAMPLE_LIST = ["1", "2", "3", "4", "1f", "2f", "4f"]
SPEC_LIST = ["base", "ctrl", "wt"]
PANEL_LIST = ["bal", "unbal"]
GROUP_LIST = ["nyt16", "nytInf", "nt"]
WINSORIZE_LIST = ["95", "99"]

DID_YEARLY = expand(
    "out/analysis/did.y.all.{estimates}_p{winsorize}_{group}.RDS",
    estimates = ["S4_bal_ctrl", "S4_unbal_ctrl"],
    winsorize = ["95", "99"],
    group = ["nytInf"]
)
DID_YEARLY_BYV = expand(
    "out/analysis/did.y.by_{byvar}.{estimates}_{group}.RDS",
    byvar = ["size", "industry"],
    estimates = ["S1_bal_ctrl", "S2_bal_ctrl", "S3_bal_ctrl"],
    group = ["nyt16"]
)
DID_YEARLY_SURV = expand(
    "out/analysis/did.y.ext_survival.{estimates}_{group}.RDS",
    estimates = ["S1f_bal_ctrl", "S2f_bal_ctrl"],
    group = ["nyt16"]
)
DID_QUARTERLY = expand(
    "out/analysis/did.q.all.{estimates}_{group}.RDS",
    estimates = ["S1_bal_ctrl", "S2_bal_ctrl"],
    group = ["nyt16"]
)

# --- Target rules --- #

rule did:
    input:
        DID_YEARLY

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
        est = "out/analysis/" + "did.y.all.S{sample}_{panel}_{spec}_p{winsorize}_{group}.RDS"
    log:
        "logs/analysis/" + "estimate_did.y.all.S{sample}_{panel}_{spec}_p{winsorize}_{group}.Rout"
    threads: 16
    wildcard_constraints:
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        winsorize = "|".join(WINSORIZE_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --winsorize {wildcards.winsorize} \
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
        est = "out/analysis/" + "did.y.by_size.S{sample}_{panel}_{spec}_p{winsorize}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.by_size.S{sample}_{panel}_{spec}_p{winsorize}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        winsorize = "|".join(WINSORIZE_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --winsorize {wildcards.winsorize} \
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
        est = "out/analysis/" + "did.y.by_industry.S{sample}_{panel}_{spec}_p{winsorize}_{group}.RDS",
    log:
        "logs/analysis/" + "estimate_did.y.by_industry.S{sample}_{panel}_{spec}_p{winsorize}_{group}.Rout"
    threads: 16
    wildcard_constraints: 
        sample = "|".join(SAMPLE_LIST),
        panel = "|".join(PANEL_LIST),
        spec = "|".join(SPEC_LIST),
        winsorize = "|".join(WINSORIZE_LIST),
        group = "|".join(GROUP_LIST)
    shell:
        "{runR} {input.script} \
            --threads {threads} \
            --sample {input.params_sample} \
            --panel {input.params_panel} \
            --spec {input.params_spec} \
            --winsorize {wildcards.winsorize} \
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
