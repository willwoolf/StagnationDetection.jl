import Base: convert, promote_rule

# promotion within FloatSD
promote_rule(::Type{Float64SD}, ::Type{Float64SD}) = Float64SD
promote_rule(::Type{Float64SD}, ::Type{Float32SD}) = Float64SD
promote_rule(::Type{Float64SD}, ::Type{Float16SD}) = Float64SD

promote_rule(::Type{Float32SD}, ::Type{Float64SD}) = Float64SD
promote_rule(::Type{Float32SD}, ::Type{Float32SD}) = Float32SD
promote_rule(::Type{Float32SD}, ::Type{Float16SD}) = Float32SD

promote_rule(::Type{Float16SD}, ::Type{Float64SD}) = Float64SD
promote_rule(::Type{Float16SD}, ::Type{Float32SD}) = Float32SD
promote_rule(::Type{Float16SD}, ::Type{Float16SD}) = Float16SD

# promotion from abstractfloat to floatsd
promote_rule(::Type{Float64SD}, ::Type{Float64}) = Float64SD
promote_rule(::Type{Float64SD}, ::Type{Float32}) = Float64SD
promote_rule(::Type{Float64SD}, ::Type{Float16}) = Float64SD

promote_rule(::Type{Float32SD}, ::Type{Float64}) = Float64SD
promote_rule(::Type{Float32SD}, ::Type{Float32}) = Float32SD
promote_rule(::Type{Float32SD}, ::Type{Float16}) = Float32SD

promote_rule(::Type{Float16SD}, ::Type{Float64}) = Float64SD
promote_rule(::Type{Float16SD}, ::Type{Float32}) = Float32SD
promote_rule(::Type{Float16SD}, ::Type{Float16}) = Float16SD

# promotion of integer types
promote_rule(::Type{Float64SD}, T2::Type{T}) where {T <: Number} = FloatSD(promote_rule(Float64, T2))
promote_rule(::Type{Float32SD}, T2::Type{T}) where {T <: Number} = FloatSD(promote_rule(Float32, T2))
promote_rule(::Type{Float16SD}, T2::Type{T}) where {T <: Number} = FloatSD(promote_rule(Float16, T2))


# conversions for assignment.
# remember every FloatXYSD has a constructor for a FloatXY and a constructor for a Real
convert(::Type{FloatSD}, x::Float64) = Float64SD(x)
convert(::Type{Float64SD}, x::Float64) = Float64SD(x)
convert(::Type{Float64SD}, x::Float32) = Float64SD(x)
convert(::Type{Float64SD}, x::Float16) = Float64SD(x)
# convert(::Type{Float64SD}, x::BFloat16) = Float64SD(x)

convert(::Type{FloatSD}, x::Float32) = Float32SD(x)
convert(::Type{Float32SD}, x::Float64) = Float32SD(x)
convert(::Type{Float32SD}, x::Float32) = Float32SD(x)
convert(::Type{Float32SD}, x::Float16) = Float32SD(x)
# convert(::Type{Float32SD}, x::BFloat16) = Float32SD(x)

convert(::Type{FloatSD}, x::Float16) = Float16SD(x)
convert(::Type{Float16SD}, x::Float64) = Float16SD(x)
convert(::Type{Float16SD}, x::Float32) = Float16SD(x)
convert(::Type{Float16SD}, x::Float16) = Float16SD(x)
# convert(::Type{Float16SD}, x::BFloat16) = Float16SD(x)

# convert(::Type{FloatSD}, x::BFloat16) = BFloat16SD(x)
# convert(::Type{BFloat16SD}, x::Float64) = BFloat16SD(x)
# convert(::Type{BFloat16SD}, x::Float32) = BFloat16SD(x)
# convert(::Type{BFloat16SD}, x::Float16) = BFloat16SD(x)
# convert(::Type{BFloat16SD}, x::BFloat16) = BFloat16SD(x)

# conversions for casting
# convert(::Type{Float64SD})

convert(::Type{T}, x::Float64SD) where {T <: Number} = T(x.value)
convert(::Type{T}, x::Float32SD) where {T <: Number} = T(x.value)
convert(::Type{T}, x::Float16SD) where {T <: Number} = T(x.value)

# these seem required for ShallowWaters
Base.Int64(x::FloatSD) = Int64(x.value)
Base.Int32(x::FloatSD) = Int32(x.value)

convert(::Type{T}, x::Float64SD) where {T <: FloatSD} = T(x)
convert(::Type{T}, x::Float32SD) where {T <: FloatSD} = T(x)
convert(::Type{T}, x::Float16SD) where {T <: FloatSD} = T(x)

convert(::Type{AbstractFloat}, x::Float64SD) = (x.value)
convert(::Type{AbstractFloat}, x::Float32SD) = (x.value)
convert(::Type{AbstractFloat}, x::Float16SD) = (x.value)

Base.Float64(x::FloatSD) = convert(Float64, x)
Base.Float32(x::FloatSD) = convert(Float32, x)
Base.Float16(x::FloatSD) = convert(Float16, x)

# rounding function
import Base: round 

# data is reset. TODO: should it not be?
round(x::Float64SD, r::RoundingMode) = Float64SD(round(x.value, r))
round(x::Float32SD, r::RoundingMode) = Float32SD(round(x.value, r))
round(x::Float16SD, r::RoundingMode) = Float16SD(round(x.value, r))
