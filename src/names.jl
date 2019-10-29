using NamedDims

Base.names(A::RangeArray{T,N,<:NamedDimsArray{L}}) where {T,N,L} = L
Base.names(A::RangeArray{T,N,<:NamedDimsArray{L}}, d) where {T,N,L} = d <= N ? L[d] : :_
Base.names(A::NamedDimsArray{L}) where {L} = L # 🏴‍☠️
Base.names(A::NamedDimsArray{L,T,N}, d) where {L,T,N} = d <= N ? L[d] : :_ # 🏴‍☠️

hasnames(A::RangeArray{T,N,<:NamedDimsArray}) where {T,N} = true
hasnames(A::NamedDimsArray) = true
hasnames(A) = false

NamedDims.unname(A::RangeArray{T,N,<:NamedDimsArray{L}}) where {T,N,L} =
    RangeArray(unname(A.data), A.ranges)

ranges(A::NamedDimsArray{L,T,N,<:RangeArray}) where {T,N,L} = ranges(parent(A))
ranges(A::NamedDimsArray{L,T,N,<:RangeArray}, d) where {T,N,L} = ranges(parent(A), d)

hasranges(A::NamedDimsArray{L,T,N,<:RangeArray}) where {L,T,N} = true
hasranges(A::RangeArray) = true
hasranges(A) = false

"""
    namedranges(A)
    namedaxes(A)

Combines `names(A)` and either `ranges(A)` or `axes(A)` into a `NamedTuple`.
"""
namedranges(A::NamedDimsArray{L,T,N,<:RangeArray}) where {L,T,N} = NamedTuple{L}(ranges(A))
namedranges(A::RangeArray{T,N,<:NamedDimsArray{L}}) where {L,T,N} = NamedTuple{L}(ranges(A))
namedranges(A::NamedDimsArray{L}) where {L} = NamedTuple{L}(axes(A))

@doc @doc(namedranges)
namedaxes(A::NamedDimsArray{L,T,N,<:RangeArray}) where {L,T,N} = NamedTuple{L}(axes(A))
namedaxes(A::RangeArray{T,N,<:NamedDimsArray{L}}) where {L,T,N} = NamedTuple{L}(axes(A))
namedaxes(A::NamedDimsArray{L}) where {L} = NamedTuple{L}(axes(A))

# A.stuff

Base.propertynames(A::NamedDimsArray{L,T,N,<:RangeArray}, private=false) where {L,T,N} =
    private ? (L..., fieldnames(typeof(A))) : L
Base.propertynames(A::RangeArray{T,N,<:NamedDimsArray{L}}, private=false) where {L,T,N} =
    private ? (L..., fieldnames(typeof(A))) : L

Base.getproperty(A::NamedDimsArray{L,T,N,<:RangeArray}, s::Symbol) where {L,T,N} =
    Base.sym_in(s, L) ? ranges(A, NamedDims.dim(L, s)) : getfield(A, s)
Base.getproperty(A::RangeArray{T,N,<:NamedDimsArray{L}}, s::Symbol) where {L,T,N} =
    Base.sym_in(s, L) ? ranges(A, NamedDims.dim(L, s)) : getfield(A, s)
Base.getproperty(A::NamedDimsArray{L}, s::Symbol) where {L} =
    Base.sym_in(s, L) ? axes(A, NamedDims.dim(L, s)) : getfield(A, s)

# Keyword indexing of RangeArray:

Base.@propagate_inbounds function Base.getindex(A::RangeArray; kw...)
    hasnames(A) || error("must have names!")
    dims = NamedDims.dim(names(A), keys(kw))
    inds = ntuple(d -> d in dims ? values(kw)[d] : (:), ndims(A))
    getindex(A, inds...)
end

# Any NamedDimsArray + RangeArray combination is callable:

Base.@propagate_inbounds (A::NamedDimsArray{L,T,N,<:RangeArray})(args...) where {L,T,N} =
    getkey(A, args...)

Base.@propagate_inbounds (A::RangeArray{T,N,<:NamedDimsArray})(;kw...) where {T,N} =
    getkey(A; kw...)
Base.@propagate_inbounds (A::NamedDimsArray{L,T,N,<:RangeArray})(;kw...) where {L,T,N} =
    getkey(A; kw...)

Base.@propagate_inbounds function getkey(A; kw...)
    list = names(A)
    issubset(kw.itr, list) || error("some keywords not in list of names!")
    args = map(s -> Base.sym_in(s, kw.itr) ? getfield(kw.data, s) : Colon(), list)
    A(args...)
end
