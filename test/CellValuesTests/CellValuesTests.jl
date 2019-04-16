module CellValuesTests

using Test
using LinearAlgebra: inv, det

using Numa
using Numa.FieldValues
using Numa.CellValues

include("Mocks.jl")
include("CachedArraysTests.jl")
include("OperationsTests.jl")
include("ConstantCellValuesTests.jl")
include("WrappersTests.jl")

end # module CellValuesTests