import Bramble: indices, npoints, dim, spacing_iterator, half_spacing_iterator, ndofs

function mesh1d_tests()
    I = interval(-1.0, 4.0)

    N = 4
    Ω = domain(I)
    Ωₕ = mesh(Ω, N, true)

    @test validate_equal(length(indices(Ωₕ)), N)
    @test validate_equal(ndofs(Ωₕ), N)
    @test dim(Ωₕ) == 1

    h = collect(spacing_iterator(Ωₕ))
    @test @views validate_equal(diff(h[2:N]), 0.0)

    hmed = collect(half_spacing_iterator(Ωₕ))
    @test @views validate_equal(diff(hmed[2:N-1]), 0.0)
end

mesh1d_tests()