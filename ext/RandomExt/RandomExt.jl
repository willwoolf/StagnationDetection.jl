module RandomExt

using StagnationDetection

import Random: Xoshiro, AbstractRNG


import Base: rand

rand(rng::AbstractRNG, ::Type{Float64SD}) = convert.(Float64SD, rand(rng, Float64))
rand(rng::AbstractRNG, ::Type{Float32SD}) = convert.(Float32SD, rand(rng, Float32))
rand(rng::AbstractRNG, ::Type{Float16SD}) = convert.(Float16SD, rand(rng, Float16))

rand(rng::AbstractRNG, ::Type{Float64SD}, dims::Integer...) = convert.(Float64SD, rand(rng, Float64, dims...))
rand(rng::AbstractRNG, ::Type{Float32SD}, dims::Integer...) = convert.(Float32SD, rand(rng, Float32, dims...))
rand(rng::AbstractRNG, ::Type{Float16SD}, dims::Integer...) = convert.(Float16SD, rand(rng, Float16, dims...))

export rand


import Base: randn

randn(rng::AbstractRNG, ::Type{Float64SD}) = convert.(Float64SD, randn(rng, Float64))
randn(rng::AbstractRNG, ::Type{Float32SD}) = convert.(Float32SD, randn(rng, Float32))
randn(rng::AbstractRNG, ::Type{Float16SD}) = convert.(Float16SD, randn(rng, Float16))

randn(rng::AbstractRNG, ::Type{Float64SD}, dims::Integer...) = convert.(Float64SD, randn(rng, Float64, dims...))
randn(rng::AbstractRNG, ::Type{Float32SD}, dims::Integer...) = convert.(Float32SD, randn(rng, Float32, dims...))
randn(rng::AbstractRNG, ::Type{Float16SD}, dims::Integer...) = convert.(Float16SD, randn(rng, Float16, dims...))

export randn


end