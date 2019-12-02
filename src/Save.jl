using HDF5
using BSON

abstract type DataManager end

# save data, overwriting existing
save(self::DataManager, path::String, data::Dict) = raise(DomainError("save() not defined!"))

# save data, adding to existing
save!(self::DataManager, path::String, data::Dict) = raise(DomainError("save!() not defined!"))

# load data
load(self::DataManager, path::String) = raise(DomainError("load() not defined!"))

# get manager filetype extension
extension() = raise(DomainError("extension() not defined!"))

# ===============
# --- H D F 5 ---
# ===============

struct HDF5Manager <: DataManager end

# Saving/Loading data
function _save(self::HDF5Manager, path::String, data::Dict, writeMode::String)
    h5open(path, writeMode) do f
      for (k,v) in data
          write(f, k, v)
      end
    end
end

extension(self::HDF5Manager) = ".h5"

save!(self::HDF5Manager, path::String, data::Dict) = _save(self, path, data, "cw")
save(self::HDF5Manager, path::String, data::Dict) = _save(self, path, data, "w")

function load(self::HDF5Manager, path::String)
    data = Dict()
    h5open(path) do f
        keys = names(f)
        for k in keys
            data[k] = read(f[k])
        end
    end
    return data
end

# ===============
# --- B S O N ---
# ===============

struct BSONManager <: DataManager end

extension(self::BSONManager) = ".bson"

function save(self::BSONManager, path::String, data::Dict)
    bson(path, data)
end

function save!(self::BSONManager, path::String, data::Dict)
    try
        priorData = BSON.load(path)
        newData = merge(data,BSON.load(path))
        bson(path, newData)
    catch
        bson(path, data)
    end
end

function load(self::BSONManager, path::String)
    return BSON.load(path)
end

