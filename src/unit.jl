# A convenient singleton type, mainly for the timescales below
struct Unit <: Integer; end
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

Base.promote_rule(::Type{Unit}, ::Type{I}) where {I <: Number} = I
Base.convert(::Type{T}, ::Unit) where {T} = one(T)
Base.convert(::Type{Rational{T}}, ::Unit) where {T<:Integer} = one(Rational{T})
Base.one(::Type{Unit}) = Unit()


# Another convenient singleton type, good for subtracting epochs
struct ZeroUnit <: Integer; end
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


Base.promote_rule(::Type{ZeroUnit}, ::Type{I}) where {I <: Number} = I
Base.convert(::Type{T}, ::ZeroUnit) where {T} = zero(T)
Base.convert(::Type{Rational{T}}, ::ZeroUnit) where {T<:Integer} = zero(Rational{T})
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
