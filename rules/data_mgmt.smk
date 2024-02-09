# Rules: data-management

# --- Dictionaries --- #

# --- Target Rules --- #

rule data:
    input: 
        "out/data/firms_yearly.fst",
        "out/data/samples.fst",
        "out/data/cohorts.fst",
        "out/data/firms_yearly_filled.fst"

# --- Build Rules --- #

rule collapse_eticket:
    input:
        script = "src/data_mgmt/" + "collapse_eticket.R",
        data = "src/data/" + "dgi_firmas/out/data/eticket_transactions.fst"
    output:
        "out/data/" + "eticket_static.fst",
        "out/data/" + "eticket_yearly.fst",
        "out/data/" + "eticket_quarterly.fst"
    log:
        "logs/data_mgmt/" + "collapse_eticket.Rout"
    threads: 16
    shell:
        "{runR} {input.script} > {log} {logAll}"

rule clean_firms_static:
    input:
        script = "src/data_mgmt/" + "clean_firms_static.R",
        databcs = "src/data/" + "bcs_covariates.csv",
        datacfe = "out/data/" + "eticket_static.fst"
    output:
        data = "out/data/" + "firms_static.fst"
    log:
        "logs/data_mgmt/" + "clean_firms_static.Rout"
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"

rule clean_firms_yearly:
    input:
        script = "src/data_mgmt/" + "clean_firms_yearly.R",
        data_bal = "src/data/dgi_firmas/out/data/balances_allF_allY.fst", 
        data_sls = "src/data/dgi_firmas/out/data/sales_allF_allY.fst", 
        data_tax = "src/data/dgi_firmas/out/data/tax_paid_retained.fst", 
        data_cfe = "out/data/eticket_yearly.fst",
        data_static = "out/data/firms_static.fst"
    output:
        data = "out/data/" + "firms_yearly.fst"
    log:
        "logs/data_mgmt/" + "clean_firms_yearly.Rout"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"

rule define_samples:
    input:
        script = "src/data_mgmt/" + "define_samples.R",
        data = "out/data/" + "firms_yearly.fst"
    output:
        data = "out/data/" + "samples.fst"
    log:
        "logs/data_mgmt/" + "define_samples.Rout"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"

rule define_cohorts:
    input:
        script = "src/data_mgmt/" + "define_cohorts.R",
        data = "out/data/" + "firms_yearly.fst"
    output:
        data = "out/data/" + "cohorts.fst"
    log:
        "logs/data_mgmt/" + "define_cohorts.Rout"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"

rule fill_firms_yearly:
    input:
        script = "src/data_mgmt/" + "fill_firms_yearly.R",
        data = "out/data/" + "firms_yearly.fst"
    output:
        data = "out/data/" + "firms_yearly_filled.fst"
    log:
        "logs/data_mgmt/" + "fill_firms_yearly.Rout"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"

rule clean_firms_quarterly:
    input:
        script = "src/data_mgmt/" + "clean_firms_quarterly.R",
        data_cfe = "out/data/eticket_yearly.fst",
        data_static = "out/data/firms_static.fst",
        data_yearly = "out/data/firms_yearly.fst"
    output:
        data = "out/data/" + "firms_quarterly.fst"
    log:
        "logs/data_mgmt/" + "clean_firms_quarterly.Rout"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"