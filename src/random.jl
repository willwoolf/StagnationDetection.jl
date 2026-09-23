import Random: Xoshiro, AbstractRNG

import Base: rand, randn
rand(rng::AbstractRNG, ::Type{Float64SD}) = convert.(Float64SD, rand(rng, Float64))
rand(rng::AbstractRNG, ::Type{Float32SD}) = convert.(Float32SD, rand(rng, Float32))
rand(rng::AbstractRNG, ::Type{Float16SD}) = convert.(Float16SD, rand(rng, Float16))
rand(rng::AbstractRNG, ::Type{Float64SD}, arg1::Integer) = convert.(Float64SD, rand(rng, Float64, arg1))
rand(rng::AbstractRNG, ::Type{Float32SD}, arg1::Integer) = convert.(Float32SD, rand(rng, Float32, arg1))
rand(rng::AbstractRNG, ::Type{Float16SD}, arg1::Integer) = convert.(Float16SD, rand(rng, Float16, arg1))
rand(rng::AbstractRNG, ::Type{Float64SD}, arg1::Integer, arg2::Integer) = convert.(Float64SD, rand(rng, Float64, arg1, arg2))
rand(rng::AbstractRNG, ::Type{Float32SD}, arg1::Integer, arg2::Integer) = convert.(Float32SD, rand(rng, Float32, arg1, arg2))
rand(rng::AbstractRNG, ::Type{Float16SD}, arg1::Integer, arg2::Integer) = convert.(Float16SD, rand(rng, Float16, arg1, arg2))

rand(::Type{T}) where {T <: FloatSD} = rand(Xoshiro(), T)
rand(::Type{T}, arg1::Integer) where {T <: FloatSD} = rand(Xoshiro(), T, arg1)
rand(::Type{T}, arg1::Integer, arg2::Integer) where {T <: FloatSD} = rand(Xoshiro(), T, arg1, arg2)

randn(rng::AbstractRNG, ::Type{Float64SD}) = convert.(Float64SD, randn(rng, Float64))
randn(rng::AbstractRNG, ::Type{Float32SD}) = convert.(Float32SD, randn(rng, Float32))
randn(rng::AbstractRNG, ::Type{Float16SD}) = convert.(Float16SD, randn(rng, Float16))
randn(rng::AbstractRNG, ::Type{Float64SD}, arg1::Integer) = convert.(Float64SD, randn(rng, Float64, arg1))
randn(rng::AbstractRNG, ::Type{Float32SD}, arg1::Integer) = convert.(Float32SD, randn(rng, Float32, arg1))
randn(rng::AbstractRNG, ::Type{Float16SD}, arg1::Integer) = convert.(Float16SD, randn(rng, Float16, arg1))
randn(rng::AbstractRNG, ::Type{Float64SD}, arg1::Integer, arg2::Integer) = convert.(Float64SD, randn(rng, Float64, arg1, arg2))
randn(rng::AbstractRNG, ::Type{Float32SD}, arg1::Integer, arg2::Integer) = convert.(Float32SD, randn(rng, Float32, arg1, arg2))
randn(rng::AbstractRNG, ::Type{Float16SD}, arg1::Integer, arg2::Integer) = convert.(Float16SD, randn(rng, Float16, arg1, arg2))

randn(::Type{T}) where {T <: FloatSD} = randn(Xoshiro(), T)
randn(::Type{T}, arg1::Integer) where {T <: FloatSD} = randn(Xoshiro(), T, arg1)
randn(::Type{T}, arg1::Integer, arg2::Integer) where {T <: FloatSD} = randn(Xoshiro(), T, arg1, arg2)