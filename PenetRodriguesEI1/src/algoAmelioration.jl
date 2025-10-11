using Random

function amelioration(C, A, x)
    z0 = sum(x .* C)
    xcopy = copy(x)
    m = size(A, 1)          # nombre de lignes (contraintes)
    nvars = length(x)       # nombre de colonnes / variables
    ameliore = true

    while ameliore == true
        ameliore = false

        # repartir de la solution courante acceptée
        xcopy = copy(x)

        # déterminer k réalisable
        nb1 = sum(xcopy)
        nb0 = nvars - nb1
        k_max = min(nb1, nb0)
        if k_max == 0
            break
        end
        k = rand(1:k_max)

        # échanger k zéros->1 et k un->0 en parcourant une permutation aléatoire
        perm = randperm(nvars)
        exch0 = 0
        exch1 = 0
        for idx in perm
            if xcopy[idx] == 0 && exch0 < k
                xcopy[idx] = 1
                exch0 += 1
            elseif xcopy[idx] == 1 && exch1 < k
                xcopy[idx] = 0
                exch1 += 1
            end
            if exch0 == k && exch1 == k
                break
            end
        end

        # vérification des contraintes (une ligne doit être couverte >= 1)
        verif = true
        for i in 1:m
            s = 0
            for j in 1:nvars
                s += A[i, j] * xcopy[j]
            end
            if s < 1
                verif = false
                break
            end
        end

        # si valide et améliore l'objectif, accepter
        if verif == true
            z1 = sum(xcopy .* C)
            if z1 < z0
                z0 = z1
                x = copy(xcopy)
                ameliore = true
            end
        end
    end

    return x, z0
end