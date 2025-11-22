using PyPlot  # Importer PyPlot pour l'affichage graphique

# Vérifie si une solution est faisable
function is_feasible(A, chosen::Vector{Int})
    m, n = size(A)
    # Vérification des indices valides
    if any(j < 1 || j > n for j in chosen)
        return false
    end
    # Vérification des doublons
    if length(unique(chosen)) != length(chosen)
        return false
    end
    # Vérification des contraintes de Set Packing
    covered = zeros(Int, m)
    for j in chosen
        covered .+= A[:, j]
    end
    return all(covered .<= 1)
end

function return_voisinage(C, A, solution)
    m, n = size(A)
    voisins = Vector{Vector{Int}}()
    chosen_set = Set(solution) 

    # Calcul initial de la couverture
    covered = sum(A[:, j] for j in solution)

    # Générer des mouvements swap
    for (pos, old_var) in enumerate(solution)
        for new_var in 1:n
            if new_var in chosen_set
                continue
            end

            # Mise à jour incrémentale de la couverture
            covered_new = covered .- A[:, old_var] .+ A[:, new_var]

            # Test rapide de faisabilité
            if all(covered_new .<= 1)
                candidate = copy(solution)
                candidate[pos] = new_var
                push!(voisins, candidate)
            end
        end
    end

    # Si aucun voisin n'a été généré via les swaps, générer des mouvements add
    if isempty(voisins)
        for new_var in 1:n
            if new_var in chosen_set
                continue
            end

            # Ajouter un nouvel élément
            candidate = copy(solution)
            push!(candidate, new_var)

            # Vérifier la faisabilité
            if is_feasible(A, candidate)
                push!(voisins, candidate)
            end
        end
    end

    # Si aucun voisin n'a été généré via les swaps ou les adds, générer des mouvements remove
    if isempty(voisins)
        for old_var in solution
            # Supprimer un élément existant
            candidate = filter(x -> x != old_var, solution)

            # Vérifier la faisabilité
            if is_feasible(A, candidate)
                push!(voisins, candidate)
            end
        end
    end

    return voisins
end


# Trouve la meilleure solution dans le voisinage, en excluant les mouvements tabous
function best_sol(L, C, x_curr::Vector{Int}, tabou_move::Vector{Tuple{Symbol, Vector{Int}, Int}})
    best = nothing
    best_val = -Inf
    best_move = nothing
    aspi_defaut = nothing
    min_tabou_time = Inf  # Initialise le temps minimum pour le critère d'aspiration

    if isempty(L)
        return best, best_val, best_move, aspi_defaut
    end

    for sol in L
        val = sum(C[j] for j in sol)
        removed = setdiff(x_curr, sol)
        added = setdiff(sol, x_curr)

        # Identifier le type de mouvement
        if length(removed) == 1 && length(added) == 1
            move = (:swap, [removed[1], added[1]])
        elseif length(removed) == 1 && isempty(added)
            move = (:remove, [removed[1]])
        elseif isempty(removed) && length(added) == 1
            move = (:add, [added[1]])
        else
            continue
        end

        # Vérifie si le mouvement est tabou
        tabou_entry = findfirst(x -> x[1] == move[1] && x[2] == move[2], tabou_move)
        if tabou_entry !== nothing
            # Si le mouvement est tabou, vérifie son temps restant
            tabou_time = tabou_move[tabou_entry][3]
            if tabou_time < min_tabou_time
                min_tabou_time = tabou_time
                aspi_defaut = move  # Met à jour le mouvement "le moins tabou"
            end
            continue
        end

        # Si le mouvement n'est pas tabou, évalue normalement
        if val > best_val
            best_val = val
            best = copy(sol)
            best_move = move
        end
    end

    return best, best_val, best_move, aspi_defaut
end

# Met à jour la mémoire tabou en respectant la taille limite
function update_memory(mem::Vector{Tuple{Symbol, Vector{Int}, Int}}, move, taille)
    # Ajouter le mouvement avec un compteur initial (par exemple, taille_tabou)
    if move !== nothing
        push!(mem, (move[1], move[2], taille))  # Le mouvement est ajouté avec son temps restant
    end

    # Réduire le compteur de chaque élément
    mem = [(m, indices, t - 1) for (m, indices, t) in mem if t > 1]  # Supprime les éléments dont le temps est écoulé

    return mem
end

function intensify(medium_term_memory, C, A)
    println("Intensification activée...")
    # Vérifier si la mémoire à moyen terme est vide
    if isempty(medium_term_memory)
        println("Mémoire à moyen terme vide, impossible d'intensifier.")
        return []
    end

    # Identifier la solution la plus prometteuse (fréquemment visitée)
    best_solution, _ = findmax(medium_term_memory)  # Trouve la clé avec la valeur maximale

    # Vérifier que la solution intensifiée est bien un vecteur
    if !(best_solution isa Vector{Int})
        println("Erreur : La solution intensifiée n'est pas un vecteur.")
        return []
    end

    println("Solution intensifiée : ", best_solution)

    # Générer un voisinage étendu autour de cette solution
    voisins = return_voisinage(C, A, best_solution)
    return voisins
end

function diversify(long_term_memory, C, A, n)
    println("Diversification activée...")

    # Vérifier si la mémoire à long terme est vide
    if isempty(long_term_memory)
        println("Mémoire à long terme vide, impossible de diversifier.")
        return []
    end

    # Identifier les colonnes les moins utilisées
    sorted_columns = sort(collect(keys(long_term_memory)), by = x -> get(long_term_memory, x, 0))

    # Construire une nouvelle solution initiale en favorisant les colonnes peu utilisées
    new_solution = Vector{Int}()  # Assure que new_solution est un Vector{Int}
    for col in sorted_columns
        if length(new_solution) >= n
            break
        end
        push!(new_solution, col)
    end

    # Vérifier la faisabilité de la nouvelle solution
    if is_feasible(A, new_solution)
        println("Nouvelle solution diversifiée : ", new_solution)
        return new_solution
    else
        println("Échec de la diversification, aucune solution faisable trouvée.")
        return []
    end
end

function tabou_upgrade(C, A, chosen_init, taille_tabou, max_iter, nom_instance)
    start_time = time()
    x_n = copy(chosen_init)
    x_fin = copy(x_n)
    z_n = sum(C[j] for j in x_n)
    z_fin = z_n
    memory = Vector{Tuple{Symbol, Vector{Int}, Int}}()  # Liste pour la mémoire tabou avec compteur
    medium_term_memory = Dict{Vector{Int}, Int}()  # Mémoire à moyen terme
    long_term_memory = Dict{Int, Int}()  # Mémoire à long terme
    iter = 0
    stagnation_counter = 0  # Compteur de stagnation
    stagnation_after_intensification = 0  # Compteur de stagnation après intensification
    seuil_stagnation = 20  # Nombre d'itérations sans amélioration avant intensification
    seuil_diversification = 5  # Nombre d'itérations sans amélioration après intensification avant diversification

    # Liste pour stocker l'évolution de z_fin
    z_fin_history = Float64[]
    z_n_history = Float64[]

    while iter < max_iter
        println("Itération : ", iter)
        println("meilleur z actuel : ", z_fin)

        # Vérifier la stagnation
        if stagnation_counter >= seuil_stagnation
            voisins = intensify(medium_term_memory, C, A)
            stagnation_counter = 0  # Réinitialiser le compteur de stagnation
            stagnation_after_intensification += 1
        elseif stagnation_after_intensification >= seuil_diversification
            x_n = diversify(long_term_memory, C, A, length(x_n))
            if isempty(x_n)
                println("Diversification échouée, arrêt de l'algorithme.")
                break
            end
            stagnation_after_intensification = 0  # Réinitialiser le compteur après diversification
            voisins = return_voisinage(C, A, x_n)
        else
            # Générer le voisinage normal
            voisins = return_voisinage(C, A, x_n)
        end

        # Trouver la meilleure solution et le critère d'aspiration
        new_x, new_z, move, aspi_defaut = best_sol(voisins, C, x_n, memory)

        if move === nothing && aspi_defaut !== nothing
            println("Critère d'aspiration activé : utilisation du mouvement le moins tabou.")
            move = aspi_defaut
            new_x = copy(x_n)
            if move[1] == :swap
                removed = move[2][1]
                added = move[2][2]
                new_x[findfirst(x -> x == removed, new_x)] = added
            elseif move[1] == :add
                push!(new_x, move[2][1])
            elseif move[1] == :remove
                new_x = filter(x -> x != move[2][1], new_x)
            end
            new_z = sum(C[j] for j in new_x)
        end

        if move !== nothing
            if new_z > z_fin
                x_fin = copy(new_x)
                z_fin = new_z
                stagnation_counter = 0  # Réinitialiser le compteur de stagnation
                stagnation_after_intensification = 0  # Réinitialiser le compteur après intensification
            else
                stagnation_counter += 1  # Incrémenter le compteur de stagnation
            end
            x_n = copy(new_x)
        end

        # Mettre à jour les mémoires
        medium_term_memory[x_n] = get(medium_term_memory, x_n, 0) + 1
        for col in x_n
            long_term_memory[col] = get(long_term_memory, col, 0) + 1
        end

        push!(z_n_history, new_z)
        push!(z_fin_history, z_fin)

        memory = update_memory(memory, move, taille_tabou)

        println("Tabou update")
        println("Mémoire taboue : ", memory)
        println("Mémoire moyen terme : ", medium_term_memory)
        println("Mémoire long terme : ", long_term_memory)
        iter += 1
    end

    elapsed_time = time() - start_time
    println("Temps d'exécution : ", elapsed_time, " secondes")

    # Affichage graphique de l'évolution de z_fin
    clf()
    figure("Évolution de z_fin", figsize=(8,6))
    title("Recherche Tabou")
    xlabel("Itérations")
    ylabel("Z")

    it = 0:(length(z_fin_history) - 1)

    plot(it, z_fin_history, linestyle="-", marker="o", color="blue")
    plot(it, z_n_history,  linestyle="--", marker="x", color="red")

    legend(["z_fin (meilleur global)", "z_n (meilleur courant)"], loc="lower right")
    grid(true)

    xticks(0:5:(length(z_fin_history) - 1))

    savefig("results/"*nom_instance*".png")

    return x_fin, z_fin
end

# solution mimi.dat : [1,2,6]