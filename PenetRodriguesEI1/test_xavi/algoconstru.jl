function SCP(C, A)
    n = length(C)
    # si A n'a pas n colonnes, on suppose qu'elle est transposée et on corrige
    if size(A, 2) != n
        @warn "Mismatch dims: length(C)=$n, size(A)=$(size(A)). Transposing A."
        A = A'
    end

    n = length(C)
    m = size(A, 1)

    x = zeros(Int, n)
    couverture = zeros(Int, m)             # nb de colonnes actives couvrant chaque ligne

    tailles = vec(sum(A; dims = 1))        # taille de chaque colonne
    scores  = C ./ (1 .+ tailles)          # ratio profit / (taille+1)

    # tri déterministe : d'abord score, puis profit comme second critère
    ordre = sortperm(1:n, by = j -> (scores[j], C[j]), rev = true)

    @inbounds for j in ordre
        colj = @view A[:, j]
        if all(couverture .+ colj .<= 1)   # test de faisabilité
            x[j] = 1
            couverture .+= colj
        end
    end

    z = sum(x .* C)
    return x, z
end