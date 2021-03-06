using SHA

# Script to download the leap seconds list from NIST, and format it into julia
# code for use in Chrono.jl.

#-------------------------------------------------------------------------------
# Download leap-seconds.list
# Official URL (?)
url = "ftp://time.nist.gov/pub/leap-seconds.list"
# IETF has a mirror if the NIST site is unresponsive, which it commonly is.
# The mirror is not as up to date though.
# url = "https://www.ietf.org/timezones/data/leap-seconds.list"
local_name = "leap-seconds.list"
if length(ARGS) < 1 || ARGS[1] != "false"
    download(url, local_name)
end
lines = readlines(local_name)

#-------------------------------------------------------------------------------
# Parse file.
rawdata = [] # for hash computation
last_update_ntp = 0
expiry_ntp = 0
leap_epochs_ntp = Int[]
leap_secs = Int[]
expected_sha = ""
for line in lines
    # Mostly, lines starting with # are comments.  However, due to
    # terribleness, lines starting with "#@", "#$" or "#h" also contain valid
    # data which needs to be parsed for hash verification.
    if startswith(line, "#\$")
        datastr = match(r"^#\$\s*(\d+)\s*$", line)[1]
        last_update_ntp = parse(Int64, datastr)
        push!(rawdata, datastr)
    elseif startswith(line, "#@")
        datastr = match(r"^#@\s*(\d+)\s*$", line)[1]
        expiry_ntp = parse(Int64, datastr)
        push!(rawdata, datastr)
    elseif startswith(line, "#h")
        # The specified hash method for leap-seconds.list is super broken,
        # since it removes semantically meaningful whitespace.  At least we can
        # guard against transmission errors...
        #
        # There's also a bug in writing out the expected hash!  Work around it
        # by parsing and reformatting, ugh.
        pieces = map(x->@sprintf("%08x", parse(Int,x,16)), split(line[3:end]))
        expected_sha = join(pieces)
    elseif !startswith(line, "#")
        m = match(r"(\d+)\s*(\d+)\s*#.*", line)
        push!(leap_epochs_ntp, parse(Int64, m[1]))
        push!(leap_secs, parse(Int, m[2]))
        push!(rawdata, m[1])
        push!(rawdata, m[2])
    end
end

actual_sha = bytes2hex(SHA.sha1(join(rawdata)))
@show expected_sha actual_sha
@assert expected_sha == actual_sha
@assert all(diff(leap_secs) .== 1)


#-------------------------------------------------------------------------------
# Generate julia code
function format_ntp_secs_as_date(ntp_epoch_secs)
    d = Dates.Second(ntp_epoch_secs) + Dates.DateTime(1900)
    @assert Dates.hour(d) == 0 && Dates.minute(d) == 0 &&
            Dates.second(d) == 0 && Dates.millisecond(d) == 0
    "Date($(Dates.year(d)), $(Dates.month(d)), $(Dates.day(d)))"
end

genname = "leap_seconds.jl"
open(genname, "w") do file
    write(file,
        """
        # Automatically generated by update_leap_seconds.jl - do not edit!

        const leap_index_offset = $(leap_secs[1]-1) # For use with searchsortedlast()

        const utc_offsets = [
            typemin(Date),  # For use with searchsortedlast()
            $(join(map(format_ntp_secs_as_date, leap_epochs_ntp[2:end]), ",\n    "))
        ]

        const leap_secs_expiry_date = $(format_ntp_secs_as_date(expiry_ntp))
        """
    )
end

print(readstring(genname))
