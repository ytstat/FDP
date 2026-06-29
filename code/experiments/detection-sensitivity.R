library(dplyr)
library(rmutil)

source(file.path("code", "repro_utils.R"))
source(file.path("code", "funcs.R"))

Sys.setenv(LANG = "en_US.UTF-8")
seed <- get_seed()
cat("seed=", seed, "\n")

filename <- result_file("detection-sensitivity", seed)
if (file.exists(filename)) {
  stop("Done!")
}

set.seed(seed, kind = "L'Ecuyer-CMRG")


h_list <- seq(0, 1, 0.1)
c_list <- seq(0.5, 3, 0.5)
error_detection <- matrix(nrow = 6, ncol = length(h_list), dimnames = list(c_list, h_list))
error_detection_sample <- matrix(nrow = 6, ncol = length(h_list), dimnames = list(c_list, h_list))

K <- 20
d <- 10
epsilon <- 1
delta <- 0.001
eta <- 0.01

n <- 100000

beta0 <- rep(1, d)/sqrt(d)
rho <- 0.25

for (i in 1:length(h_list)) {
  for (j in 1:length(c_list)) {
    threshold_c <- c_list[j]
    h <- h_list[i]
    beta <- matrix(nrow = d, ncol = K+1)
    data <- sapply(1:(K+1), function(k){
      if (k == 1) {
        beta[, k] <- beta0
      } else {
        beta[, k] <- beta0 + c(h, rep(0, d-1))
      }
      X <- matrix(rnorm(n*d), nrow = n)
      Y <- X %*% beta[, k] + rnorm(n)
      list(X = X, Y = Y)
    }, simplify = F)
    
    X_combined <- Reduce(rbind, sapply(1:(K+1), function(k){data[[k]]$X}, simplify = F))
    Y_combined <- Reduce(c, sapply(1:(K+1), function(k){data[[k]]$Y}, simplify = F))

    A <- Priviate_detection(data, rho, epsilon/2, delta/2, beta0 = NULL, eta, c = threshold_c, epsilon_r = epsilon, delta_r = delta, private_variance = "nodiff")
    error_detection[j, i] <- l2_error(LinearReg_FDP(data[A], T=floor(log(n*length(A))), rho, epsilon/2, delta/2, eta = eta, private_variance = "nodiff"), beta0)

    D <- Data_splitting(data)
    A <- Priviate_detection(D[[1]], rho, epsilon, delta, beta0 = NULL, eta, c = threshold_c, epsilon_r = epsilon, delta_r = delta, split_option = "sample", private_variance = "nodiff")
    error_detection_sample[j, i] <- l2_error(LinearReg_FDP(D[[2]][A], T=floor(log(n*length(A)/2)), rho, epsilon, delta, eta = eta, private_variance = "nodiff"), beta0)
    
  }
}

save(error_detection, error_detection_sample, file = filename)
