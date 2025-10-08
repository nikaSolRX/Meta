
function SCP(C, A)
    S = []
    LengthC = length(C)
    U = zeros(Float64, LengthC)
    Ia = zeros(Int, LengthC)
    xlist = zeros(Int, LengthC)
    for i in 1:length(A)-1
        for j in 1:length(A[i])
            if A[i][j] == 1
                Ia[j] += 1
            end
        end
    end
    for k in 1:length(Ia)
        U[k] = C[k] / Ia[k]
    end

    uMin, iMin = findmin(U)
    xlist[iMin] = 1


    while size(A, 1) > 0
        # Trouver les lignes à supprimer sans modifier A pendant la boucle
        rows_to_delete = Int[]

        for l in 1:size(A, 1)
            if A[l, iMin] == 1   # si la colonne iMin vaut 1 dans la ligne l
                push!(rows_to_delete, l)
            end
        end

        # Supprimer toutes les lignes d'un coup
        if !isempty(rows_to_delete)
            A = A[setdiff(1:size(A, 1), rows_to_delete), :]
        end

        # Réinitialiser Ia et U
        fill!(Ia, 0)
        fill!(U, 0.0)

        # Recalculer Ia
        for n in 1:size(A, 1)
            for o in 1:size(A, 2)
                if A[n, o] == 1
                    Ia[o] += 1
                end
            end
        end

        # Recalculer U (éviter division par zéro)
        for p in 1:LengthC
            if Ia[p] > 0
                U[p] = C[p] / Ia[p]
            else
                U[p] = Inf  # ignorer les colonnes non couvertes
            end
        end

        # Trouver la nouvelle valeur minimale
        uMin, iMin = findmin(U)
        xlist[iMin] = 1
    end

    return xlist
end