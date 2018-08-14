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
function ViZDoomEnvironment(scenario, map; 
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
