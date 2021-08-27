abstract type AbstractTerminator end

struct Terminator <: AbstractTerminator
    proc::Base.Process
end

struct NullTerminator <: AbstractTerminator end

function check_supported()
    # "OS" APIs used in ./server.jl
    isdir("/proc/$(getpid())") || return false
    try
        read(`kill -l`)
    catch
        return false
    end
    return true
end

const IS_SUPPORTED = check_supported()

function Terminators.open(f)
    p = Terminators.open()
    try
        f()
    finally
        close(p)
    end
end

function Terminators.open()
    IS_SUPPORTED || return NullTerminator()
    julia = Base.julia_cmd()
    script = joinpath(@__DIR__, "server.jl")
    cmd = `$julia --startup-file=no $script -- $(getpid())`
    proc = open(cmd; read = true, write = true)
    return Terminator(proc)
end

function Base.close(p::Terminator)
    close(p.proc)
    wait(p.proc)
end

Base.close(::NullTerminator) = nothing

const LOCK = ReentrantLock()
const REF = Base.Ref{Union{Nothing,Terminator}}(nothing)

function global_terminator()
    IS_SUPPORTED || return NullTerminator()
    lock(LOCK) do
        p = REF[]
        p isa Terminator && return p
        p = REF[] = Terminators.open()
        atexit() do
            close(p)
        end
        return p
    end
end

const TIMER_ID = Ref{UInt}(0)

function wait_ack(p::Terminator, id::UInt)
    ln = readline(p.proc)
    @assert ln == "ack $id"
end

function Terminators.start(
    timeout::Number,
    p::AbstractTerminator = global_terminator();
    label = "",
)
    p isa NullTerminator && return UInt(0)
    timeout = Float64(timeout)
    id = TIMER_ID[] += 1
    write(p.proc, "start $id $timeout $label\n")
    flush(p.proc)
    wait_ack(p, id)
    return id
end

function Terminators.stop(id::UInt, p::AbstractTerminator = global_terminator())
    p isa NullTerminator && return UInt(0)
    write(p.proc, "stop $id 0 \n")
    flush(p.proc)
    wait_ack(p, id)
    return id
end

function Terminators.withtimeout(
    f,
    timeout::Number,
    p::AbstractTerminator = global_terminator();
    kwargs...,
)
    id = Terminators.start(timeout, p; kwargs...)
    try
        return f()
    finally
        Terminators.stop(id, p)
    end
end
