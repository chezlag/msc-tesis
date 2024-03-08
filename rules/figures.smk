# --- Dictionaries --- #

SIMPLE_PLOTS = [
    "share_zeros",
    "small_players",
    "takeup_sample",
    "takeup"
]

OUTCOME_VARIABLES = [
    "Scaled1vatPurchasesK",
    "Scaled1vatSalesK",
    "Scaled1netVatLiabilityK",
    "Scaled1vatPaidK",
    "vatPurchases0",
    "vatSales0",
    "netVatLiability0",
    "vatPaid0"
]

PL0 = expand("out/figures/{fig}.png", fig = SIMPLE_PLOTS)

PL1 = expand(
    "out/figures/es.did.y.all.{outcome}.{estimate}.png",
    outcome = OUTCOME_VARIABLES,
    estimate = "S3_bal_ctrl_nyt16"
)

FULL_PLOTLIST = PL0 + PL1

# --- Target rules --- #

rule figs:
    input: FULL_PLOTLIST

# --- Build rules --- #

rule figures_base:
    input:
        script = "src/figures/" + "{fig}.R",
        dty = "out/data/firms_yearly.fst"
    output:
        fig = "out/figures/" + "{fig}.png"
    log:
        "logs/figures/" + "{fig}.Rout"
    wildcard_constraints:
        fig = "|".join(PL0)
    shell:
        "{runR} {input.script} -o {output.fig} > {log} {logAll}"

rule plot_es_did_y_all:
    input:
        script = "src/figures/" + "plot_es.did.y.all.R",
        est = "out/analysis/" + "did.y.all.{estimate}.RDS"
    output:
        fig = expand(
            "out/figures/" + "es.did.y.all.{outcome}.{est}.png",
            outcome = OUTCOME_VARIABLES,
            est = "{estimate}"
        )
    log:
        "logs/figures/" + "plot_es.did.y.all.{estimate}.Rout"
    shell:
        "{runR} {input.script} -spec {wildcards.estimate} > {log} {logAll}"
