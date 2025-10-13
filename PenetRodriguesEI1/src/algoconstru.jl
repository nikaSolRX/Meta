function SCP(C, A)
    n, m = size(A)
    LengthC = length(C)
    U = zeros(Float64, LengthC)
    Ia = zeros(Int, LengthC)
    xlist = zeros(Int, LengthC)
    couvert = falses(size(A, 1))
    z = 0
    
    for i in 1:n
        for j in 1:m
            if A[i, j] == 1
                Ia[j] += 1
            end
        end
    end
    for k in 1:length(Ia)
        U[k] = C[k] / Ia[k]
    end



    while any(.!couvert)
        for p in 1:LengthC
            if Ia[p] > 0
                U[p] = C[p] / Ia[p]
            else
                U[p] = Inf
            end
        end

        uMin, iMin = findmin(U)
        if uMin == Inf
            break
        end
        xlist[iMin] = 1

        for l in 1:n
            if A[l, iMin] == 1 && !couvert[l]
                couvert[l] = true
                for o in 1:m
                    if A[l, o] == 1
                        Ia[o] -= 1
                    end
                end
            end
        end

        U[iMin] = Inf
    end

    z = sum(xlist .* C)


    return xlist
end