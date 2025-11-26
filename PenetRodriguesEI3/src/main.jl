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

# =========================================================================== #
# 1️ Chargement d'une instance du Set Packing Problem
# =========================================================================== #
println("\n=== Chargement de l'instance SPP ===")

# Loading a SPP instance
println("\nLoading...")
fname = "PenetRodriguesEI3/dat/pb_1000rnd0300.dat"
#fname = "PenetRodriguesEI3/dat/mimi.dat"
#fname = "PenetRodriguesEI3/dat/didactic.dat"

instance = split(fname, "/")[end]

C, A = loadSPP(fname)

println("\nInstance : ", fname)
println("Nombre d'ensembles (colonnes) = ", length(C))
println("Nombre d'éléments (lignes)    = ", size(A, 1))

using Printf
using Random

t_construct = @elapsed begin
    x_init = SPP(C, A)
end

valeur = sum(C[j] for j in x_init)



k = length(x_init)
l_tabou = (k ÷ 2)
nb_iterations = 10
graph = true
println("\nx_init : ", x_init)
println("taille tabou : ", l_tabou)
x_up, valeur_up = tabou_upgrade(C, A, x_init, 10, nb_iterations, instance, graph)

println("\nx_init : ", x_init)
println("solution initiale : ", valeur)
println("x_update tabou : ", x_up)
println("taille tabou : ", l_tabou)
println("solution améliorée tabou : ", valeur_up)