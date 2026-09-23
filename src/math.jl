# fundamental mathematical functions

import Base: sin, cos, sinpi, cospi, tan, sinh, cosh, tanh, exp, log, sqrt, abs, abs2, acos, asin, atan

for f in (:sin, :cos, :sinpi, :cospi, :tan, :sinh, :cosh, :tanh, :exp, :log, :sqrt, :asin, :acos, :atan)
    @eval Base.$f(x::T) where {T <: FloatSD} = T($f(x.value))
end

abs(x::T) where {T <: FloatSD} = T(
    abs(x.value),
    x.u,
    x.t,
    x.additions,
    x.absorptions_up,
    x.absorptions_dn
)

# inv(x) = one(x)/x already defined in number

# adjoint(x::Real) = conj(x) = x already defined in number


import Base: hypot, atan, rem

for f in (:hypot, :atan, :rem)
    @eval Base.$f(x::FloatSD, y::FloatSD) = FloatSD($f(x.value, y.value))
end


import Base: one, oneunit, zero, issubnormal, isfinite, isinf, isnan, iszero, isone, nextfloat, prevfloat, isinteger, isreal, isodd, iseven, precision

# one(x::FloatSD) = FloatSD(one(x.value))
one(::Type{T}) where {T <: FloatSD} = T(1.0)

# oneunit(x::FloatSD) = one(x)
oneunit(::Type{T}) where {T <: FloatSD} = one(T)

zero(x::FloatSD) = FloatSD(zero(x.value))
zero(::Type{T}) where {T <: FloatSD} = T(0.0)

issubnormal(x::FloatSD) = issubnormal(x.value)
isfinite(x::FloatSD) = isfinite(x.value)
isinf(x::FloatSD) = isinf(x.value)
isnan(x::FloatSD) = isnan(x.value)
iszero(x::FloatSD) = iszero(x.value)
isone(x::FloatSD) = isone(x.value)

nextfloat(x::FloatSD, n::Integer = 1) = FloatSD(nextfloat(x.value, n))
prevfloat(x::FloatSD, n::Integer = 1) = FloatSD(prevfloat(x.value, n))

isinteger(x::FloatSD) = isinteger(x.value)
isreal(x::FloatSD) = isreal(x.value)
isodd(x::FloatSD) = isodd(x.value)
iseven(x::FloatSD) = !isodd(x)

precision(x::FloatSD) = precision(x.value)
