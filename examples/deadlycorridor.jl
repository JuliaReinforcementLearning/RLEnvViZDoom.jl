using ReinforcementLearningEnvironmentViZDoom, Flux, GR, JLD2
using Compat: @info
const withgpu = true
const gpudevice = 0

if withgpu 
    using CUDAnative
    device!(gpudevice)
    using CuArrays
    const inputdtype = Float32
else
    const inputdtype = Float64
end
env = ViZDoomEnvironment(living_reward = .1, available_buttons =
[:ATTACK, :MOVE_LEFT, :MOVE_RIGHT, :MOVE_FORWARD, :TURN_LEFT, :TURN_RIGHT])
model = Chain(x -> x./inputdtype(255), Conv((8, 8), 2 => 16, relu, stride = (4, 4)), 
                         Conv((4, 4), 16 => 32, relu, stride = (2, 2)),
                         x -> reshape(x, :, size(x, 4)),
                         Dense(2592, 256, relu), 
                         Dense(256, length(env.actions)));
learner = DQN(model, opttype = x -> Flux.ADAM(x, .0001), 
              loss = huberloss, doubledqn = true,
              updatetargetevery = 2500, nsteps = 10,
              updateevery = 4, replaysize = 10^6, nmarkov = 2,
              startlearningat = 200000);
pchain = [ImageResizeNearestNeighbour((84, 84)),
          x -> reshape(x, (84, 84, 1))]
if withgpu push!(pchain, togpu) end
preprocessor = ImagePreprocessor((160, 120), pchain)
x = RLSetup(learner, 
            env,
            ConstantNumberSteps(4 * 10^6),
            preprocessor = preprocessor,
            callbacks = [Progress(5*10^2), EvaluationPerEpisode(TotalReward()),
                         LinearDecreaseEpsilon(5 * 10^4, 10^6, 1, .01)]);
@info "start learning."
@time learn!(x)
@save "modeldeadlycorridor.jld2" model
