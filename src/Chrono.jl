module Chrono

using Base.Dates

import Base: @pure, ==

export Duration
export week, day, hour, minute, second, millisecond, microsecond, nanosecond
export weeks, days, hours, minutes, seconds, milliseconds, microseconds, nanoseconds

export Clock, TAIClock, TAIDate, GPSEpoch, GPSWeek, UTCDate, epoch, gpsweek

export Time

include("unit.jl")
include("durations.jl")
include("clock.jl")
include("time.jl")

end # module
