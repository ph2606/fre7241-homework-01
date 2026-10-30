# Reproduce the submitted solution and export report tables and complete data.
# Run from Homework_01: Rscript --vanilla report/export_results.R
# The submitted solution and professor's originals are read without modification.

export_results <- function() {
  source_name <- "Panagiotis_Housos_hw1.R"
  if (!file.exists(source_name)) {
    file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
    if (length(file_arg) != 1L) stop("Run this script from the Homework_01 folder.")
    script_path <- normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
    task_root <- dirname(dirname(script_path))
  } else {
    task_root <- normalizePath(".", mustWork = TRUE)
  }
  old_dir <- getwd()
  old_options <- options(digits = 17)
  on.exit({ setwd(old_dir); options(old_options) }, add = TRUE)
  setwd(task_root)
  dir.create(file.path("report", "tables"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path("hw1_results", "tables"), recursive = TRUE,
             showWarnings = FALSE)
  tex_dir <- file.path("report", "tables")
  data_dir <- file.path("hw1_results", "tables")

  hw <- new.env(parent = globalenv())
  source_warnings <- character(0)
  capture.output(
    withCallingHandlers(
      source(source_name, local = hw, echo = FALSE, print.eval = TRUE),
      warning = function(w) {
        source_warnings <<- c(source_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    file = file.path(data_dir, "console_output.txt")
  )
  writeLines(if (length(source_warnings)) unique(source_warnings) else "None.",
             file.path(data_dir, "execution_warnings.txt"))

  # TeX tables contain only tabular material; the report owns captions/scaling.
  tex_escape <- function(x) {
    replacement <- c("\\" = "\\textbackslash{}", "&" = "\\&", "%" = "\\%",
                     "$" = "\\$", "#" = "\\#", "_" = "\\_",
                     "{" = "\\{", "}" = "\\}", "~" = "\\textasciitilde{}",
                     "^" = "\\textasciicircum{}")
    vapply(strsplit(as.character(x), "", fixed = TRUE), function(chars) {
      paste0(ifelse(chars %in% names(replacement), replacement[chars], chars),
             collapse = "")
    }, character(1), USE.NAMES = FALSE)
  }
  write_tex <- function(values, filename, row_labels = NULL,
                        row_header = "", digits = 4L) {
    values <- as.matrix(values)
    display <- if (is.numeric(values)) {
      matrix(formatC(values, format = "f", digits = digits), nrow = NROW(values),
             dimnames = dimnames(values))
    } else values
    if (is.null(colnames(display))) colnames(display) <- seq_len(NCOL(display))
    if (!is.null(row_labels)) {
      display <- cbind(row_labels, display)
      colnames(display)[1L] <- row_header
    }
    align <- paste0(if (!is.null(row_labels)) "l" else "", 
                    paste(rep("r", NCOL(values)), collapse = ""))
    lines <- c(paste0("\\begin{tabular}{", align, "}"), "\\toprule",
               paste0(paste(tex_escape(colnames(display)), collapse = " & "),
                      " \\\\"), "\\midrule")
    lines <- c(lines, apply(display, 1L, function(row) {
      paste0(paste(tex_escape(row), collapse = " & "), " \\\\")
    }), "\\bottomrule", "\\end{tabular}")
    writeLines(lines, file.path(tex_dir, filename), useBytes = TRUE)
  }
  write_csv <- function(values, filename, row_names = FALSE) {
    write.csv(values, file.path(data_dir, filename), row.names = row_names,
              na = "", fileEncoding = "UTF-8")
  }
  matrix_frame <- function(values, first_name = "ETF") {
    out <- data.frame(rownames(values), values, check.names = FALSE)
    names(out)[1L] <- first_name
    out
  }

  price_xts <- na.omit(rutils::etfenv$prices[, c("VTI", "IEF")])
  price_dates <- zoo::index(price_xts)
  return_dates <- zoo::index(hw$retp)
  ten_weight <- optimize(hw$riskretfun, interval = c(0, 1),
                         retm = hw$retm)$minimum
  ten_wealth_opt <- drop(c(ten_weight, 1 - ten_weight) %*% hw$retm)
  ten_risk_equal <- -hw$riskretfun(hw$retm, 0.5)
  ten_risk_opt <- -hw$riskretfun(hw$retm, ten_weight)

  ten_scenarios <- data.frame(
    simulation = seq_len(hw$nboot), start_row = hw$startd,
    end_row = hw$startd + hw$holdp - 1L,
    start_date = as.character(price_dates[hw$startd]),
    end_date = as.character(price_dates[hw$startd + hw$holdp - 1L]),
    VTI = hw$retm["VTI", ], IEF = hw$retm["IEF", ],
    wealth_equal_weight = hw$wealthv, wealth_optimal = ten_wealth_opt
  )
  write_csv(ten_scenarios, "ten_year_scenarios.csv")
  write_tex(hw$retm[, 1:5], "ten_year_returns_first5.tex",
            row_labels = rownames(hw$retm), row_header = "ETF", digits = 8)
  write_tex(matrix(hw$wealthv[1:5], nrow = 1L,
                   dimnames = list(NULL, paste0("Draw ", 1:5))),
            "wealth_first5.tex", row_labels = "Equal weight", digits = 8)
  write_tex(hw$retl[[1L]][, 1:5], "short_returns_first5.tex",
            row_labels = rownames(hw$retl[[1L]]), row_header = "ETF", digits = 8)
  write_tex(matrix(hw$wealthl[[1L]][1:5], nrow = 1L,
                   dimnames = list(NULL, paste0("Draw ", 1:5))),
            "short_wealth_first5.tex", row_labels = "Optimal", digits = 8)

  # Reconstruct each horizon's exact starts to audit dependence and block reuse.
  # Return intervals within an h-observation block have length L = h - 1.
  set.seed(1121, "Mersenne-Twister", sample.kind = "Rejection")
  starts_by_horizon <- lapply(hw$holdv, function(h) {
    sample.int(hw$nrows - h + 1L, size = hw$nboot, replace = TRUE)
  })
  names(starts_by_horizon) <- names(hw$retl)
  overlap_facts <- function(starts, h) {
    interval_length <- h - 1L
    nstarts <- hw$nrows - h + 1L
    distance <- abs(outer(starts, starts, "-"))
    distance <- distance[upper.tri(distance)]
    overlap <- pmax(0, interval_length - distance)
    no_overlap_starts <- max(nstarts - interval_length, 0)
    data.frame(
      block_observations = h,
      return_intervals = interval_length,
      possible_starts = nstarts,
      bootstrap_draws = length(starts),
      distinct_sampled_starts = length(unique(starts)),
      duplicate_draws = length(starts) - length(unique(starts)),
      sampled_pair_overlap_fraction = mean(overlap > 0),
      sampled_mean_overlap_fraction = mean(overlap / interval_length),
      population_pair_overlap_probability =
        1 - no_overlap_starts * (no_overlap_starts + 1) / nstarts^2,
      max_disjoint_return_blocks = floor((hw$nrows - 1L) / interval_length)
    )
  }
  overlap <- do.call(rbind, lapply(seq_along(hw$holdv), function(i) {
    overlap_facts(starts_by_horizon[[i]], hw$holdv[i])
  }))
  rownames(overlap) <- names(hw$retl)
  ten_overlap <- overlap_facts(hw$startd, hw$holdp)
  write_csv(cbind(horizon = rownames(overlap), overlap), "bootstrap_overlap.csv")
  write_csv(ten_overlap, "ten_year_overlap.csv")

  horizon_summary <- do.call(rbind, lapply(seq_along(hw$holdv), function(i) {
    h <- hw$holdv[i]
    r <- hw$retl[[i]]
    s <- starts_by_horizon[[i]]
    reconstructed <- t(hw$pricev[s + h - 1L, , drop = FALSE] -
                         hw$pricev[s, , drop = FALSE])
    stopifnot(isTRUE(all.equal(r, reconstructed)))
    wealth <- hw$wealthl[[i]]
    data.frame(horizon = names(hw$retl)[i], block_observations = h,
               return_intervals = h - 1L, years = (h - 1L) / 252,
               VTI_weight = unname(hw$weightv[i]),
               IEF_weight = 1 - unname(hw$weightv[i]),
               mean = mean(wealth), sd = sd(wealth), min = min(wealth),
               max = max(wealth), mean_over_sd = mean(wealth) / sd(wealth),
               VTI_IEF_correlation = cor(t(r))[1L, 2L])
  }))
  rownames(horizon_summary) <- NULL
  write_csv(horizon_summary, "horizon_summary.csv")

  # Vector graphics for the PDF report, independently of the source PNG device.
  figure_dir <- file.path("report", "figures")
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
  render_pdf <- function(filename, draw) {
    pdf(file.path(figure_dir, filename), width = 7.5, height = 5.4,
        family = "Helvetica", useDingbats = FALSE)
    on.exit(dev.off(), add = TRUE)
    par(mar = c(4.3, 4.3, 3.0, 1.3), las = 1)
    draw()
  }
  render_pdf("portf_wealth_longshort.pdf", function() {
    long <- density(hw$wealthl[[which.max(hw$holdv)]])
    short <- density(hw$wealthl[[which.min(hw$holdv)]])
    plot(long, col = "blue", lwd = 2.5,
         xlim = range(long$x, short$x), ylim = c(0, max(long$y, short$y)),
         main = "Wealth Distributions for Long and Short Holding Periods",
         cex.main = 0.95, xlab = "wealth (weighted cumulative log return)",
         ylab = "Density")
    lines(short, col = "green3", lwd = 2.5)
    legend("topright", legend = c("Long", "Short"),
           col = c("blue", "green3"), lwd = 3, bty = "n")
  })
  render_pdf("scatter_etfs.pdf", function() {
    alpha08 <- hw$alphav[, "2008"]
    alpha09 <- hw$alphav[, "2009"]
    plot(alpha08, alpha09, pch = 1, cex = 1.15,
         xlim = extendrange(alpha08, f = 0.23),
         ylim = extendrange(alpha09, f = 0.18),
         main = "Scatterplot of ETF alphas in 2008 and 2009",
         cex.main = 1.0, xlab = "2008 annualized alpha", ylab = "2009 annualized alpha")
    abline(h = 0, v = 0, col = "gray80", lty = 3)
    text(alpha08, alpha09, labels = rownames(hw$alphav), pos = 4, cex = 0.9)
  })
  render_pdf("optimal_weights_by_horizon.pdf", function() {
    plot(horizon_summary$years, horizon_summary$VTI_weight,
         type = "b", pch = 19, col = "blue3", lwd = 2,
         ylim = extendrange(horizon_summary$VTI_weight, f = 0.25),
         main = "Optimal VTI Weight Across Holding Periods", cex.main = 1.05,
         xlab = "Holding period ((block observations - 1) / 252 years)",
         ylab = "VTI portfolio weight")
    text(horizon_summary$years, horizon_summary$VTI_weight,
         labels = sprintf("%.4f", horizon_summary$VTI_weight), pos = 3, cex = 0.85)
  })
  summary_display <- data.frame(
    Years = sprintf("%.3f", horizon_summary$years),
    VTI = sprintf("%.6f", horizon_summary$VTI_weight),
    Mean = sprintf("%.6f", horizon_summary$mean),
    SD = sprintf("%.6f", horizon_summary$sd),
    Min = sprintf("%.6f", horizon_summary$min),
    Max = sprintf("%.6f", horizon_summary$max),
    `Mean/SD` = sprintf("%.4f", horizon_summary$mean_over_sd),
    check.names = FALSE
  )
  write_tex(summary_display, "horizon_summary.tex",
            row_labels = horizon_summary$block_observations, row_header = "Block obs.")
  overlap_display <- data.frame(
    `Possible starts` = overlap$possible_starts,
    `Distinct draws` = overlap$distinct_sampled_starts,
    `Overlap (percent)` = sprintf("%.3f", 100 * overlap$sampled_pair_overlap_fraction),
    `Mean shared (percent)` = sprintf("%.3f", 100 * overlap$sampled_mean_overlap_fraction),
    `Disjoint maximum` = overlap$max_disjoint_return_blocks,
    check.names = FALSE
  )
  write_tex(overlap_display, "bootstrap_overlap.tex",
            row_labels = hw$holdv, row_header = "Block obs.")

  for (i in seq_along(hw$holdv)) {
    h <- hw$holdv[i]
    s <- starts_by_horizon[[i]]
    scenario <- data.frame(
      simulation = seq_len(hw$nboot), start_row = s, end_row = s + h - 1L,
      start_date = as.character(price_dates[s]),
      end_date = as.character(price_dates[s + h - 1L]),
      VTI = hw$retl[[i]]["VTI", ], IEF = hw$retl[[i]]["IEF", ],
      portfolio_wealth = hw$wealthl[[i]]
    )
    write_csv(scenario, paste0(names(hw$retl)[i], "_scenarios.csv"))
  }

  # Preserve every statistic returned by table.CAPM, not only alpha/beta.
  for (year in names(hw$capml)) {
    capm <- hw$capml[[year]]
    write_csv(matrix_frame(as.matrix(capm), "Statistic"),
              paste0("capm_", year, ".csv"))
    write_tex(as.matrix(capm), paste0("capm_", year, ".tex"),
              row_labels = rownames(capm), row_header = "Statistic", digits = 4)
  }
  saveRDS(hw$capml, file.path(data_dir, "capm_full.rds"))
  write_tex(as.matrix(hw$capml[[1L]]), "capm_first_year.tex",
            row_labels = rownames(hw$capml[[1L]]), row_header = "Statistic", digits = 4)
  write_csv(matrix_frame(hw$alphav), "annualized_alphas.csv")
  write_csv(data.frame(Rank = seq_len(NROW(hw$namev)), hw$namev,
                       check.names = FALSE), "yearly_rankings.csv")
  for (span in list(2006:2016, 2017:2026)) {
    years <- intersect(as.character(span), colnames(hw$alphav))
    suffix <- paste0(min(span), "_", max(span), ".tex")
    write_tex(hw$alphav[, years, drop = FALSE], paste0("alphas_", suffix),
              row_labels = rownames(hw$alphav), row_header = "ETF", digits = 4)
    write_tex(hw$namev[, years, drop = FALSE], paste0("rankings_", suffix),
              row_labels = seq_len(NROW(hw$namev)), row_header = "Rank")
  }
  scatter <- data.frame(ETF = rownames(hw$alphav),
                         alpha_2008 = hw$alphav[, "2008"],
                         alpha_2009 = hw$alphav[, "2009"])
  scatter_correlation <- cor(scatter$alpha_2008, scatter$alpha_2009)
  same_sign <- sum(sign(scatter$alpha_2008) == sign(scatter$alpha_2009))
  write_csv(scatter, "scatter_alphas_2008_2009.csv")
  write_tex(as.matrix(scatter[, -1L]), "scatter_alphas_2008_2009.tex",
            row_labels = scatter$ETF, row_header = "ETF", digits = 4)

  windows <- do.call(rbind, lapply(seq_along(hw$capml), function(i) {
    first <- max(1L, hw$endd[i])
    last <- hw$endd[i + 1L]
    rows <- seq.int(first, last)
    year <- names(hw$capml)[i]
    data.frame(year = year, start_row = first, end_row = last,
               start_date = as.character(return_dates[first]),
               end_date = as.character(return_dates[last]),
               observations = length(rows),
               observations_in_named_year =
                 sum(format(return_dates[rows], "%Y") == year),
               shared_previous_boundary = i > 1L)
  }))
  write_csv(windows, "annual_windows.csv")
  write_tex(windows[, c("start_date", "end_date", "observations",
                         "observations_in_named_year")], "annual_windows.tex",
            row_labels = windows$year, row_header = "Year")
  end_points <- data.frame(endpoint_number = seq_along(hw$endd),
                            row = hw$endd,
                            date = c(NA_character_,
                                     as.character(return_dates[hw$endd[-1L]])))
  write_csv(end_points, "year_endpoints.csv")
  retsub_frame <- data.frame(Date = as.character(zoo::index(hw$retsub)),
                             zoo::coredata(hw$retsub), check.names = FALSE)
  write_csv(retsub_frame, "last_window_returns.csv")
  write_tex(as.matrix(zoo::coredata(head(hw$retsub))), "last_window_head.tex",
            row_labels = as.character(zoo::index(head(hw$retsub))),
            row_header = "Date", digits = 8)
  write_tex(as.matrix(zoo::coredata(tail(hw$retsub))), "last_window_tail.tex",
            row_labels = as.character(zoo::index(tail(hw$retsub))),
            row_header = "Date", digits = 8)
  write_csv(data.frame(Date = as.character(price_dates),
                       zoo::coredata(price_xts), check.names = FALSE),
             "input_prices_VTI_IEF.csv")
  write_csv(data.frame(Date = as.character(return_dates),
                       zoo::coredata(hw$retp), check.names = FALSE),
             "input_returns_CAPM.csv")

  all_results <- list(
    ten_year_returns = hw$retm, ten_year_starts = hw$startd,
    ten_year_wealth_equal_weight = hw$wealthv,
    ten_year_wealth_optimal = ten_wealth_opt, ten_year_optimal_weight = ten_weight,
    holding_observations = hw$holdv, starts_by_horizon = starts_by_horizon,
    returns_by_horizon = hw$retl, optimal_weights = hw$weightv,
    wealth_by_horizon = hw$wealthl, horizon_summary = horizon_summary,
    bootstrap_overlap = overlap, ten_year_overlap = ten_overlap,
    CAPM = hw$capml, annualized_alphas = hw$alphav, rankings = hw$namev,
    endpoints = hw$endd, annual_windows = windows, last_window_returns = hw$retsub,
    scatter_correlation = scatter_correlation,
    prices_VTI_IEF = price_xts, returns_CAPM = hw$retp,
    execution_warnings = source_warnings
  )
  saveRDS(all_results, file.path(data_dir, "all_results.rds"))
  writeLines(capture.output(sessionInfo()), file.path(data_dir, "session_info.txt"))

  last_window <- windows[NROW(windows), ]
  last_alphas <- sort(hw$alphav[, NCOL(hw$alphav)], decreasing = TRUE)
  macro <- c(
    HWPriceRows = as.character(hw$nrows), HWReturnRows = as.character(NROW(hw$retp)),
    HWBootSamples = as.character(hw$nboot), HWCapmYears = as.character(length(hw$capml)),
    HWPriceStart = as.character(min(price_dates)), HWPriceEnd = as.character(max(price_dates)),
    HWReturnStart = as.character(min(return_dates)), HWReturnEnd = as.character(max(return_dates)),
    HWTenYearWeight = sprintf("%.7f", ten_weight),
    HWEqualRiskRatio = sprintf("%.6f", ten_risk_equal),
    HWOptimalRiskRatio = sprintf("%.6f", ten_risk_opt),
    HWAlphaCorrelation = sprintf("%.6f", scatter_correlation),
    HWAlphaSignSameCount = as.character(same_sign),
    HWAlphaSignChangedCount = as.character(NROW(scatter) - same_sign),
    HWFirstWindowRows = as.character(windows$observations[1L]),
    HWLastWindowRows = as.character(last_window$observations),
    HWLastYearActualRows = as.character(last_window$observations_in_named_year),
    HWLastWindowStart = last_window$start_date, HWLastWindowEnd = last_window$end_date,
    HWLastTopETF = names(last_alphas)[1L],
    HWLastTopAlpha = sprintf("%.4f", last_alphas[1L]),
    HWTenYearAvailableBlocks = as.character(ten_overlap$possible_starts),
    HWTenYearOverlapPct = sprintf("%.3f", 100 * ten_overlap$sampled_pair_overlap_fraction),
    HWTenYearMeanOverlapPct = sprintf("%.3f", 100 * ten_overlap$sampled_mean_overlap_fraction),
    HWTenYearDisjointBlocks = as.character(ten_overlap$max_disjoint_return_blocks)
  )
  macro_lines <- paste0("\\newcommand{\\", names(macro), "}{", tex_escape(macro), "}")
  writeLines(c("% Generated by report/export_results.R; do not edit numerical results.",
               macro_lines), file.path("report", "results_macros.tex"), useBytes = TRUE)
  write_csv(data.frame(name = names(macro), value = unname(macro)), "numerical_macros.csv")
  message("Exported ", length(hw$capml), " complete CAPM tables, all simulation data, ",
          "and report tables to ", normalizePath(tex_dir), ".")
  message("2008/2009 alpha correlation: ", sprintf("%.8f", scatter_correlation))
  if (length(source_warnings)) {
    message("Source warnings preserved in hw1_results/tables/execution_warnings.txt: ",
            paste(unique(source_warnings), collapse = "; "))
  }
  invisible(all_results)
}

export_results()
