"""
grids_functions.py  -  replicates portfolio_fin_getGridFcts.m
"""
import numpy as np
from numpy.polynomial.hermite import hermgauss
from make_income_growth import create_the_G, masters_path


def _curved_grid(n, lo, hi, spacing):
    g = np.empty(n)
    g[0] = lo
    for i in range(1, n):
        g[i] = g[i-1] + (hi - g[i-1]) / ((n - i) ** spacing)
    return g


def get_grids_and_functions(par, G_work=None):
    spa = {}

    # discount factor & gross risk-free rate
    par["Rf"] = 1.0 + par["rf"]

    # utility functions
    sigma = par["sigma"]
    if sigma == 1:
        f_U = lambda c: np.log(c)
    else:
        f_U = lambda c: c ** (1 - sigma) / (1 - sigma)

    f_MU    = lambda c: c ** (-sigma)
    f_MUinv = lambda c: c ** (-1.0 / sigma)

    sp = par["spacing"]
    spa["ss"]   = _curved_grid(par["Nss"], 0.0,   700.0, sp) # not used
    spa["bb"]   = _curved_grid(par["Nbb"], 0.0,   700.0, sp) # not used
    aa_inner    = _curved_grid(par["Naa"]-1, 0.005, 700.0, sp)

    # end of period investment
    spa["aa"]   = np.concatenate([[0.0], aa_inner])

    # equity share
    spa["alal"] = np.linspace(0.0, 1.0, par["Nalal"])

    # cash on hand
    spa["xx"]   = _curved_grid(par["Nxx"], 0.01, 800.0, sp)

    # income growth profile
    if G_work is None:
        G_work = create_the_G(
            masters_path,
            T_ret=par["T_ret"],
            start_age=par.get("start_age"),
        )

    G_ret = np.ones(par["T"] - par["T_ret"])

    # implementing the replacement rate
    G_ret[0] = par["repl_rate"]

    spa["G"] = np.concatenate([G_work, G_ret])   # length T

    # survival probabilities
    if par["ind_lifeRisky"] == 1:
        # Death rates (ages 0–98), Danish mortality data
        pD = np.array([
            0.00347847, 0.00021882, 0.00014330, 0.00008785, 0.00007991,  # 0–4
            0.00008155, 0.00007742, 0.00005786, 0.00007177, 0.00006790,  # 5–9
            0.00006489, 0.00008177, 0.00006433, 0.00007121, 0.00009065,  # 10–14
            0.00014788, 0.00017763, 0.00019221, 0.00026634, 0.00030063,  # 15–19
            0.00033751, 0.00035983, 0.00035018, 0.00039537, 0.00042413,  # 20–24
            0.00039963, 0.00045161, 0.00042489, 0.00050312, 0.00051271,  # 25–29
            0.00056446, 0.00056571, 0.00059353, 0.00060271, 0.00065683,  # 30–34
            0.00074788, 0.00079917, 0.00080899, 0.00086658, 0.00099850,  # 35–39
            0.00112376, 0.00112709, 0.00128205, 0.00132047, 0.00165314,  # 40–44
            0.00180706, 0.00195296, 0.00217362, 0.00250122, 0.00277399,  # 45–49
            0.00313178, 0.00345735, 0.00379325, 0.00424691, 0.00484022,  # 50–54
            0.00528759, 0.00579635, 0.00639989, 0.00688322, 0.00751708,  # 55–59
            0.00812454, 0.00904268, 0.00978537, 0.01049856, 0.01132980,  # 60–64
            0.01242589, 0.01364279, 0.01455259, 0.01613289, 0.01734977,  # 65–69
            0.01933677, 0.02067440, 0.02294782, 0.02640258, 0.02836122,  # 70–74
            0.03194539, 0.03523812, 0.03949314, 0.04397540, 0.04916655,  # 75–79
            0.05514296, 0.06177230, 0.07003253, 0.07909278, 0.08681083,  # 80–84
            0.09625473, 0.10793633, 0.12351766, 0.13689367, 0.15180570,  # 85–89
            0.17236873, 0.19264426, 0.21707235, 0.24002930, 0.26400742,  # 90–94
            0.29050533, 0.32531781, 0.35399503, 0.37878207,              # 95–98
            1.0])                                                          # 99 (terminal)
        age_offset = par.get("start_age", 20) - par.get("mortality_table_start_age", 20)
        if age_offset < 0:
            raise ValueError("start_age cannot be below mortality_table_start_age.")
        if age_offset + par["T"] + 1 > len(pD):
            raise ValueError("Mortality table is too short for the chosen start_age and T.")
        spa["pS"] = 1.0 - pD[age_offset:age_offset + par["T"] + 1]
    else:
        spa["pS"] = np.ones(par["T"] + 1)

    # Gauss-Hermite for income shocks
    # mu_N and mu_V are the mean-correction terms for lognormal shocks
    # (ensures E[N] = 1 and E[V] = 1)
    par["mu_N"] = -par["var_N"] / 2.0
    par["mu_V"] = -par["var_V"] / 2.0
    nodes_h, weights_h = hermgauss(par["Nyy"])
    w = weights_h / np.sqrt(np.pi)
    spa["pN"] = w
    spa["pV"] = w
    spa["nn"] = np.exp(np.sqrt(2*par["var_N"])*nodes_h + par["mu_N"])
    spa["vv"] = np.exp(np.sqrt(2*par["var_V"])*nodes_h + par["mu_V"])
    par["Nvv"] = par["Nyy"]
    par["Nnn"] = par["Nyy"]

    # Gauss-Hermite for stock-return shocks
    par["mu_Eta"] = 0.0
    nodes_e, weights_e = hermgauss(par["NEta"])
    spa["pEta"]   = weights_e / np.sqrt(np.pi)
    spa["EtaEta"] = np.sqrt(2*par["var_Eta"])*nodes_e

    return spa, par, f_U, f_MU, f_MUinv

# x - single value or vector of a variable
# xx - the GRID of that value, e.g. spa["xx"]
# Nxx - NUMBER OF GRID POINTS, e.g. par["Nxx"] = 210
