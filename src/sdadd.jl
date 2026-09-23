## stagnation detection addition

const _MINNORMAL_FLOAT64 = reinterpret(Float64, 0x0010_0000_0000_0000)
const _MINNORMAL_FLOAT32 = reinterpret(Float32, 0x0080_0000)
const _MINNORMAL_FLOAT16 = reinterpret(Float16, 0x0400)

function sdadd(in1::T, in2::F) where {T <: FloatSD, F <: AbstractFloat}
    u_i::UInt = getAbsorptionU(in1.value, in2)
    isAbsorption::Int8 = getAbsorptionInfo(in1.value, in2, u_i, in1.t)

    absorptions_up_n::UInt = ifelse(isAbsorption ==  1, in1.absorptions_up + 1, in1.absorptions_up)
    absorptions_dn_n::UInt = ifelse(isAbsorption == -1, in1.absorptions_dn + 1, in1.absorptions_dn)

    return T(
        in1.value + in2,
        in1.u + u_i,
        in1.t,
        in1.additions + 1,
        absorptions_up_n,
        absorptions_dn_n
    )
end


# subfunctions

function getAbsorptionU(x::T, y::T) where {T <: AbstractFloat}
    return max(0, precision(T) - abs(bitexponent(x) - bitexponent(y)))
end

function getAbsorptionInfo(x::T, y::T, u_classic::Integer, t::Integer) where {T <: AbstractFloat}
    isAbsorption::Int8 = 0 # should ALMOST DEFINITELY rename this
    if t == -1
        if u_classic == 0
            if abs(y) < abs(x)
                if 2 * abs(y) < eps(x)
                    isAbsorption = -sign(y) # sign corresponds to direction of rounding
                end
            else
                if 2 * abs(x) < eps(y)
                    isAbsorption = -sign(x)
                end
            end
        end
    elseif t >= 0 # can remove condition here?
        if u_classic <= t # t can be at most the precision of the format. in this case everything would be counted as absorption
            if abs(y) < abs(x)
                isAbsorption = -sign(y)
            elseif abs(x) < abs(y) # can we assume |x| == |y| isn't possible? no
                isAbsorption = -sign(x)
            end
        end
    end

    return isAbsorption
end


"""
Floating-point exponent.
Returns the exponent of the floating-point representation, unlike `exponent` which behaves differently for subnormals.
"""
function bitexponent(x::Float64)
    e::Int = 0
    if x == 0
        return e
    elseif issubnormal(x)
        e = exponent(_MINNORMAL_FLOAT64)
    elseif isinf(x) || isnan(x)
        # if values are inf or nan, stagnation detection fails silently
        e = 1024
    else
        e = exponent(x)
    end
    return e
end

function bitexponent(x::Float32)
    e::Int = 0
    if x == 0
        return e
    elseif issubnormal(x)
        e = exponent(_MINNORMAL_FLOAT32)
    elseif isinf(x) || isnan(x)
        e = 128
    else
        e = exponent(x)
    end
    return e
end

function bitexponent(x::Float16)
    e::Int = 0
    if x == 0
        return e
    elseif issubnormal(x)
        e = exponent(_MINNORMAL_FLOAT16)
    elseif isinf(x) || isnan(x)
        e = 16
    else
        e = exponent(x)
    end
    return e
end


# TODO: put warnings in report instead of bitexponent