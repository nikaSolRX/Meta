using Random

function amelioration(C, A, x)
    # maximise sum(C .* x) sous contraintes A * x .<= 1 (set packing)
    z = sum(x .* C)
    nvars = length(x)
    m = size(A, 1)

    # couverture par ligne (entièrement vectorisée)
    row_sums = A * x

    improved = true
    while improved
        improved = false

        ones_idx = findall(x .== 1)
        zeros_idx = findall(x .== 0)

        best_delta = 0.0
        best_i = 0
        best_j = 0

        # tester tous les échanges 1->0 / 0->1
        for i in ones_idx
            Ai = view(A, :, i)
            for j in zeros_idx
                Aj = view(A, :, j)
                # test de faisabilité rapide : row_sums - Ai + Aj <= 1
                if all((row_sums .- Ai .+ Aj) .<= 1)
                    delta = C[j] - C[i]   # gain si on retire i et ajoute j
                    if delta > best_delta
                        best_delta = delta
                        best_i = i
                        best_j = j
                    end
                end
            end
        end

        # appliquer la meilleure amélioration trouvée (si positive)
        if best_delta > 0
            x[best_i] = 0
            x[best_j] = 1
            z += best_delta
            # mise à jour incrémentale de row_sums
            row_sums .-= A[:, best_i]
            row_sums .+= A[:, best_j]
            improved = true
        end
    end

    return x, z
end