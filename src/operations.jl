import Base: +

"""
Be mindful of the distinction for ordering when adding Float64 and Float64SD variables.
The first method considers the Float64SD to be the left operand, it is "being added to" from the right.
The method +(::Float64SD, ::Float64SD) inherits data from the left operand and only takes the .value of the right argument.
Therefore this method +(::Float64, ::Float64SD) could lead to unexpected behaviour.
"""
+(in1::Real, in2::FloatSD) = in2 + in1

"""
The fields for stagnation detection are inherited from the LEFT argument.
"""
+(in1::FloatSD, in2::FloatSD) = in1 + in2.value

## change to work with integers

+(in1::Float64SD, in2::Float64) = sdadd(in1, in2)
+(in1::Float64SD, in2::Float32) = sdadd(in1, Float64(in2))
+(in1::Float64SD, in2::Float16) = sdadd(in1, Float64(in2))

+(in1::Float32SD, in2::Float64) = sdadd(Float64SD(in1), in2)
+(in1::Float32SD, in2::Float32) = sdadd(in1, in2)
+(in1::Float32SD, in2::Float16) = sdadd(in1, Float32(in2))

+(in1::Float16SD, in2::Float64) = sdadd(Float64SD(in1), in2)
+(in1::Float16SD, in2::Float32) = sdadd(Float32SD(in1), in2)
+(in1::Float16SD, in2::Float16) = sdadd(in1, in2)

+(in1::Float64SD, in2::Integer) = sdadd(in1, Float64(in2))
+(in1::Float32SD, in2::Integer) = sdadd(in1, Float32(in2)) # is method ambiguous?
+(in1::Float16SD, in2::Integer) = sdadd(in1, Float16(in2))

+(in1::FloatSD) = in1
+(in1::Array{FloatSD}) = in1


import Base: -

-(in1::FloatSD, in2::Real) = in1 + (-in2)
-(in1::Real, in2::FloatSD) = -(in2 - in1) # not a huge fan of this one
-(in1::FloatSD, in2::FloatSD) = in1 + (-(in2.value))

# changing sign doesn't reset the FloatSD, this is intended
function -(in1::T) where {T <: FloatSD}
    return T(
        -(in1.value),
        in1.u,
        in1.t, 
        in1.additions,
        in1.absorptions_up,
        in1.absorptions_dn
    )
end


import Base: *

*(in1::FloatSD, in2::FloatSD) = FloatSD(in1.value * in2.value)
*(in1::FloatSD, in2::Real) = FloatSD(in1.value * in2)
*(in1::Real, in2::FloatSD) = in2 * in1

*(in1::FloatSD, in2::Array{FloatSD}) = [in1 * x for x in in2]
*(in1::Array{FloatSD}, in2::FloatSD) = in2 * in1


import Base: muladd

muladd(x::T, y::T, z::T) where {T <: FloatSD} = z + (x * y)
muladd(x::F, y::F, z::T) where {T <: FloatSD, F <: AbstractFloat} = z + (x * y)


import Base: /

/(in1::FloatSD, in2::Real) = FloatSD(in1.value / in2)
/(in1::Real, in2::FloatSD) = FloatSD(in1 / in2.value)
/(in1::FloatSD, in2::FloatSD) = in1 / in2.value

# /(in1::Array{FloatSD}, in2::FloatSD)
# /(in1::FloatSD, in2::Array{FloatSD})
/(in1::Array{FloatSD}, in2::Real) = [x / in2 for x in in1]
/(in1::Real, in2::Array{FloatSD}) = [in1 / x for x in in2]


# don't need to import isless??

import Base: <, >, <=, >=, ==

<(in1::FloatSD, in2::FloatSD) = <(in1.value, in2.value)
<(in1::FloatSD, in2::Real) = <(in1.value, in2)
<(in1::Real, in2::FloatSD) = <(in1, in2.value)

>(in1::FloatSD, in2::FloatSD) = >(in1.value, in2.value)
>(in1::FloatSD, in2::Real) = >(in1.value, in2)
>(in1::Real, in2::FloatSD) = >(in1, in2.value)

<=(in1::FloatSD, in2::FloatSD) = <=(in1.value, in2.value)
<=(in1::FloatSD, in2::Real) = <=(in1.value, in2)
<=(in1::Real, in2::FloatSD) = <=(in1, in2.value)

>=(in1::FloatSD, in2::FloatSD) = >=(in1.value, in2.value)
>=(in1::FloatSD, in2::Real) = >=(in1.value, in2)
>=(in1::Real, in2::FloatSD) = >=(in1, in2.value)

==(in1::FloatSD, in2::FloatSD) = ==(in1.value, in2.value)
==(in1::FloatSD, in2::Real) = ==(in1.value, in2)
==(in1::Real, in2::FloatSD) = ==(in1, in2.value)