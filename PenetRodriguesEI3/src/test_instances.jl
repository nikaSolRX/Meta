using PyPlot
using Printf
using Random

include("loadSPP.jl")
include("algoconstru.jl")
include("algoAmelioration.jl")

function test_instances_csv(folder_path::String)
    # Récupérer les fichiers .dat
    files = filter(x -> endswith(x, ".dat"), readdir(folder_path, join=true))
    println("Instances trouvées : ", length(files))

    # Préparation des données pour le graphique
    instance_names = String[]
    initial_scores = Float64[]
    mean_scores_global = Float64[] # <--- AJOUTÉ : Stockage des moyennes
    best_scores_global = Float64[] 

    # --- Initialisation du fichier CSV ---
    csv_filename = "res/datas/resultats_tabou_test.csv"
    
    open(csv_filename, "w") do io
        # En-tête
        println(io, "instance;z_init;z_best_moyen;z_best;taille_liste_tabou;nb_diversifications_moyen;nb_intensifications_moyen")
    end

    for fname in files
        println("\n" * "#"^60)
        println("Traitement de l'instance : ", fname)
        println("#"^60)

        # 1. Chargement
        C, A = loadSPP(fname)
        nom_instance = split(fname, "/")[end]
        
        # 2. Solution Initiale
        x_init = SPP(C, A)
        z_init = sum(C[j] for j in x_init)
        k = length(x_init)

        # Paramètres Tabou
        l_tabou = (k ÷ 2)
        nb_iterations = 600

        # Variables pour accumuler
        sum_z_bests = 0.0
        sum_divs = 0
        sum_ints = 0
        max_z_best = -Inf

        # 3. Lancement des 3 runs
        nb_runs = 3
        for i in 1:nb_runs
            # On relance tabou_upgrade (graph=false)
            _, z_run, n_div, n_int = tabou_upgrade(C, A, x_init, l_tabou, nb_iterations, nom_instance, false)
            
            sum_z_bests += z_run
            sum_divs += n_div
            sum_ints += n_int
            
            if z_run > max_z_best
                max_z_best = z_run
            end
        end

        # 4. Calcul des statistiques
        z_best_moyen = sum_z_bests / nb_runs
        nb_div_moyen = sum_divs / nb_runs
        nb_int_moyen = sum_ints / nb_runs
        
        println("\n--> Résultat Instance $nom_instance :")
        println("    Z Init : $z_init")
        println("    Z Moy  : $z_best_moyen")
        println("    Z Max  : $max_z_best")

        # 5. Écriture CSV
        open(csv_filename, "a") do io
            @printf(io, "%s;%.2f;%.2f;%.2f;%d;%d;%d\n", 
                    nom_instance, z_init, z_best_moyen, max_z_best, l_tabou, nb_div_moyen, nb_int_moyen)
        end

        # Stockage pour le graphique global
        push!(instance_names, nom_instance)
        push!(initial_scores, z_init)
        push!(mean_scores_global, z_best_moyen) # <--- Stockage moyenne
        push!(best_scores_global, max_z_best)
    end 

    println("\n=== Fichier '$csv_filename' généré avec succès ===")

    # --- Génération du graphique en BARRES (Style Histogramme) ---
    if !isempty(instance_names)
        println("Génération du graphique comparatif...")
        
        # Création de la figure
        fig, ax = subplots(figsize=(14, 8))
        
        # Configuration des axes
        x_pos = 1:length(instance_names)
        width = 0.25  # Largeur d'une barre
        
        # Tracé des 3 séries de barres avec décalage
        # Position Z Init : x - 0.25
        rects1 = ax.bar(x_pos .- width, initial_scores, width, label="Z Init", color="royalblue", alpha=0.8, edgecolor="black")
        # Position Z Moy  : x
        rects2 = ax.bar(x_pos, mean_scores_global, width, label="Z Best Moy", color="mediumseagreen", alpha=0.8, edgecolor="black")
        # Position Z Best : x + 0.25
        rects3 = ax.bar(x_pos .+ width, best_scores_global, width, label="Z Best", color="indianred", alpha=0.8, edgecolor="black")

        # Mise en forme
        ax.set_ylabel("Valeur Objectif Z")
        ax.set_title("Comparaison des performances par Instance (3 runs)")
        
        # Étiquettes de l'axe X (Noms des instances)
        ax.set_xticks(x_pos)
        ax.set_xticklabels(instance_names, rotation=45, ha="right", fontsize=10)
        
        ax.legend()
        ax.grid(true, axis="y", linestyle="--", alpha=0.5)

        # Ajout des labels de gain sur la barre "Best" (Optionnel mais utile)
        for (i, z_best) in enumerate(best_scores_global)
            z_ini = initial_scores[i]
            if z_ini > 0
                gain_percent = ((z_best - z_ini) / z_ini) * 100
                # Affichage du % au dessus de la barre rouge
                ax.text(x_pos[i] + width, z_best + (maximum(best_scores_global)*0.01), 
                        @sprintf("+%.1f%%", gain_percent),
                        ha="center", va="bottom", fontsize=8, color="black", rotation=90)
            end
        end

        tight_layout()
        savefig("res/graphs/synthese_resultats_test.png")
        println("Graphique 'synthese_resultats.png' sauvegardé.")
    end
end

#test_instances_csv("dat")