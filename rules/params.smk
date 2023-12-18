# params.smk
# rules for parameters to stata format
# @chezlag

# --- Dictionaries --- #

DATA_SPECS_JSON = glob_wildcards(config["src_data_specs"] + "{fname}.json").fname
LIB_JSON = glob_wildcards(config["src_lib"] + "{fname}.json").fname

# --- Target Rules --- #

## params2stata:        Convert json parameters to Stata globals in target file
rule params2stata:
	input:
		expand(config["out_data_specs"] + "{iParams}.do",
			iParams = DATA_SPECS_JSON),
		expand(config["out_lib"] + "{iParams}.do",
			iParams = LIB_JSON),
        expand(config["out_model_specs"] + "{iParams}.do",
            iParams = PARAMS)
		
# --- Build Rules --- #

# data_params:        Convert json data parameters to Stata globals in target file
rule data_specs_json2stata:
    input:
        script = config["src_lib"] + "json2stata.py",
        params = config["src_data_specs"] + "{iParams}.json"
    output: 
        params = config["out_data_specs"] + "{iParams}.do"
    shell:
        "python {input.script} '{input.params}' '{output.params}'"

# lib_params:        Convert json lib parameters to Stata globals in target file
rule lib_json2stata:
    input:
        script = config["src_lib"] + "json2stata.py",
        params = config["src_lib"] + "{iParams}.json"
    output: 
        params = config["out_lib"] + "{iParams}.do"
    shell:
        "python {input.script} '{input.params}' '{output.params}'"

# model_specs_params:        Convert json parameters to Stata globals in target file
rule model_specs_json2stata:
    input:
        script = config["src_lib"] + "json2stata.py",
        params = config["src_model_specs"] + "{iParams}.json"
    output: 
        params = config["out_model_specs"] + "{iParams}.do"
    shell:
        "python {input.script} '{input.params}' '{output.params}'"