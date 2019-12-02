struct Summary
    μ
    σ
    n

    Summary(data::Matrix{Float64}) = new(
        mean(data,dims=2),
        std(data,corrected=true,dims=2) / √(size(data)[2]-1),
        size(data)[2]
    )

    Summary(data::Vector{Float64}) = new(
        data,
        zeros(length(data)),
        1
    )
end

# Saving/Loading data
save!(self::ConfigManager, data::Dict) = save!(self.dataManager, get_datafile(self), data)
save(self::ConfigManager, data::Dict) = save(self.dataManager, get_datafile(self), data)
load(self::ConfigManager) = load(self.dataManager, get_datafile(self))
load(self::ConfigManager, idx::Int) = load(parse!(self, idx))

# Parsing saved data

function get_run_data(self::ConfigManager, idx, run)
    parse!(self, idx, run)
    return load(self)
end

function get_data(self::ConfigManager, idx)
    runs = get_max_runs(self,idx)
    all_data = Dict()
    for r in 1:runs
        data = get_run_data(self, idx, r)
        for k in keys(data)
            if haskey(all_data, k)
                all_data[k] = hcat(all_data[k], data[k])
            else
                all_data[k] = data[k]
            end
        end
    end
    return all_data
end

function get_fields(self::ConfigManager)
    return keys(get_run_data(copy(self),1,1))
end

function get_summary(self::ConfigManager, idx::Int, key::String)
    data = get_data(self,idx)
    return Summary(data[key])
end

function get_best(self::ConfigManager, key; metric=mean, selector=argmin)
    return get_best(self, key, 1:self.total_combinations, metric=metric, selector=selector)
end

function get_best(self::ConfigManager, key, indices; metric=mean, selector=argmin)
    data = []
    parsed_indices = []
    for idx in indices
        d = get_summary(self, idx, key).μ
        m = metric(d)
        if isfinite(m)
            push!(data, metric(d))
            push!(parsed_indices, idx)
        end
    end
    if length(data) == 0
        return nothing # all configs diverged
    end
    best = selector(data)
    return parsed_indices[best]
end

function sensitivity(self::ConfigManager, key; metric=mean)
    best_idx = get_best(self,key)
    cfg = parse!(self, best_idx)

    keys = get_sweep_params(self)
    d = Dict( k=> self[k] for k in keys )

    # delete the key we're looking for sensitivity over
    delete!(d,key)

    indices = configs_with(self, d)
    sens_data = []
    for idx in indices
        value = metric(get_summary(self,idx).μ)
        push!(sens_data, value)
    end
    return sens_data
end

function get_max_runs(self::ConfigManager, idx::Int)
    cfg = parse!(self,idx,1)
    runs = readdir(get_expdir(self))
    return length(runs)
end
