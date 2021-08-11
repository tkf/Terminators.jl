module Utils

struct CompletedProcess
    stdout::String
    stderr::String
    proc::Base.Process
end

function exec(code)
    julia = Base.julia_cmd()
    script = "include_string(Main, read(stdin, String))"
    cmd = `$julia --startup-file=no -e $script`
    setup = Base.load_path_setup_code()
    out = IOBuffer()
    err = IOBuffer()
    cmd = ignorestatus(cmd)
    cmd = pipeline(cmd; stderr = err, stdout = out)
    proc = open(cmd, write = true) do proc
        write(proc, setup)
        println(proc)
        write(proc, code)
        close(proc)
        return proc
    end
    completed = CompletedProcess(String(take!(out)), String(take!(err)), proc)
    @debug(
        "Done `exec(code)`",
        code = Text(code),
        stdout = Text(completed.stdout),
        stderr = Text(completed.stderr),
    )
    return completed
end

Base.success(c::CompletedProcess) = success(c.proc)

end  # module
