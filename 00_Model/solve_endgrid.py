"""
solve_endgrid.py  -  replicates portfolio_fin_solveEndGrid.m
Endogenous Grid Point Method.
"""
import numpy as np
from scipy.interpolate import interp1d


def solve_endgrid(par, spa, f_MU, f_MUinv):
    Naa    = par["Naa"]
    Nalal  = par["Nalal"]
    T      = par["T"]
    aa     = spa["aa"]          # (Naa,)
    alal   = spa["alal"]        # (Nalal,)

    c     = np.full((Naa, T), np.nan)
    x     = np.full((Naa, T), np.nan)
    alpha = np.full((Naa, T), np.nan)

    # terminal period
    x_last = np.linspace(0.01, 30, Naa)
    x[:, T-1] = x_last
    c[:, T-1] = x_last

    ALPHAgrid, Agrid = np.meshgrid(alal, aa, indexing="ij")   # (Nalal, Naa)

    print("\nEndogenous Grid Point Method...")
    for t in range(T-2, -1, -1):
        if t % 10 == 0:
            print(f"  period {t}")

        x_next = np.concatenate([[0.0], x[:, t+1]])
        c_next = np.concatenate([[0.0], c[:, t+1]])
        interp_c = interp1d(x_next, c_next, kind="linear",
                            bounds_error=False, fill_value="extrapolate")

        # ---- Step 1: optimal equity share alpha(aa) ------------------
        ExpVal_al = np.zeros((Nalal, Naa))

        # working life
        if t+1 < par["T_ret"]:
            for iN in range(par["Nnn"]):
                for iV in range(par["Nvv"]):
                    for iEta in range(par["NEta"]):

                        # equity return  (uses group-specific tau from par)
                        Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]

                        # portfolio return
                        Rp = par["Rf"] * (1 - ALPHAgrid) + Rs * ALPHAgrid

                        # next year cash-on-hand possibility (5)
                        xp = ((spa["G"][t+1] * spa["nn"][iN]) ** (-1)
                              * Rp * Agrid + spa["vv"][iV])

                        # tomorrow's optimal c from policy matrix
                        cp = interp_c(xp)

                        # joint probability weight
                        w  = (spa["pEta"][iEta] * spa["pN"][iN] * spa["pV"][iV]
                              # normalization
                              * (spa["G"][t+1] * spa["nn"][iN]) ** (-par["sigma"]))

                        # (17) calculating that expected value
                        ExpVal_al += w * f_MU(cp) * (Rs - par["Rf"])

        # pension life
        else:
            for iEta in range(par["NEta"]):
                Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]
                Rp = par["Rf"] * (1 - ALPHAgrid) + Rs * ALPHAgrid
                xp = spa["G"][t+1] ** (-1) * Rp * Agrid + 1.0
                cp = interp_c(xp)
                w  = spa["pEta"][iEta] * spa["G"][t+1] ** (-par["sigma"])
                ExpVal_al += w * f_MU(cp) * (Rs - par["Rf"])

        gothic_V_alpha = Agrid * ExpVal_al   # (Nalal, Naa)

        alpha_ind     = np.argmin(np.abs(gothic_V_alpha), axis=0)  # (Naa,)
        alpha[:, t]   = alal[alpha_ind]

        # --- fix noisy alpha at near-zero savings ----------------------------
        G_next = spa["G"][t+1] if t + 1 < len(spa["G"]) else 1.0
        aa_thresh = 3.0 if G_next > 1.05 else 0.5
        first_stable = np.searchsorted(aa, aa_thresh)
        if first_stable < Naa:
            if t < par["T_ret"]:          # working life: HC makes 100% equity correct
                alpha[:first_stable, t] = 1.0
            else:                          # retirement: no HC, copy first stable (as before)
                alpha[:first_stable, t] = alpha[first_stable, t]
        # ---------------------------------------------------------------------


        # ---- Step 2: marginal value of assets aa ---------------------
        ExpVal = np.zeros(Naa)

        al_t   = alpha[:, t]    # (Naa,)

        if t+1 < par["T_ret"]:
            for iN in range(par["Nnn"]):
                for iV in range(par["Nvv"]):
                    for iEta in range(par["NEta"]):
                        Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]
                        Rp = par["Rf"] * (1 - al_t) + Rs * al_t
                        xp = ((spa["G"][t+1] * spa["nn"][iN]) ** (-1)
                              * Rp * aa + spa["vv"][iV])
                        cp = interp_c(xp)
                        w  = (spa["pEta"][iEta] * spa["pN"][iN] * spa["pV"][iV]
                              * (spa["G"][t+1] * spa["nn"][iN]) ** (-par["sigma"]))
                        ExpVal += w * Rp * f_MU(cp)
        else:
            for iEta in range(par["NEta"]):
                Rs = par["Rf"] + par["tau"] + spa["EtaEta"][iEta]
                Rp = par["Rf"] * (1 - al_t) + Rs * al_t
                xp = spa["G"][t+1] ** (-1) * Rp * aa + 1.0
                cp = interp_c(xp)
                w  = spa["pEta"][iEta] * spa["G"][t+1] ** (-par["sigma"])
                ExpVal += w * Rp * f_MU(cp)

        gothic_V = par["beta"] * spa["pS"][t+1] * ExpVal

        # ---- Step 3: recover consumption and cash-on-hand ------------
        c[:, t] = f_MUinv(gothic_V)
        x[:, t] = c[:, t] + aa

    print("...done")

    # aa is a vector, rest are matrices
    return x, c, aa, alpha
