module TestWithTimeout

using Terminators
using Test
using ..Utils: exec

function test_no_timeout()
    ok = Ref(false)
    Terminators.withtimeout(10) do
        ok[] = true
    end
    @test ok[]
end

function test_timeout()
    proc = Terminators.withtimeout(300) do
        exec("""
        using Terminators
        Terminators.withtimeout(0.1) do
            while true
                $(VERSION ≥ v"1.4" ? "GC.safepoint()" : "yield()")
            end
        end
        """)
    end
    @test !success(proc)
    @test occursin("Timeout", proc.stderr)
    @test occursin("terminating process", proc.stderr)
end

end  # module
