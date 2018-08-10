module ViZDoom

using CxxWrap
@wrapmodule(joinpath(@__DIR__, "..", "deps", "usr", "ViZDoom-1.1.6", "bin", "libvizdoomjl.so"), :ViZDoom)

end