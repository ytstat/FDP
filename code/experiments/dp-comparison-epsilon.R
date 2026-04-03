library(dplyr)
library(rmutil)

source(file.path("code", "repro_utils.R"))
source(file.path("code", "funcs.R"))

Sys.setenv(LANG = "en_US.UTF-8")
seed <- get_seed()
cat("seed=", seed, "\n")

filename <- result_file("dp-comparison-epsilon", seed)
if (file.exists(filename)) {
  stop("Done!")
}

set.seed(seed, kind = "L'Ecuyer-CMRG")

# ---------------------------------------------------
n <- 60000
epsilon_list <- seq(0.6, 2.4, 0.2)
error <- matrix(nrow = 6, ncol = length(epsilon_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), epsilon_list))

K <- 10
d <- 20
delta <- 0.001
eta <- 0.01



rho <- 18/(1 + 81)

for (i in 1:length(epsilon_list)) {
  epsilon <- epsilon_list[i]
  
  beta <- rep(1, d)/sqrt(d)
  data <- sapply(1:(K+1), function(k){
    X <- matrix(rnorm(n*d), nrow = n)
    Y <- X %*% beta + rnorm(n)
    list(X = X, Y = Y)
  }, simplify = F)
  
  X_combined <- Reduce(rbind, sapply(1:(K+1), function(k){data[[k]]$X}, simplify = F))
  Y_combined <- Reduce(c, sapply(1:(K+1), function(k){data[[k]]$Y}, simplify = F))
  
  error["None-DP", i] <- l2_error(LinearReg(X = data[[1]]$X, Y = data[[1]]$Y), beta)
  error["CDP-all", i] <- l2_error(LinearReg_CDP(X = X_combined, Y = Y_combined, T = floor(log(n*(K+1))), rho, epsilon, delta, eta = eta, private_variance = "nodiff"), beta)
  
  error["CDP-target", i] <- l2_error(LinearReg_CDP(X = data[[1]]$X, Y = data[[1]]$Y, T= floor(log(n)), rho, epsilon, delta, eta = eta, private_variance = "nodiff"), beta)
  
  error["FDP", i] <- l2_error(LinearReg_FDP(data, T=floor(log(n*(K+1))), rho, epsilon, delta, eta = eta, private_variance = "nodiff"), beta)
  
  error["LDP-all", i] <- l2_error(LinearReg_LDP(X = X_combined, Y = Y_combined, T = floor(log(n*(K+1))), epsilon, eta = rho), beta) # eta for the LDP alg is the step size, different from the FDP alg
  
  error["LDP-target", i] <- l2_error(LinearReg_LDP(X = data[[1]]$X, Y = data[[1]]$Y, T = floor(log(n)), epsilon, eta = rho), beta) 
  
}


save(error, file = filename)
