using JuMP, GLPK
using LinearAlgebra

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("algoconstru.jl")
include("algoAmelioration.jl")

# =========================================================================== #

# =========================================================================== #
# 1️ Chargement d'une instance du Set Packing Problem
# =========================================================================== #
println("\n=== Chargement de l'instance SPP ===")

# Loading a SPP instance
println("\nLoading...")
fname = "PenetRodriguesEI1/dat/pb_1000rnd0300.dat"
#fname = "PenetRodriguesEI1/dat/didactic.dat"

C, A = loadSPP(fname)

println("\nInstance : ", fname)
println("Nombre d'ensembles (colonnes) = ", length(C))
println("Nombre d'éléments (lignes)    = ", size(A, 1))

@show C
@show A

@time xlist1, z = SCP(C,A)

println("Solution initiale calculée : ")
println(xlist1)
println("Z = ",z);

println("Solution améliorée : ")
@time xupd, z1 = amelioration(C, A, xlist1)
println(xupd)
println("Z' = ",z1)


#xbest= amelioration_1_1_exchange(C,A,xlist1)
#println("Solution Amélioré : ")

