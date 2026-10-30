# FRE7241 Homework 1

**Panagiotis Housos · Algorithmic Portfolio Management · Fall 2026**

Historical stock/bond allocation using a paired block bootstrap, followed by
annual CAPM statistics and ETF alpha rankings. All eight assignment questions
are completed in R, with a compiled LaTeX report and reproducible result files.

**[Read the PDF report](report/Panagiotis_Housos_HW1_Report.pdf)** ·
[LaTeX source](report/Panagiotis_Housos_HW1_Report.tex) ·
[Completed R submission](Panagiotis_Housos_hw1.R) ·
[Verification results](hw1_results/verification.txt)

## Results

- Approximately ten-year optimal allocation: **45.4324% VTI / 54.5676% IEF**.
- Optimal VTI weights across the five requested holding blocks: **41.27%,
  35.97%, 41.61%, 45.88%, and 43.23%**. They are not monotonic in the horizon.
- Annualized alpha and ranking matrices: **8 ETFs × 21 intervals, 2006–2026**.
- 2008/2009 alpha correlation across the eight comparison ETFs: **−0.2393**.
- **10 independent checks passed**, including mathematical optimization and
  direct OLS checks across every annual interval.

![Optimized portfolio metric distributions](hw1_results/portf_wealth_longshort.png)

![ETF alpha scatterplot](hw1_results/scatter_etfs.png)

The report includes the methods, results and commentary for all eight tasks,
both requested figures, an additional allocation-by-horizon figure, complete
annual alpha/ranking matrices, all 21 CAPM tables, the full submitted R code,
the console record, and verification results. Individual scenario values and
data inputs are included in CSV/RDS files.

## Reproduce the analysis and report

The reference environment uses R 4.6.1, `rutils` 0.2,
`PerformanceAnalytics` 2.1.0, `RobStatTM` 1.0.11, and `png` 0.1-9.
A TeX distribution with `pdflatex` is needed to compile the report.

Run all commands from the repository root. First install missing R packages:

```sh
Rscript --vanilla setup.R
```

`setup.R` pins the two course GitHub packages to their recorded source
commits when installing them. Existing installations are retained. Exact
reference versions and dataset fingerprints are in
[`reproducibility/`](reproducibility/); other versions may produce differences.

On Windows, rebuild the results, verification record, metadata, and PDF with:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

To compile only the already-exported report:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1 -SkipAnalysis
```

Equivalent individual commands on any platform are:

```sh
Rscript --vanilla hw1_results/verify_hw1.R
Rscript --vanilla report/export_results.R
Rscript --vanilla reproducibility/record_environment.R
cd report
pdflatex -interaction=nonstopmode -halt-on-error Panagiotis_Housos_HW1_Report.tex
pdflatex -interaction=nonstopmode -halt-on-error Panagiotis_Housos_HW1_Report.tex
```

The original assignment itself can be run independently:

```sh
Rscript --vanilla Panagiotis_Housos_hw1.R
```

## Files

| Location | Contents |
| --- | --- |
| `Panagiotis_Housos_hw1.R` | Complete R submission with the original questions and solutions |
| `FRE7241_hw1.R` | Unmodified professor's template |
| Root PNG files | Unmodified professor's reference figures |
| `report/` | Compiled PDF, LaTeX source, export script, vector figures and generated tables |
| `hw1_results/` | Generated PNG figures, execution record, verification script and results |
| `hw1_results/tables/` | All scenarios, input subsets, annual CAPM tables, alpha/ranking matrices and RDS results |
| `reproducibility/` | Package source/version records, session information, data hashes and recording script |
| `setup.R`, `build.ps1` | Dependency setup and report build commands |

## Interpretation and recorded warning

The assignment's “wealth” measure is a **weighted cumulative log-return
metric**, not exact dollar buy-and-hold terminal wealth. A block with `h`
price observations spans `h - 1` return intervals. Historical bootstrap
draws are conditionally independent draws from a fixed set of overlapping
historical outcomes; they do not create new independent market histories.

The yearly CAPM windows include both neighboring endpoint observations,
following the assignment's explicit example, so they share boundary rows.
The supplied returns are daily log returns, and the requested package reports
annualized alpha using `(1 + daily_intercept)^252 - 1`. Alpha is a regression
intercept relative to VTI, not realized total return. The first and last years
are partial; large 2026 annualized values extrapolate the short final sample.

`table.CAPM()` produces one convergence warning for **VNQ's 2012 robust
downside-beta fit**. The solution retains that warning. The ordinary alphas,
betas, annualized alphas, rankings, and scatterplot are unaffected and were
independently verified. The warning is preserved in the verification record
and [`execution_warnings.txt`](hw1_results/tables/execution_warnings.txt).

The historical optimization is an in-sample academic exercise; it does not
evaluate future allocations or a predictive ETF-selection strategy.
