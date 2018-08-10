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

function interact!(a, env::VizDoomEnvironment)
    r = vz.make_action(env.game, env.actions[a])
    state = vz.get_screen(env.game)
    done = vz.is_episode_finished(env.game)
    sleep(env.sleeptime)
    return state, r, done
end

function reset!(env::VizDoomEnvironment)
    vz.new_episode(env.game)
    return nothing
end

function getstate(env::VizDoomEnvironment)
    vz.get_screen_buffer(env.game), vz.is_episode_finished(env.game)
end

close!(env::VizDoomEnvironment) = vz.close(env.game)
init!(env::VizDoomEnvironment) = vz.init(env.game)