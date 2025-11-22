using PyPlot  # Pour l'affichage graphique
using Printf
using Random

include("loadSPP.jl")
include("setSPP.jl")
include("algoconstru.jl")
include("algoAmelioration.jl")

# Fonction pour exécuter l'algorithme sur toutes les instances d'un dossier
function test_instances(folder_path::String)
    # Récupérer tous les fichiers dans le dossier
    files = filter(x -> endswith(x, ".dat"), readdir(folder_path, join=true))
    println("Instances trouvées : ", files)

    # Stocker les résultats
    instance_names = String[]
    initial_scores = Float64[]
    improved_scores = Float64[]

    for fname in files
        println("\n=== Chargement de l'instance SPP ===")
        println("Instance : ", fname)

        # Charger l'instance
        C, A = loadSPP(fname)
        println("Nombre d'ensembles (colonnes) = ", length(C))
        println("Nombre d'éléments (lignes)    = ", size(A, 1))

        # Phase 1 : Construction
        t_construct = @elapsed begin
            x_init = SPP(C, A)
        end
        valeur_init = sum(C[j] for j in x_init)

        # Phase 2 : Recherche Tabou
        n = length(x_init)
        taille_voisinage = (n * (n - 1)) / 2
        l_tabou = (taille_voisinage ÷ 2)
        nb_iterations = 300

        println("\nx_init : ", x_init)
        println("taille tabou : ", l_tabou)
        println("taille voisinage : ", taille_voisinage)

        t_improve = @elapsed begin
            x_up, valeur_up = tabou_upgrade(C, A, x_init, l_tabou, nb_iterations, fname)
        end

        println("\nSolution initiale : ", valeur_init)
        println("Solution améliorée tabou : ", valeur_up)

        # Stocker les résultats
        push!(instance_names, split(fname, "/")[end])
        push!(initial_scores, valeur_init)
        push!(improved_scores, valeur_up)
    end

    # Générer le graphique
    println("\n=== Génération du graphique ===")
    figure("Scores des solutions améliorées", figsize=(10, 6))
    title("Scores des solutions améliorées pour chaque instance")
    xlabel("Instances")
    ylabel("Score")
    xticks(1:length(instance_names), instance_names, rotation=45, fontsize=8)

    plot(1:length(instance_names), initial_scores, linestyle="--", marker="o", color="blue", label="Score initial")
    plot(1:length(instance_names), improved_scores, linestyle="-", marker="x", color="red", label="Score amélioré")

    legend(loc="upper left")
    grid(true)
    tight_layout()

    savefig("scores_instances.png")
    println("Graphique sauvegardé sous 'scores_instances.png'")
end

# Exécuter la fonction sur le dossier dat
test_instances("PenetRodriguesEI3/dat")