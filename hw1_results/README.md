# Homework 1 results

The submission is [`Panagiotis_Housos_hw1.R`](../Panagiotis_Housos_hw1.R).
Run it from the repository root:

```sh
Rscript --vanilla Panagiotis_Housos_hw1.R
```

The script requires `rutils`, `PerformanceAnalytics`, and `RobStatTM`. It saves
the two requested PNG plots in this directory. `execution_output.txt` contains
the console output captured during verification. The `tables/` directory holds
the report's CSV and RDS exports.

## Numerical checks

```sh
Rscript --vanilla hw1_results/verify_hw1.R
```

The ten checks cover output dimensions, paired bootstrap returns, the portfolio
objective, optimized weights, CAPM estimates, rankings, and plot files. The
optimization checks use asset means and covariance; the CAPM checks use direct
OLS regression. Results are saved in `verification.txt`.

## Data conventions

Holding blocks contain `holdp` price observations and span `holdp - 1` return
intervals. Starts are sampled with replacement from every valid block start,
using the same block for VTI and IEF. The objective is the negative mean of the
weighted cumulative log return divided by its standard deviation.

The CAPM calculations include both neighboring endpoint observations, as in the
assignment's `retsub` example. Adjacent windows share their boundary observation.
VTI is the benchmark; the eight other ETFs are ranked by the package's annualized
alpha, using 252 trading days.

`table.CAPM()` reports one convergence warning for VNQ's 2012 `Beta- Robust` fit.
This affects the robust downside-beta estimate. The ordinary alpha, beta,
annualized alpha, rankings, and scatterplot are unaffected. The warning is
recorded in `verification.txt` and `tables/execution_warnings.txt`.
