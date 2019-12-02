#=
Julia port of Andrew Patterson's PyExpUtils file permutations.py

https://github.com/andnp/PyExpUtils/blob/master/PyExpUtils/utils/permute.py
=#

function flattenToArray(thing::Dict)
    accum = []

    function inner(thing, path)
        if isa(thing, Array)
            if isa(thing[1], Dict)
                i=1
                for sub in thing
                    inner(sub, string(path,".[", i, "]"))
                    i+=1
                end
                return
            end

            push!(accum, (path, thing))
            return
        end

        if isa(thing, Dict)
            for key in keys(thing)
                new_path = isempty(path) ? key : string(path,".",key)
                inner(thing[key], new_path)
            end
            return
        end
        push!(accum, (path, [thing]))
        return
    end

    inner(thing, "")
    return accum
end

function getTotalCombinations(pairs::Vector{Any})
    accum = 1
    for (path, values) in pairs
        num = length(values) > 0 ? length(values) : 1
        accum *= num
    end
    return accum
end

getTotalCombinations(cfg::Dict) = getTotalCombinations(flattenToArray(cfg))

function getPermutation(pairs::Vector{Any}, idx::Int)
    perm = Dict()
    accum = 1

    for (key, values) in pairs
        num = length(values)

        if num == 0
            perm[key] = []
            continue
        end

        value_idx = Int(floor((idx-1)/accum)) % num
        perm[key] = values[value_idx + 1]
        accum *= num
    end

    return reconstructParameters(perm)
end

getPermutation(cfg::Dict, idx::Int) = getPermutation(flattenToArray(cfg), idx)

function reconstructParameters(perm::Dict)
    res = Dict()
    for key in keys(perm)
        set_at_path(res, key, perm[key])
    end
    return res
end

function set_at_path(d::Dict, path::String, val::Any)
    function inner(d::Dict, path::String, val, last)
        if length(path) == 0
            return d
        end
        sp = split(path, "."; limit=2)
        sp = map(s->String(s), sp)

        part, rest = length(sp) > 1 ? sp : (sp[1], "")
        nxt = split(rest, ".")[1]

        # lists
        if startswith(part, "[")
            num = parse(Int, replace(part, r"[\[,\]]" =>s""))

            if length(d[last]) > num
                piece = length(rest) > 0 ? inner(d[last][num], rest, val, "") : val
                d[last][num] = piece
            else
                piece = length(rest) > 0 ? inner(Dict(), rest, val, "") : val
                push!(d[last], piece)
            end
            return d

        # objects
        elseif length(rest) > 0
            if startswith(nxt, "[")
                piece = get!(d, part, [])
                return inner(d, rest, val, part)
            else
                piece = get!(d, part, Dict())
                return inner(piece, rest, val, part)
            end
        # everything else
        else
            get!(d, part, val)
            return d
        end
    end

    inner(d, path, val, "")
    return d
end

function getDiff!(dict::Dict, cfg_dict::Dict)
    dkeys = []
    for (k,v) in cfg_dict
        if typeof(dict[k]) <: Dict
            subdiff = getDiff(dict[k], cfg_dict[k])
            if isempty(subdiff)
                push!(dkeys, k)
            end
        elseif all(v.==dict[k])
            push!(dkeys, k)
        end
    end

    map(k->delete!(cfg_dict, k), dkeys)

    return cfg_dict
end

getDiff(dict::Dict, cfg_dict::Dict) = getDiff!(dict, copy(cfg_dict))


function _ensure(dirs::Vector{String})
    for d in dirs
        if !isdir(d)
            mkpath(d)
        end
    end
end
