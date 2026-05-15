"""
runs.py  —  All simulation configurations live here.

This is the only file you need to edit between runs.

HOW TO USE
──────────────────────────────────────────────────────────────────────────────
1. Edit SELECTED_RUNS to choose which simulation(s) to run:
       SELECTED_RUNS = ["benchmark_econ_vs_primary"]   # just one
       SELECTED_RUNS = None                            # everything in RUNS

2. Press F5 in Spyder (or `python main.py` on the server).

Each run is a plain dict.  Keys explained at the top of the RUNS list.
──────────────────────────────────────────────────────────────────────────────

KEY REFERENCE
─────────────────────────────────────────────────────────────────────────────
  name          unique ID string; also the output sub-folder name
  tags          list of strings shown in the dashboard
  mode          "two_group" | "benchmark"

  For each group suffix _g1, _g2 (and _g3 for benchmark):
    income_g*     income path:          "econ" | "masters" | "primary"
    var_n_g*      permanent variance:   "ECON" | "MASTERS" | "PRIMARY"
    var_v_g*      transitory variance:  "ECON" | "MASTERS" | "PRIMARY"
    tau_educ_g*   own-educ row in risk-premia table:    "econ"|"master"|"primary"
    tau_parent_g* parent col in risk-premia table:      "econ"|"master"|"primary"|"avg"
    repl_g*       [optional] replacement rate — string label OR raw number:
                    "econ"|"master"|"primary"  → uses calibrated value
                    0.75                       → uses that number directly
                  Takes priority over repl_educ_g* when both are present.
    repl_educ_g*  [optional] whose repl rate to use;   defaults to tau_educ_g*
                  use to decouple replacement rate from the risk-premium row
    a0_educ_g*    own-educ key in WIR-at-25 table:     "econ"|"master"|"primary"
    a0_parent_g*  parent key in WIR-at-25 table:       "econ"|"master"|"primary"|"avg"|"median"

  plots         [optional] dict overriding which figures to produce for this run
─────────────────────────────────────────────────────────────────────────────
"""

# ── Which run(s) to execute ────────────────────────────────────────────────
# Set to a list of name strings to run only those.
# Set to None to run everything in RUNS.
# All run names listed in run_names.txt (same folder) — copy-paste from there.
SELECTED_RUNS = [
"benchmark_econ_vs_primary"
]

# Default figure switches — override per-run with plots={...}
DEFAULT_PLOTS = dict(
    policy_functions     = True,
    lifecycle_profiles   = True,
    human_capital_wealth = True,
    wealth_to_income     = True,
    welfare_panel        = True,
    income_equity_slide  = True,
)

RUNS = [

    # ══════════════════════════════════════════════════════════════════════════
    # BENCHMARK  —  full Econ (2,2) vs full Primary (0,0)
    # ══════════════════════════════════════════════════════════════════════════


    dict(
        name="benchmark_econ_vs_primary", tags=["Consumption Equivalent"],
        mode="two_group",

        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
 


        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",


    ),
    # ══════════════════════════════════════════════════════════════════════════
    # BASELINE  —   three groups side by side, all with avg parents 
    # ══════════════════════════════════════════════════════════════════════════

    dict(
        name="baseline_overview", tags=["Baseline"],
        mode="benchmark",

        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="avg",
        a0_educ_g1="econ",   a0_parent_g1="avg",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="avg",
        a0_educ_g2="master", a0_parent_g2="avg",

        income_g3="primary", var_n_g3="PRIMARY", var_v_g3="PRIMARY",
        tau_educ_g3="primary", tau_parent_g3="avg",
        a0_educ_g3="primary", a0_parent_g3="avg",

        plots=dict(policy_functions=True, lifecycle_profiles=False,
                   human_capital_wealth=False, wealth_to_income=False,
                   welfare_panel=False),
    ),

    # Econ (avg parents) vs Masters (avg parents)
    dict(
        name="baseline_econ_avg_vs_masters_avg", tags=["Baseline"],
        mode="two_group",

        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="avg",
        a0_educ_g1="econ",   a0_parent_g1="avg",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="avg",
        a0_educ_g2="master", a0_parent_g2="avg",
    ),

    # Masters (avg parents) vs Primary (avg parents)
    dict(
        name="baseline_masters_avg_vs_primary_avg", tags=["Baseline"],
        mode="two_group",

        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="avg",
        a0_educ_g1="master", a0_parent_g1="avg",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="avg",
        a0_educ_g2="primary", a0_parent_g2="avg",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DECOMPOSITION  —  step-by-step from (0,0) toward (2,2)
    #
    # G2 is always fixed at pure (0,0) primary.
    # G1 accumulates one more econ characteristic each step.
    # CE gain = cumulative welfare value of all channels added so far.
    # Marginal effect of each channel = CE(Dn) - CE(Dn-1).
    #
    # Order: uncertainty →  rate → income path → a0 → own tau → parent tau
    # Perm and trans variance are combined into one "uncertainty" step since
    # transitory variance contributes ~0% on its own.
    # ══════════════════════════════════════════════════════════════════════════

    # D1 — Income uncertainty (perm + trans variance, primary income)
    dict(
        name="decomp_D1_uncertainty", tags=["Decomposition"],
        mode="two_group",
        income_g1="primary", var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="primary", tau_parent_g1="primary",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D2 — + replacement rate
    dict(
        name="decomp_D2_repl_rate", tags=["Decomposition"],
        mode="two_group",
        income_g1="primary", var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="econ",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D3 — + income path
    dict(
        name="decomp_D3_income", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="econ",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D4 — + starting assets
    dict(
        name="decomp_D4_a0", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D5 — + own risk premium
    dict(
        name="decomp_D5_own_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="primary",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D6 — + parental risk premium  →  full (2,2) vs (0,0)
    dict(
        name="decomp_D6_parent_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DECOMPOSITION  —  step-by-step from (0,0) toward (1,1)
    #
    # G2 is always fixed at pure (0,0) primary.
    # G1 accumulates one more masters characteristic each step.
    # Order: uncertainty → repl rate → income path → a0 → own tau → parent tau
    # ══════════════════════════════════════════════════════════════════════════

    # D1_01 — Income uncertainty
    dict(
        name="decomp_01_D1_uncertainty", tags=["Decomposition"],
        mode="two_group",
        income_g1="primary", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="primary", tau_parent_g1="primary",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D2_01 — + replacement rate
    dict(
        name="decomp_01_D2_repl_rate", tags=["Decomposition"],
        mode="two_group",
        income_g1="primary", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="master",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D3_01 — + income path
    dict(
        name="decomp_01_D3_income", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="master",
        a0_educ_g1="primary", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D4_01 — + starting assets
    dict(
        name="decomp_01_D4_a0", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="primary", tau_parent_g1="primary",
        repl_educ_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D5_01 — + own risk premium
    dict(
        name="decomp_01_D5_own_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="primary",
        repl_educ_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # D6_01 — + parental risk premium  →  full (1,1) vs (0,0)
    dict(
        name="decomp_01_D6_parent_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="master",
        repl_educ_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # DECOMPOSITION  —  step-by-step from (1,1) toward (2,2)
    #
    # G2 is always fixed at pure (1,1) masters.
    # G1 accumulates one more econ characteristic each step.
    # Order: uncertainty → repl rate → income path → a0 → own tau → parent tau
    # ══════════════════════════════════════════════════════════════════════════

    # D1_12 — Income uncertainty
    dict(
        name="decomp_12_D1_uncertainty", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="master", tau_parent_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # D2_12 — + replacement rate
    dict(
        name="decomp_12_D2_repl_rate", tags=["Decomposition"],
        mode="two_group",
        income_g1="masters", var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="master", tau_parent_g1="master",
        repl_educ_g1="econ",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # D3_12 — + income path
    dict(
        name="decomp_12_D3_income", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="master", tau_parent_g1="master",
        repl_educ_g1="econ",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # D4_12 — + starting assets
    dict(
        name="decomp_12_D4_a0", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="master", tau_parent_g1="master",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # D5_12 — + own risk premium
    dict(
        name="decomp_12_D5_own_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="master",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # D6_12 — + parental risk premium  →  full (2,2) vs (1,1)
    dict(
        name="decomp_12_D6_parent_tau", tags=["Decomposition"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        repl_educ_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # WELFARE  —  pairwise comparisons matching the CE bar chart
    #
    # CE captures the risk-premium (tau) gain for G2 if it had G1's tau.
    # Income/var/a0 set the baseline welfare level for each group.
    # ══════════════════════════════════════════════════════════════════════════

    # (0,0) vs (0,2) — parental channel, own edu = primary
    dict(
        name="welfare_00_vs_02", tags=["Welfare"],
        mode="two_group",
        income_g1="primary", var_n_g1="PRIMARY", var_v_g1="PRIMARY",
        tau_educ_g1="primary", tau_parent_g1="econ",
        a0_educ_g1="primary", a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # (0,0) vs (2,0) — own education channel, parents = primary
    dict(
        name="welfare_00_vs_20", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="primary",
        a0_educ_g1="econ",   a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # (2,0) vs (2,2) — parental channel, own edu = econ
    dict(
        name="welfare_20_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="econ",    var_n_g2="ECON",    var_v_g2="ECON",
        tau_educ_g2="econ",  tau_parent_g2="primary",
        a0_educ_g2="econ",   a0_parent_g2="primary",
    ),

    # (0,2) vs (2,2) — own education channel, parents = econ
    dict(
        name="welfare_02_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="econ",
        a0_educ_g2="primary", a0_parent_g2="econ",
    ),

    # (0,0) vs (2,2) — both channels: total gap
    dict(
        name="welfare_00_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # WELFARE  —  Primary (0) vs Masters (1) comparisons
    # ══════════════════════════════════════════════════════════════════════════

    # (0,0) vs (0,1) — parental channel, own edu = primary
    dict(
        name="welfare_00_vs_01", tags=["Welfare"],
        mode="two_group",
        income_g1="primary", var_n_g1="PRIMARY", var_v_g1="PRIMARY",
        tau_educ_g1="primary", tau_parent_g1="master",
        a0_educ_g1="primary", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # (0,0) vs (1,0) — own education channel, parents = primary
    dict(
        name="welfare_00_vs_10", tags=["Welfare"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="primary",
        a0_educ_g1="master", a0_parent_g1="primary",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # (1,0) vs (1,1) — parental channel, own edu = masters
    dict(
        name="welfare_10_vs_11", tags=["Welfare"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="primary",
        a0_educ_g2="master", a0_parent_g2="primary",
    ),

    # (0,1) vs (1,1) — own education channel, parents = masters
    dict(
        name="welfare_01_vs_11", tags=["Welfare"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="master",
        a0_educ_g2="primary", a0_parent_g2="master",
    ),

    # (0,0) vs (1,1) — both channels: primary → masters total gap
    dict(
        name="welfare_00_vs_11", tags=["Welfare"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="master",
        a0_educ_g1="master", a0_parent_g1="master",

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # WELFARE  —  Masters (1) vs Econ (2) comparisons
    # ══════════════════════════════════════════════════════════════════════════

    # (1,1) vs (1,2) — parental channel, own edu = masters
    dict(
        name="welfare_11_vs_12", tags=["Welfare"],
        mode="two_group",
        income_g1="masters", var_n_g1="MASTERS", var_v_g1="MASTERS",
        tau_educ_g1="master", tau_parent_g1="econ",
        a0_educ_g1="master", a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # (1,1) vs (2,1) — own education channel, parents = masters
    dict(
        name="welfare_11_vs_21", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="master",
        a0_educ_g1="econ",   a0_parent_g1="master",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # (2,1) vs (2,2) — parental channel, own edu = econ
    dict(
        name="welfare_21_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="econ",    var_n_g2="ECON",    var_v_g2="ECON",
        tau_educ_g2="econ",  tau_parent_g2="master",
        a0_educ_g2="econ",   a0_parent_g2="master",
    ),

    # (1,2) vs (2,2) — own education channel, parents = econ
    dict(
        name="welfare_12_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="econ",
        a0_educ_g2="master", a0_parent_g2="econ",
    ),

    # (1,1) vs (2,2) — both channels: masters → econ total gap
    dict(
        name="welfare_11_vs_22", tags=["Welfare"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",

        income_g2="masters", var_n_g2="MASTERS", var_v_g2="MASTERS",
        tau_educ_g2="master", tau_parent_g2="master",
        a0_educ_g2="master", a0_parent_g2="master",
    ),

    # ══════════════════════════════════════════════════════════════════════════
    # POLICY  —  Replacement rate analysis
    #
    # G1 = Econ (2,2),  G2 = Primary (0,0)  — all other parameters fixed.
    # Repl_2 = econ group replacement rate (repl_g1)
    # Repl_0 = primary group replacement rate (repl_g2)
    #
    # Homogeneous: both groups get the same rate
    # Heterogeneous: primary keeps higher rate, econ gets lower rate
    # ══════════════════════════════════════════════════════════════════════════

    # ── Homogeneous ───────────────────────────────────────────────────────────
    dict(
        name="policy_repl_homo_05", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.5,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.5,
    ),

    dict(
        name="policy_repl_homo_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.9,
    ),

    dict(
        name="policy_repl_homo_08", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.8,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.8,
    ),

    dict(
        name="policy_repl_homo_07", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.7,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.7,
    ),

    dict(
        name="policy_repl_homo_06", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.6,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.6,
    ),

    # ── Heterogeneous ─────────────────────────────────────────────────────────
    dict(
        name="policy_repl_hetero_09_08", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.8,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.9,
    ),

    dict(
        name="policy_repl_hetero_09_07", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.7,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.9,
    ),

    dict(
        name="policy_repl_hetero_09_06", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.6,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.9,
    ),

    # ── Heterogeneous inverted (econ keeps higher rate) ───────────────────────
    dict(
        name="policy_repl_hetero_inv_085_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.85,
    ),

    dict(
        name="policy_repl_hetero_inv_08_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.8,
    ),

    dict(
        name="policy_repl_hetero_inv_075_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.75,
    ),

    dict(
        name="policy_repl_hetero_inv_07_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.7,
    ),

    dict(
        name="policy_repl_hetero_inv_065_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.65,
    ),

    dict(
        name="policy_repl_hetero_inv_06_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.6,
    ),

    dict(
        name="policy_repl_hetero_09_05", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.5,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.9,
    ),

    dict(
        name="policy_repl_hetero_inv_055_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.55,
    ),

    dict(
        name="policy_repl_hetero_inv_05_09", tags=["Policy"],
        mode="two_group",
        income_g1="econ",    var_n_g1="ECON",    var_v_g1="ECON",
        tau_educ_g1="econ",  tau_parent_g1="econ",
        a0_educ_g1="econ",   a0_parent_g1="econ",
        repl_g1=0.9,

        income_g2="primary", var_n_g2="PRIMARY", var_v_g2="PRIMARY",
        tau_educ_g2="primary", tau_parent_g2="primary",
        a0_educ_g2="primary", a0_parent_g2="primary",
        repl_g2=0.5,
    ),

]










































