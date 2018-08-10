module RLEnvVizDoom

include("ViZDoom.jl")
export ViZDoom

const vz = ViZDoom

include("vizdoomenv.jl")
export listallactions, listbasicmoveactions, listallscreenresolutions,
listallscreenformats, listallmodes, defaultrenderdict, close!, init!, VizDoomEnvironment

end # module