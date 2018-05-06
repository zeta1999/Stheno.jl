using Stheno, Plots
plotly();


###########################  Define and inspect our model  ###########################

#=

=#
function model(gpc)
    g1, g2 = x::AbstractVector->sin.(x), x::AbstractVector->1 .* x
    w1, w2 = GP(EQ(), gpc), GP(EQ(), gpc)
    f = g1 * w1 + g2 * w2
    y = f + GP(Noise(0.001), gpc)
    return w1, w2, f, y
end

# Sample from the prior from plotting and for conditioning.
rng, N, Nplot, S = MersenneTwister(123456), 250, 500, 100;
X, Xp = sort(rand(rng, N) * 10), linspace(-2.5, 12.5, Nplot);
w1, w2, f, y = model(GPC());
w1s, w2s, fs, ŷ = rand(rng, [w1, w2, f, y], [Xp, Xp, Xp, X]);

# Compute posterior distribution over f′.
w1′, w2′, f′ = (w1, w2, f) | (y(X) ← ŷ);

# Sample from the posterior and write to file.
w1′s, w2′s, f′s = rand(rng, [w1′, w2′, f′], [Xp, Xp, Xp], S);

# Get posterior mean and marginals f′ and y′ and write them for plotting.
μw1′, σw1′ = mean(w1′, Xp), marginal_std(w1′, Xp);
μw2′, σw2′ = mean(w2′, Xp), marginal_std(w2′, Xp); 
μf′, σf′ = mean(f′, Xp), sqrt.(diag(cov(f′, Xp)));


###########################  Plot results - USE ONLY Julia-0.6!  ###########################

posterior_plot = plot();

# Plot samples against which we're regressing.
plot!(posterior_plot, X, ŷ;
    markercolor=:red,
    markershape=:circle,
    markerstrokewidth=0.0,
    markersize=4,
    markeralpha=0.7,
    label="");

# Plot posterior over `f`.
plot!(posterior_plot, Xp, μf′;
    linecolor=:blue,
    linewidth=2.0,
    label="f");
plot!(posterior_plot, Xp, [μf′ μf′];
    linewidth=0.0,
    fillrange=[μf′ .- 3 .* σf′, μf′ .+ 3 * σf′],
    fillalpha=0.3,
    fillcolor=:blue,
    label="");
plot!(posterior_plot, Xp, f′s;
    linecolor=:blue,
    linealpha=0.2,
    label="");


# Plot posterior over w1.
plot!(posterior_plot, Xp, μw1′;
    linecolor=:green,
    linewidth=2.0,
    label="w1");
plot!(posterior_plot, Xp, [μw1′ μw1′];
    linewidth=0.0,
    fillrange=[μw1′ .- 3 .* σw1′, μw1′ .+ 3 * σw1′],
    fillalpha=0.3,
    fillcolor=:green,
    label="");
plot!(posterior_plot, Xp, w1′s;
    linecolor=:green,
    linealpha=0.2,
    label="");


# Plot posterior over w2.
plot!(posterior_plot, Xp, μw2′;
    linecolor=:magenta,
    linewidth=2.0,
    label="w2");
plot!(posterior_plot, Xp, [μw2′ μw2′];
    linewidth=0.0,
    fillrange=[μw2′ .- 3 .* σw2′, μw2′ .+ 3 * σw2′],
    fillalpha=0.3,
    fillcolor=:magenta,
    label="");
plot!(posterior_plot, Xp, w2′s;
    linecolor=:magenta,
    linealpha=0.2,
    label="");

display(posterior_plot);
