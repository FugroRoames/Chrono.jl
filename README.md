# Chrono

*Scientific timekeeping in Julia*

[![Build Status](https://travis-ci.org/FugroRoames/Chrono.jl.svg?branch=master)](https://travis-ci.org/FugroRoames/Chrono.jl)
[![Coverage Status](https://coveralls.io/repos/FugroRoames/Chrono.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/FugroRoames/Chrono.jl?branch=master)
[![codecov.io](http://codecov.io/github/FugroRoames/Chrono.jl/coverage.svg?branch=master)](http://codecov.io/github/FugroRoames/Chrono.jl?branch=master)

This package provides a flexibile interface to write `Duration`s of time, and
functionality to keep track of instants of `Time` relative to specified
`Clock`s. The design is partially motivated by *C++*'s `std::chrono` template
library.

Current functionality includes storage of `Duration`s using any number type
and in periods of any chosen fraction of a second, a smattering of `Clock`s
based on the *International Atomic Time* (TAI) standard such as *UTC* and
*GPS* time standards. The `Time` type wraps a `Duration` since the start time
(a.k.a. *epoch*) of a `Clock`.

### Quick start
```julia
julia> using Chrono

julia> t1 = Time(12hours + 3.0seconds, UTCDate(2016,7,25))
43203.0 seconds (since 2016-07-25 (UTC))

julia> t2 = Time(14hours + 2minutes + 1.0seconds, UTCDate(2016,8,2))
50521.0 seconds (since 2016-08-02 (UTC))

julia> t2 - t1
698518.0 seconds

julia> t3 = Time(5hours + 5minutes + 26.0nanoseconds, GPSWeek(2016,1,1))
1.8300000000026e13 nanoseconds (since GPS week 1877 (2015-12-27))

julia> t4 = Time(t3, UTCDate(2015,12,27))
1.8317000000026e13 nanoseconds (since 2015-12-27 (UTC))

julia> t3.duration - t4.duration
-1.7e10 nanoseconds

julia> t3.clock - t4.clock
17//1 seconds
```

## User guide

### Durations

The `Duration` type represents a period of time with user-specified storage
format `T` and units (as `PeriodInSeconds` seconds):
```julia
struct Duration{PeriodInSeconds, T}
    value::T
end
```

Common durations including `weeks`, `days`, `hours`, `minutes`, `seconds`,
`milliseconds`, `microseconds` and `nanoseconds` are provided. One can add,
subtract, multiply an divide these as expected:
```julia
julia> 2.0weeks + 3.0days
17.0 days

julia> 2.0weeks / days
14.0

julia> div(19days, weeks)
2

julia> rem(19days, weeks)
5//1 days
```
is exactly `7 days` in a week, etc. However, floating point arithmetic is also
As seen above, rational arithmetic will be used whenever possible, so that there
fully supported, as well as conversion to/from `Base.Dates.Period` types.

### Clocks

A clock represents a method of measuring time. In general, a clock will have
"time = 0" at a certain instance of time - that instance is called the *epoch*.
We will represent a times as `Duration`s from a `Clock`'s epoch.

In general, it is difficult (or maybe impossible) to relate the time read by two
clocks. However, in some instances, the relationship may be known from
measurement or by definition. For an example of latter, the *International Atomic
Time* (TAI) standard is defined using a world-wide system of atomic clocks,
while a variety of *derived* time standards such as UTC and GPS time are
*defined* relative to TAI (and possibly some epoch date or dates).

Thus, the package includes support for abstract `TAIClock`s, which include as
subtypes a variety of time standards that are related:

 - `TAIDate(date)` is a TAI clock that starts at the beginning of a given `date`.
 - `UTCDate(date)` is a clock that starts at the beginning of a given `date`, and the
   package includes a table of UTC leap-seconds to relate UTC to other TAI-based
   times.
 - `GPSEpoch()` is a clock that starts on January 6, 1980 at 19 seconds behind TAI
   time.
 - `GPSWeek(n)` is a clock with an epoch at the beginning of the `n`th Sunday
   after January 6, 1980 (and trails the corresponding TAI time by 19 seconds).
   The GPS system transmits time as a combination of the GPS week and time since
   the beginning of that Sunday.

The `Duration` separating the epoch of any two TAI-derived clocks can be
obtained by subtracting the `Clock`s. The `gps_week(date)` helper function
returns the GPS week number corresponding to any date and the `epoch(clock)`
function returns the `Date` of the corresponding epoch (assumed to be at the
beginning of that day, in the corresponding time system).

### Times

As mentioned above, we measure `Time` relative to a `Clock`'s epoch. Our
definition of time is simply:
```julia
struct Time{C <: Clock, D <: Duration}
    duration::D
    clock::C # This might be singleton, or it might contain complex data
end
```

We can do all the obvious things to `Time`s: we can subtract two `Time`s to get
the `Duration` that separates them, or add/subtract a `Duration` to a `Time`.
The `Time` relative to a new clock can be created via the constructor
`Time(old_time, new_clock)`.
