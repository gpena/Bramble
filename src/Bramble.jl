"""
Bramble, a nonuniform finite difference method approximation in cartesian domains, in the Julia language.

This module provides a set of functions to create and solve discretization problems associated with finite difference methods on nonuniform grids

--------------------------------------------------------------------------------------
Author: Gonçalo Pena (University of Coimbra)
Date Create: 10/05/2023
"""

module Bramble
	using Random
#=
if Sys.isapple()
	# Apple: Load Apple Accelerate
	try
		using AppleAccelerate
		@info "Compiled with Apple Accelerate support on macOS"
	catch e
		@warn "Not an Apple machine, falling back to default BLAS/LAPACK"
	end
end

if Sys.iswindows()
	try
		#using MKLSparse
		using MKL
		@info "Compiled with MKL support on Windows"
	catch e
		@warn "Not an Intel machine, falling back to default BLAS/LAPACK"
	end
end

using InteractiveUtils: @code_warntype, @code_llvm, @code_native
import Base: eltype, similar, length, copyto!, isapprox, isequal, Generator, IndexStyle, axes, materialize!
import Base: map, map!, show, getindex, setindex!, IndexStyle, iterate, size, ndims, diff
import Base: *, +, -, /, ≈, ==, ^, \
import Random: rand!

using LazyArrays
using FastBroadcast: @..
using LinearAlgebra
using SparseArrays, FillArrays

import LinearSolve: LinearProblem, solve, KrylovJL_GMRES, LinearSolve, LUFactorization
import IncompleteLU: ilu

using Cubature
import Integrals: solve, IntegralFunction, IntegralProblem, QuadGKJL, CubatureJLh
using WriteVTK

abstract type BrambleType end

# Domain/Interval handling functions
export Interval, Domain, ×, markers

# Mesh handling
export Mesh, hₘₐₓ, submesh, ndofs, points

# Spaces handling
export GridSpace, Element
export innerₕ
export inner₊, inner₊ₓ, inner₊ᵧ, inner₊₂
export snorm₁ₕ, norm₁ₕ, norm₊, normₕ

export diff, diff₋ₓ, diff₋ᵧ, diff₋₂, D₋ₓ, D₋ᵧ, D₋₂, ∇ₕ
export Mₕ, Mₕₓ, Mₕᵧ, Mₕ₂
export jump, jumpₓ, jumpᵧ, jump₂

export Rₕ, Rₕ!, avgₕ, avgₕ!

export solve, solve!
export eltype, length, similar, copyto!, isapprox, isequal, show

# Forms exports
export BilinearForm, LinearForm, assemble, assemble!, Mass, Diff, update!
export dirichletbcs
export mass, stiffness, advection

# Exporters
export ExporterVTK, addScalarDataset!, datasets, save2file, close

include("utils.jl")

include("geometry/sets.jl")
include("geometry/domains.jl")

include("meshes/common.jl")
include("meshes/mesh1d.jl")
include("meshes/meshnd.jl")

include("spaces/gridspace.jl")
include("spaces/vectorelements.jl")
include("spaces/matrixelements.jl")
include("spaces/diff.jl")
include("spaces/average.jl")
include("spaces/jump.jl")

include("spaces/inner_product.jl")
include("spaces/linearalg.jl")


include("forms/types.jl")
include("forms/utils.jl")
include("forms/dirichletbcs.jl")
include("forms/bilinearforms.jl")
include("forms/linearforms.jl")
include("forms/assembler.jl")

include("problems/types.jl")
include("problems/laplacian.jl")

include("exporters/types.jl")
include("exporters/exporter_vtk.jl")

#include("precompile.jl")
=#
end
