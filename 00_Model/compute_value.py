"""
compute_value.py  -  backward value function evaluation at the EGM optimum

Given the EGM policy functions (c*, alpha*) and the endogenous x grid,
this computes the normalized value function V(x, t) at every grid point
by iterating the Bellman equation backward with the policy held fixed.

Why this is NOT VFI
-------------------
VFI solves for V and the policy simultaneously from a guess. Here the policy
is already optimal (from EGM), so we only need one backward pass to evaluate
V. There is no optimization, no outer iteration, and no convergence criterion.

The result is the exact expected discounted utility under the optimal policy,
integrated analytically via Gauss-Hermite quadrature — no simulation noise.

Normalization weight
--------------------
In the normalized model (state x = W/P), the Bellman equation is:

    v(x, t) = u(c*(x,t)) + beta * pS[t+1] * E[(G*N)^(1-sigma) * v(x', t+1)]

The weight (G*N)^(1-sigma) differs from the Euler equation weight (G*N)^(-sigma)
used in solve_endgrid.py by exactly one factor of (G*N). This comes from the
fact that u(C) = P^(1-sigma) * u(c) while u'(C) = P^(-sigma) * u'(c).
"""
import numpy as np
from scipy.interpolate import interp1d


def compute_value(par, spa, x_end, c_end, alpha_end):
    """
    Backward pass to compute the normalized value function V(x, t).

    Parameters
    ----------
    par       : dict — must contain sigma, beta, T, T_ret, Rf, tau, Nnn, Nvv, NEta
    spa       : dict — must contain aa, G, pS, nn, vv, pN, pV, EtaEta
    x_end     : (Naa, T)  endogenous cash-on-hand grid from solve_endgrid
    c_end     : (Naa, T)  optimal consumption from solve_endgrid
    alpha_end : (Naa, T)  optimal equity share from solve_endgrid

    Returns
    -------
    V : (Naa, T)  normalized value function at the endogenous grid points x_end
    """
    sigma = par["sigma"]
    beta  = par["beta"]
    T     = par["T"]
    Naa   = par["Naa"]
    aa    = spa["aa"]   # (Naa,) savings grid
    start_age = par.get("start_age", 20)

    def u(c):
        if sigma == 1:
            return np.log(np.maximum(c, 1e-12))
        return np.maximum(c, 1e-12) ** (1 - sigma) / (1 - sigma)

    V = np.full((Naa, T), np.nan)

    # terminal period: consume everything, no continuation value
    V[:, T-1] = u(c_end[:, T-1])

    # track worst overshoot per period for diagnostics
    max_overshoot_t = np.zeros(T - 1)   # max(xp - grid_upper) at each t

    print("\nComputing value function (backward pass)...")
    for t in range(T-2, -1, -1):
        if t % 10 == 0:
            print(f"  period {t}")

        grid_upper = x_end[-1, t+1]
        grid_lower = x_end[0,  t+1]

        # interpolator for V_{t+1} on the endogenous grid at t+1
        # fill_value: below grid → use lowest known V; above grid → 0
        # (CRRA with sigma>1 has V→0 from below as x→∞, so 0 is the correct limit)
        interp_V = interp1d(x_end[:, t+1], V[:, t+1], kind="linear",
                            bounds_error=False,
                            fill_value=(V[0, t+1], 0.0))

        al_t   = alpha_end[:, t]   # (Naa,) optimal equity share at t
        ExpVal = np.zeros(Naa)

        if t + 1 < par["T_ret"]:
            # working life: integrate over permanent (N), transitory (V), and eta shocks
            for iN in range(par["Nnn"]):
                for iV in range(par["Nvv"]):
                    for iEta in range(par["NEta"]):
                        Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]
                        Rp = par["Rf"] * (1 - al_t) + Rs * al_t
                        xp = ((spa["G"][t+1] * spa["nn"][iN]) ** (-1)
                              * Rp * aa + spa["vv"][iV])
                        max_overshoot_t[t] = max(max_overshoot_t[t],
                                                 float(np.max(xp) - grid_upper),
                                                 float(grid_lower - np.min(xp)))

                        # VALUE FUNCTION weight: (G*N)^(1-sigma)
                        # differs from EGM Euler weight (G*N)^(-sigma) by one (G*N) factor
                        w  = (spa["pEta"][iEta] * spa["pN"][iN] * spa["pV"][iV]
                              * (spa["G"][t+1] * spa["nn"][iN]) ** (1 - sigma))

                        ExpVal += w * interp_V(xp)

        else:
            # retirement: only eta shock, G*N reduces to G (N=1 in retirement)
            for iEta in range(par["NEta"]):
                Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]
                Rp = par["Rf"] * (1 - al_t) + Rs * al_t
                xp = spa["G"][t+1] ** (-1) * Rp * aa + 1.0
                max_overshoot_t[t] = max(max_overshoot_t[t],
                                         float(np.max(xp) - grid_upper),
                                         float(grid_lower - np.min(xp)))
                w  = spa["pEta"][iEta] * spa["G"][t+1] ** (1 - sigma)
                ExpVal += w * interp_V(xp)

        V[:, t] = u(c_end[:, t]) + beta * spa["pS"][t+1] * ExpVal

    # ---- overshoot diagnostic ---------------------------------------
    worst_t   = int(np.argmax(max_overshoot_t))
    worst_val = max_overshoot_t[worst_t]
    grid_max  = x_end[-1, worst_t + 1]
    print(f"  max xp overshoot  : {worst_val:.1f}  at age {start_age + worst_t}  "
          f"(grid upper = {grid_max:.1f},  overshoot = {100*worst_val/grid_max:.0f}% of grid max)")

    print("...done")
    return V
