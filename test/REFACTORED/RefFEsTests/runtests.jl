module RefFEsTests

using Test

@testset "PolynomialBases" begin include("PolynomialBasesTests.jl") end

@testset "Polytopes" begin include("PolytopesTests.jl") end

#@testset "DOFBases" begin include("DOFBasesTests.jl") end

end # module
