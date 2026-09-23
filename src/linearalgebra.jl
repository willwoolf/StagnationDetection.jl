# vector sum, vector dot-product and matrix multiply


# lrsum(X::AbstractVector{T}) where {T <: Real} = foldl(+, X)


function lrsum(X::AbstractVector{T}) where {T <: Real}
    if length(X) == 0
        return zero(eltype(X))
    end
    s = zero(first(X))
    for Ix in eachindex(X)
        s += X[Ix]
    end
    return s
end


"""
Dot product with left-to-right recursive summation.
Heavily based on LinearAlgebra: dot
"""
function lrdot(X::AbstractVector{T}, Y::AbstractVector{T}) where {T <: Real}
    lx = length(X)
    if lx != length(Y)
        throw(DimensionMismatch(lazy"first array has length $(lx) which does not match the length of the second, $(length(y))."))
    end
    if lx == 0
        return zero(dot(zero(eltype(X)), zero(eltype(Y))))
    end
    s = zero(first(X) * first(Y))
    for (Ix, Iy) in zip(eachindex(X), eachindex(Y))
        s = muladd(@inbounds(X[Ix]), @inbounds(Y[Iy]), s)
    end
    return s
end


# do we keep the zero addition?
# it is consistent with dot

# next: matrix multiply


"""
Matrix multiplication, employing dot product within each entry.
"""
function lrmatmul(A::AbstractMatrix, B::AbstractVector)
    mA, nA = size(A)
    if nA != length(B)
        throw(DimensionMismatch(lazy"matrix has $(nA) columns which does not match the length of B, $(length(B))."))
    end
    C = similar(A, mA)
    lrmatmul!(C, A, B)
    return C
end

function lrmatmul(A::AbstractMatrix, B::AbstractMatrix)
    mA, nA = size(A)
    mB, nB = size(B)
    if nA != mB
        throw(DimensionMismatch(lazy"matrix has $(nA) columns which does not match the number of rows in B, $(mB)."))
    end

    C = similar(A, mA, nB)
    lrmatmul!(C, A, B)
    return C
end


"""
Based on LinearAlgebra: generic_matmatmul_generic!
"""
function lrmatmul!(C::AbstractVector, A::AbstractMatrix, B::AbstractVector)
    @inbounds for i in axes(A, 1)
        Ctmp = zero(eltype(C))
        for k in axes(A, 2)
            Ctmp = muladd(A[i, k], B[k], Ctmp)
        end
        C[i] = Ctmp
    end
end

function lrmatmul!(C::AbstractMatrix, A::AbstractMatrix, B::AbstractMatrix)
    @inbounds for i in axes(A, 1), j in axes(B, 2)
        Ctmp = zero(eltype(C))
        for k in axes(A, 2)
            Ctmp = muladd(A[i, k], B[k, j], Ctmp)
        end
        C[i, j] = Ctmp
    end
end





## block LU with partial pivoting

import LinearAlgebra: tril, triu, LowerTriangular, UpperTriangular, UnitLowerTriangular

"""
    `lrblu(A::Matrix, b::Int = 1024)`

Block LU factorisation algorithm for square matrices.
"""
lrblu(A::Matrix{T}, b::Int = 1024) where {T <: AbstractFloat} = lrblu!(deepcopy(A), b)

function lrblu!(A::Matrix{T}, b::Int) where {T <: AbstractFloat}
    m, n = size(A)
    @assert m == n

    num_blocks::Int = n ÷ b
    P::Vector{Int} = collect(1:m)
    # rem_block::Int = n % b

    for k in 0:num_blocks
        if k != num_blocks
            # tall LU factorisation
            F, p = lrlu(A[k*b + 1:end, k*b + 1:(k+1)*b])
            
            # apply permutation, I think this is safe
            A[k*b + 1:end, :] = A[k*b + 1:end, :][p, :]
            P[k*b + 1:end] = P[k*b + 1:end][p]

            # update the L block-colum
            A[k*b + 1:end, k*b + 1:(k+1)*b] = F

            # solve for the remaining U block-row
            A[k*b + 1:(k+1)*b, (k+1)*b + 1:end] = UnitLowerTriangular(A[k*b + 1:(k+1)*b, k*b + 1:(k+1)*b]) \ A[k*b + 1:(k+1)*b, (k+1)*b + 1:end]
            
            # level 3 operation on unfactorised submatrix
            A[(k+1)*b + 1:end, (k+1)*b + 1:end] -= A[(k+1)*b + 1:end, k*b + 1:(k+1)*b] * A[k*b + 1:(k+1)*b, (k+1)*b + 1:end]
        else
            # final LU factorisation
            F, p = lrlu(A[k*b + 1:end, k*b + 1:end])

            # apply permutation
            A[k*b + 1:end, :] = A[k*b + 1:end, :][p, :]
            P[k*b + 1:end] = P[k*b + 1:end][p]

            # update
            A[k*b + 1:end, k*b + 1:end] = F

            # no remaining elements to solve for
            
            return A, P
        end
    end
end

lrlu(A) = lrlu!(deepcopy(A))

function lrlu!(A::Matrix)
    m, n = size(A)
    r = min(m, n)
    pivots::Vector{Int} = collect(1:m)
    for k in 1:r
        # partial pivoting
        μ::Int = argmax(abs.(
            vcat(
                zeros(Int, k-1),
                A[k:m, k]
            )
        ))
        (A[k, :], A[μ, :]) = (A[μ, :], A[k, :])
        (pivots[k], pivots[μ]) = (pivots[μ], pivots[k])

        # gauss operation
        if A[k, k] != 0
            ρ = k+1:m
            τ = k+1:n

            A[ρ, k] = A[ρ, k] / A[k, k]
            A[ρ, τ] = A[ρ, τ] - A[ρ, k]*A[k, τ]'
        end
    end
    return A, pivots
end


# function pivvector(indices::Vector{Int})
#     X::Vector{Int} = collect(1:lastindex(indices)+1)
#     for i in 1:lastindex(indices)
#         (X[i], X[indices[i]]) = (X[indices[i]], X[i])
#     end
#     return X

# end

# function splitlu(A::Matrix)
#     L = UnitLowerTriangular(tril(A))
#     U = UpperTriangular(triu(A))

#     return (L, U)
# end



# benchmark these methods with block sizes b=64, 128, 256, 512, 1024 against LinAlg: lu
# modify lrblu to report stagnation in level 3 operations and run with test matrices



# stagnation detection in the level 3 block-LU operations

# lrblu(A::Matrix{T}, b::Int = 1024) where {T <: FloatSD} = lrblu!(deepcopy(A), b)

function lrblu!(A::Matrix{T}, b::Int) where {T <: FloatSD}
    m, n = size(A)
    @assert m == n

    num_blocks::Int = n ÷ b
    P::Vector{Int} = collect(1:m)
    # rem_block::Int = n % b

    results::Vector{Int} = zeros(length(n-b:-b:0))

    function underlying(T)
        if T == Float64SD
            return Float64
        elseif T == Float32SD
            return Float32
        elseif T == Float16SD
            return Float16
        else
            return T
        end
    end

    FloatT = underlying(T)

    for k in 0:num_blocks
        if k != num_blocks
            # tall LU factorisation
            F, p = lrlu(FloatT.(A[k*b + 1:end, k*b + 1:(k+1)*b]))
            
            # apply permutation, I think this is safe
            A[k*b + 1:end, :] = A[k*b + 1:end, :][p, :]
            P[k*b + 1:end] = P[k*b + 1:end][p]

            # update the L block-colum
            A[k*b + 1:end, k*b + 1:(k+1)*b] = F

            # solve for the remaining U block-row
            A[k*b + 1:(k+1)*b, (k+1)*b + 1:end] = UnitLowerTriangular(FloatT.(A[k*b + 1:(k+1)*b, k*b + 1:(k+1)*b])) \ FloatT.(A[k*b + 1:(k+1)*b, (k+1)*b + 1:end])

            # level 3 operation on unfactorised submatrix
            # additions from the solve will not be counted because they contribute to matrix multiplication
            # only doing stagnation detection here so do the rest on normal?
            # how to report this information. return the outer products themselves, or some reduction of the data? summation length never changes, just the size of the result of L3
            L3O = A[(k+1)*b + 1:end, k*b + 1:(k+1)*b] * A[k*b + 1:(k+1)*b, (k+1)*b + 1:end]
            results[k+1] = !isempty(L3O) ? maximum(diff_absorptions.(L3O)) : 0

            A[(k+1)*b + 1:end, (k+1)*b + 1:end] -= FloatT.(L3O)
        else
            F, p = lrlu(A[k*b + 1:end, k*b + 1:end])

            # apply permutation
            A[k*b + 1:end, :] = A[k*b + 1:end, :][p, :]
            P[k*b + 1:end] = P[k*b + 1:end][p]

            # update
            A[k*b + 1:end, k*b + 1:end] = F

            # no remaining elements to solve for
        
            return A, P, results
        end
    end
    # repeat on next block
end