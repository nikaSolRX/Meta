function SCP(C, A)
    n = length(C)
    nbcolonne = size(A, 1)
    x = zeros(Int, n)
    couverture = zeros(Int, nbcolonne)

    scores = [C[j] / (1 + sum(A[:, j])) for j in 1:n]
    #print(a=sum(A[:, j]))
    ordre = sortperm(scores, rev=true)

    for j in ordre
        if all(couverture .+ A[:, j] .<= 1)
            x[j] = 1
            couverture .+= A[:, j]
        end
    end

    return x
end