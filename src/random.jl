import Base: rand

rand(::Type{Float64SD}) = convert(Float64SD, rand(Float64))
rand(::Type{Float32SD}) = convert(Float32SD, rand(Float32))
rand(::Type{Float16SD}) = convert(Float16SD, rand(Float16))

rand(::Type{Float64SD}, dims::Integer...) = convert.(Float64SD, rand(Float64, dims...))
rand(::Type{Float32SD}, dims::Integer...) = convert.(Float32SD, rand(Float32, dims...))
rand(::Type{Float16SD}, dims::Integer...) = convert.(Float16SD, rand(Float16, dims...))


import Base: randn

randn(::Type{Float64SD}) = convert(Float64SD, randn(Float64))
randn(::Type{Float32SD}) = convert(Float32SD, randn(Float32))
randn(::Type{Float16SD}) = convert(Float16SD, randn(Float16))

randn(::Type{Float64SD}, dims::Integer...) = convert.(Float64SD, randn(Float64, dims...))
randn(::Type{Float32SD}, dims::Integer...) = convert.(Float32SD, randn(Float32, dims...))
randn(::Type{Float16SD}, dims::Integer...) = convert.(Float16SD, randn(Float16, dims...))


