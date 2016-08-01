module Chrono

import Base: @pure, ==

export Duration, Epoch, Time

include("unit.jl")
include("durations.jl")
include("epoch.jl")
include("time.jl")

end # module
