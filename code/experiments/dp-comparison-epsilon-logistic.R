library(dplyr)
library(rmutil)

source(file.path("code", "repro_utils.R"))
source(file.path("code", "funcs-logistic.R"))

Sys.setenv(LANG = "en_US.UTF-8")
seed <- get_seed()
cat("seed=", seed, "\n")

args <- commandArgs(trailingOnly = TRUE)
d <- get_positive_int_arg(args, 1, 10, "d")
K <- get_positive_int_arg(args, 2, 20, "K")
cat("d=", d, "\n")
cat("K=", K, "\n")

filename <- result_file("dp-comparison-epsilon-logistic", seed, scenario_name(d, K))
if (file.exists(filename)) {
  stop("Done!")
}

set.seed(seed, kind = "L'Ecuyer-CMRG")

n <- 60000
epsilon_list <- seq(0.6, 2.4, 0.2)
error <- matrix(nrow = 8, ncol = length(epsilon_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "FDP-detection", "FDP-detection-sample", "LDP-all", "LDP-target"), epsilon_list))

delta <- 0.001
eta <- 0.01

rho <- 2

for (i in 1:length(epsilon_list)) {
  epsilon <- epsilon_list[i]
  
  beta <- rep(1, d)/sqrt(d)
  data <- sapply(1:(K+1), function(k){
    X <- matrix(rnorm(n*d), nrow = n)
    Y <- rbinom(n, 1, as.numeric(plogis(X %*% beta)))
    list(X = X, Y = Y)
  }, simplify = F)
  
  X_combined <- Reduce(rbind, sapply(1:(K+1), function(k){data[[k]]$X}, simplify = F))
  Y_combined <- Reduce(c, sapply(1:(K+1), function(k){data[[k]]$Y}, simplify = F))
  
  error["None-DP", i] <- l2_error(LogisticReg(X = data[[1]]$X, Y = data[[1]]$Y), beta)
  error["CDP-all", i] <- l2_error(LogisticReg_CDP(X = X_combined, Y = Y_combined, T = floor(log(n*(K+1))), rho, epsilon, delta, eta = eta), beta)
  
  error["CDP-target", i] <- l2_error(LogisticReg_CDP(X = data[[1]]$X, Y = data[[1]]$Y, T= floor(log(n)), rho, epsilon, delta, eta = eta), beta)
  
  error["FDP", i] <- l2_error(LogisticReg_FDP(data, T=floor(log(n*(K+1))), rho, epsilon, delta, eta = eta), beta)
  
  error["LDP-all", i] <- l2_error(LogisticReg_LDP(X = X_combined, Y = Y_combined, T = floor(log(n*(K+1))), epsilon, eta = rho), beta) # eta for the LDP alg is the step size, different from the FDP alg
  
  error["LDP-target", i] <- l2_error(LogisticReg_LDP(X = data[[1]]$X, Y = data[[1]]$Y, T = floor(log(n)), epsilon, eta = rho), beta) 

  A <- Priviate_detection_logistic(data, rho, epsilon/2, delta/2, beta0 = NULL, eta, c = 1, epsilon_r = epsilon, delta_r = delta)
  error["FDP-detection", i] <- l2_error(LogisticReg_FDP(data[A], T=floor(log(n*length(A))), rho, epsilon/2, delta/2, eta = eta), beta)

  D <- Data_splitting(data)
  A <- Priviate_detection_logistic(D[[1]], rho, epsilon, delta, beta0 = NULL, eta, c = 1, epsilon_r = epsilon, delta_r = delta, split_option = "sample")
  error["FDP-detection-sample", i] <- l2_error(LogisticReg_FDP(D[[2]][A], T=floor(log(n*length(A)/2)), rho, epsilon, delta, eta = eta), beta)
}


save(error, file = filename)
