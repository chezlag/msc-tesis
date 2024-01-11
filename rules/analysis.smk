# rules: analysis

# --- Dictionaries --- #

EST_LIST = ["S0.unbal", "S1.base", "S1.ctrl", "S1.wt", "S2.base"]

# --- Target rules --- #

rule Tdid:
    input:
        expand("out/analysis/did_yearly_{sample}.RDS", sample = EST_LIST)

# --- Build rules --- #

rule estimate_did_yearly:
    input:
        script = "src/analysis/" + "estimate_did_yearly_{sample}.R",
        data = "out/data/" + "firms_yearly.fst",
        samples = "out/data/" + "samples.fst"
    output:
        "out/analysis/" + "did_yearly_{sample}.RDS",
        "out/analysis/" + "did_yearly_{sample}_aggte.simple.RDS",
        "out/analysis/" + "did_yearly_{sample}_aggte.dynamic.RDS"
    log:
        "logs/analysis/" + "estimate_did_yearly_{sample}.log"
    threads: 8
    wildcard_constraints: sample = "|".join(EST_LIST)
    shell:
        "{runR} {input.script} > {log} {logAll}"