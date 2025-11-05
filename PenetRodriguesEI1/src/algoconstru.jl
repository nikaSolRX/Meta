function SPP(C, A)
    m, n = size(A)
    covered = falses(m)                             # quelles lignes sont déjà couvertes
    chosen = Int[]                                  # indices des variables choisies

    iter = 0
    println("Début algorithme greedy (Ci / Ti recalculé)")

    while true
        iter += 1
        # déterminer variables admissibles (aucun 1 sur une ligne déjà couverte)
        admissible = Bool[]
        for j in 1:n
            conflict = false
            for i in 1:m
                if A[i,j] == 1 && covered[i]
                    conflict = true
                    break
                end
            end
            push!(admissible, !conflict)
        end

        # pour chaque admissible, calculer Ti' sur les lignes libres et score
        scores = fill(-Inf, n)   # -Inf pour non admissible ou Ti'=0
        T = zeros(Int, n)
        for j in 1:n
            if admissible[j]
                for i in 1:m
                    if !covered[i] && A[i,j] == 1
                        T[j] += 1
                    end
                end
                if T[j] > 0
                    scores[j] = C[j] / T[j]
                end
            end
        end

        # afficher état courant
        println("\nItération $iter")
        println("  Lignes couvertes: ", findall(covered))
        println("  Variables admissibles: ", findall(admissible))
        println("  Ti (sur lignes libres): ", T)
        println("  Scores Ci/Ti (−Inf = non admissible): ", scores)

        # choisir la variable de score max
        jstar = findmax(scores)[2]    # index du max (si tous -Inf, findmax renvoie -Inf et index 1)
        if scores[jstar] == -Inf
            println("  Aucune variable admissible restante. Fin.")
            break
        end

        # enregistrer choix et marquer lignes couvertes
        push!(chosen, jstar)
        println("  -> Choix: x$jstar (score = $(round(scores[jstar], digits=4)), Ti=$(T[jstar]), C=$(C[jstar]))")
        for i in 1:m
            if A[i,jstar] == 1
                covered[i] = true
            end
        end

        # stop si toutes les lignes couvertes (optionnel)
        if all(covered)
            println("  Toutes les lignes sont couvertes. Fin.")
            break
        end
    end

    return chosen
end

