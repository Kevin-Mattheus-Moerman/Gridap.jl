struct JacobiPolynomial <: Field end

struct JacobiPolynomialBasis{D,T} <: AbstractVector{JacobiPolynomial}
  orders::NTuple{D,Int}
  terms::Vector{CartesianIndex{D}}
  function JacobiPolynomialBasis{D}(
    ::Type{T}, orders::NTuple{D,Int}, terms::Vector{CartesianIndex{D}}) where {D,T}
    new{D,T}(orders,terms)
  end
end

@inline Base.size(a::JacobiPolynomialBasis{D,T}) where {D,T} = (length(a.terms)*num_components(T),)
@inline Base.getindex(a::JacobiPolynomialBasis,i::Integer) = JacobiPolynomial()
@inline Base.IndexStyle(::JacobiPolynomialBasis) = IndexLinear()

function JacobiPolynomialBasis{D}(
  ::Type{T}, orders::NTuple{D,Int}, filter::Function=_q_filter) where {D,T}

  terms = _define_terms(filter, orders)
  JacobiPolynomialBasis{D}(T,orders,terms)
end

function JacobiPolynomialBasis{D}(
  ::Type{T}, order::Int, filter::Function=_q_filter) where {D,T}

  orders = tfill(order,Val{D}())
  JacobiPolynomialBasis{D}(T,orders,filter)
end

# API

function get_exponents(b::JacobiPolynomialBasis)
  indexbase = 1
  [Tuple(t) .- indexbase for t in b.terms]
end

function get_order(b::JacobiPolynomialBasis)
  maximum(b.orders)
end

function get_orders(b::JacobiPolynomialBasis)
  b.orders
end

return_type(::JacobiPolynomialBasis{D,T}) where {D,T} = T

# Field implementation

function return_cache(f::JacobiPolynomialBasis{D,T},x::AbstractVector{<:Point}) where {D,T}
  @assert D == length(eltype(x)) "Incorrect number of point components"
  np = length(x)
  ndof = length(f.terms)*num_components(T)
  n = 1 + _maximum(f.orders)
  r = CachedArray(zeros(T,(np,ndof)))
  v = CachedArray(zeros(T,(ndof,)))
  c = CachedArray(zeros(eltype(T),(D,n)))
  (r, v, c)
end

function evaluate!(cache,f::JacobiPolynomialBasis{D,T},x::AbstractVector{<:Point}) where {D,T}
  r, v, c = cache
  np = length(x)
  ndof = length(f.terms)*num_components(T)
  n = 1 + _maximum(f.orders)
  setsize!(r,(np,ndof))
  setsize!(v,(ndof,))
  setsize!(c,(D,n))
  for i in 1:np
    @inbounds xi = x[i]
    _evaluate_nd_jp!(v,xi,f.orders,f.terms,c)
    for j in 1:ndof
      @inbounds r[i,j] = v[j]
    end
  end
  r.array
end

# Optimizing evaluation at a single point

function return_cache(f::JacobiPolynomialBasis{D,T},x::Point) where {D,T}
  ndof = length(f.terms)*num_components(T)
  r = CachedArray(zeros(T,(ndof,)))
  xs = [x]
  cf = return_cache(f,xs)
  r, cf, xs
end

function evaluate!(cache,f::JacobiPolynomialBasis{D,T},x::Point) where {D,T}
  r, cf, xs = cache
  xs[1] = x
  v = evaluate!(cf,f,xs)
  ndof = size(v,2)
  setsize!(r,(ndof,))
  a = r.array
  copyto!(a,v)
  a
end

# Helpers

@inline function _evaluate_1d_jp!(v::AbstractMatrix{T},x,order,d) where T
  n = order + 1
  z = one(T)
  @inbounds v[d,1] = z
  if n > 1
    ξ = ( 2*x[d] - 1 )
    for i in 2:n
      @inbounds v[d,i] = sqrt(2*i-1)*jacobi(ξ,i-1,0,0)
    end
  end
end

function _evaluate_nd_jp!(
  v::AbstractVector{V},
  x,
  orders,
  terms::AbstractVector{CartesianIndex{D}},
  c::AbstractMatrix{T}) where {V,T,D}

  dim = D
  for d in 1:dim
    _evaluate_1d_jp!(c,x,orders[d],d)
  end

  o = one(T)
  k = 1

  for ci in terms

    s = o
    for d in 1:dim
      @inbounds s *= c[d,ci[d]]
    end

    k = _set_value!(v,s,k)

  end

end
