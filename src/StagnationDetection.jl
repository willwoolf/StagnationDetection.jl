module StagnationDetection


include("FloatSD.jl")
include("linearalgebra.jl")
include("sdadd.jl")
include("math.jl")
include("operations.jl")
include("promotion.jl")
include("random.jl")
include("report.jl")

export FloatSD, Float64SD, Float32SD, Float16SD
export lrsum, lrdot, lrmatmul, lrlu, lrblu
export bitexponent
export sin, cos, sinpi, cospi, tan, sinh, cosh, tanh, exp, log, sqrt, abs, abs2, acos, asin, atan, hypot, rem, one, oneunit, zero, issubnormal, isfinite, isinf, isnan, iszero, isone, nextfloat, prevfloat, isinteger, isreal, isodd, iseven, precision
export +, -, *, /, muladd, <, <=, >, >=, ==
export promote_rule, convert, round
export rand, randn
export report, reportall, isunused, num_additions, num_absorptions, net_absorptions, diff_absorptions, show

end