"""
	SpaceType{MeshType}

Abstract type for grid spaces defined on meshes of type [MeshType](@ref).
"""
abstract type SpaceType{MeshType} <: BrambleType end

"""
	struct VectorElement{S,T}
		space::S
		values::Vector{T}
	end

Vector element of space `S` with coefficients of type `T`.
"""
struct VectorElement{S,T} <: AbstractVector{T}
	space::S
	values::Vector{T}
end

"""
	MatrixElement{S, T}

A `MatrixElement` is a container with a sparse matrix where each entry is a `T` and a space `S`. Its purpose is to represent discretization matrices from finite difference methods.
"""
struct MatrixElement{S,T} <: AbstractMatrix{T}
	space::S
	values::SparseMatrixCSC{T,Int}
end


"""
	struct GridSpace{MType,D,T}
		mesh::MType
		innerh_weights::Vector{T}
		innerplus_weights::NTuple{D,Vector{T}}}
		cache::SpaceCacheType
	end

Structure for a gridspace defined on a mesh.

The vector `innerh_weights` has the weights for the standard discrete ``L^2``
inner product on the space of grid functions defined as follows

  - 1D case

```math
(u_h, v_h)_h = \\sum_{i=1}^{N_x} h_{i+1/2} u_h(x_i) v_h(x_i)
```

  - 2D case

```math
(u_h, v_h)_h = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y} h_{x,i+1/2} h_{y,j+1/2} u_h(x_i,y_j) v_h(x_i,y_j)
```

  - 3D case

```math
(u_h, v_h)_h = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y}\\sum_{l=1}^{N_z} h_{x,i+1/2} h_{y,j+1/2} h_{z,l+1/2} u_h(x_i,y_j,z_l) v_h(x_i,y_j,z_l).
```

The vector `innerplus_weights` has the weights for the modified discrete ``L^2`` inner product on the space of grid functions, for each component (x, y, z).

  - 1D case

```math
(u_h, v_h)_+ = \\sum_{i=1}^{N_x} h_{i} u_h(x_i) v_h(x_i)
```

  - 2D case

```math
(u_h, v_h)_{+x} = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y} h_{x,i} h_{y,j+1/2} u_h(x_i,y_j) v_h(x_i,y_j)
```

```math
(u_h, v_h)_{+y} = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y} h_{x,i} h_{y,j+1/2} u_h(x_i,y_j) v_h(x_i,y_j)
```

  - 3D case

```math
(u_h, v_h)_{+x} = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y}\\sum_{l=1}^{N_z} h_{x,i} h_{y,j+1/2} h_{z,l+1/2} u_h(x_i,y_j,z_l) v_h(x_i,y_j,z_l)
```

```math
(u_h, v_h)_{+y} = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y}\\sum_{l=1}^{N_z} h_{x,i+1/2} h_{y,j} h_{z,l+1/2} u_h(x_i,y_j,z_l) v_h(x_i,y_j,z_l)
```

```math
(u_h, v_h)_{+z} = \\sum_{i=1}^{N_x}\\sum_{j=1}^{N_y}\\sum_{l=1}^{N_z} h_{x,i+1/2} h_{y,j+1/2} h_{z,l} u_h(x_i,y_j,z_l) v_h(x_i,y_j,z_l).
```
"""
struct GridSpace{MType,D,T} <: SpaceType{MType}
	mesh::MType
	innerh_weights::Vector{T}
	innerplus_weights::NTuple{D,Vector{T}}
	diff_matrix_cache::Dict{Int, MatrixElement{GridSpace{MType,D,T},T}}
end

const var2symbol = ("ₓ", "ᵧ", "₂")


"""
	gridspace(Ωₕ::MeshType)

Constructor for a [GridSpace](@ref) defined on the mesh `Ωₕ`.
"""
function gridspace(Ωₕ::MType) where MType
	T = eltype(Ωₕ)
	innerh = _create_vector(Ωₕ)
	build_innerh_weights!(innerh, Ωₕ)

	D = dim(Ωₕ)
	npts = npoints(Ωₕ, Tuple)
	innerplus = ntuple(i -> _create_vector(Ωₕ), D)
	innerplus_per_component = ntuple(j -> _create_vector(Ωₕ(j)), D)

	for i in 1:D
		for k in 1:D
			if k == i
				_innerplus_weights!(innerplus_per_component[k], Ωₕ, k)
			else
				_innerplus_mean_weights!(innerplus_per_component[k], Ωₕ, k)
			end
		end

		v = Base.ReshapedArray(innerplus[i], npts, ())
		__innerplus_weights!(v, innerplus_per_component)
	end

	T = eltype(Ωₕ)
	type = MatrixElement{GridSpace{MType, D, T}, T}
	Wₕ = GridSpace(Ωₕ, innerh, innerplus, Dict{Int, type}())

	# create backward difference matrices
	diff_matrices = create_backward_diff_matrices(Wₕ; vector = _create_vector(Ωₕ))

	# push diff matrices to cache
	for i in 1:D
		push!(Wₕ.diff_matrix_cache, i => diff_matrices[i])
	end

	return Wₕ
end

function show(io::IO, Wₕ::GridSpace)
	Ωₕ = mesh(Wₕ)
	D = dim(Ωₕ)

	properties = ["Gridspace defined on a $(D)D Mesh",
		"nPoints: $(npoints(Ωₕ))",
		"Markers: $(keys(Ωₕ.markers))"]

	println(io, join(properties, "\n"))

	print(io, "\nSubmeshes:\n")

	direction = ["x", "y", "z"]
	properties = ["  $(direction[i]) direction | nPoints: $(npoints(Ωₕ, Tuple)[i])" for i in 1:D]

	print(io, join(properties, "\n"))
end


"""
	mesh(Wₕ::SpaceType)

Returns the `mesh` on which the [GridSpace](@ref) `Wₕ` is defined.
"""
@inline mesh(Wₕ::SpaceType{MType}) where MType = Wₕ.mesh

"""
	ndofs(Wₕ::SpaceType)

Returns the number of degrees of freedom of the [GridSpace](@ref) `Wₕ`.
"""
@inline ndofs(Wₕ::SpaceType) = npoints(mesh(Wₕ))

"""
	eltype(Wₕ::SpaceType)

Returns the element type of [GridSpace](@ref) `Wₕ`.
"""
@inline eltype(Wₕ::SpaceType) = eltype(typeof(Wₕ))
@inline eltype(::Type{<:SpaceType{MType}}) where MType = eltype(MType)

@inline function get_diff_matrix(Wₕ::SpaceType, i) 
	@assert 1 <= i <= dim(mesh(Wₕ))
	return Wₕ.diff_matrix_cache[i]
end

"""
	_create_vector(Wₕ::SpaceType)

Returns a `Vector` with the same number of degrees of freedom as the [GridSpace](@ref) `Wₕ`.
"""
@inline _create_vector(Wₕ::SpaceType) = _create_vector(mesh(Wₕ))

"""
	_create_diagonal(Ωₕ::MeshType)

Returns a diagonal matrix with the same number of degrees of freedom as the mesh.
"""
@inline _create_vector(Ωₕ::MeshType) = Vector{eltype(Ωₕ)}(undef, npoints(Ωₕ))

"""
	build_innerh_weights!(u::Vector, Ωₕ::MeshType)

Builds the weights for the standard discrete ``L^2`` inner product, ``inner_h(\\cdot, \\cdot)``, on the space of grid functions, following the order of the [points](@ref). The values are stored in vector `u`.
"""
function build_innerh_weights!(u::Vector, Ωₕ::MeshType)
	f = Base.Fix1(cell_measure, Ωₕ)
	map!(f, u, indices(Ωₕ))
end

"""
	_innerplus_weights!(u::Vector{T}, Ωₕ::MeshType, component::Int = 1)

Builds a set of weights based on the spacings, associated with the `component`-th direction, for the modified discrete ``L^2`` inner product on the space of grid functions, following the order of the [points](@ref). The values are stored in vector `u`.
"""
function _innerplus_weights!(u::Vector{T}, Ωₕ::MeshType, component::Int = 1) where T
	@assert 1 <= component <= dim(Ωₕ)

	#N = npoints(Ωₕ(component))
	u[1] = zero(T)
	f = Base.Fix1(spacing, Ωₕ(component))

	for i in Iterators.drop(indices(Ωₕ(component)), 1) #2:N
		u[i] = f(i)
	end
end

"""
	_innerplus_mean_weights!(u::Vector{T}, Ωₕ::MeshType, component::Int = 1)

Builds a set of weights based on the half spacings, associated with the `component`-th direction, for the modified discrete ``L^2`` inner product on the space of grid functions, following the order of the [points](@ref). The values are stored in vector `u`.
for each component.
"""
function _innerplus_mean_weights!(u::Vector{T}, Ωₕ::MeshType, component::Int = 1) where T
	@assert 1 <= component <= dim(Ωₕ)

	u[1] = zero(T)

	idxs = Iterators.drop(indices(Ωₕ(component)), 1)
	for i in Iterators.take(idxs, 1) #2:(N - 1)
		u[i] = half_spacing(Ωₕ(component), i)
	end

	u[npoints(Ωₕ(component))] = zero(T)
end
#=
@inline @generated function __prod(diags::NTuple{D}, I) where D
	res = :(1)
	for i in 1:D
		res = :(diags[$i][I[$i]] * $res)
	end
	return res
end
=#
@inline @generated function __prod(diags::NTuple{D, Vector{T}}, I) where {D,T}
	res = :(convert(T, 1)::T)
	for i in 1:D
		res = :(diags[$i][I[$i]] * $res)
	end
	return res
end

"""
	__innerplus_weights!(v, innerplus_per_component)

Builds the weights for the modified discrete ``L^2`` inner product on the space of grid functions [GridSpace](@ref).
"""
function __innerplus_weights!(v, innerplus_per_component)
	for idx in CartesianIndices(v)
		v[idx] = __prod(innerplus_per_component, idx)
	end
end