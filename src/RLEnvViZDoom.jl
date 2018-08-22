__precompile__(false)
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
listallactions() = listconsts(:Button)
listallscreenresolutions() = listconsts(:ScreenResolution)
listallscreenformats() = listconsts(:ScreenFormat)
listallmodes() = listconsts(:Mode)
listbasicmoveactions() = [:MOVE_FORWARD, :TURN_RIGHT, :TURN_LEFT]
function defaultrenderdict()
    d = Dict()
    for name in names(vz, all = true)
        sname = string(name)
        if length(sname) >= 10 && sname[1:10] == "set_render"
            d[name] = false
        end
    end
    d
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
    ViZDoomEnvironment(scenario, map; 
                       actions = listallactions(),
                       mode = :PLAYER,
                       screenformat = :RGB24,
                       screenresolution = :RES_160X120,
                       showscreen = false,
                       livingreward = 0,
                       episodelength = 500,
                       render = defaultrenderdict())
"""
function ViZDoomEnvironment(; kw...)
    defaults = (screen_format = :GRAY8, screen_resolution = :RES_160X120, 
                window_visible = false, living_reward = 0, 
                episode_timeout = 500)
    config = merge(defaults, kw)
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
    sleep(env.sleeptime)
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

export listallactions, listbasicmoveactions, listallscreenresolutions,
listallscreenformats, listallmodes, defaultrenderdict, close!, init!
end # module
