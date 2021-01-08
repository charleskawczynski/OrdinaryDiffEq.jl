using OrdinaryDiffEq, RecursiveArrayTools, Test, StaticArrays, DiffEqCallbacks


f = function (u,p,t)
  - u + sin(-t)
end


prob = ODEProblem(f,1.0,(0.0,-10.0))

condition= function (u,t,integrator) # Event when event_f(u,t,k) == 0
  - t - 2.95
end

affect! = function (integrator)
  integrator.u = integrator.u + 2
end

callback = ContinuousCallback(condition,affect!)

sol = solve(prob,Tsit5(),callback=callback)
@test length(sol) < 20

condition= function (out, u,t,integrator) # Event when event_f(u,t,k) == 0
  out[1] = - t - 2.95
end

affect! = function (integrator, idx)
  if idx == 1
    integrator.u = integrator.u + 2
  end
end

callback = VectorContinuousCallback(condition,affect!,1)

sol = solve(prob,Tsit5(),callback=callback)

f = function (du,u,p,t)
  du[1] = - u[1] + sin(t)
end


prob = ODEProblem(f,[1.0],(0.0,10.0))

condition= function (u,t,integrator) # Event when event_f(u,t,k) == 0
  t - 2.95
end

affect! = function (integrator)
  integrator.u = integrator.u .+ 2
end

callback = ContinuousCallback(condition,affect!)

sol = solve(prob,Tsit5(),callback=callback,abstol=1e-8,reltol=1e-6)

condition= function (out, u,t,integrator) # Event when event_f(u,t,k) == 0
  out[1] = t - 2.95
end

affect! = function (integrator, idx)
  if idx == 1
    integrator.u = integrator.u .+ 2
  end
end

callback = VectorContinuousCallback(condition,affect!,1)

sol = solve(prob,Tsit5(),callback=callback,abstol=1e-8,reltol=1e-6)

f = function (du,u,p,t)
  du[1] = u[2]
  du[2] = -9.81
end

condition= function (u,t,integrator) # Event when event_f(u,t,k) == 0
  u[1]
end

affect! = nothing
affect_neg! = function (integrator)
  integrator.u[2] = -integrator.u[2]
end

callback = ContinuousCallback(condition,affect!,affect_neg!,interp_points=100)

u0 = [50.0,0.0]
tspan = (0.0,15.0)
prob = ODEProblem(f,u0,tspan)


sol = solve(prob,Tsit5(),callback=callback,adaptive=false,dt=1/4)

condition= function (out, u,t,integrator) # Event when event_f(u,t,k) == 0
  out[1] = u[1]
end

affect! = nothing
affect_neg! = function (integrator, idx)
  if idx == 1
    integrator.u[2] = -integrator.u[2]
  end
end

vcb = VectorContinuousCallback(condition,affect!,1,interp_points=100)

sol = solve(prob,Tsit5(),callback=vcb,adaptive=false,dt=1/4)

condition_single = function (u,t,integrator) # Event when event_f(u,t,k) == 0
  u
end

affect! = nothing
affect_neg! = function (integrator)
  integrator.u[2] = -integrator.u[2]
end

callback_single = ContinuousCallback(condition_single,affect!,affect_neg!,interp_points=100,idxs=1)

u0 = [50.0,0.0]
tspan = (0.0,15.0)
prob = ODEProblem(f,u0,tspan)

sol = solve(prob,Tsit5(),callback=callback_single,adaptive=false,dt=1/4)
sol = solve(prob,Tsit5(),callback=callback_single,save_everystep=false)
t = sol.t[end÷2] # this is the callback time point
sol = solve(prob,Tsit5(),callback=callback_single,saveat=t)
@test count(x->x==t, sol.t) == 2
sol = solve(prob,Tsit5(),callback=callback_single,saveat=t-eps(t))
@test count(x->x==t, sol.t) == 2
# check interpolation @ discontinuity
@test sol(t,continuity=:right)[2] > 0
@test sol(t,continuity=:left)[2] < 0

#plot(sol,denseplot=true)

condition_single = function (out,u,t,integrator) # Event when event_f(u,t,k) == 0
  out[1] = u[1]
end

affect! = nothing
affect_neg! = function (integrator,idx)
  if idx == 1
    integrator.u[2] = -integrator.u[2]
  end
end

callback_single = VectorContinuousCallback(condition_single,affect!,affect_neg!,1,interp_points=100)

sol = solve(prob,Tsit5(),callback=callback_single,adaptive=false,dt=1/4)
sol = solve(prob,Tsit5(),callback=callback_single,save_everystep=false)
t = sol.t[end÷2] # this is the callback time point
sol = solve(prob,Tsit5(),callback=callback_single,saveat=t)
@test count(x->x==t, sol.t) == 2
sol = solve(prob,Tsit5(),callback=callback_single,saveat=t-eps(t))
@test count(x->x==t, sol.t) == 2
# check interpolation @ discontinuity
@test sol(t,continuity=:right)[2] > 0
@test sol(t,continuity=:left)[2] < 0


sol = solve(prob,Vern6(),callback=callback)
sol = solve(prob,Vern6(),callback=vcb)
#plot(sol,denseplot=true)
sol = solve(prob,BS3(),callback=vcb)
sol = solve(prob,BS3(),callback=callback)

sol33 = solve(prob,Vern7(),callback=callback)
sol33 = solve(prob,Vern7(),callback=vcb)

bounced = ODEProblem(f,sol[8],(0.0,1.0))
sol_bounced = solve(bounced,Vern6(),callback=callback,dt=sol.t[9]-sol.t[8])
#plot(sol_bounced,denseplot=true)
sol_bounced(0.04) # Complete density
@test maximum(maximum.(map((i)->sol.k[9][i]-sol_bounced.k[2][i],1:length(sol.k[9])))) == 0


sol2= solve(prob,Vern6(),callback=callback,adaptive=false,dt=1/2^4)
#plot(sol2)

sol2= solve(prob,Vern6())

sol3= solve(prob,Vern6(),saveat=[.5])

## Saving callback

condition = function (u,t,integrator)
  true
end
affect! = function (integrator) end

save_positions = (true,false)
saving_callback = DiscreteCallback(condition,affect!,save_positions=save_positions)

sol4 = solve(prob,Tsit5(),callback=saving_callback)

@test sol2(3) ≈ sol(3)

affect! = function (integrator)
  u_modified!(integrator,false)
end
saving_callback2 = DiscreteCallback(condition,affect!,save_positions=save_positions)
sol4 = solve(prob,Tsit5(),callback=saving_callback2)

cbs = CallbackSet(saving_callback,saving_callback2)
sol4_extra = solve(prob,Tsit5(),callback=cbs)

@test length(sol4_extra) == 2length(sol4) - 1

condition= function (u,t,integrator)
  u[1]
end

vcondition= function (out,u,t,integrator)
  out[1] = u[1]
end

affect! = function (integrator, retcode = nothing)
  if retcode === nothing
    terminate!(integrator)
  else
    terminate!(integrator, retcode)
  end
end

vaffect! = function (integrator, idx, retcode = nothing)
  if idx == 1
    if retcode === nothing
      terminate!(integrator)
    else
      terminate!(integrator, retcode)
    end
  end
end

terminate_callback = ContinuousCallback(condition,affect!)
custom_retcode_callback = ContinuousCallback(condition,x->affect!(x,:Custom))
vterminate_callback = VectorContinuousCallback(vcondition,vaffect!,1)
vcustom_retcode_callback = VectorContinuousCallback(vcondition,(x,idx)->vaffect!(x,idx,:Custom),1)

tspan2 = (0.0,Inf)
prob2 = ODEProblem(f,u0,tspan2)

sol5 = solve(prob2,Tsit5(),callback=terminate_callback)
sol5_1 = solve(prob2,Tsit5(),callback=custom_retcode_callback)

@test sol5.retcode == :Terminated
@test sol5_1.retcode == :Custom
@test sol5[end][1] < 3e-12
@test sol5.t[end] ≈ sqrt(50*2/9.81)

sol5 = solve(prob2,Tsit5(),callback=vterminate_callback)
sol5_1 = solve(prob2,Tsit5(),callback=vcustom_retcode_callback)

@test sol5.retcode == :Terminated
@test sol5_1.retcode == :Custom
@test sol5[end][1] < 3e-12
@test sol5.t[end] ≈ sqrt(50*2/9.81)

affect2! = function (integrator)
  if integrator.t >= 3.5
    terminate!(integrator)
  else
    integrator.u[2] = -integrator.u[2]
  end
end

vaffect2! = function (integrator,idx)
  if idx == 1
    if integrator.t >= 3.5
      terminate!(integrator)
    else
      integrator.u[2] = -integrator.u[2]
    end
  end
end

terminate_callback2 = ContinuousCallback(condition,nothing,affect2!,interp_points=100)
vterminate_callback2 = VectorContinuousCallback(vcondition,nothing,vaffect2!,1,interp_points=100)


sol5 = solve(prob2,Vern7(),callback=terminate_callback2)

@test sol5[end][1] < 1.3e-10
@test sol5.t[end] ≈ 3*sqrt(50*2/9.81)

sol5 = solve(prob2,Vern7(),callback=vterminate_callback2)

@test sol5[end][1] < 1.3e-10
@test sol5.t[end] ≈ 3*sqrt(50*2/9.81)

condition= function (u,t,integrator) # Event when event_f(u,t,k) == 0
  t-4
end

affect! = function (integrator)
  terminate!(integrator)
end

terminate_callback3 = ContinuousCallback(condition,affect!,interp_points=1000)

bounce_then_exit = CallbackSet(callback,terminate_callback3)

sol6 = solve(prob2,Vern7(),callback=bounce_then_exit)

@test sol6[end][1] > 0
@test sol6[end][1] < 100
@test sol6.t[end] ≈ 4

# Test ContinuousCallback hits values on the steps
t_event = 100.0
f_simple(u,p,t) = 1.00001*u
event_triggered = false
condition_simple(u,t,integrator) = t_event-t
function affect_simple!(integrator)
  global event_triggered
  event_triggered = true
end
cb = ContinuousCallback(condition_simple, nothing, affect_simple!)
prob = ODEProblem(f_simple, [1.0], (0.0, 2.0*t_event))
sol = solve(prob,Tsit5(),callback=cb, adaptive = false, dt = 10.0)
@test event_triggered

# https://github.com/JuliaDiffEq/OrdinaryDiffEq.jl/issues/328
ode = ODEProblem((du, u, p, t) -> (@. du .= -u), ones(5), (0.0, 100.0))
sol = solve(ode, AutoTsit5(Rosenbrock23()), callback=TerminateSteadyState())
sol1 = solve(ode, Tsit5(), callback=TerminateSteadyState())
@test sol.u == sol1.u

# DiscreteCallback
f = function (du,u,p,t)
  du[1] = -0.5*u[1] + 10
  du[2] = -0.5*u[2]
end

u0 = [10,10.]
tstop = [5.;8.]
prob = ODEProblem(f, u0, (0, 10.))
condition = (u,t,integrator) -> t in tstop
affect! = (integrator) -> integrator.u .= 1.0
save_positions = (true,true)
cb = DiscreteCallback(condition, affect!, save_positions=save_positions)
sol1 = solve(prob,Tsit5(),callback = cb,tstops=tstop,saveat=tstop)
@test count(x->x==tstop[1], sol1.t) == 2
@test count(x->x==tstop[2], sol1.t) == 2
sol2 = solve(prob,Tsit5(),callback = cb,tstops=tstop,saveat=prevfloat.(tstop))
@test count(x->x==tstop[1], sol2.t) == 2
@test count(x->x==tstop[2], sol2.t) == 2

# check VectorContinuousCallback works for complex valued solutions
# see issue #1222
f = (u,p,t) -> -1.0im * u
prob = ODEProblem(f, complex([1.0]), (0.0, 1.0))
condition = function(out, u, t, integrator)
  out[1] = t - 0.5
end
n = 0
affect! = function(integrator, event_index)
  global n
  n += 1
end
callback = VectorContinuousCallback(condition, affect!, 1)
sol = solve(prob, Tsit5(), callback=callback)
@test n == 1

# check that multiple discrete callbacks with save_everystep do not double save
# https://github.com/SciML/DifferentialEquations.jl/issues/711

prob = ODEProblem((u,p,t)->1.01u,[1.0],(0.0,10.0))
savecond1(u,t,integrator) = t == 2.5
savecond2(u,t,integrator) = t == 2.5
saveaffect1!(integrator) = nothing
saveaffect2!(integrator) = nothing
cb1 = DiscreteCallback(savecond1,saveaffect1!,save_positions = (false,false))
cb2 = DiscreteCallback(savecond2,saveaffect2!,save_positions = (false,false))
cb = CallbackSet(cb1,cb2)
sol = solve(prob,Tsit5(),callback = cb,tstops = [2.5])
@test !any(diff(sol.t) .== 0)
