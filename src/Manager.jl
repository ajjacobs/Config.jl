import Base: get, getindex, setindex!, haskey
import Pkg: TOML

mutable struct ConfigManager{DM <: DataManager}
    config_dict::Dict
    parsed_config::Vector
    total_combinations::Int
    spec::Dict
    rootdir::String
    dataManager::DM
end

function ConfigManager(config_file::String, rootdir::String, manager::DM = HDF5Manager()) where { DM<:DataManager }
    cfg = Dict()
    if splitext(config_file)[end] == ".toml"
        cfg = TOML.parsefile(config_file)
    else
        open(config_file, "r") do f
            txt = read(f,String)
            cfg = JSON.parse(txt)
        end
    end

    parsed = flattenToArray(cfg)
    total = getTotalCombinations(cfg)

    cm = ConfigManager(cfg, parsed, total, Dict(), rootdir, manager)

    # sometimes want this without having to parse!() the config
    cm.spec["save_path"] = getPermutation(cm.parsed_config, 1)["save_path"]

    _ensure([_data_root(cm), _output_root(cm), _checklists(cm) ])

    return cm
end

function Base.copy(cm::ConfigManager{DM}) where {DM<:DataManager}
    ConfigManager{DM}(
        deepcopy(cm.config_dict),
        copy(cm.parsed_config),
        cm.total_combinations,
        Dict("save_path"=>getPermutation(cm.parsed_config, 1)["save_path"]),
        cm.rootdir,
        typeof(cm.dataManager)()
    )
end


haskey(self::ConfigManager, k::String) = k ∈ keys(self.spec)
getindex(self::ConfigManager, param::String) = self.spec[param]
setindex!(self::ConfigManager, value::Any, param::String) = setindex!(self.spec, value, param)

_data_root(self::ConfigManager) = joinpath(self.rootdir, "data")
_output_root(self::ConfigManager) = joinpath(_data_root(self), "output")
_checklists(self::ConfigManager) = joinpath(_data_root(self), "checklists")

total_combinations(self::ConfigManager) = self.total_combinations

struct _CM_Iterator{CM<:ConfigManager}
    manager::CM
    num_runs::Int
end

Base.length(iter::_CM_Iterator) = total_combinations(iter.manager)*iter.num_runs

iterator(cm::ConfigManager, num_runs) = _CM_Iterator(cm, num_runs)

function Base.iterate(iter::_CM_Iterator, state=(1,1))

    if state[1] > total_combinations(iter.manager)
        return nothing
    end
    
    new_state = begin
        if state[2] == iter.num_runs
            (state[1] + 1, 1)
        else
            (state[1], state[2]+1)
        end
    end
    cm = copy(iter.manager)

    parse!(cm, state[1], state[2])
    return cm, new_state
    
end



"""
    parse!

    get spec while modifying config manager. repercusions.
"""
function parse!(self::ConfigManager, idx::Int, run::Int=1)
    self.spec = getPermutation(self.parsed_config, idx)

    self.spec["run"] = run
    self.spec["param_setting"] = idx

    _ensure([get_expdir(self), get_logdir(self)])

    return self
end

function param_values(self::ConfigManager, key::String)
    path = map(s->string(s), split(key,"/"))
    d = copy(self.config_dict)
    for ss in path
        d = d[ss]
    end
    return d
end

function params_with(self::ConfigManager, cfg_dict::Dict)
    indices = Int[]
    for idx in 1:self.total_combinations
        param_setting = getPermutation(self.parsed_config,idx)
        diff = getDiff(param_setting, cfg_dict)
        if isempty(diff)
            push!(indices, idx)
        end
    end
    return indices
end


function get_expdir(self::ConfigManager)
    return joinpath(_output_root(self), self["save_path"])
end

function get_logdir(self::ConfigManager)
    return joinpath(get_expdir(self), string(self["run"],"_run"), string(self["param_setting"], "_param_setting"))
end

function get_datafile(self::ConfigManager)
    path = joinpath(get_logdir(self),string("data", extension(self.dataManager)))
    if !isfile(path)
        touch(path)
    end
    return path
end

function log_config(self::ConfigManager, logger::Logging.SimpleLogger)
    function _log(keys, attrs)
        for param in keys
            value = attrs[param]
            if value == nothing
                continue
            end

            s = string(param, ": ", value)

            # log to stdout
            @info s

            # log to logfile
            Logging.with_logger(logger) do
                @info s
            end
        end
    end

    attrs = get_attrs(self)
    attr_lst = sort(collect(keys(attrs)), by = x->x[1])
    model_attrs = filter(k -> occursin("|", k), attr_lst)
    other_attrs = filter(k-> !occursin("|",k), attr_lst)

    _log(other_attrs, attrs)
    _log(model_attrs, attrs)
end

function get_attrs(self::ConfigManager)
    return copy(self.spec)
end

function dump_config(self::ConfigManager)
    # Dump the config to the data file so it's easier
    # to recreate a single specific experiment/setting

    path = joinpath(get_logdir(self), "config.json")
    attrs = get_attrs(self)
    delete!(attrs, "param_setting")
    delete!(attrs, "run")

    open(path,"w+") do f
        JSON.print(f, attrs, 4)
    end
end

function get_subconfig(self::ConfigManager, keys...)
    sub = self.spec[keys[1]]
    for k in keys[2:end]
        sub = sub[k]
    end
    return sub
end


