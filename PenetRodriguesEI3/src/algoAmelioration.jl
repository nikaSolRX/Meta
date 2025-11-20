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
    return voisins
end

function return_mid_voisinage(C,A,solution)
    m, n = size(A)
    voisins = Vector{Vector{Int}}()
    chosen_set = Set(solution)

    # Calcul initial de la couverture
    covered = sum(A[:, j] for j in solution)

    for (pos, old_var) in enumerate(solution)
        if pos > length(solution) ÷ 2
            break
        end
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
    return voisins
end


# Trouve la meilleure solution dans le voisinage, en excluant les mouvements tabous
function best_sol(L, C, x_curr::Vector{Int}, tabou_move::Vector{Tuple{Tuple{Symbol, Int, Int}, Int}})
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

        if length(removed) == 1 && length(added) == 1
            move = (:swap, removed[1], added[1])

            # Vérifie si le mouvement est tabou
            tabou_entry = findfirst(x -> x[1] == move, tabou_move)
            if tabou_entry !== nothing
                # Si le mouvement est tabou, vérifie son temps restant
                tabou_time = tabou_move[tabou_entry][2]
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
    end

    return best, best_val, best_move, aspi_defaut
end

# Met à jour la mémoire tabou en respectant la taille limite
function update_memory(mem::Vector{Tuple{Tuple{Symbol, Int, Int}, Int}}, move, taille)
    # Ajouter le mouvement avec un compteur initial (par exemple, taille_tabou)
    if move !== nothing
        push!(mem, (move, taille))  # Le mouvement est ajouté avec son temps restant
    end

    # Réduire le compteur de chaque élément
    mem = [(m, t - 1) for (m, t) in mem if t > 1]  # Supprime les éléments dont le temps est écoulé

    return mem
end

function intensify(L, medium_term_memory)
    return sort(L, by = x -> get(medium_term_memory, x, 0), rev = true)
end

function diversify(L, long_term_memory)
    return sort(L, by = x -> sum(get(long_term_memory, col, 0) for col in x))
end

function tabou_upgrade(C, A, chosen_init, taille_tabou, max_iter)

    start_time = time()
    x_n = copy(chosen_init)
    x_fin = copy(x_n)
    z_n = sum(C[j] for j in x_n)
    z_fin = z_n
    memory = Vector{Tuple{Tuple{Symbol, Int, Int}, Int}}()  # Liste pour la mémoire tabou avec compteur    
    iter = 0

    # Liste pour stocker l'évolution de z_fin
    z_fin_history = Float64[]
    z_n_history = Float64[]

    medium_term_memory = Dict{Vector{Int}, Int}()  # Mémoire à moyen terme : solutions fréquemment visitées
    long_term_memory = Dict{Int, Int}()  # Mémoire à long terme : fréquence des colonnes utilisées      

    while iter < max_iter
        println("Itération : ", iter)
        println("meilleur z actuel : ", z_fin)

        # Générer le voisinage
        L = return_voisinage(C, A, x_n)

        # Intensification : Favoriser les solutions fréquemment visitées
        L = intensify(L, medium_term_memory)

        # Diversification : Favoriser les colonnes peu utilisées
        L = diversify(L, long_term_memory)

        # Trouver la meilleure solution et le critère d'aspiration
        new_x, new_z, move, aspi_defaut = best_sol(L, C, x_n, memory)

        if move === nothing && aspi_defaut !== nothing
            println("Critère d'aspiration activé : utilisation du mouvement le moins tabou.")
            move = aspi_defaut
            new_x = copy(x_n)
            removed = move[2]
            added = move[3]
            new_x[findfirst(x -> x == removed, new_x)] = added
            new_z = sum(C[j] for j in new_x)
        end

        if move !== nothing
            if new_z > z_fin
                x_fin = copy(new_x)
                z_fin = new_z
            end
            x_n = copy(new_x)

            # Mettre à jour les mémoires
            medium_term_memory[x_n] = get(medium_term_memory, x_n, 0) + 1
            for col in x_n
                long_term_memory[col] = get(long_term_memory, col, 0) + 1
            end
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

    savefig("tabou_3_result.png")

    return x_fin, z_fin
end