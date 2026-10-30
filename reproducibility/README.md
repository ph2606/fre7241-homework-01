These files record the environment used to execute and verify Homework 1.

- `package-versions.csv` records the four direct packages and their installed
  dependency closure, including GitHub commit metadata when available.
- `session-info.txt` records the R version, operating system, and loaded namespaces.
- `data-manifest.csv` fingerprints only the ETF subsets used by this assignment,
  before and after preprocessing. It records dimensions, dates, symbols, the
  source `rutils` commit, and SHA-256 hashes of R version-3 serialized objects.
  These hashes identify the recorded R objects; they are not hashes of CSV files.

The ETF observations are supplied by the pinned `rutils` package. No account
credentials, live downloads of market prices, or unrelated course datasets are
required. The reference data end on April 7, 2026.

From the repository root, run `Rscript --vanilla setup.R` to install missing
packages. Existing installations are retained. The two course GitHub packages
are pinned to the reference commits for new installations; CRAN package versions
and their dependencies are recorded rather than forced on an existing library.
Consequently, this is an environment record, not a complete dependency lockfile.

To replace these records with a snapshot of the current environment, run
`Rscript --vanilla reproducibility/record_environment.R`. This uses `digest`,
which is already a transitive dependency of the course packages.
