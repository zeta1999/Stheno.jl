"""
    PseudoPoints

Some pseudo-points. Really need to improve the documentation here...
"""
struct PseudoPoints{Tf_q<:AbstractGP, Tc<:PseudoPointCache}
    f_q::Tf_q
    c::Tc
end

|(f::AbstractGP, u::PseudoPoints) = GP(|, f, u)

function μ_p′(::typeof(|), f::AbstractGP, u::PseudoPoints)
    return ApproxCondMean(u.c, mean(f), kernel(u.f_q, f))
end

function k_p′(::typeof(|), f::AbstractGP, u::PseudoPoints)
    return ApproxCondKernel(u.c, kernel(u.f_q, f), kernel(f))
end

function k_p′p(::typeof(|), f::AbstractGP, u::PseudoPoints, fp::GP)
    if fp.args[1] isa typeof(|) && fp.args[3] === u
        f′ = fp.args[2]
        return ApproxCondCrossKernel(u.c, kernel(u.f_q, f), kernel(u.f_q, f′), kernel(f, f′))
    else
        error("Unsupported cross-covariance.")
    end
end

function k_pp′(fp::GP, ::typeof(|) , f::AbstractGP, u::PseudoPoints)
    if fp.args[1] isa typeof(|) && fp.args[3] === u
        f′ = fp.args[2]
        return ApproxCondCrossKernel(u.c, kernel(u.f_q, f′), kernel(u.f_q, f), kernel(f′, f))
    else
        error("Unsupported cross-covariance")
    end
end













# Compute the approximate posterior 
function optimal_q(f::FiniteGP, y::AV{<:Real}, u::FiniteGP)
    σ = sqrt(FillArrays.getindex_value(f.σ²))
    U = cholesky(Symmetric(cov(u))).U
    Γ = broadcast(/, U' \ cov(u, f), σ)
    Λ = cholesky(Γ * Γ' + I)
    m′u = mean(u) + broadcast(/, U' * (Λ \ (Γ * (y - mean(f)))), σ)
    return m′u, Λ, U
end
optimal_q(c::Observation, u::FiniteGP) = optimal_q(c.f, c.y, u)

# Sugar for multiple approximate conditioning.
optimal_q(c::Observation, us::Tuple{Vararg{FiniteGP}}) = optimal_q(c, merge(us))
optimal_q(cs::Tuple{Vararg{Observation}}, u::FiniteGP) = optimal_q(merge(cs), u)
function optimal_q(cs::Tuple{Vararg{Observation}}, us::Tuple{Vararg{FiniteGP}})
    return optimal_q(merge(cs), merge(us))
end



# # Sugar.
# function optimal_q(f::AV{<:AbstractGP}, y::AV{<:AV{<:Real}}, u::AbstractGP, σ::Real)
#     return optimal_q(BlockGP(f), BlockVector(y), u, σ)
# end
# function optimal_q(f::AbstractGP, y::AV{<:Real}, u::AV{<:AbstractGP}, σ::Real)
#     return optimal_q(f, y, BlockGP(u), σ)
# end
# function optimal_q(f::AV{<:AbstractGP}, y::AV{<:AV{<:Real}}, u::AV{<:AbstractGP}, σ::Real)
#     return optimal_q(BlockGP(f), BlockVector(y), BlockGP(u), σ)
# end


# abstract type AbstractConditioner end

# """
#     Titsias <: AbstractConditioner

# Construct an object which is able to compute an approximate posterior.
# """
# struct Titsias{Tu<:FiniteGP, Tm<:AV{<:Real}, Tγ} <: AbstractConditioner
#     u::Tu
#     m′u::Tm
#     γ::Tγ
# end
# function Titsias(u::FiniteGP, m′u::AV{<:Real}, Λ, U)
#     return Titsias(u, m′u, GP(PPC(Λ, U), u.f.gpc))
# end
# Titsias(f::FiniteGP, y::AV{<:Real}, u::FiniteGP) = Titsias(u, optimal_q(f, y, u)...)
# Titsias(c::Observation, u::FiniteGP) = Titsias(c.f, c.y, u)

# # Construct an approximate posterior distribution.
# |(g::GP, c::Titsias) = g | (c.u←c.m′u) + project(kernel(c.u.f, g), c.γ, c.u.x)






# # FillArrays.Zeros(x::BlockVector) = BlockVector(Zeros.(x.blocks))

# |(g::Tuple{Vararg{AbstractGP}}, c::Titsias) = deconstruct(BlockGP([g...]) | c)
# function |(g::BlockGP, c::Titsias)
#     return BlockGP(g.fs .| Ref(c))
# end

# # """
# #     Titsias(
# #         c::Union{Observation, Vector{<:Observation}},
# #         u::Union{AbstractGP, Vector{<:AbstractGP}},
# #         σ::Real,
# #     )

# # Instantiate the saturated Titsias conditioner.
# # """
# # function Titsias(c::Observation, u::AbstractGP, σ::Real)
# #     return Titsias(u, optimal_q(c, u, σ)...)
# # end
# # function Titsias(c::Vector{<:Observation}, u::Vector{<:AbstractGP}, σ::Real)
# #     return Titsias(merge(c), BlockGP(u), σ)
# # end
# # function Titsias(c::Observation, u::Vector{<:AbstractGP}, σ::Real)
# #     return Titsias(c, BlockGP(u), σ::Real)
# # end
# # function Titsias(c::Vector{<:Observation}, u::AbstractGP, σ::Real)
# #     return Titsias(merge(c), u,  σ)
# # end
