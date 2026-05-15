import os
import numpy as np
import pandas as pd
from pathlib import Path

# --- Path switcher (auto-detects server vs laptop, override with FORCE_ENV) --
FORCE_ENV = None   # set to "server" or "laptop" to force an environment

_LAPTOP_DATA = Path(r"C:\Users\olsha\CBS - Copenhagen Business School\Patrick Natarajan Larsen - Thesis\05_Data\02_ Reference Data - PLEASE BE CAREFUL TO TOUCH")

if FORCE_ENV == "server" or (FORCE_ENV is None and Path("/work/Home").exists()):
    DATA_DIR     = Path("/work/Home/01_thesis/data")
    masters_path = str(DATA_DIR / "masters - deterministic income path - 4-29-2026.csv")
    primary_path = str(DATA_DIR / "primary - deterministic income path - 4-29-2026.csv")
    econ_path    = str(DATA_DIR / "econ masters - deterministic income path - 4-29-2026.csv")
else:
    DATA_DIR     = _LAPTOP_DATA
    masters_path = str(DATA_DIR / "masters - deterministic income path - 4-29-2026.csv")
    primary_path = str(DATA_DIR / "primary - deterministic income path - 4-29-2026.csv")
    econ_path    = str(DATA_DIR / "econ masters - deterministic income path - 4-29-2026.csv")
# -----------------------------------------------------------------------------


def create_the_G(csv_path, T_ret, start_age=None):
    df = pd.read_csv(csv_path)

    if start_age is not None and "Age" in df.columns:
        first_age = int(df.loc[0, "Age"])
        if first_age != start_age:
            raise ValueError(
                f"{csv_path} starts at age {first_age}, expected age {start_age}."
            )

    df = df.iloc[:T_ret].copy()

    for i in range(T_ret):
        if i == 0:
            df.loc[i, "G_work"] = df.loc[i, "Income"] / 1000.0   # DKK -> thousands of DKK
        else:
            df.loc[i, "G_work"] = df.loc[i, "Income"] / df.loc[i - 1, "Income"]

    G_work = np.array(df["G_work"])

    return G_work


G_masters = create_the_G(masters_path, T_ret=40)
G_primary = create_the_G(primary_path, T_ret=40)
G_econ    = create_the_G(econ_path,    T_ret=40)
