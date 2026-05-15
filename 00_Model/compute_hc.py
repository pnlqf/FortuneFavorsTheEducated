"""
compute_hc.py — Survival-weighted PDV of remaining labour income (human capital).

Human capital at period t is the present value of all future labour income the
agent expects to receive, discounted at the risk-free rate and weighted by
cumulative survival probabilities.  After retirement HC = 0.

Backward recursion (efficient, no nested loops over agents):
    HC[:, T_ret-1] = Y[:, T_ret-1]
    HC[:, t]       = Y[:, t] + pS[t+1] / (1+rf) * HC[:, t+1]
"""
import numpy as np


def compute_human_capital(Y, pS, rf):
    """
    Parameters
    ----------
    Y  : ndarray (I, T)  Realised income (labour + pension), denormalised (1,000 DKK).
    pS : ndarray (T+1,)  Period survival probabilities (spa["pS"]).
    rf : float           Risk-free rate (par["rf"]).

    Returns
    -------
    mean_HC : ndarray (T,)  Cross-sectional mean HC at each period.
              Includes pension income after retirement so HC declines
              smoothly to zero only at end of life (consistent with Cocco 2005).
    """
    I, T = Y.shape
    HC = np.zeros((I, T))

    disc = 1.0 / (1.0 + rf)

    for t in range(T - 1, -1, -1):
        if t == T - 1:
            HC[:, t] = Y[:, t]
        else:
            HC[:, t] = Y[:, t] + pS[t + 1] * disc * HC[:, t + 1]

    return HC.mean(axis=0)
