# Install the packages needed for Homework 1 and its verification script.
# Run from the repository root with: Rscript --vanilla setup.R
# Existing installations are retained; reference versions are recorded under
# reproducibility/. Only the two course GitHub packages have pinned commits.

options(repos = c(CRAN = "https://cloud.r-project.org"))

github_packages <- c(
  rutils = "algoquant/rutils@131a2b9b950c35a9ad48aee05444f76244ab0616",
  PerformanceAnalytics = paste0(
    "braverock/PerformanceAnalytics@",
    "c079aea14727f68b5bfcc1e90292ceeb8a1f22e7"
  )
)
cran_packages <- c("RobStatTM", "png")
is_installed <- function(package) requireNamespace(package, quietly = TRUE)

missing_github <- names(github_packages)[
  !vapply(names(github_packages), is_installed, logical(1))
]
if (length(missing_github) > 0L) {
  if (!is_installed("remotes")) {
    install.packages("remotes")
  }
  for (package in missing_github) {
    remotes::install_github(
      github_packages[[package]],
      dependencies = NA,
      upgrade = "never",
      build_vignettes = FALSE
    )
  }
}

missing_cran <- cran_packages[
  !vapply(cran_packages, is_installed, logical(1))
]
if (length(missing_cran) > 0L) {
  # Prefer precompiled Windows packages, including RobStatTM and its dependencies.
  package_type <- if (.Platform$OS.type == "windows") "binary" else "source"
  install.packages(missing_cran, type = package_type)
}

required_packages <- c(names(github_packages), cran_packages)
stopifnot(all(vapply(required_packages, is_installed, logical(1))))
cat("Homework 1 packages are available:\n")
print(vapply(required_packages, function(package) {
  as.character(utils::packageVersion(package))
}, character(1)))
