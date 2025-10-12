using Random

function amelioration(C, A, x)
    z0 = sum(x .* C)
    nvars = length(x)
    m = size(A, 1)
    ameliore = true

    # nombre d'essais aléatoires par itération (augmente le temps de calcul si nécessaire)
    trials_per_iter = 200

    while ameliore
        ameliore = false

        for t in 1:trials_per_iter
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

            # échanger k éléments (zéros->1 et uns->0) sur une permutation aléatoire
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

            # si on n'a pas pu échanger k/k éléments, passer
            if exch0 != k || exch1 != k
                continue
            end

            # vérification de faisabilité vectorisée : chaque ligne doit être couverte >= 1
            if all(A * xcopy .>= 1)
                z1 = sum(xcopy .* C)
                if z1 < z0
                    # accepter la nouvelle solution
                    z0 = z1
                    x = copy(xcopy)
                    ameliore = true
                    break  # relancer une nouvelle phase d'amélioration depuis la solution acceptée
                end
            end
        end
    end

    return x, z0
end