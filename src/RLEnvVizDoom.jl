__precompile__(false)
module RLEnvVizDoom
using Reexport
@reexport using ReinforcementLearning
import ReinforcementLearning:interact!, reset!, getstate

module ViZDoomWrapper
using CxxWrap
wrap_module(joinpath(ENV["LIBVIZDOOMPATH"], "libvizdoomjl"), ViZDoomWrapper)
end
const vz = ViZDoomWrapper

function listconsts(typ)
    allconsts = names(vz, true)
    idx = find(x -> typeof(getfield(vz, x)) == getfield(vz, typ), allconsts)
    allconsts[idx]
end
listallactions() = listconsts(:Button)
listallscreenresolutions() = listconsts(:ScreenResolution)
listallscreenformats() = listconsts(:ScreenFormat)
listallmodes() = listconsts(:Mode)
listbasicmoveactions() = [:MOVE_FORWARD, :TURN_RIGHT, :TURN_LEFT]
function defaultrenderdict()
    d = Dict()
    for name in names(vz, true)
        sname = string(name)
        if length(sname) >= 10 && sname[1:10] == "set_render"
            d[name] = false
        end
    end
    d
end

"""
    struct VizDoomEnvironment
        game::vz.DoomGameAllocated
        actions::Array{Array{Float64, 1}, 1}
        sleeptime::Float64
"""
struct VizDoomEnvironment
    game::vz.DoomGameAllocated
    actions::Array{Array{Float64, 1}, 1}
    sleeptime::Float64
end
export VizDoomEnvironment
"""
    VizDoomEnvironment(scenario, map; 
                       actions = listallactions(),
                       mode = :PLAYER,
                       screenformat = :RGB24,
                       screenresolution = :RES_160X120,
                       showscreen = false,
                       livingreward = 0,
                       episodelength = 500,
                       render = defaultrenderdict())
"""
function VizDoomEnvironment(scenario, map; 
                            actions = listallactions(),
                            mode = :PLAYER,
                            screenformat = :RGB24,
                            screenresolution = :RES_160X120,
                            showscreen = false,
                            livingreward = 0,
                            episodelength = 500,
                            render = defaultrenderdict())
    game = vz.DoomGame()
    vz.set_doom_scenario_path(game, scenario)
    vz.set_doom_map(game, map)
    vz.set_mode(game, getfield(vz, mode))
    vz.set_screen_format(game, getfield(vz, screenformat))
    vz.set_screen_resolution(game, getfield(vz, screenresolution))
    vz.set_window_visible(game, showscreen)
    vz.set_living_reward(game, livingreward)
    vz.set_episode_timeout(game, episodelength)
    for a in actions vz.add_available_button(game, getfield(vz, a)) end
    for (r, v) in render getfield(vz, r)(game, v) end
    na = length(actions)
    if showscreen
        sleeptime = 1.0 / vz.DEFAULT_TICRATE
    else
        sleeptime = 0.
    end
    env = VizDoomEnvironment(game, 
                             [Float64[i == j for i in 1:na] for j in 1:na], 
                             sleeptime)
    init!(env)
    env
end

function interact!(a, env::VizDoomEnvironment)
    r = vz.make_action(env.game, env.actions[a])
    state = vz.get_state(env.game)
    done = vz.is_episode_finished(env.game)
    sleep(env.sleeptime)
    return state, r, done
end
function reset!(env::VizDoomEnvironment)
    vz.new_episode(env.game)
    return Nothing
end
function getstate(env::VizDoomEnvironment)
    vz.get_state(env.game), vz.is_episode_finished(env.game)
end

close!(env::VizDoomEnvironment) = vz.close(env.game)
init!(env::VizDoomEnvironment) = vz.init(env.game)

export listallactions, listbasicmoveactions, listallscreenresolutions,
listallscreenformats, listallmodes, defaultrenderdict, close!, init!
end # module
