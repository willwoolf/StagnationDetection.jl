# StagnationDetection

[![Build Status](https://github.com/willwoolf/StagnationDetection.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/willwoolf/StagnationDetection.jl/actions/workflows/CI.yml?query=branch%3Amain)

## About

StagnationDetection.jl is a package for detecting errors in floating point summation.
Stagnation occurs when, in an arbitrary sum of $n$ variables, there are $0 < M \leq n-1$ cases where an addend is rounded off completely or almost completely.

For example, take the harmonic series

$$\sum_{n=1}^\infty \frac{1}{n}.$$

In real arithmetic, this diverges to infinity, but in finite precision it will converge to a finite value.
We can attempt to compute the harmonic series in finite precision arithmetic by storing the sum of the first $k$ terms in $s_k$ and computing $s_k + 1/(k+1)$ in finite precision.
We continue this for $k$ starting at $1$ and incrementing on each addition.
The value of the sum will stop growing in finite precision arithmetic when $1/(k+1)$ becomes sufficiently small.
The $\mathrm{ulp}$ of a floating point number $x$ is the difference between $x$ and the next greater floating point number,
so if the following condition is satisfied when using round-to-nearest

$$\frac{1}{k+1} < \frac{1}{2}\mathrm{ulp}(s_k)$$

then stagnation will occur.
This is because the value being added is small enough in magnitude that $\mathrm{fl}(s_k + 1/(k+1))$ is rounded back to $s_k$.

## Installation

Currently this package is not registered but can be installed manually.
In a working directory of your choice, 
```
>> git clone https://github.com/willwoolf/StagnationDetection.jl.git
>> cd StagnationDetection.jl
>> julia
julia> ]
pkg> develop .
```

The package will be installed and ready to use.

## Usage

Stagnation Detection provides the types `Float64SD`, `Float32SD` and `Float16SD`.
Similar to how core floating point types are subtypes of `AbstractFloat`, stagnation detection types are subtypes of `FloatSD`.
Stagnation detection and tracking relies on addition operations of the form `x = x + y` where `x` is one of the provided types, 
this applies generally to large summations of any kind, such as dot products and matrix multiplication. 
To track stagnation, the user should create a variable using a stagnation detection type to be treated as the accumulator.
Arithmetic will behave as normal but will record data on stagnation.

### Example

In its simplest form, stagnation detection can be implemented in a for-loop.

```julia
using StagnationDetection

x::Float64SD = 1.0

for _ in 1:100
    x += rand()
end
```

Stagnation detection is activated here because the addition operator `+` is called where one argument, `x`, is a `Float64SD`.
We can also perform stagnation detection in vector summation.

```julia
X = rand(Float64SD, 1000)

x = foldl(+, X)
```

There are other ways of performing vector summation:
```julia
x = sum(X)

x = foldl(+, X)

x = +(X...)
```
However, we have noticed in our testing that `sum` does not behave the same as other implementations.
We recommend using `foldl(+, X)` for general addition with stagnation detection.

Any algorithm that performs recursive additions, such as but not limited to matrix multiplication, can be performed with stagnation detection by simply assigning the correct type to one or more arguments.

To produce stagnation information in a readable form, use the function `report(x::FloatSD)`.
An example output is shown below

```
julia> report(x) 
--------------- SUMMARY ----------------
Detecting total stagnation in 999 additions.
The condition for total absorption is u = 0 and for the smaller addend to be rounded off completely in a given addition.
Accumulator precision: 53 (Float64SD).

Overall stagnation length 0.
0 round down, 0 round up.
Net stagnation length 0 (round up).

-------- PROCESSING OF RESULTS ---------
u is the total number of bits which were not shifted off in the addition.
Total number of bits processed u = 43992.
Average uᵢ = 44.03603603603604.
See paper: Analysis and Detection of Stagnation in Floating-Point Summation,
Mantas Mikaitis and William Woolfenden, 2026.

------------ END OF SUMMARY ------------
```

Absorptions in different rounding directions are tracked.
We provide the functions `num_additions`, `num_absorptions`, `diff_absorptions` and `net_absorptions` as extra user tools for stagnation detection diagnostics.
Please see our paper for more details.
In addition, we have a function `reportall` which identifies and prints information on all stagnation detection variables in the local scope, however this only works to the desired effect in the REPL.
An example output of `reportall` is shown below.

```
julia> reportall()
 ---------  SCALARS IN GLOBAL SCOPE  --------- 
x (Float32SD), stagnation 10005 / 999999 additions (1.0%), threshold 0 (total)
y (Float32SD), stagnation 2581 / 499999 additions (0.52%), threshold 0 (total)
z (Float32SD), stagnation 951424 / 2000000 additions (48.0%), threshold 0 (near-total)

 ----------- ARRAYS IN GLOBAL SCOPE  --------- 
A (Matrix{Float16SD}, 32×32), stagnation range 0.0% to 0.0%, mean 0.0%
B (Matrix{Float32SD}, 32×32), stagnation range 3.1% to 3.1%, mean 3.1%

 -------------- END OF REPORTALL  ------------ 
```

The threshold to qualify stagnation can be adjusted; in the above examples we are measuring total stagnation, but can loosen this requirement to look at all additions where $u$ is below a positive threshold.
See [here](#controlling-stagnation-detection) for more details.

### Addition operations

If performing an addition operation `(::FloatSD) + (::Real)` or `(::Real) + (::FloatSD)`, stagnation detection will be performed. 
Data relating to stagnation will be stored in additional fields of the `FloatSD` variable.
The addition operation creates a copy of the `FloatSD` variable, updates the fields with the properties observed during addition, and returns it.

If an addition of the form `(::FloatSD) + (::FloatSD)` is performed, only the data from the *left* argument will be copied and all data from the other argument will not affect the result.


### Features

Random number generators (`rand`, `randn`),
trigonometric functions (`sin`, `cos`, `tan`, `sinpi`, ...),
and fundamental `::Number` functions (`one`, `zero`, `isfinite`, `isreal`, ...) are all supported for `FloatSD` types.
Please get in touch or submit a pull request if you encounter a missing function implementation or a bug due to lack of specialisation.
Plenty of core Julia functions for real numbers are operational without being implemented in this package, since they rely on the fundamental functions for `::Number` types.


### Linear algebra

Stagnation detection is compatible with matrices.
Each entry in a matrix will be stored as a `Float64SD` or similar, so stagnation information will be monitored per entry in the matrix.
Currently `report()` is not implemented for arrays, but can be called on individual elements or broadcast.


### Controlling stagnation detection

The tool tracks total stagnation by default. This can be adjusted by a `threshold` value in the constructor.
There are three definitions for stagnation: total, near-total and partial.
Total stagnation refers to sequences of additions where addends are completely rounded off.
Near-total stagnation extends this condition to include cases where the addends are shifted off when aligning significands, but may still round away from the accumulator.
Partial stagnation extends this further by considering all cases where the significand is not shifted off completely, but the number of bits that do get carried  is below a threshold.

The recommended way to initialise a `FloatSD` variable is either
```julia
julia> x::Float64SD = 5
```
or
```julia
julia> x = Float64SD(5)
```
The `threshold` can be provided as an optional argument to the constructor: by writing
```julia
julia> x = Float64SD(5; threshold = 2)
```
Stagnation detection will now record additions where the number of bits carried is $2$ or less.
This is the same for any value of threshold from $1$ to the precision of the given format.
For `threshold = 0` this records total and near-total stagnation.
For any negative value of `threshold`, only total stagnation will be recorded (the default value is $-1$, all negative values lead to the same behaviour).
The greatest possible value for `threshold` is always the precision of the accumulator.
The value of the threshold cannot be changed after construction, so multiple accumulators must be used if you wish to measure stagnation in multiple ways.


### Constructors

In addition to choosing the constructor for the type, the abstract type constructor `FloatSD` can be used and will match the type of the argument given.
```julia
julia> x = FloatSD(1.0) # will make x a Float64SD

julia> x = FloatSD(1.0f0) # will make x a Float32SD

julia> x = FloatSD(Float16(1.0)) # will make x a Float16SD
```
If the argument is any other real, non floating-point type, conversion defaults to `Float64SD`
We can also convert between formats:
```julia
julia> x = Float64SD(1.0, threshold = 2)

julia> ... # do stuff with x

julia> y = Float32SD(x) # all fields from x are copied to y, the value is converted from Float64 to Float32.
```
Note that the fields will be carried, but this does not reflect the same conditions.
If we perform the same recursive sum on `Float32` and `Float64` data, the measures of stagnation will be different, and this would not be reflected if we performed a recursive sum with a `Float64SD` accumulator and then converted to `Float32SD` or similar.

Our recommended approach is to declare types as general practice (`x::Float64SD  = 5`, or even `x::Float64SD = Float64SD(5)`), then we provide the option to use additional parameters where needed.


## Contact

For questions about this package please contact Will via. rcvw5971 [at] leeds [dot] ac [dot] uk.
