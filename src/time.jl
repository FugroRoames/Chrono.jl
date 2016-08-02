
"""
    Time(duration, clock)

An instant in `Time` is represented as the `duration` since the "epoch" of the
`clock`, where the epoch is the instant the `clock` reads zero.

Times can be subtracted to get a relative duration, if a relationship between
their clocks is known.
"""
immutable Time{C <: Clock, D <: Duration}
    duration::D
    clock::C # This might be singleton, or it might have complex data
end

function Base.show(io::IO, t::Time)
    print(io, t.duration)
    print(io, " (since ")
    print(io, t.clock)
    print(io, ")")
end

# Mathematical operations
@inline Base.:+(d::Duration, t::Time) = Time(d + t.duration, t1.clock)
@inline Base.:+(t::Time, d::Duration) = Time(t.duration + d, t1.clock)
@inline Base.:-(t::Time, d::Duration) = Time(t.duration - d, t1.clock)

@inline Base.:-{C1<:TAIClock, C2<:TAIClock}(t1::Time{C1}, t2::Time{C2}) = t1.duration - t2.duration + (t1.clock - t2.clock)

"""
    Time(time, clock)

Convert the input `time` to use a new `clock`, if a relationship is known.
"""
function (::Type{Time}){C1 <: TAIClock, C2 <: TAIClock}(time::Time{C1}, clock::C2)
    return Time(time.duration + (time.clock - clock), clock)
end
