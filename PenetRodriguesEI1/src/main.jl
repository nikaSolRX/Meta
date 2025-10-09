# =========================================================================== #
# Compliant julia 1.x

# Using the following packages
using JuMP, GLPK
using LinearAlgebra

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("algoconstru.jl")
include("algoAmelioration.jl")
# =========================================================================== #

# Loading a SPP instance
println("\nLoading...")
#fname = "Data/pb_100rnd0100.dat"
fname = "Data/didactic.dat"
C, A = loadSPP(fname)
@show C
@show A

xlist1 = SCP(C,A)

println("Solution initiale calculée : ")
println(xlist1)


xbest= amelioration_1_1_exchange(C,A,xlist1)
println("Solution Amélioré : ")
println(xbest)