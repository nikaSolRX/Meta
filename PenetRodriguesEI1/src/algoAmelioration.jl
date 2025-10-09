
function amelioration_1_1_exchange(C, A, x_init)
    x_best = copy(x_init)
    z_best = sum(C .* x_best)
    m, n = size(A)

    couverture = A * x_best

    amelioration = true
    while amelioration
        amelioration = false

        # Parcourir chaque ensemble actuellement sélectionné
        for j_remove in findall(x_best .== 1)

            # Tester le retrait de j_remove
            couverture_temp = couverture .- A[:, j_remove]

            # Parcourir les ensembles non sélectionnés
            for j_add in findall(x_best .== 0)
                # Vérifier faisabilité si on ajoute j_add
                if all(couverture_temp .+ A[:, j_add] .<= 1)
                    z_new = z_best - C[j_remove] + C[j_add]

                    # Si amélioration de la valeur objective, on adopte la nouvelle solution
                    if z_new > z_best
                        x_best[j_remove] = 0
                        x_best[j_add] = 1
                        couverture = couverture_temp .+ A[:, j_add]
                        z_best = z_new
                        amelioration = true
                        break
                    end
                end
            end

            if amelioration
                break
            end
        end
    end

    return x_best
end
