abstract type DirichletBCs <: BrambleType end

struct DirichletBCs1{F} <: DirichletBCs
    markers::NTuple{1,Marker{F}}
end

struct DirichletBCs2{F, G} <: DirichletBCs
    markers::Tuple{Marker{F}, Marker{G}}
end

struct DirichletBCs3{F, G, H} <: DirichletBCs
    markers::Tuple{Marker{F}, Marker{G}, Marker{H}}
end

abstract type BilinearFormType <: BrambleType end

struct BilinearForm{S1<:SpaceType,S2<:SpaceType,F} <: BilinearFormType
    space1::S1
    space2::S2
    form_expr::F
end

struct BilinearMass{S1, S2, T} <: BilinearFormType
    space1::S1
    space2::S2
    vec::Vector{T}
end


struct BilinearDiff{S1, S2, D, T} <: BilinearFormType
    space1::S1
    space2::S2
    aux::NTuple{D, MatrixElement{S1,T}}
    grad::NTuple{D, MatrixElement{S2,T}}
    buffer_sparse::SparseMatrixCSC{T, Int}
    buffer_bitvector::BitVector
end