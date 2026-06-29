library(dplyr)
library(rmutil)

source(file.path("code", "repro_utils.R"))
source(file.path("code", "funcs.R"))

Sys.setenv(LANG = "en_US.UTF-8")
seed <- get_seed()
cat("seed=", seed, "\n")

args <- commandArgs(trailingOnly = TRUE)
d <- get_positive_int_arg(args, 1, 10, "d")
K <- get_positive_int_arg(args, 2, 20, "K")
cat("d=", d, "\n")
cat("K=", K, "\n")

filename <- result_file("fdp-rho-sensitivity", seed, scenario_name(d, K))
if (file.exists(filename)) {
  stop("Done!")
}

set.seed(seed, kind = "L'Ecuyer-CMRG")

n <- 60000
epsilon_list <- 1:6
rho_list <- c(0.1, 0.15, 0.2, 0.25, seq(0.3, 1, 0.1))
error <- matrix(nrow = length(rho_list), ncol = length(epsilon_list), dimnames = list(rho_list, epsilon_list))

delta <- 0.001
eta <- 0.01

for (i in 1:length(epsilon_list)) {
  epsilon <- epsilon_list[i]
  
  beta <- rep(1, d)/sqrt(d)
  data <- sapply(1:(K+1), function(k){
    X <- matrix(rnorm(n*d), nrow = n)
    Y <- X %*% beta + rnorm(n)
    list(X = X, Y = Y)
  }, simplify = F)
  
  for (j in 1:length(rho_list)) {
    rho <- rho_list[j]
    error[j, i] <- l2_error(LinearReg_FDP(data, T=floor(log(n*(K+1))), rho, epsilon, delta, eta = eta, private_variance = "nodiff"), beta)
  }
}


save(error, rho_list, epsilon_list, file = filename)
