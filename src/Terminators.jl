baremodule Terminators

function withtimeout end
function open end
function start end
function stop end

"""
    Terminators.withtimeout(f, seconds::Number, [terminator])

Run `f()` with the timeout `seconds`. This process is terminated if `f()` does
not finish after `seconds` seconds.
"""
withtimeout

"""
    Terminators.open() -> terminator
    Terminators.open(f)

Create a terminator.
"""
open

module Internal

using ..Terminators: Terminators

include("internal.jl")

end  # module Internal

end  # baremodule Terminators
