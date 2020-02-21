
"""
"""
struct AffineFEOperator <: FEOperator
  test::FESpace
  trial::FESpace
  op::AffineOperator
end

"""
"""
function AffineFEOperator(test::FESpace,trial::FESpace,matrix::AbstractMatrix,vector::AbstractVector)
  @assert num_free_dofs(test) == size(matrix,1) "Incompatible test space and matrix"
  @assert num_free_dofs(trial) == size(matrix,2) "Incompatible trial space and matrix"
  op = AffineOperator(matrix,vector)
  AffineFEOperator(test,trial,op)
end

"""
   AffineFEOperator(test::FESpace,trial::FESpace,assem::Assembler,terms::AffineFETerm...)
   AffineFEOperator(test::FESpace,trial::FESpace,terms::AffineFETerm...)
"""
function AffineFEOperator(test::FESpace,trial::FESpace,assem::Assembler,terms::AffineFETerm...)

  v = get_cell_basis(test)
  u = get_cell_basis(trial)
  @assert is_trial(u)

  uhd = zero(trial)

  matvecdata, matdata, vecdata = collect_cell_matrix_and_vector(v,u,uhd,terms)
  A,b = assemble_matrix_and_vector(assem,matvecdata,matdata,vecdata)

  #matdata = collect_cell_matrix(v,u,terms)
  #vecdata = collect_cell_vector(v,uhd,terms)
  #A = assemble_matrix(assem,matdata...)
  #b = assemble_vector(assem,vecdata...)

  AffineFEOperator(test,trial,A,b)
end

function AffineFEOperator(test::FESpace,trial::FESpace,terms::AffineFETerm...)
  assem = SparseMatrixAssembler(test,trial)
  AffineFEOperator(test,trial,assem,terms...)
end

function AffineFEOperator(mat::Type{<:AbstractSparseMatrix},test::FESpace,trial::FESpace,terms::AffineFETerm...)
  assem = SparseMatrixAssembler(mat,test,trial)
  AffineFEOperator(test,trial,assem,terms...)
end

get_trial(feop::AffineFEOperator) = feop.trial

get_test(feop::AffineFEOperator) = feop.test

"""
"""
get_matrix(feop::AffineFEOperator) = get_matrix(feop.op)

"""
"""
get_vector(feop::AffineFEOperator) = get_vector(feop.op)

get_algebraic_operator(feop::AffineFEOperator) = feop.op

function allocate_residual(feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  allocate_residual(feop.op,x)
end

function residual!(b::AbstractVector,feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  residual!(b,feop.op,x)
end

function residual(feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  residual(feop.op,x)
end

function allocate_jacobian(feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  allocate_jacobian(feop.op,x)
end

function jacobian!(A::AbstractMatrix,feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  jacobian!(A,feop.op,x)
end

function jacobian(feop::AffineFEOperator,u)
  @assert is_a_fe_function(u)
  x = get_free_values(u)
  jacobian(feop.op,x)
end

