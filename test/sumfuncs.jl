# import Random: Xoshiro

function harm(N::Int, T::DataType = Float64)
    if N == 0 return T(0.0) end
    if N == 1 return T(1.0) end
    @assert N > 1

    s::T = 1.0
    for i in 2:N
        x = one(T)/i
        s += x
    end
    return s
end

function harm(s::T, N::Int) where {T <: AbstractFloat}
    if N == 0 return s end
    if N == 1 return s + 1 end
    @assert N > 1

    for i in 1:N
        x = one(T)/i
        s += x
    end

    return s
end

function iharm(N::Int, T::DataType = Float64)
    if N == 0 return T(0.0) end
    if N == 1 return T(1.0) end
    @assert N > 1

    s::T = 0.0
    for i in N:-1:1
        x = one(T)/i
        s += x
    end
    return s
end

function iharm(s::T, N::Int) where {T <: AbstractFloat}
    if N == 0 return s end
    if N == 1 return s + 1 end
    @assert N > 1

    for i in N:-1:1
        x = one(T)/i
        s += x
    end

    return s
end

function randsum(rng, N::Int, T::DataType = Float64)
    if N == 0 return T(0.0) end
    if N == 1 return rand(rng, T) end
    @assert N > 1

    s::T = 0.0
    for _ in 1:N
        x = rand(rng, T)
        s += x       
    end
    return s
end

function rand2um(rng, N::Int, T::DataType = Float64)
    if N == 0 return T(0.0) end
    if N == 1 return rand(rng, T) end
    @assert N > 1
    
    s::T = 0.0
    for _ in 1:N
        x = rand(rng, T)
        s += x
        if s > 1
            s = 0
        end 
    end
    return s
end

function pisum(N::Int, T::DataType = Float64)
    if N == 0 return T(0.0) end
    if N == 1 return T(1.0) end
    @assert N > 1

    s::T = 1.0
    for i in 2:N
        x = one(T)/(i*i)
        s += x
    end
    return s
end

function pisum(s::T, N::Int) where {T <: AbstractFloat}
    if N == 0 return T(0.0) end
    if N == 1 return T(1.0) end
    @assert N > 1

    for i in 1:N
        x = one(T)/(i*i)
        s += x
    end
    return s
end


randsum(N::Int, T::DataType = Float64) = randsum(Xoshiro(), N, T)
rand2um(N::Int, T::DataType = Float64) = rand2um(Xoshiro(), N, T)



# test different recursive sums, see if stagnation cancelling out from mixed signs makes much of a difference