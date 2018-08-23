module RLEnvViZDoom
using Reexport
@reexport using ReinforcementLearning
import ReinforcementLearning:interact!, reset!, getstate
using ViZDoom
const vz = ViZDoom

function listconsts(typ)
    allconsts = names(vz, all = true)
    idx = findall(x -> typeof(getfield(vz, x)) == getfield(vz, typ), allconsts)
    allconsts[idx]
end
list_available_buttons() = listconsts(:Button)
list_screen_resolution() = listconsts(:ScreenResolution)
list_screen_format() = listconsts(:ScreenFormat)
list_mode() = listconsts(:Mode)
function list_options()
    allconsts = names(vz, all = true)
    idx = findall(x -> length(string(x)) > 2 && string(x)[1:3] == "set", allconsts)
    map(x -> Symbol(string(x)[5:end]), allconsts[idx])
end

"""
    struct ViZDoomEnvironment
        game::vz.DoomGameAllocated
        actions::Array{Array{Float64, 1}, 1}
        sleeptime::Float64
"""
struct ViZDoomEnvironment
    game::vz.DoomGameAllocated
    actions::Array{Array{Float64, 1}, 1}
    sleeptime::Float64
end
export ViZDoomEnvironment
"""
    ViZDoomEnvironment(; kw...)

Creates a new ViZDoomEnvironment. Use `list_options()` for possible `kw` and
`list_available_buttons()`, `list_screen_resolution()`, `list_screen_format()`,
`list_mode()` for possible values.
"""
function ViZDoomEnvironment(; kw...)
    defaults = (screen_format = :GRAY8, screen_resolution = :RES_160X120, 
                window_visible = false, living_reward = 0, 
                episode_timeout = 500)
    config = Dict(pairs(merge(defaults, kw)))
    for (k, v) in config
        if typeof(v) == Symbol
            config[k] = getfield(vz, v)
        elseif typeof(v) <: AbstractArray && typeof(v[1]) == Symbol
            config[k] = map(x -> getfield(vz, x), v)
        end
    end
    game = vz.basic_game(; config...)
    if config[:window_visible]
        sleeptime = 1.0 / vz.DEFAULT_TICRATE
    else
        sleeptime = 0.
    end
    na = haskey(config, :available_buttons) ? length(config[:available_buttons]) : 3
    env = ViZDoomEnvironment(game, 
                             [Float64[i == j for i in 1:na] for j in 1:na], 
                             sleeptime)
    init!(env)
    env
end

function interact!(a, env::ViZDoomEnvironment)
    r = vz.make_action(env.game, env.actions[a])
    done = vz.is_episode_finished(env.game)
    if done
        state = zeros(UInt8, vz.get_screen_size(env.game))
    else
        state = vz.get_screen_buffer(env.game)
    end
    if env.sleeptime > 0 sleep(env.sleeptime) end
    return state, r, done
end
function reset!(env::ViZDoomEnvironment)
    vz.new_episode(env.game)
    vz.get_screen_buffer(env.game)
end
function getstate(env::ViZDoomEnvironment)
    vz.get_screen_buffer(env.game), vz.is_episode_finished(env.game)
end

close!(env::ViZDoomEnvironment) = vz.close(env.game)
init!(env::ViZDoomEnvironment) = vz.init(env.game)

export list_available_buttons, list_screen_resolution,
list_screen_format, list_mode, list_options, close!, init!
end # module
