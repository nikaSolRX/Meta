function SPP(C, A)
    # Vérifier les dimensions de la matrice A
    m, n = size(A)
    if m <= 0 || n <= 0
        error("La matrice A doit avoir des dimensions valides (m > 0, n > 0).")
    end

    # Initialiser les BitVectors
    covered = BitVector(undef, m)  # Utilisation de BitVector pour les lignes couvertes
    chosen = BitVector(undef, n)  # Utilisation de BitVector pour les variables choisies

    # Initialiser les valeurs à false
    fill!(covered, false)
    fill!(chosen, false)

    iter = 0
    println("Début algorithme greedy (Ci / Ti recalculé)")

    while true
        iter += 1
        # déterminer variables admissibles (aucun 1 sur une ligne déjà couverte)
        admissible = BitVector(undef, n)  # Utilisation de BitVector pour les variables admissibles
        fill!(admissible, false)
        for j in 1:n
            conflict = false
            for i in 1:m
                if A[i, j] == 1 && covered[i]
                    conflict = true
                    break
                end
            end
            admissible[j] = !conflict
        end

        # pour chaque admissible, calculer Ti' sur les lignes libres et score
        scores = fill(-Inf, n)   # -Inf pour non admissible ou Ti'=0
        T = zeros(Int, n)
        for j in 1:n
            if admissible[j]
                for i in 1:m
                    if !covered[i] && A[i, j] == 1
                        T[j] += 1
                    end
                end
                if T[j] > 0
                    scores[j] = C[j] / T[j]
                end
            end
        end

        # choisir la variable de score max
        jstar = findmax(scores)[2]    # index du max (si tous -Inf, findmax renvoie -Inf et index 1)
        if scores[jstar] == -Inf
            println("  Aucune variable admissible restante. Fin.")
            break
        end

        # enregistrer choix et marquer lignes couvertes
        chosen[jstar] = true  # Marquer la variable choisie dans le BitVector
        for i in 1:m
            if A[i, jstar] == 1
                covered[i] = true  # Marquer les lignes couvertes dans le BitVector
            end
        end

        # stop si toutes les lignes couvertes (optionnel)
        if all(covered)
            println("  Toutes les lignes sont couvertes. Fin.")
            break
        end
    end

    # Retourner les indices des variables choisies
    return findall(chosen)
end