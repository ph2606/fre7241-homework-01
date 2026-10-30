# Record the reference environment and fingerprints of the Homework 1 inputs.
# Run from the repository root: Rscript --vanilla reproducibility/record_environment.R
# This records the current environment; it does not install or update packages.

library(rutils)
library(PerformanceAnalytics)

required_packages <- c("rutils", "PerformanceAnalytics", "RobStatTM", "png")
stopifnot(all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)))
stopifnot(requireNamespace("digest", quietly = TRUE))
dir.create("reproducibility", showWarnings = FALSE)

installed <- utils::installed.packages()
dependencies <- tools::package_dependencies(
  required_packages,
  db = installed,
  which = c("Depends", "Imports", "LinkingTo"),
  recursive = TRUE
)
package_names <- sort(unique(c(required_packages, unlist(dependencies))))
package_names <- intersect(package_names, rownames(installed))

field <- function(description, name) {
  value <- description[[name]]
  if (is.null(value)) "" else as.character(value)
}
package_rows <- lapply(package_names, function(package) {
  description <- utils::packageDescription(package)
  data.frame(
    package = package,
    version = field(description, "Version"),
    repository = field(description, "Repository"),
    remote_type = field(description, "RemoteType"),
    remote_username = field(description, "RemoteUsername"),
    remote_repo = field(description, "RemoteRepo"),
    remote_ref = field(description, "RemoteRef"),
    remote_sha = field(description, "RemoteSha"),
    stringsAsFactors = FALSE
  )
})
utils::write.csv(
  do.call(rbind, package_rows),
  "reproducibility/package-versions.csv", row.names = FALSE
)

symbols <- c("VTI", "IEF", "VNQ", "USO", "XLY", "XLP", "XLE", "XLF", "XLK")
prices <- na.omit(rutils::etfenv$prices[, c("VTI", "IEF")])
raw_returns <- rutils::etfenv$returns[, symbols]
returns <- na.omit(zoo::na.locf(raw_returns))
data_objects <- list(
  part_i_prices = prices,
  part_i_log_prices = log(zoo::coredata(prices)),
  part_ii_returns_raw = raw_returns,
  part_ii_returns = returns
)
data_dates <- list(
  part_i_prices = zoo::index(prices),
  part_i_log_prices = zoo::index(prices),
  part_ii_returns_raw = zoo::index(raw_returns),
  part_ii_returns = zoo::index(returns)
)
preprocessing <- c(
  part_i_prices = 'na.omit(etfenv$prices[, c("VTI", "IEF")])',
  part_i_log_prices = "log(zoo::coredata(part_i_prices))",
  part_ii_returns_raw = "etfenv$returns[, symbols]",
  part_ii_returns = "na.omit(zoo::na.locf(part_ii_returns_raw))"
)
data_rows <- lapply(names(data_objects), function(name) {
  object <- data_objects[[name]]
  dates <- data_dates[[name]]
  data.frame(
    dataset = name,
    source = "rutils::etfenv",
    source_version = as.character(utils::packageVersion("rutils")),
    source_commit = field(utils::packageDescription("rutils"), "RemoteSha"),
    symbols = paste(colnames(object), collapse = ";"),
    preprocessing = preprocessing[[name]],
    rows = NROW(object),
    columns = NCOL(object),
    first_date = as.character(min(dates)),
    last_date = as.character(max(dates)),
    hash_method = "SHA-256 of R serialize(object, NULL, version = 3)",
    sha256 = digest::digest(
      serialize(object, NULL, version = 3),
      algo = "sha256", serialize = FALSE
    ),
    stringsAsFactors = FALSE
  )
})
utils::write.csv(
  do.call(rbind, data_rows),
  "reproducibility/data-manifest.csv", row.names = FALSE
)
writeLines(
  capture.output(utils::sessionInfo()),
  "reproducibility/session-info.txt"
)
cat("Recorded package versions, session information, and four input fingerprints.\n")
