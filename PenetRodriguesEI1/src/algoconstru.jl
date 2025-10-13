function SCP(C, A)
    n = length(C)
    m = size(A, 1)

    x = zeros(Int, n)
    couverture = zeros(Int, m)             # nb de colonnes actives couvrant chaque ligne

    tailles = vec(sum(A; dims = 1))               # nombre de 1 par colonne
    scores = similar(C, Float64)
    for j in eachindex(C)
        t = tailles[j]
        scores[j] = t == 0 ? -Inf : C[j] / t     # exclure colonnes vides en leur donnant -Inf
    end

    # sélection greedy : à chaque étape, prendre la colonne restante de score maximal
    remaining = collect(1:n)
    while !isempty(remaining)
        sub_scores = scores[remaining]
        pos = argmax(sub_scores)           # position dans 'remaining'
        j = remaining[pos]                 # index réel de la colonne choisie

        colj = @view A[:, j]
        if all(couverture .+ colj .<= 1)   # test de faisabilité
            x[j] = 1
            couverture .+= colj
        end

        deleteat!(remaining, pos)          # retirer j des candidats restants
    end

    return x
end