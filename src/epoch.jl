# Epochs more-or-less need to define offsets relative to one another (as a Duration), and that's it!

abstract Epoch



immutable GPSEpoch <: Epoch; end

Base.:-(::GPSEpoch, ::GPSEpoch) = Duration{1, ZeroUnit}(zerounit)

Base.show(io::IO, ::GPSEpoch) = print(io, "GPS epoch")



immutable OffsetEpoch{E <: Epoch} <: Epoch
    offset::Duration
    epoch::E
end

Base.:-(e1::OffsetEpoch, e2::Epoch)       = e1.duration + (e1.epoch - e2)
Base.:-(e1::Epoch, e2::OffsetEpoch)       = e1.duration + (e1 - e2.epoch)
Base.:-(e1::OffsetEpoch, e2::OffsetEpoch) = e1.duration - e2.duration + (e1.epoch - e2.epoch)

function Base.show(io::IO, e::OffsetEpoch)
    print(io, e.duration)
    print(io, " after ")
    print(io, e.epoch)
end
