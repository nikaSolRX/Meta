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


# Trouve la meilleure solution dans le voisinage, en excluant les mouvements tabous
function best_sol(L, C, x_curr::Vector{Int}, tabou_move::Vector{Tuple{Symbol, Int, Int}})
    if isempty(L)
        return Vector{Int}(), 0.0, nothing
    end
    best = nothing
    best_val = -Inf
    best_move = nothing
    for sol in L
        val = sum(C[j] for j in sol)
        removed = setdiff(x_curr, sol)
        added = setdiff(sol, x_curr)
        if length(removed) == 1 && length(added) == 1
            move = (:swap, removed[1], added[1])
            if move in tabou_move
                continue
            end
            if val > best_val
                best_val = val
                best = copy(sol)
                best_move = move
            end
        end
    end
    return best, best_val, best_move
end

# Met à jour la mémoire tabou en respectant la taille limite
function update_memory(mem::Vector{Tuple{Symbol, Int, Int}}, move, taille)
    push!(mem, move)
    if length(mem) > taille
        popfirst!(mem)  # Supprime le plus ancien élément
    end
    return mem
end

function tabou_upgrade(C, A, chosen_init, taille_tabou=7; max_iter=100)

    start_time = time()
    x_n = copy(chosen_init)
    x_fin = copy(x_n)
    z_n = sum(C[j] for j in x_n)
    z_fin = z_n
    memory = Vector{Tuple{Symbol, Int, Int}}()  # Liste pour la mémoire tabou
    iter = 0

    # Liste pour stocker l'évolution de z_fin
    z_fin_history = Float64[]

    while iter < max_iter
        println("Itération : ", iter)
        L = return_voisinage(C, A, x_n)
        new_x, new_z, move = best_sol(L, C, x_n, memory)
        if new_x === nothing
            break
        end
        if new_z > z_fin
            x_fin = copy(new_x)
            z_fin = new_z
        end
        x_n = copy(new_x)
        z_n = new_z
        memory = update_memory(memory, move, taille_tabou)

        # Enregistrer la valeur de z_fin
        push!(z_fin_history, z_fin)

        println("Tabou update")
        println("Mémoire taboue : ", memory)
        iter += 1
    end

    elapsed_time = time() - start_time
    println("Temps d'exécution : ", elapsed_time, " secondes")

    # Affichage graphique de l'évolution de z_fin
    clf()  # Efface la figure précédente
    figure("Évolution de z_fin", figsize=(8, 6))
    title("Recherche Tabou")
    xlabel("Itérations")
    ylabel("Z")
    plot(0:(length(z_fin_history) - 1), z_fin_history, linestyle="-", marker="o", color="blue")
    legend(["z_fin"], loc="lower right")
    grid(true)

    # Espacer les ticks sur l'axe des abscisses (par exemple, tous les 5)
    xticks(0:5:(length(z_fin_history) - 1))

    savefig("tabou_2_result.png")

    return x_fin, z_fin
end