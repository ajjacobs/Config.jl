# Config.jl

A configuration manager for Julia.

## Quick Start

### Initialize a ConfigManager

Suppose you have a configuration file called "tdlambda.json", specifying 
a set of parameter settings for an experiment

```json
{
    "save_path": "RandomWalk19/tdlambda",

    "experiment": {
        "class": "MarkovRewardProcess",
        "episodes": 10
    },

    "environment": {
        "class": "RandomWalk",
        "nstates": 19
    },

    "agent": {
        "class": "TDLambda",
        "gamma": 1.0,
        "metastep": [0.025, 0.05, 0.075, 0.1],
        "lambda": [0.0, 0.4, 0.8, 0.9]
    }
}
```

Note: any config file *must* have the "save_path" parameter. This 
specifies the directory in `data/output` which the data will be saved to. In this 
example, data will be saved to `data/output/RandomWalk19/tdlambda`

Initialize a manager to manage all the details of this config file

```julia
cfg = ConfigManager("tdlambda.json", @__DIR__)
```

The second argument specifies where the data directory should be 
setup. In this case, a directory `data/` will be setup in the same directory 
as the experiment which `ConfigManager` was instantiated in.

### Parsing a config

Any lists of parameters in the lowest-level of the config can be swept over 
(in this case, `cfg["agent"]["metastep"]` and `cfg["agent"]["lambda"]`). 
The different parameter settings are linearized. In order to sweep all the 
parameters of this config, we can first check how many different parameters 
there are:

```julia
N = total_combinations(cfg)
```

Then, we need to parse each of the individual settings into a concrete 
parameterization:

```julia
for idx=1:N
    parse!(cfg, idx)
    
    run_some_experiment(cfg)
end
```

parse sets up the settings of a particular parameterization. After parsing the 
config, individual parameters can be accessed by indexing. For example, to this 
parameterization's "metastep" parameter, we can call `cfg["agent"]["metastep"]`. 
If you will be referencing certain nested parameters quite often, you can 
get the subconfiguration instead: `subcfg = get_subconfig(cfg, "agent")`. 
Then access parameters of the subconfig in the same way: `subcfg["metastep"]`.

Note that `parse!` has a third argument -- the run number -- which defaults to 1.
To do multiple runs of an experiment, you can therefore do:

```julia
for run=1:100
    for idx=1:N
        parse!(cfg, idx, run)
        
        run_some_experiment(cfg)
    end
end
```

### Saving data

The `ConfigManager` also takes care of saving data to the right place. 
Just collect whatever data you want during your experiment in a `Dict()` 
and pass it to the ConfigManager. 

```julia
function experiment(cfg::ConfigManager)
    data = Dict()
    data["ValueError"] = Float64[]
    for i=1:1000
       push!(data["ValueError"], rand()) 
    end
    
    save(cfg, data)
end
```

Then load the data later using `load(cfg)` (where cfg is a parse!'d config).

