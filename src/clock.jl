# Epochs more-or-less need to define offsets relative to one another (as a Duration), and that's it!

"""
    abstract Clock

An `Clock` defines the instant of time to which a clock measures its time
relative to, i.e. the instant at time = 0. A `Time` object is simply a
combination of a `Duration` since this instant and a `Clock`.

If the relative difference between two clocks is known, then the two clocks can
be subtracted to get this difference as a duration. If the ticking rates of the
two clocks are different, the result should be in the units of the first clock
(i.e. `c1` in `c1 - c2`). This duration will be used automatically when
converting `Time` from one clock to another.
"""
abstract Clock


########################
## TAI time standards ##
########################

"""
     abstract TAIClock <: Clock

International Atomic Time (TAI) is used to define mulitple other standard
measurements of time, such as UTC and GPS time. Time standards defined against
TAI can be easily transformed between one another by knowing the relative
difference between their epochs (where the clock time = 0).

The relative difference between standard TAI time (at a given date) and a
custom-defined `TAIClock` class can be given by defining the `epoch()` of the
clock (as a `Base.Dates.Date`) and by defining the subtraction operation between
the clock and `TAIDate`. This will allow times to be converted between your
custom clock and any other TAI-derived clock.
"""
abstract TAIClock <: Clock

"""
    TAIDate <: TAIClock
    TAIDate(date)
    TAIDate(year, month, day)

An International Atomic Time (TAI) clock with epoch (time = 0) set at the
beginning of the given `date`.
"""
immutable TAIDate <: TAIClock
    date::Date
end
TAIDate(year, month, day) = TAIDate(Date(year, month, day))

"""
    epoch(clock)

Returns the date corresponding to the epoch (starting time, t = 0) of the clock.
E.g. `epoch(TAIDate(Dates.Date(1980, 1, 6)))` is 1980-01-06.
"""
epoch(tai_date::TAIDate) = tai_date.date

function Base.:-(c1::TAIDate, c2::TAIDate)
    return (epoch(c1) - epoch(c2)).value * days
end

# By default, the TAI-derived times will go through TAIDate as an intermediatary
function Base.:-{C1 <: TAIClock, C2 <: TAIClock}(c1::C1, c2::C2)
    return (c1 - TAIDate(epoch(c1))) - (c2 - TAIDate(epoch(c1)))
end

########################
## GPS time standards ##
########################

"""
    GPSEpoch <: TAIClock
    GPSEpoch()

The GPS time standard is defined relative to the start of 6th January, 1980.
Equivalent to `GPSWeek(0)`.
"""
immutable GPSEpoch <: TAIClock; end

#Base.:-(::GPSEpoch, ::GPSEpoch) = Duration{1, ZeroUnit}(zerounit)

Base.show(io::IO, ::GPSEpoch) = print(io, "GPS epoch")

function Base.:-(c1::GPSEpoch, c2::GPSEpoch)
    return Duration{1}(zerounit)
end

function Base.:-(c1::GPSEpoch, c2::TAIDate)
    return (epoch(c1) - epoch(c2)).value * days - gpsoffset
end

function Base.:-(c1::TAIDate, c2::GPSEpoch)
    return (epoch(c1) - epoch(c2)).value * days + gpsoffset
end

Base.@pure epoch(::GPSEpoch) = Date(1980, 1, 6)

"""
    GPSWeek <: TAIClock
    GPSWeek(week)

The GPS epoch began on Sunday 6th January, 1980, and the GPS broadcast signal
resets to zero every Sunday at midnight. For instance, week 1908 corresponds to
the week beginning 2016-07-31 (a Sunday).
"""
immutable GPSWeek <: TAIClock
    week::Int
end

function epoch(gps_week::GPSWeek)
    epoch(GPSEpoch()) + Week(gps_week.week)
end

Base.show(io::IO, c::GPSWeek) = print(io, "GPS week $(c.week) ($(epoch(c)))")

"""
    gpsweek(date)

Get the GPS week for the given date, i.e. how many Sundays have passed between
6th January 1980 and `date` (including `date`).
"""
gpsweek(date::Date) = fld(Duration(date - epoch(GPSEpoch())), weeks)

"""
    GPSWeek(date)
    GPSWeek(day, year, month)

Create a `GPSWeek` clock corresponding to the given `date`.
"""
GPSWeek(date::Date) = GPSWeek(gpsweek(date))
GPSWeek(year, month, day) = GPSWeek(gpsweek(Date(year, month, day)))

const gps_offset = 19seconds

function Base.:-(c1::GPSWeek, c2::GPSWeek)
    return (c1.week - c2.week)*weeks
end

function Base.:-(c1::GPSWeek, c2::TAIDate)
    return (epoch(c1) - epoch(c2)).value * days - gps_offset
end

function Base.:-(c1::TAIDate, c2::GPSWeek)
    return (epoch(c1) - epoch(c2)).value * days + gps_offset
end

########################
## UTC time standards ##
########################

"""
    UTCDate <: TAIClock
    UTCDate(date)
    UTCDate(year, month, day)

A clock which starts (defines it epoch) at the beggining of the specificied
Coordinated Universal Time (UTC) day.
"""
immutable UTCDate <: TAIClock
    date::Date
end

UTCDate(year, month, day) = UTCDate(Date(year, month, day))

epoch(utc_date::UTCDate) = utc_date.date

Base.show(io::IO, utc_date::UTCDate) = (print(io, utc_date.date); print(io, " (UTC)"))

include("../gen/leap_seconds.jl")

function lookup_leapsecs(date::UTCDate)
    d = epoch(date)
    if d > leap_secs_expiry_date
        throw(ErrorException("Unknown number of leap seconds for date $d"))
    end
    (searchsortedlast(utc_offsets, d) + leap_index_offset)seconds
end

function Base.:-(c1::UTCDate, c2::TAIDate)
    return (epoch(c1) - epoch(c2)).value * days - lookup_leapsecs(c1)
end

function Base.:-(c1::TAIDate, c2::UTCDate)
    return (epoch(c1) - epoch(c2)).value * days + lookup_leapsecs(c2)
end

function Base.:-(c1::UTCDate, c2::UTCDate)
    return (epoch(c1) - epoch(c2)).value * days - (lookup_leapsecs(c1) - lookup_leapsecs(c2))
end


#=
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
=#

