
"""
Logs the information on stagnation via print statements to user.
"""
function report(x::FloatSD)
    if isunused(x)
        println("Argument `x::`" * typeof(x) * " is unused.")
        println("Please refer to the example test/demo.jl on performing stagnation detection.")
        return nothing
    end

    sev = ("Partial", "partial")
    if x.t == -1
        sev = ("Total", "total")
    elseif x.t == 0
        sev = ("Near-total", "near-total")
    end

    cond = "u ≤ " * string(x.t) * " in a given addition."
    if x.t == -1
        cond = "u = 0 and for the smaller addend to be rounded off completely in a given addition."
    elseif x.t == 0
        cond = "u = 0, where the smaller addend is completely shifted off in an addition."
    end

    para1_1 = "Detecting " * sev[2] * " stagnation in " * string(x.additions) * " additions."
    para1_2 = "The condition for " * sev[2] * " absorption is " * cond
    para1_3 = "Accumulator precision: " * string(precision(x)) * " (" * string(typeof(x)) * ")."
    
    para2_1 = "Net stagnation length " * string(diff_absorptions(x)) * (net_absorptions(x) < 0 ? " (round down)." : " (round up).")
    para2_2 = string(x.absorptions_dn) * " negative, " * string(x.absorptions_up) * " positive."
    para2_3 = "Overall stagnation length " * string(num_absorptions(x)) * " if ignoring cancellation of rounding directions."

    lcite = "See paper: Analysis and Detection of Stagnation in Floating-Point Summation,"
    lcite2 = "Mantas Mikaitis and William Woolfenden, 2026 (in progress)."

    para3_1 = "u is the total number of bits which were not shifted off in the addition."
    para3_2 = "Total number of bits processed u = " * string(x.u) * "." 
    para3_3 = "Average uᵢ = " * string(x.u/x.additions) * "."

    print("\n--------------- SUMMARY ----------------\n")

    println(para1_1)
    println(para1_2)
    println(para1_3)
    println()

    println(para2_1)
    println(para2_2)
    println(para2_3)

    print("\n-------- PROCESSING OF RESULTS ---------\n")

    println(para3_1)
    println(para3_2)
    println(para3_3)

    println(lcite)
    println(lcite2)

    print("\n------------ END OF SUMMARY ------------\n")

    return nothing
end

## report all

# function reportall()
#     V = varinfo() # get all the global variables
#     varnames = [var[1] for var in V.content[1].rows if any(occursin.(["Float64SD", "Float32SD", "Float16SD"], var[3]))]

#     N = names(Main)
#     varnames = [varname for varname in N if (eval(varname))]

#     scalars = [x for x in varnames if eval(Meta.parse(x)) isa Number]
#     arrays = [x for x in varnames if eval(Meta.parse(x)) isa Array]

#     for x in scalars
#         eval(Meta.parse("report("*x*")"))
#     end


# end


function reportall()
    allvars = names(Main)

    vars = [x for x in allvars if (getfield(Main, x) isa Number || getfield(Main, x) isa Array && eltype(getfield(Main, x)) != Symbol)]

    scalars = [x for x in vars if getfield(Main, x) isa FloatSD]
    arrays = [X for X in vars if getfield(Main, X) isa Array && zero(eltype(getfield(Main, X))) isa FloatSD]

    println(" ---------  SCALARS IN GLOBAL SCOPE  --------- ")

    for name in scalars
        arg = getfield(Main, name)
        stags = diff_absorptions(arg)
        adds = arg.additions
        percentage = (round(((stags/max(adds, 1)) * 100); sigdigits = 2))
        thresh = arg.t

        print(string(name) * " (" * string(typeof(arg)) * "), ")
        print("stagnation " * string(stags) * " / " * string(adds) * " additions (" * string(percentage) * "%), ")
        if thresh == -1
            print("bits threshold 0 (total)")
        elseif thresh == 0
            print("bits threshold 0 (near-total)")
        else
            print("bits threshold " * string(thresh) * " (partial)")            
        end
        print("\n")
    end

    println()
    println(" ----------- ARRAYS IN GLOBAL SCOPE  --------- ")

    for name in arrays
        A = getfield(Main, name)

        stags = diff_absorptions.(A)
        adds = getfield.(A, :additions)
        percentage = (round.((stags ./ max.(1, adds)) * 100, sigdigits = 2))
        minpercent = minimum(percentage)
        maxpercent = maximum(percentage)
        avg = round(sum(percentage) / (size(percentage)[1] * size(percentage)[2]), sigdigits = 2)

        print(string(name) * " (" * string(typeof(A)) * ", " * string(size(A)[1]) * "×" * string(size(A)[2]) * "), ")
        print("stagnation range " * string(minpercent) * "% to " * string(maxpercent) * "%, mean " * string(avg) * "%")
        print("\n")
    end

    println()
    println(" -------------- END OF REPORTALL  ------------ ")

    return nothing
end


function isunused(x::FloatSD)
    return num_additions(x) == x.u == num_absorptions(x) == 0
end


## diagnostic functions 

"""
`num_additions(x::FloatSD)`

Given an accumulator, returns the number of additions observed. 
"""
num_additions(x::FloatSD) = x.additions

"""
`num_absorptions(x::FloatSD)`

Given an accumulator, returns the number of absorptions or equivalently the "stagnation".
"""
num_absorptions(x::FloatSD) = x.absorptions_dn + x.absorptions_up

"""
`net_absorptions(x::FloatSD)`

Given an accumulator, returns the overall number of absorptions not cancelled out, with regard to sign.
Two absorptions in opposite direction are considered to cancel out and are ignored.

For example, if the total count of absorptions is `15`, with `5` rounding up and `10` rounding down, `net_absorptions` will return `5 - 10 = -5`.
If instead `10` absorptions round up and `5` round down, `net_absorptions` will return `10 - 5 = 5`.
"""
function net_absorptions(x::FloatSD)
   absorptions_down::UInt = x.absorptions_dn
   absorptions_up::UInt = x.absorptions_up
   sign_absorption::Int = absorptions_down > absorptions_up ? -1 : 1

   difference = diff2(absorptions_up, absorptions_down)

   return difference <= typemax(Int) ? sign_absorption * Int(difference) : sign_absorption * Int128(difference)
end

diff2(a::UInt, b::UInt) = ifelse(b > a, b - a, a - b)

"""
`diff_absorptions(x::FloatSD)`

Given an accumulator, returns the overall number of absorptions not cancelled out.
Does not return sign to indicate rounding direction.

For example, if the total count of absorptions is `15`, with `5` rounding up and `10` rounding down, `diff_absorptions` will return `abs(5 - 10) = 5`.
"""
function diff_absorptions(x::FloatSD)
    absorptions_down::UInt = x.absorptions_dn
    absorptions_up::UInt = x.absorptions_up

    difference::UInt = diff2(absorptions_up, absorptions_down)

    return difference
end


import Base: show
# want printing of any Float64SD to print the Float64 equivalent

show(io::IO, x::FloatSD) = show(io, x.value)

function show(io::IO, ::MIME"text/plain", x::FloatSD)
    if get(io, :typeinfo, Any) === FloatSD
        print(io, x.value)
    else
        show(io, x.value)
    end
end