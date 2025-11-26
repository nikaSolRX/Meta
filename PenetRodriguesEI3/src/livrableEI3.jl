# =========================================================================== #
# Compliant julia 1.x

# Using the following packages
using JuMP, GLPK
using LinearAlgebra
using Printf
using Random

include("loadSPP.jl")
include("setSPP.jl")
include("getfname.jl")
include("algoconstru.jl")
include("algoAmelioration.jl")

# =========================================================================== #
# Fonction principale : tabouSPP
function tabouSPP(instance::String, iterations::Int, taille_tabou::Int = -1)
    # Chargement de l'instance
    println("\n=== Chargement de l'instance SPP ===")
    println("\nLoading...")
    fname = instance
    n_instance = split(fname, "/")[end]

    C, A = loadSPP(fname)

    println("\nInstance : ", fname)
    println("Nombre d'ensembles (colonnes) = ", length(C))
    println("Nombre d'éléments (lignes)    = ", size(A, 1))

    # Construction gloutonne
    t_construct = @elapsed begin
        x_init = SPP(C, A)
    

        valeur = sum(C[j] for j in x_init)

        # Calcul de la taille tabou par défaut si non spécifiée
        k = length(x_init)
        if taille_tabou == -1
            taille_tabou = k ÷ 2
        end

        graph = true
        println("\nx_init : ", x_init)
        println("taille tabou : ", taille_tabou)

        # Recherche tabou
        x_up, valeur_up = tabou_upgrade(C, A, x_init, taille_tabou, iterations, n_instance, graph)
    end

    #println("\nx_init : ", x_init)
    println("solution initiale : ", valeur)
    #println("x_update tabou : ", x_up)
    println("taille tabou : ", taille_tabou)
    println("solution améliorée tabou : ", valeur_up)

    # Résumé
    println(" Résumé de l’exécution :")
    @printf("  ẑ₀ = %.1f   →   ẑ₁ = %.1f\n", valeur, valeur_up)
    @printf("  Gain total : %.1f\n", valeur_up - valeur)
    @printf("  Temps total : %.2f s\n", t_construct)

    # Ligne compacte pour ton tableau (instance ; z0 ; t0 ; z1 ; t1)
    @printf("\n[Table] %s ; %.0f ; %.2f ; %.0f ; %.2f\n",
            fname, valeur, t_construct, valeur_up, iterations)

    return x_up, valeur_up
end

# Exemple d'appel depuis la console
# tabouSPP("dat/pb_1000rnd0300.dat", 600)