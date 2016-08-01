

immutable Time{Epoch, Duration}
    duration::Duration
    epoch::Epoch # This might be singleton, or it might have complex data
end

function Base.show(io::IO, t::Time)
    print(io, t.duration)
    print(io, " (since ")
    print(io, t.epoch)
    print(io, ")")
end

# Mathematical operations
@inline Base.:+(d::Duration, t::Time) = Time(d + t.duration, t1.epoch)
@inline Base.:+(t::Time, d::Duration) = Time(t.duration + d, t1.epoch)
@inline Base.:-(t::Time, d::Duration) = Time(t.duration - d, t1.epoch)

@inline Base.:-(t1::Time, t2::Time) = t1.duration - t2.duration + (t1.epoch - t2.epoch)
