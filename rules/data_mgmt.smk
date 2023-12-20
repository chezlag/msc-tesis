# Rules: data-management
#
# Contributors: @lachlandeer, @julianlanger, @bergmul

# --- Dictionaries --- #

# --- Target Rules --- #

rule Tdata:
    input: "out/data/firms_yearly.fst"

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
        "logs/data_mgmt" + "collapse_eticket.log"
    threads: 16
    shell:
        "{runR} {input.script} > {log} {logAll}"

rule clean_firms_yearly:
    input:
        script = "src/data_mgmt/" + "clean_firms_yearly.R",
        data_bal = "src/data/dgi_firmas/out/data/balances_allF_allY.fst", 
        data_sls = "src/data/dgi_firmas/out/data/sales_allF_allY.fst", 
        data_tax = "src/data/dgi_firmas/out/data/tax_paid_retained.fst", 
        data_cfe = "out/data/eticket_yearly.fst"
    output:
        data = "out/data/" + "firms_yearly.fst"
    log:
        "logs/data_mgmt/" + "clean_firms_yearly.log"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data} > {log} {logAll}"
