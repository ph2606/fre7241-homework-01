# Reference environment

- `package-versions.csv`: versions of the four direct packages and their
  dependencies, with GitHub commit metadata where available.
- `session-info.txt`: R version, platform, locale, and loaded namespaces.
- `data-manifest.csv`: symbols, preprocessing, dimensions, dates, source commit,
  and SHA-256 hashes for the assignment's input data subsets.

Data hashes use `serialize(object, NULL, version = 3)` and identify the R objects,
not the exported CSV files. The packaged `rutils::etfenv` data end on April 7,
2026; running the analysis does not download current market prices.

From the repository root, install missing packages with:

```sh
Rscript --vanilla setup.R
```

New installations of `rutils` and `PerformanceAnalytics` use the reference
GitHub commits. Existing installations are retained. CRAN package versions are
recorded without forcing changes to an existing library. These files describe
the reference environment rather than enforce a dependency lockfile.

To replace the records with the current environment and data fingerprints:

```sh
Rscript --vanilla reproducibility/record_environment.R
```

The recording script uses `digest`, a transitive dependency of the course
packages.
