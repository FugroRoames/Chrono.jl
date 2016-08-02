# A convenient singleton type, mainly for the timescales below
immutable Unit <: Integer; end
const unit = Unit()
Base.show(io::IO, ::Unit) = print(io, "one")

@inline Base.:-(::Unit) = -1
@inline Base.:+(::Unit, ::Unit) = 2

@inline Base.:*(::Unit, ::Unit) = unit
@inline Base.:*(::Unit, x::Number) = x
@inline Base.:*(x::Number, ::Unit) = x
@inline Base.:/(::Unit, ::Unit) = unit
@inline Base.:/(::Unit, x::Number) = 1 / x
@inline Base.:/(x::Number, ::Unit) = x
@inline Base.://(::Unit, ::Unit) = unit
@inline Base.://(::Unit, x::Number) = 1 // x
@inline Base.://(x::Number, ::Unit) = x

Base.promote_rule{I <: Number}(::Type{Unit}, ::Type{I}) = I
Base.convert{T}(::Type{T}, ::Unit) = one(T)
Base.convert{T<:Integer}(::Type{Rational{T}}, ::Unit) = one(Rational{T})
Base.one(::Type{Unit}) = Unit()


# Another convenient singleton type, good for subtracting epochs
immutable ZeroUnit <: Integer; end
const zerounit = ZeroUnit()
Base.show(io::IO, ::ZeroUnit) = print(io, "zero")

@inline Base.:+(::ZeroUnit, ::ZeroUnit) = zerounit
@inline Base.:+(::ZeroUnit, x::Number) = x
@inline Base.:+(x::Number, ::ZeroUnit) = x
@inline Base.:-(::ZeroUnit, ::ZeroUnit) = zerounit
@inline Base.:-(::ZeroUnit, x::Number) = -x
@inline Base.:-(x::Number, ::ZeroUnit) = x

@inline Base.:*(::ZeroUnit, ::ZeroUnit) = zerounit
@inline Base.:*(::ZeroUnit, x::Number) = zerounit
@inline Base.:*(x::Number, ::ZeroUnit) = zerounit
@inline Base.:/(::ZeroUnit, x::Number) = zerounit
@inline Base.://(::ZeroUnit, x::Number) = zerounit
@inline Base.div(::ZeroUnit, x::Number) = zerounit
@inline Base.rem(::ZeroUnit, x::Number) = zerounit


Base.promote_rule{I <: Number}(::Type{ZeroUnit}, ::Type{I}) = I
Base.convert{T}(::Type{T}, ::ZeroUnit) = zero(T)
Base.convert{T<:Integer}(::Type{Rational{T}}, ::ZeroUnit) = zero(Rational{T})
Base.zero(::Type{ZeroUnit}) = ZeroUnit()


# Mixed types...
@inline Base.:-(::Unit, ::Unit) = zerounit

@inline Base.:*(::ZeroUnit, ::Unit) = zerounit
@inline Base.:*(::Unit, x::ZeroUnit) = zerounit
@inline Base.:/(::ZeroUnit, x::Unit) = zerounit
@inline Base.://(::ZeroUnit, x::Unit) = zerounit

@inline Base.:rem(::Unit, ::Unit) = zerounit
@inline Base.:div(::ZeroUnit, ::Unit) = zerounit
@inline Base.:rem(::ZeroUnit, ::Unit) = zerounit

Base.promote_rule(::Type{ZeroUnit}, ::Type{Unit}) = Int
