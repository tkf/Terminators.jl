# Terminators.jl: adding timeout to your code

```julia
using Terminators

Terminators.withtimeout(3) do
    sleep(3)  # too slow, the process will be terminated
end
```
