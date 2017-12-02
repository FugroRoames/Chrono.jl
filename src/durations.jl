"""
    Duration{PeriodInSeconds}(value)

Construct a `Duration` object which stores an amount of time in units
`PeriodInSeconds` seconds. For instance, `Duration{60}(3)` represents 3 minutes
(three intervals of 60 seconds long).

The common units `weeks`, `days`, `hours`, `minutes`, `seconds`, `milliseconds`,
`microseconds` and `nanonseconds` are exported (as well as their non-plural
forms, `week`, etc) to make it convenient to construct any length of time,
such as `10seconds` or `10 * second`.
"""
struct Duration{PeriodInSeconds, T}
    value::T
end
Duration{P}(v::T) where {P,T} = Duration{P,T}(v)
Duration{P}(d::Duration) where {P} = convert(Duration{P}, d)
Duration{P,T}(d::Duration) where {P,T} = convert(Duration{P,T}, d)

@pure period(::Type{Duration{P}}) where {P} = P

@inline Base.get(d::Duration) = d.value

#@inline seconds(d::Duration) = get(d) * period(typeof(d))

# Conversion and promotion designed to maximize chance of staying "rational" if
# the user requests that (though Float64 is "default").
Base.convert(::Type{Duration{P}}, d::Duration{P,T}) where {P,T} = Duration{P,T}(get(d))
Base.convert(::Type{Duration{P1}}, d::Duration{P2}) where {P1,P2} = Duration{P1}((get(d) * P2) / P1)

Base.convert(::Type{Duration{P,T}}, d::Duration{P,T}) where {P,T} = Duration{P,T}(get(d))
Base.convert(::Type{Duration{P,T}}, d::Duration{P,T2}) where {P,T,T2} = Duration{P,T}(convert(T, get(d)))
Base.convert(::Type{Duration{P1,T}}, d::Duration{P2}) where {P1,P2,T} = Duration{P1,T}(convert(T, (get(d) * P2) / P1))

@pure function Base.promote_type(::Type{Duration{P1,T1}}, ::Type{Duration{P2,T2}}) where {P1,P2,T1,T2}
    # Note: this relation is assymetric if P1 == P2 but !(P1 === P2) (e.g. 1 vs 1.0)
    # Using promote_rule() results in stack overflows in this case
    if P1 === P2
        Duration{P1, promote_type(T1, T2)}
    elseif P1 < P2
        Duration{P1, Base.promote_op(/, promote_type(promote_type(T1, T2), typeof(P2)), typeof(P1))}
    else
        Duration{P2, Base.promote_op(/, promote_type(promote_type(T1, T2), typeof(P1)), typeof(P2))}
    end
end

@pure function Base.promote_op(f::F, ::Type{Duration{P1,T1}}, ::Type{Duration{P2,T2}}) where {F,P1,P2,T1,T2}
    if P1 === P2
        Duration{P1, Base.promote_op(f, T1, T2)}
    elseif P1 < P2
        Duration{P1, Base.promote_op(/, Base.promote_op(f, promote_type(T1, T2), typeof(P2)), typeof(P1))}
    else
        Duration{P2, Base.promote_op(/, Base.promote_op(f, promote_type(T1, T2), typeof(P1)), typeof(P2))}
    end
end

#Base.promote_op{P,T1,T2,F}(::F, ::Type{Duration{P,T1}}, ::Type{Duration{P,T2}}) = Duration{P, Base.promote_op(F,T1,T2)}
#Base.promote_op{P1,P2,T1,T2,F}(::F, ::Type{Duration{P1,T1}}, ::Type{Duration{P2,T2}}) = Duration{P1, promote_type(Base.promote_op(F,T1,T2),Base.promote_op(/, typeof(P1), typeof(P2)))}

function Base.show(io::IO, d::Duration{P}) where P
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " period of ") : print(io, " periods of ")
    print(io, P)
    (isa(P, Integer) && P == 1) ? print(io, " seconds") : print(io, " seconds")
end


# Mathematical operations
@inline Base.:-(d::Duration{P,T}) where {P,T} = Duration{P}(-get(d))

@inline Base.:+(d1::Duration, d2::Duration) = ((d1p, d2p) = promote(d1, d2); d1p + d2p)
@inline Base.:+(d1::Duration{P,T}, d2::Duration{P,T}) where {P,T} = Duration{P,T}(get(d1) + get(d2))

@inline Base.:-(d1::Duration, d2::Duration) = ((d1p, d2p) = promote(d1, d2); d1p - d2p)
@inline Base.:-(d1::Duration{P,T}, d2::Duration{P,T}) where {P,T} = Duration{P,T}(get(d1) - get(d2))

@inline Base.:/(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = (get(d1) * P1) / (get(d2) * P2)
@inline Base.://(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = (get(d1) * P1) // (get(d2) * P2)
@inline Base.div(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = div((get(d1) * P1), (get(d2) * P2)) # Euclidean division, pairs with rem()
@inline Base.rem(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = Duration{P1}(rem((get(d1) * P1), (get(d2) * P2)) / P1) # Negative iff d1.value is negative
@inline Base.fld(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = fld((get(d1) * P1), (get(d2) * P2)) # Flooring division, pairs with mod()
@inline Base.mod(d1::Duration{P1}, d2::Duration{P2}) where {P1,P2} = Duration{P1}(mod((get(d1) * P1), (get(d2) * P2)) / P1) # Always positive

# Scaling
@inline Base.:*(d::Duration{P}, s::Number) where {P} = ((dp, sp) = promote(get(d), s); Duration{P}(dp * s))
@inline Base.:*(s::Number, d::Duration{P}) where {P} = ((dp, sp) = promote(get(d), s); Duration{P}(s * dp))

@inline Base.:/(d::Duration{P}, s::Number) where {P} = ((dp, sp) = promote(get(d), s); Duration{P}(dp / s))
@inline Base.://(d::Duration{P}, s::Number) where {P} = ((dp, sp) = promote(get(d), s); Duration{P}(dp // s))

# Interface with Base.Dates. Autoconversion will result in Floats, not Rationals
Base.convert(::Type{Duration}, d::Base.Dates.Week) = Duration{604800//1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Day) = Duration{86400//1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Hour) = Duration{3600//1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Minute) = Duration{60//1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Second) = Duration{1//1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Millisecond) = Duration{1//1000,Int64}(d.value)

Base.convert(::Type{Duration{P}}, d::Base.Dates.Week) where {P} = Duration{P}(d.value * P * 604800)
Base.convert(::Type{Duration{P}}, d::Base.Dates.Day) where {P} = Duration{P}(d.value * P * 86400)
Base.convert(::Type{Duration{P}}, d::Base.Dates.Hour) where {P} = Duration{P}(d.value * P * 3600)
Base.convert(::Type{Duration{P}}, d::Base.Dates.Minute) where {P} = Duration{P}(d.value * P * 60)
Base.convert(::Type{Duration{P}}, d::Base.Dates.Second) where {P} = Duration{P}(d.value * P)
Base.convert(::Type{Duration{P}}, d::Base.Dates.Millisecond) where {P} = Duration{P}(d.value * P / 1000)

Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Week) where {P,T} = Duration{P,T}(d.value * P * 604800)
Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Day) where {P,T} = Duration{P,T}(d.value * P * 86400)
Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Hour) where {P,T} = Duration{P,T}(d.value * P * 3600)
Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Minute) where {P,T} = Duration{P,T}(d.value * P * 60)
Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Second) where {P,T} = Duration{P,T}(d.value * P)
Base.convert(::Type{Duration{P,T}}, d::Base.Dates.Millisecond) where {P,T} = Duration{P,T}(d.value * P / 1000)

Base.convert(::Type{Base.Dates.Week}, d::Duration{P}) where {P} = Base.Dates.Week(div(Int64(d.value * P), 604800))
Base.convert(::Type{Base.Dates.Day}, d::Duration{P}) where {P} = Base.Dates.Day(div(Int64(d.value * P), 86400))
Base.convert(::Type{Base.Dates.Hour}, d::Duration{P}) where {P} = Base.Dates.Hour(div(Int64(d.value * P), 3600))
Base.convert(::Type{Base.Dates.Minute}, d::Duration{P}) where {P} = Base.Dates.Minute(div(Int64(d.value * P), 60))
Base.convert(::Type{Base.Dates.Second}, d::Duration{P}) where {P} = Base.Dates.Second(Int(d.value * P))
Base.convert(::Type{Base.Dates.Millisecond}, d::Duration{P}) where {P} = Base.Dates.Millisecond(Int(d.value * P) * 1000)

Base.promote_rule(::Type{Duration{P,T}}, ::Type{DatesPeriod}) where {P,T, DatesPeriod <: Base.Dates.Period} = Duration{P, T}
Base.promote_rule(::Type{Duration{P,T}}, ::Type{DatesPeriod}) where {P,T, DatesPeriod <: Base.Dates.Millisecond} = Duration{P, promote_op(/, T, Int)}


# Export some convenience timescales as efficient singletons, e.g. week or weeks
const week = Duration{604800//1, Unit}(unit)
const day = Duration{86400//1, Unit}(unit)
const hour = Duration{3600//1, Unit}(unit)
const minute = Duration{60//1, Unit}(unit)
const second = Duration{1//1, Unit}(unit)
const millisecond = Duration{1//1000, Unit}(unit)
const microsecond = Duration{1//1_000_000, Unit}(unit)
const nanosecond = Duration{1//1_000_000_000, Unit}(unit)

const weeks = Duration{604800//1, Unit}(unit)
const days = Duration{86400//1, Unit}(unit)
const hours = Duration{3600//1, Unit}(unit)
const minutes = Duration{60//1, Unit}(unit)
const seconds = Duration{1//1, Unit}(unit)
const milliseconds = Duration{1//1000, Unit}(unit)
const microseconds = Duration{1//1_000_000, Unit}(unit)
const nanoseconds = Duration{1//1_000_000_000, Unit}(unit)

# Some nice outputs

function Base.show(io::IO, d::Duration{604800//1})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " week") : print(io, " weeks")
end

function Base.show(io::IO, d::Duration{86400//1})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " day") : print(io, " days")
end

function Base.show(io::IO, d::Duration{3600//1})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " hour") : print(io, " hours")
end

function Base.show(io::IO, d::Duration{60//1})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " minute") : print(io, " minutes")
end

function Base.show(io::IO, d::Duration{1//1})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " second") : print(io, " seconds")
end

function Base.show(io::IO, d::Duration{1/1000})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " millisecond") : print(io, " milliseconds")
end

function Base.show(io::IO, d::Duration{1//1_000_000})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " microsecond") : print(io, " microseconds")
end

function Base.show(io::IO, d::Duration{1//1_000_000_000})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " nanosecond") : print(io, " nanoseconds")
end
