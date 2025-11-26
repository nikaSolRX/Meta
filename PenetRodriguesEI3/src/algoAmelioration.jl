using PyPlot
using Random

# Vérifie si une solution est faisable
function is_feasible(A, chosen::Vector{Int})
    m, n = size(A)
    if any(j < 1 || j > n for j in chosen)
        return false
    end
    if length(unique(chosen)) != length(chosen)
        return false
    end
    covered = zeros(Int, m)
    for j in chosen
        covered .+= A[:, j]
    end
    return all(covered .<= 1)
end

function return_voisinage_candidate(C, A, solution, limit_size=20)
    m, n = size(A)
    voisins = Vector{Vector{Int}}()
    chosen_set = Set(solution) 
    covered = sum(A[:, j] for j in solution)

    # Stratégie 1 : DROP WORST + SWAP
    candidates_drop = sort(solution, by = j -> C[j])
    candidates_drop = candidates_drop[1:min(length(candidates_drop), limit_size)]

    for old_var in candidates_drop
        covered_after_drop = covered .- A[:, old_var]
        
        for new_var in 1:n
            if new_var in chosen_set; continue; end
            
            if all(covered_after_drop .+ A[:, new_var] .<= 1)
                candidate = copy(solution)
                candidate[findfirst(x->x==old_var, candidate)] = new_var
                push!(voisins, candidate)
            end
        end
    end

    # Stratégie 2 : ADD BEST (si peu de voisins)
    if length(voisins) < 5
        candidates_add = [j for j in 1:n if !(j in chosen_set)]
        sort!(candidates_add, by = j -> C[j], rev = true)
        candidates_add = candidates_add[1:min(length(candidates_add), limit_size)]
        
        for new_var in candidates_add
            for (pos, old_var) in enumerate(solution)
                covered_new = covered .- A[:, old_var] .+ A[:, new_var]
                if all(covered_new .<= 1)
                    candidate = copy(solution)
                    candidate[pos] = new_var
                    push!(voisins, candidate)
                end
            end
        end
    end

    # Filet de sécurité : REMOVE
    if isempty(voisins)
        for old_var in solution
            candidate = filter(x -> x != old_var, solution)
            if is_feasible(A, candidate)
                push!(voisins, candidate)
            end
        end
    end

    return voisins
end

function best_sol_diversifiee(L, C, x_curr::Vector{Int}, tabou_move, freqs::Vector{Int}, alpha::Float64, z_best::Float64)
    best = nothing
    best_val_score = -Inf
    best_val_real = -Inf
    best_move = nothing
    
    aspi_defaut = nothing
    min_tabou_time = Inf

    if isempty(L)
        return best, best_val_real, best_move, aspi_defaut
    end

    for sol in L
        val_real = sum(C[j] for j in sol)
        
        # Pénalité de diversification
        penalty = sum(freqs[j] for j in sol)
        val_score = val_real - (alpha * penalty)

        removed = setdiff(x_curr, sol)
        added = setdiff(sol, x_curr)

        if length(removed) == 1 && length(added) == 1
            move = (:swap, [removed[1], added[1]])
        elseif length(removed) == 1 && isempty(added)
            move = (:remove, [removed[1]])
        elseif isempty(removed) && length(added) == 1
            move = (:add, [added[1]])
        else
            continue
        end

        # Gestion Tabou & Aspiration
        tabou_entry = findfirst(x -> x[1] == move[1] && x[2] == move[2], tabou_move)
        if tabou_entry !== nothing
            tabou_time = tabou_move[tabou_entry][3]
            
            if val_real <= z_best
                if tabou_time < min_tabou_time
                    min_tabou_time = tabou_time
                    aspi_defaut = move
                end
                continue 
            end
        end

        # Sélection basée sur le SCORE
        if val_score > best_val_score
            best_val_score = val_score
            best_val_real = val_real
            best = copy(sol)
            best_move = move
        end
    end

    return best, best_val_real, best_move, aspi_defaut
end

function update_memory(mem::Vector{Tuple{Symbol, Vector{Int}, Int}}, move, taille)
    if move !== nothing
        push!(mem, (move[1], move[2], taille))
    end
    mem = [(m, indices, t - 1) for (m, indices, t) in mem if t > 1]
    return mem
end

function perturb_solution(x::Vector{Int}, A, C, n_vars, strength=3)
    x_new = copy(x)
    
    # Retirer 'strength' éléments aléatoires
    for _ in 1:min(strength, length(x_new) - 1)
        if !isempty(x_new)
            idx = rand(1:length(x_new))
            deleteat!(x_new, idx)
        end
    end
    
    # Ajouter 'strength' éléments aléatoires faisables
    candidates = setdiff(1:n_vars, x_new)
    shuffle!(candidates)
    
    for var in candidates
        x_test = copy(x_new)
        push!(x_test, var)
        if is_feasible(A, x_test)
            x_new = x_test
            if length(x_new) >= length(x) + strength - 1
                break
            end
        end
    end
    
    return x_new
end

function tabou_upgrade(C, A, chosen_init, taille_tabou, max_iter, nom_instance, graph)
    m, n = size(A)
    start_time = time()
    
    # --- Initialisation ---
    x_n = copy(chosen_init)
    z_n = sum(C[j] for j in x_n)
    
    x_fin = copy(x_n)
    z_fin = z_n
    
    memory = Vector{Tuple{Symbol, Vector{Int}, Int}}()
    
    # --- PARAMÈTRES ---
    freqs = zeros(Int, n)
    iter_sans_amelioration = 0
    iter_depuis_derniere_div = 0
    iter_depuis_derniere_int = 0
    
    SEUIL_DIV = 100
    SEUIL_INT = 40
    
    alpha = 0.0
    cpt_int = 0
    cpt_div = 0
    
    z_fin_history = Float64[]
    z_n_history = Float64[]
    events_intensification = Int[]
    events_diversification = Int[]
    last_moves_from_best = Vector{Tuple{Symbol, Vector{Int}}}()
    push!(z_n_history, z_n)
    push!(z_fin_history, z_n)

    iter = 0

    while iter < max_iter
        # 1. Mise à jour mémoire long terme
        for j in x_n
            freqs[j] += 1
        end

        # 2. Incrémentation des compteurs
        iter_sans_amelioration += 1
        iter_depuis_derniere_div += 1
        iter_depuis_derniere_int += 1

        diversification_active = false
        intensification_active = false
        if iter_sans_amelioration > SEUIL_DIV
            #println('DIVERSIFICATION')
            diversification_active = true
            alpha = 5.0 * (z_fin / max(1, n))
            iter_depuis_derniere_div = 0
            iter_sans_amelioration = 0
            cpt_div += 1
            push!(events_diversification, iter)
        
        elseif iter_depuis_derniere_int > SEUIL_INT
            #println('INTENSIFICATION')
            intensification_active = true
            x_n = perturb_solution(x_fin, A, C, n, 3)
            z_n = sum(C[j] for j in x_n)
            
            if !isempty(last_moves_from_best)
                for mv in last_moves_from_best
                    push!(memory, (mv[1], mv[2], Int(taille_tabou * 2)))
                end
            end
            
            iter_depuis_derniere_int = 0
            #iter_depuis_derniere_div = 0
            alpha = 0.0
            cpt_int += 1
            push!(events_intensification, iter)
            
        elseif alpha > 0.0 && iter_depuis_derniere_div > 10
            alpha *= 0.9
            if alpha < 0.5
                alpha = 0.0
            end
        end

        voisins = return_voisinage_candidate(C, A, x_n, 20)

        new_x, new_z_real, move, aspi_defaut = best_sol_diversifiee(voisins, C, x_n, memory, freqs, alpha, Float64(z_fin))

        if move === nothing 
            if aspi_defaut !== nothing
                move = aspi_defaut
                new_x = copy(x_n)
                if move[1] == :swap
                    removed, added = move[2][1], move[2][2]
                    new_x[findfirst(==(removed), new_x)] = added
                elseif move[1] == :add
                    push!(new_x, move[2][1])
                elseif move[1] == :remove
                    filter!(!=(move[2][1]), new_x)
                end
                new_z_real = sum(C[j] for j in new_x)
            else
                break 
            end
        end

        if new_z_real > z_fin
            x_fin = copy(new_x)
            z_fin = new_z_real
            iter_sans_amelioration = 0
            empty!(last_moves_from_best)
        elseif x_n == x_fin && move !== nothing
            push!(last_moves_from_best, (move[1], move[2]))
            if length(last_moves_from_best) > 5
                popfirst!(last_moves_from_best)
            end
        end
        
        x_n = copy(new_x)
        z_n = new_z_real

        push!(z_n_history, z_n)
        push!(z_fin_history, z_fin)
        memory = update_memory(memory, move, Int(taille_tabou))

        iter += 1

        println("Itération $iter | Z_curr: $z_n | Z_best: $z_fin | Alpha: $(round(alpha, digits=2)) | $(diversification_active ? "Diversification" : intensification_active ? "Intensification" : "")")
    end

    if graph
        if !isdir("res")
            mkdir("res")
        end

        safe_instance_name = replace(nom_instance, r"[^\w\d]" => "_")

        clf()
        
        # 1. Les courbes
        iterations = 0:(length(z_fin_history)-1)
        plot(iterations, z_fin_history, label="Z Best", color="blue", linewidth=2)
        plot(iterations, z_n_history, label="Z Courant", color="red", alpha=0.3)
        
        # 2. Lignes verticales (Intensification / Diversification)
        for (i, idx) in enumerate(events_diversification)
            axvline(x=idx, color="purple", linestyle="--", alpha=0.6, 
                label=(i==1 ? "Diversification" : ""))
        end
        for (i, idx) in enumerate(events_intensification)
            axvline(x=idx, color="green", linestyle="-", alpha=0.6, 
                    label=(i==1 ? "Intensification" : ""))
        end
        
        legend()
        xlabel("Itérations")
        ylabel("Valeur de z(x)")
        title("Recherche Tabou | Z_curr ZBest | $nom_instance\nStart: $(Int(z_n_history[1])) -> Best: $(Int(z_fin))")
        grid(true, alpha=0.3)
        savefig("res/graphs/" * safe_instance_name * ".png", dpi=150)
    end

    return x_fin, z_fin, cpt_div, cpt_int
end