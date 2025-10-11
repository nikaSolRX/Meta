using JuMP, GLPK
using LinearAlgebra

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("algoconstru.jl")

# =========================================================================== #

# Loading a SPP instance
println("\nLoading...")
# fname = "Data/didactic.dat"
fname = "Data/pb_1000rnd0300.dat"
C, A = loadSPP(fname)
@show C
@show A

xlist1, z = SCP(C,A)

println("Solution initiale calculée : ")
println(xlist1)
println("Z = ",z);