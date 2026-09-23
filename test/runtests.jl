using StagnationDetection
using Test

include("sumfuncs.jl")
export harm, iharm, randsum, rand2um, pisum

const _MINNORMAL_FLOAT64 = reinterpret(Float64, 0x0010_0000_0000_0000)
const _MINNORMAL_FLOAT32 = reinterpret(Float32, 0x0080_0000)
const _MINNORMAL_FLOAT16 = reinterpret(Float16, 0x0400)

import LinearAlgebra: dot, lu
import Random: Xoshiro



@testset "StagnationDetection.jl" begin

    # space filler
    @testset "Existence of methods" begin
        @test isdefined(Main, :StagnationDetection)
        @test StagnationDetection.:(+) == Base.:(+)
        @test StagnationDetection.:(-) == Base.:(-)
        @test StagnationDetection.:(*) == Base.:(*)
        @test StagnationDetection.:(\) == Base.:(\)
        @test !isempty([x for x in methods(+) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(-) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(*) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(/) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(==) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(<=) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(>=) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(<) if x.module == StagnationDetection])
        @test !isempty([x for x in methods(>) if x.module == StagnationDetection])
    end

    ## operations with stagnation detection

    @testset "Addition and Subtraction" begin
        s::Float64SD = 1.0
        a::Float64 = 2.0
        d::Int32 = 5
        X::Vector{Float64SD} = [2.0, 3.0, 4.0]
        Y::Vector{Int32} = [2, 3, 4]

        ## note that comparisons are to Float64s but types are Float64SDs
        @test s + a == 3.0
        @test typeof(s + a) == Float64SD

        @test a + s == 3.0
        @test typeof(a + s) == Float64SD

        @test s + d == 6.0
        @test typeof(s + d) == Float64SD

        @test d + s == 6.0
        @test typeof(d + s) == Float64SD

        @test +s == s
        @test typeof(+s) == typeof(s)

        @test +X == X
        @test typeof(+X) == typeof(X)

        @test X .+ d == [7, 8, 9]
        @test typeof(X .+ d) == Vector{Float64SD}

        @test d .+ X == [7, 8, 9]
        @test typeof(d .+ X) == Vector{Float64SD}

        @test s .+ Y == [3, 4, 5]
        @test typeof(s .+ Y) == Vector{Float64SD}

        @test Y .+ s == [3, 4, 5]
        @test typeof(Y .+ s) == Vector{Float64SD}

        @test X .+ d == d .+ X
        @test s .+ Y == Y .+ s

        @test -s == -1.0
        @test typeof(-s) == Float64SD

        @test s - a == s + (-a)
        @test typeof(s - a) == typeof(s + (-a)) == Float64SD

        @test a - s == a + (-s)
        @test typeof(a - s) == typeof(a + (-s)) == Float64SD

        @test d - s == d + (-s)
        @test typeof(d - s) == typeof(d + (-s)) == Float64SD

        @test s - d == s + (-d)
        @test typeof(s - d) == typeof(s + (-d)) == Float64SD

        @test -X == [-2, -3, -4]
        @test typeof(-X) == Vector{Float64SD}

        @test d .- X == d .+ (-X)
        @test typeof(d .- X) == Vector{Float64SD}

        @test X .- d == X .+ (-d)
        @test typeof(X .- d) == Vector{Float64SD}

        @test s - a == -(a - s)
        @test s - d == -(d - s)
        @test X .- d == -(d .- X)
    end

    @testset "Multiplication and Division" begin
        s::Float64SD = 1.0
        a::Float64 = 2.0
        d::Int32 = 5
        X::Vector{Float64SD} = [2.0, 3.0, 4.0]
        Y::Vector{Int32} = [2, 3, 4]

        @test s * a == 2.0
        @test typeof(s * a) == Float64SD

        @test a * s == 2.0
        @test typeof(a * s) == Float64SD

        @test s * d == 5.0
        @test typeof(s * d) == Float64SD

        @test d * s == 5.0
        @test typeof(d * s) == Float64SD

        @test X .* d == [10, 15, 20]
        @test typeof(X .* d) == Vector{Float64SD}

        @test d .* X == [10, 15, 20]
        @test typeof(d .* X) == Vector{Float64SD}

        @test s .* Y == [2, 3, 4]
        @test typeof(s .* Y) == Vector{Float64SD}

        @test Y .* s == [2, 3, 4]
        @test typeof(Y .+ s) == Vector{Float64SD}

        @test X .* d == d .* X
        @test s .* Y == Y .* s

        @test 1/s == 1.0
        @test typeof(1/s) == Float64SD # will this fail?

        @test s / a == 1 / (a / s)
        @test typeof(s / a) == typeof(1 / (a / s)) == Float64SD

        @test a / s == 1 / (s / a)
        @test typeof(a / s) == typeof(1 / (s / a)) == Float64SD

        @test d / s == 1 / (s / d)
        @test typeof(d / s) == typeof(1 / (s / d)) == Float64SD

        @test s / d == 1 / (d / s)
        @test typeof(s / d) == typeof(1 / (d / s)) == Float64SD

        @test 1 ./ X == [1/2, 1/3, 1/4]
        @test typeof(1 ./ X) == Vector{Float64SD}

        @test d ./ X == 1 ./ (X ./ d)
        @test typeof(d ./ X) == Vector{Float64SD}

        @test X ./ d == 1 ./ (d ./ X)
        @test typeof(X ./ d) == Vector{Float64SD}
    end


    ## correct counting of operations

    @testset "Operation counting" begin
        @testset "Scalar addition" begin
            s::Float64SD = 0.0

            a1 = s + 1.0
            a2 = s + Int64(1)
            a3 = 1 + s

            @test a1.additions == 1
            @test a2.additions == 1
            @test a3.additions == 1

            t::Float64SD = s + 1 + 2 + 3
            
            @test t.additions == 3

            a4 = s + t
            a5 = t + s

            # @test a4.additions == 1
            @test a5.additions == 4

            u = +(s, 1.0, 2.0)

            @test u.additions == 2

            lens = [2, 3, 4, 5]
            v::Float64SD = 1.0

            for n in lens
                vn = v
                for k in 2:n
                    vn += k
                end
                @test vn == sum(1:n)
                @test vn.additions == n - 1
            end
        end

        @testset "Array addition" begin
            # adding scalar to float64sd Array
            # adding float64sd scalar to Array
            # adding arrays of mixed types
            # adding matrices
            # matrix multiplication

                a::Float64 = 2.0
                X::Vector{Float64SD} = [1.0, 2.0, 3.0, 4.0]

                s::Float64SD = 4.0
                Y::Vector{Float64} = [4.0, 3.0, 2.0, 1.0]

                Xr = X .+ a
                Yr = Y .+ s
            for i in 1:4
                @test Xr[i].additions == 1
                @test Yr[i].additions == 1
            end

                Xl = a .+ X
                Yl = s .+ Y
            for i in 1:4
                @test Xl[i].additions == 1
                @test Yl[i].additions == 1
            end

                Zr = X + Y
                Zl = Y + X
            for i in 1:4
                @test Zr[i].additions == 1
                @test Zl[i].additions == 1
            end
        end

        @testset "Matrix multiplication" begin

            # matrix multiplication
            ## for dimensions 2:5, produce square matrices, perform multiplication, count additions in each element
            # matrices copied

            A2::Matrix{Float64} = [3 1; 2 4]
            A3::Matrix{Float64} = [8 5 1; 3 7 4; 6 2 9]
            A4::Matrix{Float64} = [15 14 9 1; 6 14 11 8; 7 12 13 3; 2 10 5 16]
            A5::Matrix{Float64} = [24 14 10 19 11; 4 22 5 15 1; 20 7 23 8 17; 2 16 6 21 3; 12 18 9 13 25] 

            S2::Matrix{Float64SD} = A2
            S3::Matrix{Float64SD} = A3
            S4::Matrix{Float64SD} = A4
            S5::Matrix{Float64SD} = A5

            PL2 = A2 * S2
            PL3 = A3 * S3
            PL4 = A4 * S4
            PL5 = A5 * S5

            PR2 = S2 * A2
            PR3 = S3 * A3
            PR4 = S4 * A4
            PR5 = S5 * A5

            P2 = S2 * S2
            P3 = S3 * S3
            P4 = S4 * S4
            P5 = S5 * S5

            lefts = (PL2, PL3, PL4, PL5)
            rights = (PR2, PR3, PR4, PR5)
            directs = (P2, P3, P4, P5)

            #the following checks that additions in matrix multiplications are counted correctly

            ## number of additions in matrix multiplication. see definition of LinearAlgebra: _generic_matmatmul_generic!

            for n in 1:4
                expectedadds = true
                num_adds = n + 1
                ## this is not fun, check version to see how entries are counted.
                # TODO: compatibility with operation counting in Julia 1.10
                # current solution is to not be compatible with Julia 1.10
                if VERSION.minor == 10
                    ## TODO: fix
                else
                    
                end

                for entry in lefts[n]
                    expectedadds = (expectedadds && (entry.additions == num_adds))
                end
                @test expectedadds
            end
        end

        @testset "Matrix LU factorisation" begin
            rng = Xoshiro(1)
            A::Matrix{Float64} = rand(Float64, 3, 3)
            # A::Matrix{Float64} = [
            #     0.1 0.5 0.9;
            #     0.5 0.9 0.1;
            #     0.9 0.1 0.5
            # ]

            A64::Matrix{Float64SD} = A
            A32::Matrix{Float32SD} = A
            A16::Matrix{Float16SD} = A

            (L64, U64) = lu(A64)
            (L32, U32) = lu(A32)
            (L16, U16) = lu(A16)

            # row i of the U matrix has undergone i-1 additions

            for i in 1:size(A)[1]
                @test all(getfield.(U64[i, i:end], :additions) .== i-1)
                @test all(getfield.(U32[i, i:end], :additions) .== i-1)
                @test all(getfield.(U16[i, i:end], :additions) .== i-1)
                # test modified to test the upper triangular part of the matrix
            end
        end
    end

    @testset "LR algorithms" begin
        @testset "lrsum" begin
            rng = Xoshiro(1)

            for d in [100, 1000, 1_000_000, 8_000_000]
                X = rand(rng, d)
                @test lrsum(X) == foldl(+, X)
            end
        end

        @testset "lrdot" begin
            rng = Xoshiro(1)

            for d in [100, 1000, 1_000_000, 8_000_000]
                X = rand(rng, d)
                Y = rand(rng, d)
                Z = lrdot(X, Y)
                @test Z == foldl(+, X .* Y)
                @test Z ≈ dot(X, Y)
            end
        end

        @testset "lrmatmul" begin
            rng = Xoshiro(1)

            m = 2
            for d in [100, 1000, 1_000_000, 8_000_000]
                A = rand(rng, m, d) 
                B = rand(rng, d, m)
                C = lrmatmul(A, B)

                for i in axes(C, 1), j in axes(C, 2)
                    @test C[i, j] ≈ foldl(+, A[i, :] .* B[:, j])
                end
                @test C ≈ A * B
            end
        end

        @testset "lrblu" begin
            rng = Xoshiro(1)

            A = rand(100, 100)
            decomp = lu(A)
            for b in [1, 10, 20, 30, 50]
                Fb, pb = lrblu(A, b)
                @test pb == decomp.p
            end
        end
    end

    ## correct measurement of bits (important!!)
    @testset "Stagnation measurement" begin
        @testset "64-bit double precision" begin
            @testset "Normals" begin
                for ΔE in 0:100 # covers the precision 53 but doesn't reach subnormals at 1022
                    a::Float64SD = 1.0
                    b::Float64 = 2.0^-ΔE
                    c::Float64SD = a + b
                    if ΔE > precision(Float64)
                        @test c.u == 0 != precision(Float64) - ΔE    
                    else
                        @test c.u == precision(Float64) - ΔE             
                    end
                end
            end

            @testset "Normals + subnormals" begin
                a::Float64SD = _MINNORMAL_FLOAT64
                for ΔE in 2:precision(Float64)
                    b::Float64 = _MINNORMAL_FLOAT64 * 2.0^-(ΔE-1) # the 1 is in position ΔE of the significand of b
                    c::Float64SD = a + b
                    @test c.u == precision(Float64) # there should be no shifting taking place. one test in loop fails
                end
                # extend this?
            end

            @testset "Subnormals" begin
                for lead in 1:precision(Float64) - 1
                    a::Float64SD = _MINNORMAL_FLOAT64 * 2.0^(-lead)
                    for lesser in lead:precision(Float64) - 1
                        b::Float64 = _MINNORMAL_FLOAT64 * 2.0^(-lesser)
                        c::Float64SD = a + b
                        @test c.u == precision(Float64)
                    end
                end
            end
        end

        @testset "32-bit single precision" begin
            @testset "Normals" begin
                for ΔE in 0:50 # covers the precision 24 but doesn't reach subnormals at 128
                    a::Float32SD = 1.0f0
                    b::Float32 = 2.0f0^-ΔE
                    c::Float32SD = a + b
                    if ΔE > precision(Float32)
                        @test c.u == 0 != precision(Float32) - ΔE    
                    else
                        @test c.u == precision(Float32) - ΔE             
                    end
                end
            end

            @testset "Normals + subnormals" begin
                a::Float32SD = _MINNORMAL_FLOAT32
                for ΔE in 2:precision(Float32)
                    b::Float32 = _MINNORMAL_FLOAT32 * 2.0f0^-(ΔE-1)
                    c::Float32SD = a + b
                    @test c.u == precision(Float32)
                end
                # extend this?
            end

            @testset "Subnormals" begin
                for lead in 1:precision(Float32) - 1
                    a::Float32SD = _MINNORMAL_FLOAT32 * 2.0f0^(-lead)
                    for lesser in lead:precision(Float32) - 1
                        b::Float32 = _MINNORMAL_FLOAT32 * 2.0f0^(-lesser)
                        c::Float32SD = a + b
                        @test c.u == precision(Float32)
                    end
                end
            end
        end

        @testset "16-bit half precision" begin
            @testset "Normals" begin
                for ΔE in 0:20 # covers the precision 11 but doesn't reach subnormals at 128
                    a::Float16SD = Float16(1.0)
                    b::Float16 = Float16(2.0)^-ΔE
                    c::Float16SD = a + b
                    if ΔE > precision(Float16)
                        @test c.u == 0 != precision(Float16) - ΔE    
                    else
                        @test c.u == precision(Float16) - ΔE             
                    end
                end
            end

            @testset "Normals + subnormals" begin
                a::Float16SD = _MINNORMAL_FLOAT16
                for ΔE in 2:precision(Float16)
                    b::Float16 = _MINNORMAL_FLOAT16 * Float16(2.0)^-(ΔE-1)
                    c::Float16SD = a + b
                    @test c.u == precision(Float16)
                end
                # extend this?
            end

            @testset "Subnormals" begin
                for lead in 1:precision(Float16) - 1
                    a::Float16SD = _MINNORMAL_FLOAT16 * Float16(2.0)^(-lead)
                    for lesser in lead:precision(Float16) - 1
                        b::Float16 = _MINNORMAL_FLOAT16 * Float16(2.0)^(-lesser)
                        c::Float16SD = a + b
                        @test c.u == precision(Float16)
                    end
                end
            end
            
        end


    end


    # when multiplying FloatSDs, multiplying a FloatSD by anything, data should reset

    # likewise with division

    X1::Vector{Float64SD} = [x^(-4) for x in 1:1]
    X10::Vector{Float64SD} = [x^(-4) for x in 1:10]
    X100::Vector{Float64SD} = [x^(-4) for x in 1:100]

    S1 = foldl(+, X1)
    S10 = foldl(+, X10)
    S100 = foldl(+, X100)

    scalings = Vector{Union{Float64, Int}}()
    push!(scalings, Float64(5.2))      # floating-point non-identity multiplication
    push!(scalings, Int(5))            # integer non-identity multiplication
    push!(scalings, Float64(1.0))      # floating-point identity multiplication
    push!(scalings, Int(1))            # integer identity multiplication (does this fail?)

    sums = [S1, S10, S100]

    @testset "Stagnation acted on by multiply or divide" begin
        @test getfield(S1, :additions) == lastindex(X1) - 1
        @test getfield(S10, :additions) == lastindex(X10) - 1
        @test getfield(S100, :additions) == lastindex(X100) - 1

        @testset "Operations reset stagnation data" for c in scalings
            for S in sums
                # @test isunused(c * S) 
                # @test isunused(S * c) 
                # @test isunused(S / c) 
                # @test isunused(c / S) 
            end
        end
    end


    @testset "Type promotions for FloatSD behave as expected for subtypes of AbstractFloat" begin
        CORE_TYPES = [Float64, Float32, Float16, Int64, Int32, Int16, UInt64, UInt32, UInt16]
        REAL_TYPES = [Float64, Float32, Float16]

        for ctype in CORE_TYPES
            for rtype in REAL_TYPES
                stype = FloatSD(rtype)
                # test that promote_rule(Float64SD, Float32) == FloatSD(promote_rule(Float64, Float32)) and similar
                # modified: promote_type is a commutative extension of promote_rule
                @test promote_type(stype, ctype) == FloatSD(promote_type(rtype, ctype))
            end
        end
    end


    ## summation functions such as harmonic series. testing that results are consistent when run with and without stagnation
    N::Vector{Int} = [-100, -1, 0, 1, 2, 5, 10, 100, 1000000]
    F::Vector{Function} = [harm, iharm, pisum]
    randF::Vector{Function} = [randsum, rand2um]

    @testset "Results for various functions are unchanged when run with stagnation detection" begin
        for n in N
            for f in F
                for T in [Float64, Float32, Float16]
                    if n < 0
                        @test_throws AssertionError f(n, FloatSD(T))
                        @test_throws AssertionError f(n, T)
                    else
                        s = f(n, FloatSD(T))
                        x = f(n, T)
                        
                        @test s == x
                        @test s isa FloatSD(T)
                        @test x isa T
                    end
                end
            end
            for f in randF
                # seed = UInt(1)
                for T in [Float64, Float32, Float16]
                    if n < 0
                        @test_throws AssertionError f(Xoshiro(1), n, FloatSD(T))
                        @test_throws AssertionError f(Xoshiro(), n, T)
                    else
                        s = f(Xoshiro(1), n, FloatSD(T))
                        x = f(Xoshiro(1), n, T)
                        
                        @test s == x
                        @test s isa FloatSD(T)
                        @test x isa T
                    end
                end
            end
        end
    end

    @testset "Output of matrix multiplication is unchanged when run with stagnation detection" begin
        A2::Matrix{Float64} = [3 1; 2 4]
        A3::Matrix{Float64} = [8 5 1; 3 7 4; 6 2 9]
        A4::Matrix{Float64} = [15 14 9 1; 6 14 11 8; 7 12 13 3; 2 10 5 16]
        A5::Matrix{Float64} = [24 14 10 19 11; 4 22 5 15 1; 20 7 23 8 17; 2 16 6 21 3; 12 18 9 13 25] 

        S2::Matrix{Float64SD} = A2
        S3::Matrix{Float64SD} = A3
        S4::Matrix{Float64SD} = A4
        S5::Matrix{Float64SD} = A5

        PL2 = A2 * S2
        PL3 = A3 * S3
        PL4 = A4 * S4
        PL5 = A5 * S5

        PR2 = S2 * A2
        PR3 = S3 * A3
        PR4 = S4 * A4
        PR5 = S5 * A5

        P2 = S2 * S2
        P3 = S3 * S3
        P4 = S4 * S4
        P5 = S5 * S5

        T2 = A2 * A2
        T3 = A3 * A3
        T4 = A4 * A4
        T5 = A5 * A5

        @test P2 == PR2 == PL2 == T2
        @test P3 == PR3 == PL3 == T3
        @test P4 == PR4 == PL4 == T4
        @test P5 == PR5 == PL5 == T5
    end


    # harmonic series as an example. when stagnation starts, value should be the same as when computed without stagnation
    # two floatSDs should equate when their values are the same but fields do not need to match

    sd_harm_a = harm(100, Float32SD)          # not reached stagnation
    sd_harm_b = harm(3000000, Float32SD)      # reached stagnation
    sd_harm_c = harm(4000000, Float32SD)      # reached stagnation

    @testset "Equality of FloatSD types with mismatched fields" begin
        @test sd_harm_a.u          != sd_harm_b.u          == sd_harm_c.u
        @test sd_harm_a.additions  != sd_harm_b.additions  != sd_harm_c.additions
        @test num_absorptions(sd_harm_a) != num_absorptions(sd_harm_b) != num_absorptions(sd_harm_c)

        @test sd_harm_a != sd_harm_b && sd_harm_a.value != sd_harm_b.value
        @test sd_harm_a != sd_harm_c && sd_harm_a.value != sd_harm_c.value
        @test sd_harm_b == sd_harm_c && sd_harm_b.value == sd_harm_c.value
    end


    ## same sum, different thresholds leads to different measures of stagnation
    @testset "Custom thresholds in Float32SD" begin
        s1 = Float32SD(0, threshold = 10)
        s2 = Float32SD(0, threshold = 0)
        s3 = Float32SD(0) # default threshold is -1 for total stagnation

        @test s1.t == 10
        @test s2.t == 0
        @test s3.t == -1

        for k in 1:3000000
            x = 1.0f0/k

            s1 += x
            s2 += x
            s3 += x
        end

        @test s1.additions == s2.additions == s3.additions
        @test num_absorptions(s1) > num_absorptions(s2) > num_absorptions(s3)
        @test s1.u == s2.u == s3.u
    end



    ## difficult operations

    T = [Float64, Float32, Float16]

    @testset "Defined operations with zero, inf, NaN" begin
        for type in T
            FloatSDType = FloatSD(type)

            x = FloatSDType(1.0)
            y = FloatSDType(2.0)

            @test typeof(x) == FloatSDType
            @test x + y == type(3.0)
            
            #put a test here on inexactly represented floats.
            # previously tried 0.1 + 0.2 != 0.3 but this only works in Float64

            @test +x == x
            @test -x == type(0) - x
            @test x - y == -(y - x)

            @test x * y == type(2.0)
            @test FloatSDType(prevfloat(typemax(type))) < type(Inf)
            @test FloatSDType(prevfloat(typemax(type))) * 2 == type(Inf)

            @test FloatSDType(6.0) / FloatSDType(3.0) == type(2.0)
            @test FloatSDType(1.0) / FloatSDType(0.0) == type(Inf)
            @test FloatSDType(-1.0) / FloatSDType(0.0) == type(-Inf)
            @test isnan(FloatSDType(0.0) / FloatSDType(0.0))

                pluszero = FloatSDType(0.0)
                negzero = FloatSDType(-0.0)

            @test pluszero == negzero
            @test 1 / pluszero == type(Inf)
            @test 1 / negzero == type(-Inf)

                sdnan = FloatSDType(type(NaN))

            @test isnan(sdnan)
            @test sdnan != sdnan
            @test !(sdnan < type(1.0))
            @test !(sdnan > type(1.0))
            @test !(sdnan == type(1.0))

                plusinf = FloatSDType(type(Inf))
                neginf = FloatSDType(type(-Inf))

            @test isinf(plusinf)
            @test isinf(neginf)
        end
    end


    # lots of good stuff to copy over such as all the multiple precision linear algebra


    @testset "Correct promotions for multiple precision operations" begin
        @testset "Addition" begin
            s64 = Float64SD(1.0)
            s32 = Float32SD(1.0)
            s16 = Float16SD(1.0)

            f64::Float64 = 1.0
            f32::Float32 = 1.0
            f16::Float16 = 1.0

            @test typeof(s64 + f64) == Float64SD
            @test typeof(s64 + f32) == Float64SD
            @test typeof(s64 + f16) == Float64SD
            
            @test typeof(s32 + f64) == Float64SD
            @test typeof(s32 + f32) == Float32SD
            @test typeof(s32 + f16) == Float32SD

            @test typeof(s16 + f64) == Float64SD
            @test typeof(s16 + f32) == Float32SD
            @test typeof(s16 + f16) == Float16SD
        end


        @testset "Matrix multiplication" begin
            A_64 = [sqrt(2) 0 1/10; 1/10 sqrt(2) 0; 0 1/10 sqrt(2)]
            A_32::Matrix{Float32} = convert.(Float32, A_64)
            A_16::Matrix{Float16} = convert.(Float16, A_64)

            A_64SD::Matrix{Float64SD} = A_64
            A_32SD::Matrix{Float32SD} = A_32
            A_16SD::Matrix{Float16SD} = A_16

            @test typeof(A_64SD * A_64SD) == Matrix{Float64SD}
            @test typeof(A_64SD * A_32SD) == Matrix{Float64SD}
            @test typeof(A_64SD * A_16SD) == Matrix{Float64SD}

            @test typeof(A_32SD * A_64SD) == Matrix{Float64SD}
            @test typeof(A_32SD * A_32SD) == Matrix{Float32SD}
            @test typeof(A_32SD * A_16SD) == Matrix{Float32SD}

            @test typeof(A_16SD * A_64SD) == Matrix{Float64SD}
            @test typeof(A_16SD * A_32SD) == Matrix{Float32SD}
            @test typeof(A_16SD * A_16SD) == Matrix{Float16SD}

            @test typeof(A_64 * A_64SD) == Matrix{Float64SD}
            @test typeof(A_64 * A_32SD) == Matrix{Float64SD}
            @test typeof(A_64 * A_16SD) == Matrix{Float64SD}

            @test typeof(A_32 * A_64SD) == Matrix{Float64SD}
            @test typeof(A_32 * A_32SD) == Matrix{Float32SD}
            @test typeof(A_32 * A_16SD) == Matrix{Float32SD}

            @test typeof(A_16 * A_64SD) == Matrix{Float64SD}
            @test typeof(A_16 * A_32SD) == Matrix{Float32SD}
            @test typeof(A_16 * A_16SD) == Matrix{Float16SD}

            @test typeof(A_64SD * A_64) == Matrix{Float64SD}
            @test typeof(A_64SD * A_32) == Matrix{Float64SD}
            @test typeof(A_64SD * A_16) == Matrix{Float64SD}

            @test typeof(A_32SD * A_64) == Matrix{Float64SD}
            @test typeof(A_32SD * A_32) == Matrix{Float32SD}
            @test typeof(A_32SD * A_16) == Matrix{Float32SD}

            @test typeof(A_16SD * A_64) == Matrix{Float64SD}
            @test typeof(A_16SD * A_32) == Matrix{Float32SD}
            @test typeof(A_16SD * A_16) == Matrix{Float16SD}
        end


        @testset "Matrix-vector multiplication" begin
            A_64 = [sqrt(2) 0 1/10; 1/10 sqrt(2) 0; 0 1/10 sqrt(2)]
            A_32::Matrix{Float32} = convert.(Float32, A_64)
            A_16::Matrix{Float16} = convert.(Float16, A_64)

            A_64SD::Matrix{Float64SD} = A_64
            A_32SD::Matrix{Float32SD} = A_32
            A_16SD::Matrix{Float16SD} = A_16

            x_64 = [1.0, 2.0, 3.0]
            x_32::Vector{Float32} = convert.(Float32, x_64)
            x_16::Vector{Float16} = convert.(Float16, x_64)

            x_64SD::Vector{Float64SD} = x_64
            x_32SD::Vector{Float32SD} = x_32
            x_16SD::Vector{Float16SD} = x_16

            @test typeof(A_64SD * x_64SD) == Vector{Float64SD}
            @test typeof(A_64SD * x_32SD) == Vector{Float64SD}
            @test typeof(A_64SD * x_16SD) == Vector{Float64SD}

            @test typeof(A_32SD * x_64SD) == Vector{Float64SD}
            @test typeof(A_32SD * x_32SD) == Vector{Float32SD}
            @test typeof(A_32SD * x_16SD) == Vector{Float32SD}

            @test typeof(A_16SD * x_64SD) == Vector{Float64SD}
            @test typeof(A_16SD * x_32SD) == Vector{Float32SD}
            @test typeof(A_16SD * x_16SD) == Vector{Float16SD}

            @test typeof(A_64 * x_64SD) == Vector{Float64SD}
            @test typeof(A_64 * x_32SD) == Vector{Float64SD}
            @test typeof(A_64 * x_16SD) == Vector{Float64SD}

            @test typeof(A_32 * x_64SD) == Vector{Float64SD}
            @test typeof(A_32 * x_32SD) == Vector{Float32SD}
            @test typeof(A_32 * x_16SD) == Vector{Float32SD}

            @test typeof(A_16 * x_64SD) == Vector{Float64SD}
            @test typeof(A_16 * x_32SD) == Vector{Float32SD}
            @test typeof(A_16 * x_16SD) == Vector{Float16SD}

            @test typeof(A_64SD * x_64) == Vector{Float64SD}
            @test typeof(A_64SD * x_32) == Vector{Float64SD}
            @test typeof(A_64SD * x_16) == Vector{Float64SD}

            @test typeof(A_32SD * x_64) == Vector{Float64SD}
            @test typeof(A_32SD * x_32) == Vector{Float32SD}
            @test typeof(A_32SD * x_16) == Vector{Float32SD}

            @test typeof(A_16SD * x_64) == Vector{Float64SD}
            @test typeof(A_16SD * x_32) == Vector{Float32SD}
            @test typeof(A_16SD * x_16) == Vector{Float16SD}
        end


        @testset "Vector inner product" begin
            x_64 = [1.0, 2.0, 3.0]
            x_32::Vector{Float32} = x_64
            x_16::Vector{Float16} = x_64

            x_64SD::Vector{Float64SD} = x_64
            x_32SD::Vector{Float32SD} = x_32
            x_16SD::Vector{Float16SD} = x_16

            @test typeof(dot(x_64SD, x_64SD)) == Float64SD
            @test typeof(dot(x_64SD, x_32SD)) == Float64SD
            @test typeof(dot(x_64SD, x_16SD)) == Float64SD

            @test typeof(dot(x_32SD, x_64SD)) == Float64SD
            @test typeof(dot(x_32SD, x_32SD)) == Float32SD
            @test typeof(dot(x_32SD, x_16SD)) == Float32SD

            @test typeof(dot(x_16SD, x_64SD)) == Float64SD
            @test typeof(dot(x_16SD, x_32SD)) == Float32SD
            @test typeof(dot(x_16SD, x_16SD)) == Float16SD

            @test typeof(dot(x_64, x_64SD)) == Float64SD
            @test typeof(dot(x_64, x_32SD)) == Float64SD
            @test typeof(dot(x_64, x_16SD)) == Float64SD

            @test typeof(dot(x_32, x_64SD)) == Float64SD
            @test typeof(dot(x_32, x_32SD)) == Float32SD
            @test typeof(dot(x_32, x_16SD)) == Float32SD

            @test typeof(dot(x_16, x_64SD)) == Float64SD
            @test typeof(dot(x_16, x_32SD)) == Float32SD
            @test typeof(dot(x_16, x_16SD)) == Float16SD

            @test typeof(dot(x_64SD, x_64)) == Float64SD
            @test typeof(dot(x_64SD, x_32)) == Float64SD
            @test typeof(dot(x_64SD, x_16)) == Float64SD

            @test typeof(dot(x_32SD, x_64)) == Float64SD
            @test typeof(dot(x_32SD, x_32)) == Float32SD
            @test typeof(dot(x_32SD, x_16)) == Float32SD

            @test typeof(dot(x_16SD, x_64)) == Float64SD
            @test typeof(dot(x_16SD, x_32)) == Float32SD
            @test typeof(dot(x_16SD, x_16)) == Float16SD
        end

        @testset "Matrix-vector solve with stagnation detection" begin
            A::Matrix{Float64} = [
                0.75     0.000018 14.44444;
                0.000018 14.44444 0.75;
                14.44444 0.75     0.000018
            ]

            A64::Matrix{Float64SD} = convert.(Float64SD, A)
            A32::Matrix{Float32SD} = convert.(Float32SD, A)
            A16::Matrix{Float16SD} = convert.(Float16SD, A)

            v::Vector{Float64} = [1, 1, 1]

            v64::Vector{Float64SD} = convert.(Float64SD, v)
            v32::Vector{Float32SD} = convert.(Float32SD, v)
            v16::Vector{Float16SD} = convert.(Float16SD, v)

            x6464 = A64 \ v64
            x3264 = A32 \ v64
            x1664 = A16 \ v64
            
            x6432 = A64 \ v32
            x3232 = A32 \ v32
            x1632 = A16 \ v32

            x6416 = A64 \ v16
            x3216 = A32 \ v16
            x1616 = A16 \ v16

            @test typeof(x6464) == Vector{Float64SD}
            @test typeof(x6432) == Vector{Float64SD}
            @test typeof(x6416) == Vector{Float64SD}

            @test typeof(x3264) == Vector{Float64SD}
            @test typeof(x3232) == Vector{Float32SD}
            @test typeof(x3216) == Vector{Float32SD}

            @test typeof(x1664) == Vector{Float64SD}
            @test typeof(x1632) == Vector{Float32SD}
            @test typeof(x1616) == Vector{Float16SD}
        end
    end


    ## summation tests. verifying the MATLAB results from the paper, ported into Julia

    @testset "Summation with stagnation detection" begin
        N1::Int64 = 10000
        N2::Int64 = 20000
        N3::Int64 = 40000

        s_harm_n1 = harm(N1, Float64SD)
        s_harm_n2 = harm(N2, Float64SD)      
        s_harm_n3 = harm(N3, Float64SD)
        
        u1 = s_harm_n1.u/s_harm_n1.additions
        u2 = s_harm_n2.u/s_harm_n2.additions
        u3 = s_harm_n3.u/s_harm_n3.additions

        @test u3 < u2
        @test u2 < u1

        s_iharm_n1 = iharm(N1, Float64SD)
        s_iharm_n2 = iharm(N2, Float64SD)
        s_iharm_n3 = iharm(N3, Float64SD)

        u4 = s_iharm_n1.u/s_iharm_n1.additions
        u5 = s_iharm_n2.u/s_iharm_n2.additions
        u6 = s_iharm_n3.u/s_iharm_n3.additions

        @test u6 < u5
        @test u5 < u4

        s_rand1 = randsum(N1, Float64SD)  
        s_rand2 = randsum(N2, Float64SD)   
        s_rand3 = randsum(N3, Float64SD)
        
        ur1 = s_rand1.u/s_rand1.additions
        ur2 = s_rand2.u/s_rand2.additions
        ur3 = s_rand3.u/s_rand3.additions

        @test ur3 < ur2
        @test ur2 < ur1

        s_rand4 = rand2um(N1, Float64SD)
        s_rand5 = rand2um(N2, Float64SD)
        s_rand6 = rand2um(N3, Float64SD)
        
        ur4 = s_rand4.u/s_rand4.additions
        ur5 = s_rand5.u/s_rand5.additions
        ur6 = s_rand6.u/s_rand6.additions

        # these are NaN sometimes
        # @test abs(ur4 - ur5) < 0.1
        # @test abs(ur6 - ur5) < 0.1

        s_pi1 = pisum(N1, Float64SD)
        s_pi2 = pisum(N2, Float64SD)
        s_pi3 = pisum(N3, Float64SD)

        up1 = s_pi1.u/s_pi1.additions
        up2 = s_pi2.u/s_pi2.additions
        up3 = s_pi3.u/s_pi3.additions

        @test up3 < up2
        @test up2 < up1
    end

end


# ensure that any addition operation that can be done on Reals is available to be done with FloatSD types
# ensure that any operations that are NOT supported for Reals are likewise


#TODO: expand with tests that ensure stagnation information is being tracked and done so correctly
#TODO: expand with more tests to catch unreliable behaviour
#TODO: include test suite on long summation
#TODO: include test suite on integration of functions