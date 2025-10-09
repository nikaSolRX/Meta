# Construction gloutonne pour SPP
# Entrées : C (profits, Vector{<:Real}), A (matrice binaire m×n, Matrix{Int})
# Sortie  : x (solution admissible, Vector{Int} avec 0/1)
function SCP(C, A)
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

    return x
end
