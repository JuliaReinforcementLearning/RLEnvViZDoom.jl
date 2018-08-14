using RLEnvViZDoom, Test
import RLEnvViZDoom: interact!, reset!, getstate

function test1()
    env = ViZDoomEnvironment("", "map01")
    s, r, done = interact!(1, env)
    @test typeof(s) == Array{UInt8, 1}
    s = reset!(env)
    @test typeof(s) == Array{UInt8, 1}
    s, done = getstate(env)
    @test typeof(s) == Array{UInt8, 1}
end
test1()
