# Homework 1 — Panagiotis Housos

Submit `../Panagiotis_Housos_hw1.R`. All 18 code placeholders across the eight
questions are completed. The original assignment and reference images remain
unchanged.

From the `Homework_01` folder, run:

```powershell
Rscript --vanilla Panagiotis_Housos_hw1.R
```

Required R packages are `rutils`, `PerformanceAnalytics`, and `RobStatTM`.
The missing `RobStatTM` package and its dependencies were installed locally.
The submission uses the assignment's packaged `rutils::etfenv` data.

The generated plots are `portf_wealth_longshort.png` and `scatter_etfs.png`
in this results folder. `execution_output.txt` contains the calculated output.

## Conventions

- Part I follows the lecture's convention that a holding block contains
  `holdp` price observations, spanning `holdp - 1` return intervals. Sampling
  includes every valid block start, with replacement, and uses the same block
  for VTI and IEF. “Wealth” is the weighted cumulative log-return quantity used
  in the assignment. The objective is its negative mean divided by standard
  deviation, minimized with `optimize()` over weights from zero to one.
- Part II includes both neighboring endpoint observations, as explicitly
  illustrated by the assignment's `retsub` example. Adjacent intervals therefore
  share their boundary observation. VTI is the benchmark, excluded from the
  eight comparison ETFs, and annualization uses 252 trading days.

## Verification

Run `Rscript --vanilla hw1_results/verify_hw1.R` from `Homework_01` to reproduce
the checks. All **10 checks passed**, including independent inverse-covariance
optimal-weight calculations and direct OLS verification of all years' alpha,
beta, and annualized alpha values. See `verification.txt` for the results.
Both generated plots were also visually inspected.

`table.CAPM()` emits one convergence warning for VNQ's 2012 **Beta- Robust**
fit. This concerns the robust downside-beta estimate. Ordinary alpha/beta,
annualized alpha, rankings, and the scatterplot are unaffected and independently
verified. The submitted code retains the package warning; it does not suppress
or replace the requested calculation.

## Course-folder review

The review covered the complete course inventory, both syllabi, all 21 lecture
PDFs, readings/reference guides, code examples, setup files, and dataset
structures. All 14 R data archives were loaded and inspected; the text tables,
identifiers, and workbook were also inspected. All 171 original course files
were checked against their recorded SHA-256 hashes and remain unchanged.

Available PDF text was extracted and surveyed across the folder. The homework's
relevant sections were read in detail, including `strategies_univariate.pdf`
slides 14–19, the bootstrap and optimization materials, R functionals and
time-series indexing, and CAPM examples. All substantive code-example sources
were read. The large textbooks were reviewed through their contents and
relevant sections, not cover to cover; the two media videos were inventoried
but not watched, and scanned/garbled PDF text limited some unrelated readings.
