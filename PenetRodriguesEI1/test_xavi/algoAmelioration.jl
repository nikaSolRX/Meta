using Random

function ameliorationSPP_rapide(C, A, x_init; essais_in::Int=0)
    # NB: essais_in est ignoré ici (on évalue tout le voisinage) – cohérent “descente profonde”
    # NB: essais_in est ignoré ici (on évalue tout le voisinage) – cohérent “descente profonde”

    # Accept either a vector x_init or a tuple like (x, z). Extract a copy of the vector.
    if isa(x_init, Tuple) && length(x_init) >= 1 && isa(x_init[1], AbstractVector)
        x_best = copy(x_init[1])
    elseif isa(x_init, AbstractVector)
        x_best = copy(x_init)
    else
        throw(ArgumentError("x_init must be a vector or a tuple whose first element is a vector"))
    end

    z_best = sum(C .* x_best)
    couverture = A * x_best
    n = length(C)

    improved = true
    while improved
        improved = false

        # 0) add-only : si on peut ajouter une colonne sans retirer, on prend la meilleure
        best_add = 0.0
        best_j   = 0
        for j in 1:n
            if x_best[j] == 0 && all(couverture .+ A[:, j] .<= 1)
                if C[j] > best_add
                    best_add = C[j]; best_j = j
                end
            end
        end
        if best_j != 0
            x_best[best_j] = 1
            couverture .+= A[:, best_j]
            z_best += best_add
            improved = true
            continue
        end

        # 1) 1-1 exchange (plus profonde descente)
        best_gain = 0.0
        best_out, best_in = 0, 0

        # pour chaque colonne sélectionnée
        for j_out in findall(x_best .== 1)
            # couverture si on retire j_out
            couverture_temp = couverture .- A[:, j_out]

            # toutes les colonnes non sélectionnées faisables après le retrait de j_out
            # (celles qui ne “touchent” aucune ligne déjà saturée dans couverture_temp)
            for j_in in findall(x_best .== 0)
                if all(couverture_temp .+ A[:, j_in] .<= 1)
                    gain = C[j_in] - C[j_out]
                    if gain > best_gain
                        best_gain = gain
                        best_out, best_in = j_out, j_in
                    end
                end
            end
        end

        # appliquer le meilleur mouvement s’il améliore
        if best_gain > 0
            x_best[best_out] = 0
            x_best[best_in]  = 1
            couverture .+= -A[:, best_out] .+ A[:, best_in]
            z_best += best_gain
            improved = true
        end
    end

    return x_best
end
