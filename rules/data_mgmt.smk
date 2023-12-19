# Rules: data-management
#
# Contributors: @lachlandeer, @julianlanger, @bergmul

# --- Dictionaries --- #

# --- Target Rules --- #

rule Tdata:
    input: "out/data/yearly_data.fst"

# --- Build Rules --- #

rule clean_yearly_data:
    input:
        script = "src/data_mgmt/" + "clean_yearly_data.R",
        data_bal = "src/data/dgi_firmas/out/data/balances_allF_allY.fst", 
        data_sls = "src/data/dgi_firmas/out/data/sales_allF_allY.fst", 
        data_tax = "src/data/dgi_firmas/out/data/tax_paid_retained.fst", 
        data_cfe = "src/data/dgi_firmas/out/data/eticket_transactions.fst"
    output:
        data = "out/data/" + "yearly_data.fst"
    threads: 16
    shell:
        "{runR} {input.script} -o {output.data}"
