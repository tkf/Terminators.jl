function terminator_loop(output::IO, input::IO, ppid::Int)
    mypid = getpid()
    timers = Dict{UInt,Timer}()
    for ln in eachline(input)
        @debug "[$mypid] GOT: $ln"
        sop, sid, stime = split(ln; limit = 3)
        id = parse(UInt, sid)
        time = parse(Float64, stime)
        print(output, "ack $sid\n")
        flush(output)
        if sop == "start"
            timer = Timer(time) do _
                @error "[$mypid] Timeout ($time) terminating process $ppid"
                isactive() = isdir("/proc/$ppid")
                function signalling(sig, n = typemax(Int))
                    @info "[$mypid] Trying to terminate process $ppid with $sig"
                    for _ in 1:n
                        run(`kill -s $sig $ppid`)
                        sleep(0.1)
                        isactive() || return true
                    end
                    return false
                end
                signalling("SIGINT", 10) && return
                signalling("SIGTERM", 10) && return
                signalling("SIGHUP", 100) && return
                signalling("SIGKILL")
            end
            timers[id] = timer
        elseif sop == "stop"
            close(pop!(timers, id))
        else
            error("unknown op: $sop")
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    terminator_loop(stdout, stdin, parse(Int, ARGS[1]))
end
