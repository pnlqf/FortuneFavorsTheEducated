import os
import numpy as np
import pandas as pd
from pathlib import Path

# --- Path switcher (auto-detects server vs laptop, override with FORCE_ENV) --
FORCE_ENV = None   # set to "server" or "laptop" to force an environment

_LAPTOP_DATA = Path(r"C:\Users\olsha\CBS - Copenhagen Business School\Patrick Natarajan Larsen - Thesis\05_Data\02_ Reference Data - PLEASE BE CAREFUL TO TOUCH")

if FORCE_ENV == "server" or (FORCE_ENV is None and Path("/work/Home").exists()):
    DATA_DIR = Path("/work/Home/01_thesis/data")
    csv_path = str(DATA_DIR / "equity_shares - 5-2-2026.csv")
else:
    DATA_DIR = _LAPTOP_DATA
    csv_path = str(DATA_DIR / "equity_shares - 5-2-2026.csv")
# -----------------------------------------------------------------------------

data = pd.read_csv(csv_path)


def calc_risk_premia(var_equity, sigma, b_1, df_e_share):

    df_e_premium = pd.DataFrame(columns=["risk_premium_avg"])

    df_e_premium["my_educ"] = df_e_share["my_educ"]

    df_e_premium["risk_premium_avg"]     = df_e_share["parent_avg"]     * var_equity * sigma * b_1
    df_e_premium["risk_premium_primary"] = df_e_share["parent_primary"] * var_equity * sigma * b_1
    df_e_premium["risk_premium_master"]  = df_e_share["parent_master"]  * var_equity * sigma * b_1
    df_e_premium["risk_premium_econ"]    = df_e_share["parent_econ"]    * var_equity * sigma * b_1

    return df_e_premium
