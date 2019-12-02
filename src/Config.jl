module Config

using JSON
using Dates
using Mmap
using Logging
using HDF5
using Statistics

# utilities
include("Utils.jl")

# data managers
include("Save.jl")

# Base Class
include("Manager.jl")
export ConfigManager, total_combinations, add!, parse!,
    get_sweep_params, param_setting_from_id, params_with, param_values,
    get_datafile, get_stepslog, get_expdir, get_logdir,
    log_config, get_subconfig, get_attrs,
    getindex, setindex!, haskey

# Saving/Loading/Parsing data
include("Data.jl")
export save, save!, load, update!, clear!,
     get_run_data, get_data, get_summary, get_best,
    sensitivity, get_max_runs,
    Summary

# Checklist to prevent overwriting results or redundantly re-running
# already-ran experiments
include("Checklist.jl")
export dump_config, mark_config, check_config, unmarked_configs


end # module
