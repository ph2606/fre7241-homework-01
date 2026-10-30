# Run from Homework_01: Rscript --vanilla hw1_results/verify_hw1.R
solution <- new.env(parent = globalenv())
warnings <- character()
execution <- withCallingHandlers(
  capture.output(source("Panagiotis_Housos_hw1.R", local = solution,
                        print.eval = TRUE)),
  warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
writeLines(execution, "hw1_results/execution_output.txt")

checks <- character()
check <- function(label, condition) {
  if (!isTRUE(condition)) stop("FAIL: ", label)
  checks <<- c(checks, paste("PASS:", label))
}

check("Return matrices and named horizon outputs have the required shapes",
      identical(dim(solution$retm), c(2L, 1000L)) &&
      all(vapply(solution$retl, function(x) {
        identical(dim(x), c(2L, 1000L)) &&
          identical(rownames(x), c("VTI", "IEF"))
      }, logical(1))) &&
      identical(names(solution$retl), names(solution$weightv)) &&
      identical(names(solution$retl), names(solution$wealthl)))

# Sum daily log returns to check the endpoint differences independently.
daily <- diff(solution$pricev)
reconstructed <- vapply(solution$startd, function(start) {
  colSums(daily[seq.int(start, start + solution$holdp - 2L), , drop = FALSE])
}, numeric(2))
check("Paired bootstrap returns equal sums of the underlying daily log returns",
      max(abs(reconstructed - solution$retm)) < 1e-12)

# Interior mean/SD weights are proportional to solve(covariance, mean).
moment_optimum <- function(returns) {
  mu <- rowMeans(returns)
  sigma <- cov(t(returns))
  tangent <- drop(solve(sigma, mu))
  stationary <- tangent[1] / sum(tangent)
  candidates <- c(0, 1, stationary)
  candidates <- candidates[is.finite(candidates) &
                             candidates >= 0 & candidates <= 1]
  scores <- vapply(candidates, function(w) {
    allocation <- c(w, 1 - w)
    sum(allocation * mu) / sqrt(drop(t(allocation) %*% sigma %*% allocation))
  }, numeric(1))
  candidates[which.max(scores)]
}

analytic_weights <- vapply(solution$retl, moment_optimum, numeric(1))
check("All five optimized weights agree with inverse-covariance calculations",
      max(abs(analytic_weights - solution$weightv)) < 1e-4)
tenyear <- optimize(solution$riskretfun, interval = c(0, 1),
                    retm = solution$retm)$minimum
check("Ten-year optimization agrees with the independent mathematical optimum",
      abs(tenyear - moment_optimum(solution$retm)) < 1e-4)

# Compare the risk function with moments of a separate sample.
synthetic <- rbind(c(-0.4, 0.1, 0.8, 0.3, -0.2),
                   c(0.2, 0.5, -0.1, 0.6, 0.3))
mu <- rowMeans(synthetic)
sigma <- cov(t(synthetic))
risk_errors <- vapply(c(0, 0.3, 1), function(w) {
  a <- c(w, 1 - w)
  expected <- -sum(a * mu) / sqrt(drop(t(a) %*% sigma %*% a))
  abs(solution$riskretfun(synthetic, w) - expected)
}, numeric(1))
check("Risk function agrees with the synthetic sample's moments",
      max(risk_errors) < 1e-12)

check("CAPM tables and alpha matrix have eight assets and one column per interval",
      all(vapply(solution$capml, is.data.frame, logical(1))) &&
      identical(dim(solution$alphav), c(8L, length(solution$endd) - 1L)) &&
      identical(rownames(solution$alphav), solution$symbolv[-1]) &&
      identical(colnames(solution$alphav), names(solution$capml)))

# Fit the same endpoint windows directly with OLS.
alpha_errors <- beta_errors <- intercept_errors <- numeric(length(solution$capml))
for (i in seq_along(solution$capml)) {
  rows <- seq.int(max(1L, solution$endd[i]), solution$endd[i + 1L])
  sample <- zoo::coredata(solution$retp[rows, ])
  fit <- lm.fit(cbind(Intercept = 1, VTI = sample[, "VTI"]),
                sample[, solution$symbolv[-1], drop = FALSE])
  coefficients <- fit$coefficients
  alpha <- (1 + coefficients[1, ])^252 - 1
  alpha_errors[i] <- max(abs(alpha - solution$alphav[, i]))
  intercept_errors[i] <- max(abs(coefficients[1, ] -
                                  unlist(solution$capml[[i]]["Alpha", ])))
  beta_errors[i] <- max(abs(coefficients[2, ] -
                             unlist(solution$capml[[i]]["Beta", ])))
}
rounding_tolerance <- 0.00005 + 1e-12
check("Every annualized alpha agrees with independent OLS regression",
      max(alpha_errors) <= rounding_tolerance)
check("Every CAPM intercept and beta agrees with independent OLS regression",
      max(intercept_errors, beta_errors) <= rounding_tolerance)

rankings_correct <- vapply(seq_len(ncol(solution$alphav)), function(i) {
  tickers <- solution$namev[, i]
  setequal(tickers, rownames(solution$alphav)) &&
    all(diff(solution$alphav[tickers, i]) <= 0)
}, logical(1))
check("Each year's ranking contains every ETF once in descending alpha order",
      all(rankings_correct))

plot_files <- file.path("hw1_results", c("portf_wealth_longshort.png", "scatter_etfs.png"))
check("Both generated PNG plots exist and have the requested dimensions",
      all(file.exists(plot_files)) &&
      all(vapply(plot_files, function(path) {
        identical(dim(png::readPNG(path))[1:2], c(1250L, 1500L))
      }, logical(1))))

summary <- c(
  checks,
  "",
  sprintf("All %d independent checks passed.", length(checks)),
  sprintf("Ten-year optimal VTI allocation: %.7f", tenyear),
  sprintf("Largest weight difference from analytic optimum: %.3g",
          max(abs(analytic_weights - solution$weightv))),
  sprintf("Largest annualized-alpha difference before rounding: %.3g",
          max(alpha_errors)),
  "",
  if (length(warnings)) c("Package warnings during execution:", unique(warnings)) else
    "No package warnings during execution."
)
writeLines(summary, "hw1_results/verification.txt")
cat(paste(summary, collapse = "\n"), "\n")
