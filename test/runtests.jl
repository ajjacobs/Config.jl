
using Test
using Config

function manager_tests()
    cfg = ConfigManager(joinpath(@__DIR__,"tdlambda.json"), @__DIR__)

    metasteps = [0.025, 0.05, 0.075, 0.1]
    lambdas = [0.0, 0.4, 0.8, 0.9]
    N = length(lambdas)
    cfgs = []
    for i=1:N
        for j=1:N
            push!(cfgs, (metasteps[j],lambdas[i]))
        end
    end

    for i=1:total_combinations(cfg)
        cfg = parse!(cfg, i)
        subconfig = get_subconfig(cfg, "agent")
        tru = cfgs[i]
        @test subconfig["metastep"] == tru[1]
        @test subconfig["lambda"] == tru[2]
    end
end

function manager_tests_toml()
    cfg = ConfigManager(joinpath(@__DIR__,"tdlambda.toml"), @__DIR__)

    metasteps = [0.025, 0.05, 0.075, 0.1]
    lambdas = [0.0, 0.4, 0.8, 0.9]
    N = length(lambdas)
    cfgs = []
    for i=1:N
        for j=1:N
            push!(cfgs, (metasteps[j],lambdas[i]))
        end
    end

    for i=1:total_combinations(cfg)
        cfg = parse!(cfg, i)
        subconfig = get_subconfig(cfg, "agent")
        tru = cfgs[i]
        @test subconfig["metastep"] == tru[1]
        @test subconfig["lambda"] == tru[2]
    end
end

@testset "Config.jl Tests:" begin
    manager_tests()
    manager_tests_toml()
end
