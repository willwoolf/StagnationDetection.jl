using StagnationDetection
using Test

import Random: Xoshiro

include("sumfuncs.jl")
export harm, iharm, randsum, rand2um, pisum


@testset "StagnationDetection.jl" begin

    # existence of methods
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

    # data types after operations
    @testset "Types of FloatSD operation outputs" begin
        @testset "Addition and subtraction" begin
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

        @testset "Multiplication and division" begin
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
    end

    # correct promotion rules
    @testset "Type promotions for FloatSD" begin
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

    # correctness for scalar operations
    @testset "Scalar operations with FloatSD" begin
        @testset "Float64" begin
            x::Float64 = 1.0
            s::Float64SD = 1.0

            d::Float64 = eps(x) / 4

            @test x + d == x
            @test s + d == s
            @test !iszero(d)
        end

        @testset "Float32" begin
            x::Float32 = 1.0
            s::Float32SD = 1.0

            d::Float32 = eps(x) / 4

            @test x + d == x < Float64(x) + Float64(d)
            @test s + d == s < Float64SD(s) + Float64(d)
            @test !iszero(d)
        end

        @testset "Float16" begin
            x::Float16 = 1.0
            s::Float16SD = 1.0

            d::Float16 = eps(x) / 4

            @test x + d == x < Float64(x) + Float64(d)
            @test s + d == s < Float64SD(s) + Float64(d)
            @test !iszero(d)
        end
    end

    # correct operation counting
    #   for loop with accumulator
    #   vector sum
    @testset "Counting addition operations" begin
        rng = Xoshiro(1)
        X = randn(rng, Float64, 100000)

        @testset "For-loop with accumulator" begin
            s::Float64SD = 0.0
            for i in 1:lastindex(X)
                s += X[i]
            end

            @test num_additions(s) == lastindex(X)
        end

        @testset "Vector sum" begin
            S = Float64SD.(X)
            s = foldl(+, S)

            @test num_additions(s) == lastindex(X) - 1
        end

        ## null for LinearAlgebra: dot and matmul
        # various instances where implementation
        # of dot and matmul have changed. some
        # versions of LinearAlgebra start with a 
        # zero accumulator and perform n
        # additions, others start with the first
        # and perform n-1 additions
    end

    # correct stagnation measurement for the test problems
    @testset "Stagnation in deterministic test problems" begin
        @testset "Harmonic series" begin
            n = 2500000
            h = harm(n, Float32SD)

            @test num_absorptions(h) == 402_849 # total stagnation
            @test num_absorptions(h) == diff_absorptions(h) == h.absorptions_dn && h.absorptions_up == 0

            h2 = Float32SD(0.0f0; threshold = 0)
            h2 = harm(h2, n)

            @test num_absorptions(h2) == 1_451_424 # partial stagnation just checks u == 0
            @test num_absorptions(h2) == diff_absorptions(h2) == h2.absorptions_dn && h2.absorptions_up == 0

        end

        @testset "Harmonic series (reverse)" begin
            n = 2500000
            ih = Float32SD(0.0f0; threshold = 0)
            ih = iharm(ih, n)

            @test num_absorptions(ih) == diff_absorptions(ih) == 0
        end
    
        @testset "Converging pi approximation" begin
            n = 2500000
            p = pisum(n, Float32SD)

            @test num_absorptions(p) == 2_495_904 ## total stagnation
            @test num_absorptions(p) == diff_absorptions(p) == p.absorptions_dn && p.absorptions_up == 0

            p2 = Float32SD(0.0f0; threshold = 0)
            p2 = pisum(p2, n)
            
            @test num_absorptions(p2) == 2_497_104 # partial stagnation just checks u == 0
            @test num_absorptions(p2) == diff_absorptions(p2) == p2.absorptions_dn && p2.absorptions_up == 0
        end
    end

    # stagnation measurement fp16 exhaustive
    @testset "Stagnation measurement (sampling)" begin
        REPRESENTATIONS = vcat(
            UInt16(32769):UInt16(1):UInt16(64511),
            UInt16(1):UInt16(1):UInt16(31743)
        ) # nonzero, finite, number valued
        FLOATS = Float16SD.(reinterpret.(Float16, REPRESENTATIONS))

        stagnation_detected = true
        no_false_positives = true

        # randomly sample from the collection
        rng = Xoshiro()
        numsamples = 1000

        STAGNATION_DETECTED = ones(Bool, numsamples)
        NO_FALSE_POSITIVES = ones(Bool, numsamples)

        for i in 1:numsamples
            x, y = rand(rng, FLOATS, 2)
            (x, y) = abs(x) > abs(y) ? (x, y) : (y, x)
        
            z = x + y

            # one absorption has occurred and x == y, or neither of the above
            # if (z == x && y != 0) || (z == y && x != 0)
            if z == x
                # @test num_absorptions(z) != 0
                # stagnation_detected = stagnation_detected && (num_absorptions(z) != 0)
                STAGNATION_DETECTED[i] = (num_absorptions(z) != 0)
            else
                # @test num_absorptions(z) == 0
                # no_false_positives = no_false_positives && (num_absorptions(z) == 0)
                NO_FALSE_POSITIVES[i] = (num_absorptions(z) == 0)
            end
        end

        @test all(STAGNATION_DETECTED)
        @test all(NO_FALSE_POSITIVES)
    end

    ## removed exhaustive test. too expensive, make into separate application

end