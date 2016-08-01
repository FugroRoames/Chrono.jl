immutable Duration{PeriodInSeconds, T}
    value::T
end
(::Type{Duration{P}}){P,T}(v::T) = Duration{P,T}(v)

@pure period{P}(::Type{Duration{P}}) = P

@inline Base.get(d::Duration) = d.value

#@inline seconds(d::Duration) = get(d) * period(typeof(d))

Base.convert{P1,P2}(::Type{Duration{P1}}, d::Duration{P2}) = Duration{P1}(get(d) * P1 / P2)

Base.promote_type{P1,P2,T1,T2}(::Type{Duration{P1,T1}}, ::Type{Duration{P2,T2}}) = Duration{P1, promote_type(T1,T2)}
Base.promote_op{P1,P2,T1,T2,F}(::F, ::Type{Duration{P1,T1}}, ::Type{Duration{P2,T2}}) = Duration{P1, promote_op(F,T1,T2)}

function Base.show{P}(io::IO, d::Duration{P})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " period of ") : print(io, " periods of ")
    print(io, P)
    (isa(P, Integer) && P == 1) ? print(io, " seconds") : print(io, " seconds")
end


# Mathematical operations
@inline Base.:-{P,T}(d::Duration{P,T}) = Duration{P,T}(-get(d))

@inline Base.:+(d1::Duration, d2::Duration) = ((d1p, d2p) = promote(d1, d2); d1p + d2p)
@inline Base.:+{P,T}(d1::Duration{P,T}, d2::Duration{P,T}) = Duration{P,T}(get(d1) + get(d2))

@inline Base.:-(d1::Duration, d2::Duration) = ((d1p, d2p) = promote(d1, d2); d1p + d2p)
@inline Base.:-{P,T}(d1::Duration{P,T}, d2::Duration{P,T}) = Duration{P,T}(get(d1) + get(d2))

@inline Base.:/{P1,P2}(d1::Duration{P1}, d2::Duration{P2}) = (get(d1) * P1) / (get(d2) * P2)
@inline Base.://{P1,P2}(d1::Duration{P1}, d2::Duration{P2}) = (get(d1) * P1) // (get(d2) * P2)
@inline Base.div{P1,P2}(d1::Duration{P1}, d2::Duration{P2}) = div((get(d1) * P1), (get(d2) * P2))
@inline Base.rem{P1,P2}(d1::Duration{P1}, d2::Duration{P2}) = rem((get(d1) * P1), (get(d2) * P2))

# Scaling
@inline Base.:*{P}(d::Duration{P}, s::Number) = ((dp, sp) = promote(get(d), s); Duration{P}(dp * s))
@inline Base.:*{P}(s::Number, d::Duration{P}) = ((dp, sp) = promote(get(d), s); Duration{P}(s * dp))

@inline Base.:/{P}(d::Duration{P}, s::Number) = ((dp, sp) = promote(get(d), s); Duration{P}(dp / s))
@inline Base.://{P}(d::Duration{P}, s::Number) = ((dp, sp) = promote(get(d), s); Duration{P}(dp // s))
@inline Base.div{P}(d::Duration{P}, s::Number) = ((dp, sp) = promote(get(d), s); Duration{P}(div(dp, s)))
@inline Base.rem{P}(d::Duration{P}, s::Number) = ((dp, sp) = promote(get(d), s); Duration{P}(rem(dp, s)))


# Interface with Base.Dates. Autoconversion will result in Floats, not Rationals
Base.convert(::Type{Duration}, d::Base.Dates.Week) = Duration{604800,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Day) = Duration{86400,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Hour) = Duration{3600,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Minute) = Duration{60,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Second) = Duration{1,Int64}(d.value)
Base.convert(::Type{Duration}, d::Base.Dates.Millisecond) = Duration{1//1000,Int64}(d.value)

Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Week) = Duration{P}(d.value * P * 604800)
Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Day) = Duration{P}(d.value * P * 86400)
Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Hour) = Duration{P}(d.value * P * 3600)
Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Minute) = Duration{P}(d.value * P * 60)
Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Second) = Duration{P}(d.value * P)
Base.convert{P}(::Type{Duration{P}}, d::Base.Dates.Millisecond) = Duration{P}(d.value * P / 1000)

Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Week) = Duration{P,T}(d.value * P * 604800)
Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Day) = Duration{P,T}(d.value * P * 86400)
Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Hour) = Duration{P,T}(d.value * P * 3600)
Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Minute) = Duration{P,T}(d.value * P * 60)
Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Second) = Duration{P,T}(d.value * P)
Base.convert{P,T}(::Type{Duration{P,T}}, d::Base.Dates.Millisecond) = Duration{P,T}(d.value * P / 1000)

Base.convert{P}(::Type{Base.Dates.Week}, d::Duration{P}) = Base.Dates.Week(div(Int64(d.value * P), 604800))
Base.convert{P}(::Type{Base.Dates.Day}, d::Duration{P}) = Base.Dates.Day(div(Int64(d.value * P), 86400))
Base.convert{P}(::Type{Base.Dates.Hour}, d::Duration{P}) = Base.Dates.Hour(div(Int64(d.value * P), 3600))
Base.convert{P}(::Type{Base.Dates.Minute}, d::Duration{P}) = Base.Dates.Minute(div(Int64(d.value * P), 60))
Base.convert{P}(::Type{Base.Dates.Second}, d::Duration{P}) = Base.Dates.Second(Int(d.value * P))
Base.convert{P}(::Type{Base.Dates.Millisecond}, d::Duration{P}) = Base.Dates.Millisecond(Int(d.value * P) * 1000)

Base.promote_type{P,T, DatesPeriod <: Base.Dates.Period}(::Type{Duration{P,T}}, ::Type{DatesPeriod}) = Duration{P, T}
Base.promote_type{P,T, DatesPeriod <: Base.Dates.Millisecond}(::Type{Duration{P,T}}, ::Type{DatesPeriod}) = Duration{P, promote_op(/, T, Int)}


# Export some convenience timescales as efficient singletons, e.g. week or weeks
const week = Duration{604800, Unit}(unit)
const day = Duration{86400, Unit}(unit)
const hour = Duration{3600, Unit}(unit)
const minute = Duration{60, Unit}(unit)
const second = Duration{1, Unit}(unit)
const millisecond = Duration{1//1000, Unit}(unit)
const microsecond = Duration{1//1_000_000, Unit}(unit)
const nanosecond = Duration{1//1_000_000_000, Unit}(unit)

export week, day, hour, minute, second, millisecond, microsecond, nanosecond

const weeks = Duration{604800, Unit}(unit)
const days = Duration{86400, Unit}(unit)
const hours = Duration{3600, Unit}(unit)
const minutes = Duration{60, Unit}(unit)
const seconds = Duration{1, Unit}(unit)
const milliseconds = Duration{1//1000, Unit}(unit)
const microseconds = Duration{1//1_000_000, Unit}(unit)
const nanoseconds = Duration{1//1_000_000_000, Unit}(unit)

export weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds

# Some nice outputs

function Base.show(io::IO, d::Duration{604800})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " week") : print(io, " weeks")
end

function Base.show(io::IO, d::Duration{86400})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " day") : print(io, " days")
end

function Base.show(io::IO, d::Duration{3600})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " hour") : print(io, " hours")
end

function Base.show(io::IO, d::Duration{60})
    print(io, d.value)
    (isa(d.value, Integer) && d.value == 1) ? print(io, " minute") : print(io, " minutes")
end

function Base.show(io::IO, d::Duration{d = 1})
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
