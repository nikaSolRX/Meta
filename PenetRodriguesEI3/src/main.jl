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

#@show C
#@show A

#xlist1 = SCP(C,A)

#println("Solution initiale calculée : ")
#println(xlist1)


#xbest= amelioration_1_1_exchange(C,A,xlist1)
#println("Solution Amélioré : ")


using Printf
using Random
# ===================== Phase 1 : Construction =====================
t_construct = @elapsed begin
    x_init = SPP(C, A)
end

valeur = sum(C[j] for j in x_init)



k = length(x_init)
l_tabou = (k ÷ 2)
nb_iterations = 1000
graph = true
println("\nx_init : ", x_init)
println("taille tabou : ", l_tabou)
x_up, valeur_up = tabou_upgrade(C, A, x_init, 10, nb_iterations, instance, graph)
#x_up, valeur_up = tabou_upgrade_advanced(C, A, x_init, l_tabou, nb_iterations)

println("\nx_init : ", x_init)
println("solution initiale : ", valeur)
println("x_update tabou : ", x_up)
println("taille tabou : ", l_tabou)
println("solution améliorée tabou : ", valeur_up)

#=
z0 = sum(C .* x_init) |> float

println("Phase 1 : Construction gloutonne")
println("  Valeur initiale x_init = \n", x_init)
@printf("  Valeur initiale ẑ₀ = %.1f\n", z0)
@printf("  Temps construction = %.3f s\n\n", t_construct)

# ===================== Phase 2 : Amélioration =====================
t_improve = @elapsed begin
    x_best, z1, iteration = local_search_spp_swap(C, A, x_init)
end
#z1   = sum(C .* x_best)
gain = z1 - z0

println("→ Phase 2 : Amélioration locale rapide")
println("  Valeur améliorée x_best = \n", x_best)
@printf("  Valeur finale ẑ₁ = %.1f\n", z1)
@printf("  Gain Δz = %.1f\n", gain)
@printf("  Temps amélioration = %.3f s\n\n", t_improve)

# ===================== Résumé (affichage double) ==================
println(" Résumé de l’exécution :")
@printf("  ẑ₀ = %.1f   →   ẑ₁ = %.1f\n", z0, z1)
@printf("  Gain total : %.1f\n", gain)
@printf("  Temps total : %.2f s\n", t_construct + t_improve)

# Ligne compacte pour ton tableau (instance ; z0 ; t0 ; z1 ; t1)
@printf("\n[Table] %s ; %.0f ; %.2f ; %.0f ; %.2f\n",
        fname, z0, t_construct, z1, t_improve)

=#