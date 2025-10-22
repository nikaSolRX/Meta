function GRASP_C(C, A)
    n = length(C)
    m = size(A, 1)
    alpha = 0.70

    #RCL = zeros(Int, n)
    couverture = zeros(Int, m)             # nb de colonnes actives couvrant chaque ligne

    tailles = vec(sum(A; dims = 1))               # nombre de 1 par colonne
    U = similar(C, Float64)
    for j in eachindex(C)
        t = tailles[j]
        U[j] = t == 0 ? -Inf : C[j] / t     # exclure colonnes vides en leur donnant -Inf
    end
    ULimit = alpha * (maximum(U) - minimum(U)) + minimum(U)

    RCL = findall(u -> U[u] >= ULimit, 1:n)

    return RCL
end