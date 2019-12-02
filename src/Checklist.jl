# Checklists which prevent already-ran
# experiments from being re-ran. Useful when
# ComputeCanada experiments timeout

function mark_config(self::ConfigManager)
    chk_lst = get_checklist(self)
    chk_lst[self["param_setting"]] = 1
end

function check_config(self::ConfigManager)
    chk_lst = get_checklist(self)
    if chk_lst[self["param_setting"]] == 1
        println(string("Already ran param setting ", self["param_setting"], " ", self["run"]))
        exit(0)
    end
end

function get_checklist(self::ConfigManager)
    filename = join(split(self[ "save_path"],"/"), "_")
    path = joinpath(_checklists(self), string(filename ,".bin"))

    if !isfile(path)
        touch(path)
    end

    f = open(path,"r+")
    return Mmap.mmap(f, Vector{UInt8}, self.total_combinations, (self["run"] - 1) * self.total_combinations * sizeof(UInt8))
end

function unmarked_configs(self::ConfigManager)
    chkLst = get_checklist(self)
    indices = Int[]
    for i=1:total_combinations(self)
        if chkLst[i] != 1
            push!(indices, i)
        end
    end
    return indices
end
