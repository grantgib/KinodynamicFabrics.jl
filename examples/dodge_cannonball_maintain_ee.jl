using Revise 
using KinodynamicFabrics
using KinodynamicFabrics.DigitInterface
using KinodynamicFabrics.MuJoCo.PythonCall
using KinodynamicFabrics.LinearAlgebra


const kfb = KinodynamicFabrics
const di = DigitInterface 

F = 1e1
N = 30

# init Digit
visualize = true
digit = load_digit(;visualize=visualize)

## task goals
xᵨs = Dict()

# level 1 
xᵨs[:upper_body_posture] = [-0.15, 1.1, 0, -0.145, 0.15, -1.1, 0, 0.145] 
xᵨs[:com_target] = [0.0, -0.15, 0.9, -0.0, 0.15, 0.9, 0.0, 0.0]
xᵨs[:open_arms_posture] = [-0.337, 0.463, -0.253, 0, 0.337, -0.463, 0.253, 0]
xᵨs[:close_arms_posture] = [0.0, 0.463, 0.253, 0, -0.0, -0.463, -0.253, 0]
xᵨs[:clutch_arms_posture] = [0.0, 0.463, 0.253, -0.5, 0.0, -0.463, -0.253, 0.5]
xᵨs[:normal_posture] = [0.0, 0.463, 0.253, 0, -0.0, -0.463, -0.253, 0]
xᵨs[:lower_body_posture] = [0.31, 0.2, 0.19, -0.31, -0.2, -0.19]
xᵨs[:zmp] = [0.0, 0.0]
xᵨs[:left_hand_target] = [0.2, 0.3, 0.8]
xᵨs[:right_hand_target] = [0.6, -0.5, 1.3] 

## task maps
ψs = Dict() 
ψs[:level4] = []
ψs[:level3] = [] 
ψs[:level2] = [] 
ψs[:level1] = [ 
                :lower_body_posture, 
                :dodge,
                :zmp_upper_limit,
                :zmp_lower_limit,
                :right_hand_target,
                :left_hand_target, 
                :joint_lower_limit,
                :joint_upper_limit
               ] 


## Task weights
Ws = Dict() 
Ws[:lower_body_posture] = 0.7e0 
Ws[:left_hand_target] = 1e0
Ws[:right_hand_target] = 1e0
Ws[:dodge] = 1e1
Ws[:zmp_upper_limit] = 1e-1
Ws[:zmp_lower_limit] = 1e-1
Ws[:joint_lower_limit] = 1e-1
Ws[:joint_upper_limit] = 1e-1

## Priorities
Pr = Dict() 
Pr[:lower_body_posture] = 2 
Pr[:left_hand_target] = 2
Pr[:right_hand_target] = 2
Pr[:dodge] = 2
Pr[:zmp_upper_limit] = 1
Pr[:zmp_lower_limit] = 1
Pr[:joint_lower_limit] = 2
Pr[:joint_upper_limit] = 2

## dynamics functions
g = kfb.dyn.generalized_gravity
M = kfb.dyn.mass_inertia_matrix

## selection matrics 
s_leg = zeros(N)
s_leg[digit.leg_joint_indices] .= 1.0
S_leg = diagm(s_leg)

s_arm = zeros(N)
s_arm[digit.arm_joint_indices] .= 1.0
S_arm = diagm(s_arm)

s_whole = zeros(N)
s_whole[[digit.arm_joint_indices; digit.leg_joint_indices]] .= 1.0
S_whole = diagm(s_whole)

s_toes = zeros(N)
s_toes[[di.qleftToePitch, di.qleftToeRoll, di.qrightToePitch, di.qrightToeRoll]] .= 1.0
S_toes = diagm(s_toes)

Ss = Dict()  
Ss[:lower_body_posture] = S_leg 
Ss[:left_hand_target] = S_whole  
Ss[:right_hand_target] = S_whole  
Ss[:dodge] = S_leg 
Ss[:zmp_upper_limit] = S_toes 
Ss[:zmp_lower_limit] = S_toes 
Ss[:joint_lower_limit] = S_arm
Ss[:joint_upper_limit] = S_arm


data = Dict()
data[:obstacle] = Dict(
                :radius=>0.15,
                :position=>zeros(3),
                :max_range=>15.0
)

data[:zmp] = Dict(
                :prev_time=>0.0,
                :prev_com_vel=>[0.0, 0.0],
                :g=>9.806, 
                :prev_zmp=>[0.0, 0.0],
                :prev_a=>[0.0, 0.0],
                :filter=>0.01,
                :lower_limit=>-0.1,
                :upper_limit=>0.1
) 
 

Js = nothing
Obstacles = nothing

problem = FabricProblem(ψs, Js, g, M, Ss, xᵨs, Ws, Obstacles, Pr, data,
zeros(N), zeros(N), 1.0/F, N, digit, 0.0)
 

digit.problem = problem
digit.obstacle_force = -1.0 #Newtons
step(digit)
dists = []

#Horizon
T = 3 # seconds
Horizon = T/digit.Δt # timesteps

for i = 1:Horizon
    fabric_controller!(digit)
    step(digit)
    render_sim(digit, visualize)  
end

if visualize digit.viewer.close() end 
:Done