#################################
### FRE7241 Homework #1 due at 6PM Tuesday November 3
#################################
# Max score 80pts

# Please write in this file the R code needed to perform 
# the tasks below, rename it to your_name_hw1.R,
# and upload the file to Brightspace

# Student: Panagiotis Housos
# Figures are saved in hw1_results/.

############## Part I
# Summary: Calculate the optimal weights for a portfolio 
# of stocks and bonds, to maximize the risk-adjusted 
# wealth, for different holding periods.

# Disclaimer: 
# The comments and conclusions below are based on 
# 20 years of very positive stock and bond returns, 
# when stocks and bonds have both been in a secular 
# bull market.
# The conclusions would not hold if stocks and bonds 
# had suffered from a bear market (losses).

## Run all the setup code below

library(rutils)
# Coerce the log prices from xts time series to matrix 
pricev <- na.omit(rutils::etfenv$prices[, c("VTI", "IEF")])
pricev <- log(zoo::coredata(pricev))
nrows <- NROW(pricev)


## End of setup code


# 1. (10pts)
# Sample the start dates for the bootstrap.
# Run the code below.

# A block contains holdp prices and spans holdp - 1 return intervals.
holdp <- 10 * 252
nboot <- 1000
set.seed(1121, "Mersenne-Twister", sample.kind = "Rejection")
# There are nrows - holdp + 1 valid starting rows.
startd <- sample.int(nrows - holdp + 1L, size = nboot, replace = TRUE)


# Calculate a matrix of 1000 simulated VTI and IEF returns,
# for the 10 year holding period.

retm <- t(pricev[startd + holdp - 1L, , drop = FALSE] -
          pricev[startd, , drop = FALSE])


# You should get the outputs:
dim(retm)
# [1] 2 1000
retm[, 1:5]
#         [,1]      [,2]      [,3]      [,4]     [,5]
# VTI 1.3889156 1.1463289 0.7314036 1.5094435 1.11841720
# IEF 0.4327528 0.1021709 0.5198690 0.2757054 0.08607574


# Specify the weight for VTI.
# Run the code below.

weightv <- 0.5

# Calculate the vector of wealths for retm and weightv.
# You can use the functions drop(), c(), and the %*% operator.

# Wealth is measured as a weighted cumulative log return.
wealthv <- drop(c(weightv, 1 - weightv) %*% retm)


# You should get the outputs:
is.vector(wealthv)
# TRUE
NROW(wealthv)
# [1] 1000
wealthv[1:5]
# [1] 0.9108342 0.6242499 0.6256363 0.8925745 0.6022465


# 2. (10pts)
# Define a risk-adjusted wealth function, which accepts
# two arguments: retm and weightv, and returns the
# negative of the risk-adjusted wealth value.

riskretfun <- function(retm, weightv) {
  wealthv <- drop(c(weightv, 1 - weightv) %*% retm)
  -mean(wealthv) / sd(wealthv)
}


# You should get the output:
riskretfun(retm, weightv)
# [1] -6.934682

# Calculate the optimal VTI weight using the function
# optimize() and the function riskretfun().

weightv <- optimize(riskretfun, interval = c(0, 1), retm = retm)$minimum


# You should get the output:
weightv
# [1] 0.4543241


# 3. (10pts)
# Define a vector of holding periods.
# Run the code below.

holdv <- round(nrows * seq(0.1, 0.5, 0.1))


# Calculate a named list of 1000 simulated VTI and 
# IEF returns, one for each holding period in holdv.

set.seed(1121, "Mersenne-Twister", sample.kind = "Rejection")

retl <- lapply(holdv, function(holdp) {
  startd <- sample.int(nrows - holdp + 1L, size = nboot, replace = TRUE)
  t(pricev[startd + holdp - 1L, , drop = FALSE] -
    pricev[startd, , drop = FALSE])
})
names(retl) <- paste0("hold", holdv)


# You should get the outputs:
NROW(retl)
# [1] 5
class(retl)
# [1] "list"
names(retl)
# [1] "hold596"  "hold1192" "hold1789" "hold2385" "hold2981"
dim(retl[[1]])
# [1] 2 1000
# You should get output similar to:
retl[[1]][, 1:5]
#         [,1]       [,2]       [,3]       [,4]      [,5]
# VTI 0.26369527 0.3695579 0.1482638  0.2195997 0.2832994
# IEF 0.09298308 0.2352719 0.1463518 -0.2017072 0.2119880

# Your values may be slightly different, because
# they're from a simulation.

# Calculate a named vector of optimal VTI weights,
# for each holding period in holdv.
# Hint: Perform an sapply() loop over the list retl.
# You must use the function optimize().

weightv <- sapply(retl, function(retm) {
  optimize(riskretfun, interval = c(0, 1), retm = retm)$minimum
})


# You should get output similar to:
weightv
#   hold596  hold1192  hold1789  hold2385  hold2981 
# 0.4127018 0.3597272 0.4160783 0.4588359 0.4322657 

# Your values may be slightly different, because
# they're from a simulation.

# Note that the optimal VTI weights increase with
# longer holding periods.
# Except for the shortest holding period, which is
# large.
# This may be because of higher correlations between 
# stocks and bonds for very short holding periods.

# The final weight also falls, from 0.4588 to 0.4323, in this sample.


# 4. (10pts)
# Calculate a list of portfolio wealths, for each 
# holding period in holdv.
# Hint: Perform an lapply() loop over names(retl).

wealthl <- lapply(names(retl), function(name) {
  weight <- weightv[[name]]
  drop(c(weight, 1 - weight) %*% retl[[name]])
})
names(wealthl) <- names(retl)


# You should get the outputs:
NROW(wealthl)
# [1] 5
class(wealthl)
# [1] "list"
is.vector(wealthl[[1]])
# [1] TRUE
# You should get output similar to:
wealthl[[1]][1:5]
# [1]  0.16343630  0.29069195  0.14714087 -0.02783308  0.24141838


# Plot the distributions of the portfolio wealths,
# for the shortest and longest holding periods.

# Your plot should be similar to portf_wealth_longshort.png

denslong <- density(wealthl[[which.max(holdv)]])
densshort <- density(wealthl[[which.min(holdv)]])
dir.create("hw1_results", showWarnings = FALSE)
png(file.path("hw1_results", "portf_wealth_longshort.png"),
    width = 1500, height = 1250, res = 160)
plot(denslong, col = "blue", lwd = 3,
     xlim = range(denslong$x, densshort$x),
     ylim = c(0, max(denslong$y, densshort$y)),
     main = "Wealth Distributions for Long and Short Holding Periods",
     cex.main = 1.1, xlab = "wealth", ylab = "Density")
lines(densshort, col = "green", lwd = 3)
legend("topright", legend = c("Long", "Short"),
       col = c("blue", "green"), lwd = 6, bty = "n", inset = 0.05)
invisible(dev.off())


############## Part II
# Summary: Calculate a matrix of the best performing ETFs
# in each year.  Create a scatterplot of alphas for the
# years 2008 and 2009.

## Run the setup code below

library(rutils)
library(PerformanceAnalytics)
symbolv <- c("VTI", "IEF", "VNQ", "USO", "XLY", "XLP", "XLE", "XLF", "XLK")
retp <- rutils::etfenv$returns[, symbolv]
retp <- na.omit(zoo::na.locf(retp))

## End of setup code.


# 1. (10pts)
# Create a vector of yearly end points of the returns.
# You can use the function rutils::calc_endpoints().

endd <- rutils::calc_endpoints(retp, interval = "years")


# You should get the output:
endd
#  [1]    0  183  434  687  939 1191 1443 1693 1945 2197 2449 2701 2952 3203 3455 3708
# [17] 3960 4211 4461 4713 4963 5028

# Select the returns for the symbolv, and for the dates between 
# the last two end points.
# You can use the function NROW().

# Include both endpoint rows, as in the supplied retsub example.
retsub <- retp[seq.int(endd[NROW(endd) - 1L], endd[NROW(endd)]), symbolv]


# You should get the outputs:
head(retsub)
#                     VTI           IEF           VNQ          USO          XLY
# 2025-12-31 -0.0076658326 -0.0033222622 -0.0082156784 -0.008351380 -0.007924302
# 2026-01-02  0.0030971763 -0.0008322930  0.0003389639 -0.002896034 -0.008916614
# 2026-01-05  0.0074946659  0.0030137721  0.0022568279  0.018106544  0.016342287
# 2026-01-06  0.0069701039 -0.0007266311  0.0072997124 -0.024653451  0.006380268
# 2026-01-07 -0.0034054579  0.0018674142 -0.0097825034 -0.010565029 -0.001405133
# 2026-01-08  0.0002646319 -0.0030103308  0.0088869475  0.039765233  0.016569980
#                     XLP          XLE          XLF           XLK
# 2025-12-31 -0.006032233 -0.005576015 -0.007457970 -0.0099523940
# 2026-01-02  0.000128725  0.020806417  0.002917049  0.0022895212
# 2026-01-05 -0.004385972  0.026800826  0.021610782  0.0022151470
# 2026-01-06  0.001550188 -0.027019908  0.004798730  0.0139391827
# 2026-01-07 -0.011032625 -0.011237311 -0.014106117 -0.0008186098
# 2026-01-08  0.023475862  0.030979790  0.005201339 -0.0157516068
tail(retsub)
#                     VTI           IEF         VNQ          USO           XLY
# 2026-03-30 -0.0045136687  0.0070574897 0.003785928  0.044332733 -0.0001892685
# 2026-03-31  0.0288720271  0.0017828121 0.015565843 -0.020072247  0.0309379874
# 2026-04-01  0.0075460338 -0.0008682939 0.003601174 -0.025146547  0.0074961499
# 2026-04-02  0.0016074192  0.0023121398 0.013500902  0.105666698 -0.0151413767
# 2026-04-06  0.0044686269 -0.0026278462 0.001439726  0.007368378  0.0081956350
# 2026-04-07  0.0006762572  0.0025228648 0.001437656 -0.006208958 -0.0117154608
#                     XLP          XLE         XLF          XLK
# 2026-03-30  0.001222046 -0.009637081 0.011438203 -0.018802512
# 2026-03-31  0.001220554 -0.011361914 0.020669927  0.041480601
# 2026-04-01 -0.006363213 -0.038098261 0.001416861  0.015010924
# 2026-04-02  0.005264781  0.004736940 0.001818733  0.007973464
# 2026-04-06  0.009358926  0.007231176 0.007041574  0.005792442
# 2026-04-07 -0.017081919  0.008010724 0.000000000  0.004740901

# Perform an lapply() loop over the neighboring end points 
# of endd.
# Inside the loop, select the returns for the symbolv and
# the neighboring end points.  
# Then for the selected returns, calculate a data frame of 
# statistics using table.CAPM(), and using VTI as the 
# benchmark asset "Rb".
# Simplify the column names and return the data frame.
# The output should be a list of data frames. 
# You can use the functions lapply(), sapply(), 
# PerformanceAnalytics::table.CAPM(), colnames(), 
# strsplit(), NROW(), and an anonymous function.
# You don't need to use all of these functions.
# You can use any functions you choose.
# If you're getting an error when running table.CAPM(), 
# then install the package RobStatTM:
#   install.packages("RobStatTM")

capml <- lapply(seq_len(NROW(endd) - 1L), function(i) {
  # The first endpoint is zero; subsequent windows share the year-end row.
  rows <- seq.int(max(1L, endd[i]), endd[i + 1L])
  retsub <- retp[rows, symbolv]
  capm <- PerformanceAnalytics::table.CAPM(
    Ra = retsub[, symbolv[-1]], Rb = retsub[, "VTI"], Rf = 0, scale = 252
  )
  colnames(capm) <- sub(" to .*$", "", colnames(capm))
  capm
})

# You should get the outputs:
is.list(capml)
# [1] TRUE
capml[[1]]
#                         IEF    VNQ     USO    XLY    XLP     XLE    XLF     XLK
# Alpha                0.0003 0.0007 -0.0016 0.0002 0.0004 -0.0004 0.0003 -0.0002
# Beta                 0.0326 0.9094  0.0865 0.9956 0.5466  1.2493 0.9259  1.1092
# Alpha Robust         0.0003 0.0006 -0.0015 0.0003 0.0005 -0.0001 0.0002 -0.0002
# Beta Robust          0.0523 0.9582  0.0881 0.9822 0.5670  1.2525 0.8963  1.1390
# Beta+                0.0831 0.8206  0.6261 1.0077 0.3818  1.4792 0.8758  1.0898
# Beta-                0.0188 0.6517  0.0731 0.9016 0.6239  1.5042 0.9472  0.9853
# Beta+ Robust         0.0868 0.8887  0.6261 0.9673 0.3920  1.4617 0.8617  1.0265
# Beta- Robust         0.0639 0.7227  0.0835 0.8966 0.6247  1.5130 0.9279  1.0427
# R-squared            0.0069 0.4583  0.0015 0.7497 0.4770  0.3022 0.7175  0.7213
# R-squared Robust     0.0183 0.4976  0.0015 0.7283 0.4658  0.3144 0.6502  0.7006
# Annualized Alpha     0.0689 0.1926 -0.3242 0.0632 0.1090 -0.0886 0.0769 -0.0604
# Correlation          0.0832 0.6770  0.0383 0.8658 0.6906  0.5498 0.8471  0.8493
# Correlation p-value  0.2631 0.0000  0.6064 0.0000 0.0000  0.0000 0.0000  0.0000
# Tracking Error       0.1144 0.1089  0.2668 0.0631 0.0801  0.2099 0.0642  0.0765
# Active Premium      -0.0577 0.1957 -0.4673 0.0684 0.0550 -0.0928 0.0739 -0.0578
# Information Ratio   -0.5040 1.7976 -1.7512 1.0842 0.6870 -0.4421 1.1511 -0.7553
# Treynor Ratio        2.2196 0.3582 -3.8978 0.1993 0.3385  0.0298 0.2203  0.0651

# Assign names to the list using the years corresponding to the endd.
# You can use the functions names(), format() with the "%Y" format, 
# and zoo::index(),

names(capml) <- format(zoo::index(retp)[endd[-1L]], "%Y")


# You should get the outputs:
names(capml)
#  [1] "2006" "2007" "2008" "2009" "2010" "2011" "2012" "2013" "2014" "2015" "2016"
# [12] "2017" "2018" "2019" "2020" "2021" "2022" "2023" "2024" "2025" "2026"


# 2. (10pts)
# Perform an sapply() loop over "capml".
# Inside the loop extract the data frame row called
# "Annualized Alpha", coerce it to a vector using unlist(),
# and return the vector.
# You can use the functions sapply(), unlist(),
# and an anonymous function,

alphav <- sapply(capml, function(capm) {
  unlist(capm["Annualized Alpha", ])
})


# alphav should be a matrix of annual alphas like this:
dim(alphav)
# [1]  8 21
alphav
#       2006    2007    2008    2009    2010    2011    2012    2013    2014    2015    2016
# IEF  0.0689  0.1137  0.1205 -0.0488  0.1229  0.1639  0.0790 -0.0470  0.1114  0.0152  0.0290
# VNQ  0.1926 -0.2144  0.2848 -0.2019  0.0418  0.0730  0.0489 -0.2262  0.2165  0.0116 -0.0101
# USO -0.3242  0.4603 -0.4475 -0.0128 -0.1545 -0.0072 -0.2647 -0.1209 -0.4477 -0.4537 -0.0814
# XLY  0.0632 -0.1814  0.0540  0.0706  0.0763  0.0481  0.0654  0.0602 -0.0286  0.1013 -0.0575
# XLP  0.1090  0.0921  0.0858  0.0086  0.0341  0.1348  0.0166  0.0090  0.0800  0.0608 -0.0252
# XLE -0.0886  0.2754  0.0866 -0.0996  0.0129  0.0183 -0.1196 -0.0710 -0.1912 -0.2141  0.1115
# XLF  0.0769 -0.2474 -0.0868 -0.3040 -0.0766 -0.1798  0.0701 -0.0409  0.0257 -0.0217  0.0622
# XLK -0.0604  0.1025 -0.1060  0.2115 -0.0430  0.0164 -0.0115 -0.0142  0.0523  0.0502  0.0123
#       2017    2018    2019    2020    2021    2022    2023    2024    2025    2026
# IEF  0.0726  0.0061  0.1485  0.1170 -0.0249 -0.1376  0.0253 -0.0185  0.0827 -0.0016
# VNQ -0.0382 -0.0305  0.1478 -0.2243  0.1978 -0.1146 -0.1366 -0.0936 -0.0465  0.1760
# USO -0.0468 -0.1623  0.0594 -0.7307  0.3353  0.3262 -0.1133  0.1058 -0.1417  9.9429
# XLY  0.0249  0.0743 -0.0200  0.0799 -0.0163 -0.1583  0.0398 -0.0272 -0.1046 -0.2319
# XLP  0.0350 -0.0508  0.1040 -0.0376  0.0715  0.1145 -0.1125  0.0687 -0.0189  0.2001
# XLE -0.1553 -0.1372 -0.1606 -0.4797  0.1888  0.8886 -0.1496 -0.0440 -0.0361  2.0778
# XLF -0.0530 -0.0856 -0.0047 -0.2174  0.0957  0.0810 -0.1099  0.1168  0.0100 -0.2248
# XLK  0.0696  0.0545  0.0496  0.1615  0.0111 -0.0488  0.1940 -0.1167  0.0062 -0.0094

# 3. (10pts)
# Sort the last column of alphav in descending order, 
# and extract the ETF names.
# You can use the functions names(), sort(), and NCOL().

names(sort(alphav[, NCOL(alphav)], decreasing = TRUE))


# You should get the output:
# [1] "USO" "XLE" "XLP" "VNQ" "IEF" "XLK" "XLF" "XLY"

# Sort all the columns of alphav in descending order, 
# using an apply() loop over the columns of alphav, and 
# extract the ETF names.
# You can use the functions apply(), sort(), names(),
# and an anonymous function,

namev <- apply(alphav, 2, function(alpha) {
  names(sort(alpha, decreasing = TRUE))
})


# You should get the outputs:
dim(namev)
# [1]  8 21
namev
#       2006  2007  2008  2009  2010  2011  2012  2013  2014  2015  2016  2017  2018  2019 
# [1,] "VNQ" "USO" "VNQ" "XLK" "IEF" "IEF" "IEF" "XLY" "VNQ" "XLY" "XLE" "IEF" "XLY" "IEF"
# [2,] "XLP" "XLE" "IEF" "XLY" "XLY" "XLP" "XLF" "XLP" "IEF" "XLP" "XLF" "XLK" "XLK" "VNQ"
# [3,] "XLF" "IEF" "XLE" "XLP" "VNQ" "VNQ" "XLY" "XLK" "XLP" "XLK" "IEF" "XLP" "IEF" "XLP"
# [4,] "IEF" "XLK" "XLP" "USO" "XLP" "XLY" "VNQ" "XLF" "XLK" "IEF" "XLK" "XLY" "VNQ" "USO"
# [5,] "XLY" "XLP" "XLY" "IEF" "XLE" "XLE" "XLP" "IEF" "XLF" "VNQ" "VNQ" "VNQ" "XLP" "XLK"
# [6,] "XLK" "XLY" "XLF" "XLE" "XLK" "XLK" "XLK" "XLE" "XLY" "XLF" "XLP" "USO" "XLF" "XLF"
# [7,] "XLE" "VNQ" "XLK" "VNQ" "XLF" "USO" "XLE" "USO" "XLE" "XLE" "XLY" "XLF" "XLE" "XLY"
# [8,] "USO" "XLF" "USO" "XLF" "USO" "XLF" "USO" "VNQ" "USO" "USO" "USO" "XLE" "USO" "XLE"
#       2020  2021  2022  2023  2024  2025  2026 
# [1,] "XLK" "USO" "XLE" "XLK" "XLF" "IEF" "USO"
# [2,] "IEF" "VNQ" "USO" "XLY" "USO" "XLF" "XLE"
# [3,] "XLY" "XLE" "XLP" "IEF" "XLP" "XLK" "XLP"
# [4,] "XLP" "XLF" "XLF" "XLF" "IEF" "XLP" "VNQ"
# [5,] "XLF" "XLP" "XLK" "XLP" "XLY" "XLE" "IEF"
# [6,] "VNQ" "XLK" "VNQ" "USO" "XLE" "VNQ" "XLK"
# [7,] "XLE" "XLY" "IEF" "VNQ" "VNQ" "XLY" "XLF"
# [8,] "USO" "IEF" "XLY" "XLE" "XLK" "USO" "XLY"


# 4. (10pts)
# Plot a scatterplot of the alphas for the years 
# "2008" and "2009", and add labels with ETF names.
# You can use the functions plot(), rownames(), 
# range(), and text().
# Hint: Use the parameters xlim and ylim in the 
# function plot(), to enlarge the dimensions of 
# the plot, and make room for the labels.
# Your plot should be similar to scatter_etfs.png

alpha2008 <- alphav[, "2008"]
alpha2009 <- alphav[, "2009"]
dir.create("hw1_results", showWarnings = FALSE)
png(file.path("hw1_results", "scatter_etfs.png"),
    width = 1500, height = 1250, res = 160)
plot(alpha2008, alpha2009, pch = 1, cex = 1.2,
     xlim = extendrange(alpha2008, f = 0.20),
     ylim = extendrange(alpha2009, f = 0.15),
     main = "Scatterplot of ETF alphas in 2008 and 2009",
     xlab = "2008", ylab = "2009")
text(alpha2008, alpha2009, labels = rownames(alphav), pos = 4)
invisible(dev.off())


# Comment: 
# The scatterplot of the ETF alphas in the years 2008 and 2009
# doesn't show any relationship between the alphas in those years.
# For some ETFs the positive or negative alphas persist, while for 
# others, the alphas change radically from year to year.

