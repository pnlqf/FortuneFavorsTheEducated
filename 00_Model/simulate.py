"""
simulate.py  -  replicates portfolio_fin_sim.m
Simulates the life-cycle model for par["I"] individuals.
"""
import numpy as np
from scipy.interpolate import interp1d


def simulate(seed_fix, par, spa, a_func, alpha_func, s_func, b_func, xgrid, method):
    rng = np.random.default_rng(seed_fix)
    start_age = par.get("start_age", 20)

    # get these inputs from main
    I, T, T_ret = par["I"], par["T"], par["T_ret"]

    # ---- draw shocks ------------------------------------------------
    # permanent income shocks
    # create a matrix with (I, T): every individual per time
    # we use ones, because next we create shocks only for the working life
    # such that when we do not touch the retirement period, because everything
    # is ones, there won't be any shocks
    N = np.ones((I, T))

    # make sure to draw N-shocks only before retirement
    # uses group-specific mu_N and var_N from par
    N[:, :T_ret-1] = rng.lognormal(par["mu_N"], np.sqrt(par["var_N"]), (I, T_ret-1))

    # transitory income shocks
    # uses group-specific mu_V and var_V from par
    V = np.ones((I, T))
    V[:, :T_ret-1] = rng.lognormal(par["mu_V"], np.sqrt(par["var_V"]), (I, T_ret-1))

    # permanent income component  P
    P = np.ones((I, T))

    # starting point
    P[:, 0] = spa["G"][0] * N[:, 0]

    # create permanent income path based on the random picks for N
    for t in range(1, T):
        P[:, t] = spa["G"][t] * P[:, t-1] * N[:, t]

    # total income
    Y  = P * V

    # stock returns
    # randomly realize normal etas with zero mean for each I for every t
    eta = rng.normal(0.0, np.sqrt(par["var_Eta"]), (I, T))

    # get realized stock returns  (uses group-specific tau from par)
    Rs  = par["Rf"] + par["tau"] + eta

    # time of death
    die_temp  = rng.uniform(0, 1, (I, T))

    ind_alive = np.ones((I, T))

    for t in range(1, T):
        ind_alive[:, t] = ind_alive[:, t-1] * (die_temp[:, t] < spa["pS"][t])

    # ---- initialise result matrices ---------------------------------
    state_x  = np.full((I, T), np.nan)
    norm_a   = np.full((I, T), np.nan)
    sim_alpha = np.full((I, T), np.nan)

    if method == "value":
        norm_s = np.full((I, T), np.nan)
        norm_b = np.full((I, T), np.nan)

    # cash-on-hand at t=0: transitory shock + any group-specific initial assets
    # a0 is in normalised units (set per group in experiment block; default = 0.0)
    state_x[:, 0] = V[:, 0] + par.get("a0", 0.0)

    # ---- iterate forward --------------------------------------------
    print("\nSimulating...")

    for t in range(T-1):

        xg = xgrid[:, t] if xgrid.ndim == 2 else xgrid  # endgrid: 2d; value: 1d

        if method == "value":
            interp_s = interp1d(np.concatenate([[0], xg]),
                                np.concatenate([[0], s_func[:, t]]),
                                bounds_error=False, fill_value="extrapolate")
            interp_b = interp1d(np.concatenate([[0], xg]),
                                np.concatenate([[0], b_func[:, t]]),
                                bounds_error=False, fill_value="extrapolate")
            norm_s[:, t] = interp_s(state_x[:, t])
            norm_b[:, t] = interp_b(state_x[:, t])
            state_x[:, t+1] = ((Rs[:, t+1] * norm_s[:, t]
                                 + par["Rf"] * norm_b[:, t])
                                * (spa["G"][t+1] * N[:, t+1]) ** (-1)
                                + V[:, t+1])

        else:   # endgrid

            x_points = np.concatenate([[0], xg])
            a_points = np.concatenate([[0], a_func])

            interp_a = interp1d(x_points, a_points,
                    bounds_error=False, fill_value=(0.0, a_points[-1]))

            norm_a[:, t]    = interp_a(state_x[:, t])

            interp_al = interp1d(np.concatenate([[0], xg]),
                                 np.concatenate([[1], alpha_func[:, t]]),
                                 bounds_error=False, fill_value="extrapolate")

            sim_alpha[:, t] = interp_al(state_x[:, t])

            # calculate the realized return
            Rp = par["Rf"] + sim_alpha[:, t] * (Rs[:, t] - par["Rf"])

            # calculate the state of the next period
            state_x[:, t+1] = (Rp * norm_a[:, t]
                                * (spa["G"][t+1] * N[:, t+1]) ** (-1)
                                + V[:, t+1])

    if method == "value":
        norm_a    = norm_s + norm_b
        sim_alpha = norm_s / np.where(norm_a != 0, norm_a, np.nan)

    # ---- denormalize ------------------------------------------------
    X = state_x * P # to get kDKK again
    A = norm_a   * P

    # ---- grid coverage diagnostic -----------------------------------
    aa_max   = spa["aa"][-1]
    at_ceil  = np.nansum(norm_a >= 0.999 * aa_max)   # count of (i,t) pairs at ceiling
    total    = np.sum(~np.isnan(norm_a))
    pct_ceil = 100.0 * at_ceil / total
    t_worst  = int(np.nanargmax((norm_a >= 0.999 * aa_max).sum(axis=0)))
    print(f"  aa grid max        : {aa_max:.1f}  (normalized units)")
    print(f"  agents at ceiling  : {at_ceil:,} / {total:,}  ({pct_ceil:.2f}% of all person-periods)")
    print(f"  worst age          : {start_age + t_worst}")
    if pct_ceil > 0.1:
        print(f"  *** WARNING: {pct_ceil:.2f}% of agents are capped — aa max of {aa_max:.0f} is too small ***")

    print("...done")
    return state_x, norm_a, sim_alpha, X, A, Y, N, V, Rs, ind_alive
