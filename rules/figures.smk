# --- Dictionaries --- #

SIMPLE_PLOTS_DTY = [
    "reception_intensity.all",
    "reception_intensity.by_industry",
    "reception_intensity.by_size",
    "share_zeros",
    "small_players.all",
    "small_players.by_industry",
    "small_players.by_size",
    "takeup.by_industry",
    "takeup.in_sample",
    "takeup.by_size",
    "takeup.full",
    "time_trends"
]
SIMPLE_PLOTS_EST = [
    "aggte.did.y.by_industry.ext",
    "aggte.did.y.by_industry",
    "aggte.did.y.by_size.ext",
    "aggte.did.y.by_size",
]
PL0 = expand("out/figures/{fig}.png", fig = SIMPLE_PLOTS_DTY + SIMPLE_PLOTS_EST)
PL1 = expand(
    "out/figures/es.did.y.all.{outcome}.{estimate}.png",
    outcome = OUTCOME_VARIABLES,
    estimate = PREFFERED_SPEC
)
PL2 = expand(
    "out/figures/es.did.y.by_size.{outcome}.{estimate}.png",
    outcome = OUTCOME_VARIABLES,
    estimate = PREFFERED_SPEC
)
PL3 = expand(
    "out/figures/es.did.y.by_industry.{outcome}.{estimate}.png",
    outcome = OUTCOME_VARIABLES,
    estimate = PREFFERED_SPEC
)
PLOTLIST = PL0 + PL1 + PL2 + PL3

# --- Target rules --- #

rule figs:
    input: PLOTLIST

rule sfigs:
    input: PL1

# --- Build rules --- #

rule figures_simple_dty:
    input:
        script = "src/figures/" + "{fig}.R",
        dty = "out/data/firms_yearly.fst"
    output:
        fig = "out/figures/" + "{fig}.png"
    log:
        "logs/figures/" + "{fig}.Rout"
    wildcard_constraints:
        fig = "|".join(SIMPLE_PLOTS_DTY)
    shell:
        "{runR} {input.script} -o {output.fig} > {log} {logAll}"

rule figures_simple_est:
    input:
        script = "src/figures/" + "{fig}.R",
        est_all = "out/analysis/did.y.all." + PREFFERED_SPEC + ".RDS",
        est_siz = "out/analysis/did.y.by_size." + PREFFERED_SPEC + ".RDS",
        est_ind = "out/analysis/did.y.by_industry." + PREFFERED_SPEC + ".RDS"
    output:
        fig = "out/figures/" + "{fig}.png"
    log:
        "logs/figures/" + "{fig}.Rout"
    wildcard_constraints:
        fig = "|".join(SIMPLE_PLOTS_EST)
    shell:
        "{runR} {input.script} -o {output.fig} > {log} {logAll}"

rule plot_es_did_y_all:
    input:
        script = "src/figures/" + "es.did.y.all.R",
        fcn = "src/figures/" + "gges.R",
        est = "out/analysis/" + "did.y.all.{estimate}.RDS"
    output:
        fig = "out/figures/" + "did.y.all.{estimate}.png"
    log:
        "logs/figures/" + "es.did.y.all.{estimate}.Rout"
    shell:
        "{runR} {input.script} --spec {wildcards.estimate} -o {output.fig} > {log} {logAll}"

rule plot_es_did_y_by_size:
    input:
        script = "src/figures/" + "es.did.y.by_size.R",
        fcn = "src/figures/" + "gges.R",
        est = "out/analysis/" + "did.y.by_size.{estimate}.RDS"
    output:
        fig = expand(
            "out/figures/" + "es.did.y.by_size.{outcome}.{est}.png",
            outcome = OUTCOME_VARIABLES,
            est = "{estimate}"
        )
    log:
        "logs/figures/" + "es.did.y.by_size.{estimate}.Rout"
    shell:
        "{runR} {input.script} --spec {wildcards.estimate} > {log} {logAll}"

rule plot_es_did_y_by_industry:
    input:
        script = "src/figures/" + "es.did.y.by_industry.R",
        fcn = "src/figures/" + "gges.R",
        est = "out/analysis/" + "did.y.by_industry.{estimate}.RDS"
    output:
        fig = expand(
            "out/figures/" + "es.did.y.by_industry.{outcome}.{est}.png",
            outcome = OUTCOME_VARIABLES,
            est = "{estimate}"
        )
    log:
        "logs/figures/" + "es.did.y.by_industry.{estimate}.Rout"
    shell:
        "{runR} {input.script} --spec {wildcards.estimate} > {log} {logAll}"
