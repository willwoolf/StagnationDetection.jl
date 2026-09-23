# import BFloat16s: BFloat16
"""
Abstract supertype for all floating point numbers with stagnation detection.
"""
abstract type FloatSD <: AbstractFloat end

# catch-all and specialised constructors
FloatSD(x::T) where {T <: Real} = Float64SD(Float64(x)) 
FloatSD(x::Float64) = Float64SD(x)
FloatSD(x::Float32) = Float32SD(x)
FloatSD(x::Float16) = Float16SD(x)
FloatSD(::Type{Float64}) = Float64SD
FloatSD(::Type{Float32}) = Float32SD
FloatSD(::Type{Float16}) = Float16SD


# implement separate count for counting absorptions - done
# implement threshold and modify the default constructors - done

## Float64SD, wrapper for Float64 with stagnation detection
"""
`Float64SD <: FloatSD <: AbstractFloat <: Real`

Data structure for performing 64-bit floating point arithmetic with stagnation detection.
Contains `value`, `u`, `t`, `additions`, `stagnation` and `stagnation_rd` fields.

* `value::Float64` for use in arithmetic operations.
* `u::UInt64` number of bits preserved from previous additions.
* `t::Int8` threshold to determine absorption (-1 to precision(Float64)).
* `additions::UInt64` number of previous additions.
* `absorptions_up::UInt64` stagnation rounding up (number of absorptions rounding up).
* `absorptions_dn::UInt64` stagnation rounding down.

If performing addition where one argument is type `T` where `T <: FloatSD`, stagnation detection will be recorded.
Call `report(x)` for a human-readable output.
"""
struct Float64SD <: FloatSD
    # floating point value
    value::Float64

    # measures for quantifying stagnation
    u::UInt
    t::Int8
    additions::UInt
    absorptions_up::UInt
    absorptions_dn::UInt

    # copy constructor
    Float64SD(x::Float64SD) = deepcopy(x)

    # conversion constructor
    Float64SD(x::FloatSD) = new(
        Float64(x.value),
        x.u,
        x.t,
        x.additions,
        x.absorptions_up,
        x.absorptions_dn
    )

    # initialiser constructor from Float64
    function Float64SD(x::Float64; threshold::Integer = -1)
        if threshold < -1
            threshold = -1
        elseif threshold > 53
            threshold = 53
        end
        
        return new(
            x,
            UInt(0),
            Int8(threshold),
            UInt(0),
            UInt(0),
            UInt(0)
        )
    end

    # conversion initialiser constructor from Real
    Float64SD(x::Real; threshold::Int = -1) = Float64SD(convert(Float64, x); threshold)

    # default constructor
    Float64SD(x::Float64, u::UInt, t::Int8, additions::UInt, absorptions_up::UInt, absorptions_dn::UInt) = new(
        x,
        u,
        t,
        additions,
        absorptions_up,
        absorptions_dn
    )
end

"""
`Float32SD <: FloatSD <: AbstractFloat <: Real`

Data structure for performing 32-bit floating point arithmetic with stagnation detection.
Contains `value`, `u`, `t`, `additions`, `stagnation` and `stagnation_rd` fields.

* `value::Float32` for use in arithmetic operations.
* `u::UInt64` number of bits preserved from previous additions.
* `t::Int8` threshold to determine absorption (-1 to precision(Float64)).
* `additions::UInt64` number of previous additions.
* `absorptions_up::UInt64` stagnation rounding up (number of absorptions rounding up).
* `absorptions_dn::UInt64` stagnation rounding down.

If performing addition where one argument is type `T` where `T <: FloatSD`, stagnation detection will be recorded.
Call `report(x)` for a human-readable output.
"""
struct Float32SD <: FloatSD
    # floating point value
    value::Float32

    # measures for quantifying stagnation
    u::UInt
    t::Int8
    additions::UInt
    absorptions_up::UInt
    absorptions_dn::UInt
    
    # copy constructor
    Float32SD(x::Float32SD) = deepcopy(x)

    # conversion constructor
    Float32SD(x::FloatSD) = new(
        Float32(x.value),
        x.u,
        x.t,
        x.additions,
        x.absorptions_up,
        x.absorptions_dn
    )

    # initialiser constructor from Float32
    function Float32SD(x::Float32; threshold::Int64 = -1)
        if threshold < -1
            threshold = -1
        elseif threshold > 24
            threshold = 24
        end
        
        return new(
            x,
            UInt(0),
            Int8(threshold),
            UInt(0),
            UInt(0),
            UInt(0)
        )
    end

    # conversion initialiser constructor from Real
    Float32SD(x::Real; threshold::Int = -1) = Float32SD(convert(Float32, x); threshold)

    # default constructor
    Float32SD(x::Float32, u::UInt, t::Int8, additions::UInt, absorptions_up::UInt, absorptions_dn::UInt) = new(
        x,
        u,
        t,
        additions,
        absorptions_up,
        absorptions_dn
    )
end

"""
`Float16SD <: FloatSD <: AbstractFloat <: Real`

Data structure for performing 16-bit floating point arithmetic with stagnation detection.
Contains `value`, `u`, `t`, `additions`, `stagnation` and `stagnation_rd` fields.

* `value::Float16` for use in arithmetic operations.
* `u::UInt64` number of bits preserved from previous additions.
* `t::Int8` threshold to determine absorption (-1 to precision(Float64)).
* `additions::UInt64` number of previous additions.
* `absorptions_up::UInt64` stagnation rounding up (number of absorptions rounding up).
* `absorptions_dn::UInt64` stagnation rounding down.

If performing addition where one argument is type `T` where `T <: FloatSD`, stagnation detection will be recorded.
Access fields of `x::Float16SD` with `x.stagnation` or similar, or by calling `report(x)` for a human-readable output.
"""
struct Float16SD <: FloatSD
    # floating point value
    value::Float16

    # measures for quantifying stagnation
    u::UInt
    t::Int8
    additions::UInt
    absorptions_up::UInt
    absorptions_dn::UInt

    # copy constructor
    Float16SD(x::Float16SD) = deepcopy(x)

    # conversion constructor
    Float16SD(x::FloatSD) = new(
        Float16(x.value),
        x.u,
        x.t,
        x.additions,
        x.absorptions_up,
        x.absorptions_dn
    )

    function Float16SD(x::Float16; threshold::Int64 = -1)
        if threshold < -1
            threshold = -1
        elseif threshold > 11
            threshold = 11
        end
        
        return new(
            x,
            UInt(0),
            Int8(threshold),
            UInt(0),
            UInt(0),
            UInt(0)
        )
    end

    # convert Real to Float64 will have to be removed when alternative precisions are introduced
    Float16SD(x::Real; threshold::Int64 = -1) = Float16SD(convert(Float16, x); threshold)

    # default constructor
    Float16SD(x::Float16, u::UInt, t::Int8, additions::UInt, absorptions_up::UInt, absorptions_dn::UInt) = new(
        x,
        u,
        t,
        additions,
        absorptions_up,
        absorptions_dn
    )
end

# """
# `BFloat16SD <: FloatSD <: AbstractFloat <: Real`

# Data structure for performing 16-bit floating point arithmetic with stagnation detection.
# Contains `value`, `u`, `t`, `additions` and `stagnation` fields.

# * `value::Float16` for use in arithmetic operations.
# * `u::UInt64` number of bits preserved from previous additions.
# * `t::UInt8` threshold to determine absorption (-1 to precision(Float16)).
# * `additions::UInt64` number of previous additions.
# * `stagnation::UInt64` length of stagnation (number of previous absorptions).

# If performing addition where one argument is type `T` where `T <: FloatSD`, stagnation detection will be recorded.
# Access fields of `x::Float16SD` with `x.stagnation` or similar, or by calling `report(x)` for a human-readable output.
# """
# mutable struct BFloat16SD <: FloatSD
#     # floating point value
#     value::BFloat16

#     # measures for quantifying stagnation
#     u::UInt
#     const t::Int8
#     additions::UInt
#     stagnation::UInt
#     stagnation_rd::UInt

#     # copy constructor
#     BFloat16SD(x::BFloat16SD) = deepcopy(x)

#     # conversion constructor
#     BFloat16SD(x::FloatSD) = new(
#         BFloat16(x.value),
#         x.u,
#         x.t,
#         x.additions,
#         x.stagnation,
#         x.stagnation_rd
#     )

#     function BFloat16SD(x::BFloat16; threshold::Int64 = -1)
#         if threshold < -1
#             threshold = -1
#         elseif threshold > 11
#             threshold = 11
#         end
        
#         return new(
#             x,
#             UInt(0),
#             Int8(threshold),
#             UInt(0),
#             UInt(0),
#             UInt(0)
#         )
#     end

#     # convert Real to Float64 will have to be removed when alternative precisions are introduced
#     BFloat16SD(x::Real; threshold::Int64 = -1) = BFloat16SD(convert(BFloat16, x); threshold)
# end