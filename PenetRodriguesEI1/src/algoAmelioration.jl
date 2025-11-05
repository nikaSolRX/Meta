# Recherche locale simple pour Set Packing Problem

function is_feasible(A, chosen)
    # vérifie qu'aucune ligne n'est couverte plus d'une fois
    m = size(A, 1)
    covered = zeros(Int, m)
    for j in chosen
        for i in 1:m
            if A[i,j] == 1
                covered[i] += 1
                if covered[i] > 1
                    return false
                end
            end
        end
    end
    return true
end

function local_search_1exchange(C, A, chosen_init; max_iter=1000, verbose=true)
    m, n = size(A)
    current = copy(chosen_init)
    current_val = sum(C[j] for j in current)
    
    if verbose
        println("\n=== Recherche locale 1-exchange ===")
        println("Solution initiale : ", current, " val=", current_val)
    end
    
    iter = 0
    improved = true
    
    while improved && iter < max_iter
        iter += 1
        improved = false
        best_move = nothing
        best_val = current_val
        
        # 1) Essayer de remplacer chaque variable choisie par une autre
        for (idx, old_var) in enumerate(current)
            for new_var in 1:n
                if new_var in current
                    continue
                end
                
                # créer candidat en remplaçant old_var par new_var
                candidate = copy(current)
                candidate[idx] = new_var
                
                if is_feasible(A, candidate)
                    val = sum(C[j] for j in candidate)
                    if val > best_val
                        best_val = val
                        best_move = (:exchange, idx, old_var, new_var)
                        improved = true
                    end
                end
            end
        end
        
        # 2) Essayer d'ajouter une variable admissible
        for new_var in 1:n
            if new_var in current
                continue
            end
            
            candidate = vcat(current, new_var)
            if is_feasible(A, candidate)
                val = sum(C[j] for j in candidate)
                if val > best_val
                    best_val = val
                    best_move = (:add, new_var)
                    improved = true
                end
            end
        end
        
        # Appliquer le meilleur mouvement trouvé
        if improved
            if best_move[1] == :exchange
                _, idx, old_var, new_var = best_move
                current[idx] = new_var
                if verbose
                    println("Iter $iter: EXCHANGE x$old_var → x$new_var, val: $current_val → $best_val")
                end
            elseif best_move[1] == :add
                _, new_var = best_move
                push!(current, new_var)
                if verbose
                    println("Iter $iter: ADD x$new_var, val: $current_val → $best_val")
                end
            end
            current_val = best_val
        end
    end
    
    if verbose
        println("\nOptimum local atteint après $iter itérations")
        println("Solution finale : ", current, " val=", current_val)
    end
    
    return current, current_val
end