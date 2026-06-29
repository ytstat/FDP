library(dplyr)
library(rmutil)

# Functions used across all simulation scripts.

Euc_norm <- function(x) {
  sqrt(sum(x^2))
}

l2_error <- function(beta_hat, beta) {
  Euc_norm(beta_hat - beta)
}

PrivateVariance <- function(W, epsilon, delta, J = 10) {
  n <- floor(length(W)/2)
  Wp <- W[seq(2, 2*n, 2)] - W[seq(1, 2*n, 2)]
  pt <- numeric(2*J+1)
  for (j in (-J):J) {
    p <- sum(Wp <= 2^(j+1) & Wp > 2^j)/n
    if (p == 0) {
      pt[j+J+1] <- 0
    } else {
      pt[j+J+1] <- p + 2/(epsilon*n)*rlaplace(1)
      if (pt[j+J+1] < 2*log(1/delta)/(epsilon*n) + 1/n) {
        pt[j+J+1] <- 0
      }
    }
  }
  j_hat <- order(pt, decreasing = T)[1]-J-1
  return(2^(j_hat+2))
}


PrivateVariance_nodiff <- function(W, epsilon, delta, J = 10) {
  n <- length(W)
  pt <- numeric(2*J+1)
  for (j in (-J):J) {
    p <- sum(W <= 2^(j+1) & W > 2^j)/n
    if (p == 0) {
      pt[j+J+1] <- 0
    } else {
      pt[j+J+1] <- p + 2/(epsilon*n)*rlaplace(1)
      if (pt[j+J+1] < 2*log(1/delta)/(epsilon*n) + 1/n) {
        pt[j+J+1] <- 0
      }
    }
  }
  j_hat <- order(pt, decreasing = T)[1]-J-1
  return(2^(j_hat+2))
}

Row_proj <- function(X, R) {
  t(sapply(1:nrow(X), function(i){
    norm_Xi <- Euc_norm(X[i,])
    X[i, ]/norm_Xi*min(norm_Xi, R)
  }))
} 

Vec_proj <- function(x, R) {
  x/Euc_norm(x)*min(Euc_norm(x), R)
} 

Proj <- function(x, R) {
  sapply(1:length(x), function(i){
    x[i]/abs(x[i])*min(abs(x[i]), R)
  })
}




LinearReg <- function(X, Y) {
  return(as.numeric(solve(t(X) %*% X) %*% t(X) %*% Y))
}
  
  
LinearReg_CDP_TWZ <- function(X, Y, T, C = sqrt(d), eta0=d/2, epsilon, delta, beta0 = NULL) {
  X <- X/sqrt(d + 2*sqrt(d*log(n/0.01)) + 2*log(n/0.01))
  n <- nrow(X)
  d <- ncol(X)
  R <- sqrt(2*log(n))
  c_x <- 1
  c_0 <- sqrt(d+log(n))
  B <- 4*(R + c_0*c_x)*c_x
  
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  
  
  beta_t <- beta0
  for (t in 1:T) {
    res <- Proj(Y, R) - X %*% beta_t
    
    beta_t <- Vec_proj(beta_t - eta0*colMeans(-X*as.numeric(res) + rnorm(d, sd = eta0*sqrt(2)*B*sqrt(log(2*T/delta))/(n*epsilon/T))), C)
  }
  
  return(beta_t/sqrt(d + 2*sqrt(d*log(n/0.01)) + 2*log(n/0.01)))
}



LinearReg_CDP <- function(X, Y, T, rho, epsilon, delta, beta0 = NULL, eta = 0.01, private_variance = c("diff", "nodiff")) {
  n <- nrow(X)
  d <- ncol(X)
  private_variance <- match.arg(private_variance)
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  b <- floor(n/T)
  R <- sqrt(d + 2*sqrt(d*log(n/eta)) + 2*log(n/eta))
  ind_batch <- sapply(1:T, function(t){
    if (t != T) {
      ((t-1)*b+1):(t*b)
    } else {
      ((t-1)*b+1):n
    }
  }, simplify = F)
  beta_t <- beta0
  
  for (t in 1:T) {
    ind <- ind_batch[[t]]
    res <- Y[ind] - X[ind,] %*% beta_t
    if (private_variance == "diff") {
      R_t <- sqrt(log(n/eta))*PrivateVariance(res, epsilon/2, delta/2)
    } else {
      R_t <- sqrt(log(n/eta))*PrivateVariance_nodiff(res, epsilon/2, delta/2)
    }
    beta_t <- beta_t - rho*(colMeans(Row_proj(X[ind, ], R)*Proj(-res, R_t)) + sqrt(2*log(2.5/delta))*R*R_t/(b*epsilon/2)*rnorm(d))
  }
  
  return(beta_t)
} 
 
# Detect which source datasets are close enough to the target site to pool.
Priviate_detection <- function(data, rho, epsilon, delta, beta0 = NULL, eta = 0.01, target_index = 1, c = 1, epsilon_r = NULL, delta_r = NULL, split_option = c("privacy", "sample"), private_variance = c("diff", "nodiff")) {
  K <- length(data)
  d <- ncol(data[[1]]$X)
  split_option <- match.arg(split_option)
  private_variance <- match.arg(private_variance)
  
  if (split_option == "privacy") {
    n <- sapply(1:K, function(k){length(data[[k]]$Y)})
  } else {
    n <- sapply(1:K, function(k){length(data[[k]]$Y)})*2
  }
  
  
  if (is.null(epsilon_r)) {
    epsilon_r <- epsilon
  }
  
  if (is.null(delta_r)) {
    delta_r <- delta
  }
  
  r <- log(log(n[target_index])/eta)*sqrt(d*log(n[target_index])/n[target_index]) + d*(log(n[target_index]/eta))^2*sqrt(log(1/delta_r)*log(log(n[target_index])/eta))/(n[target_index]*epsilon_r)
  
  beta_all <- sapply(1:K, function(k){
    LinearReg_CDP(data[[k]]$X, data[[k]]$Y, T=floor(log(length(data[[k]]$Y))), rho, epsilon, delta, beta0 = NULL, eta, private_variance)
  })
  
  beta_diff <- beta_all - matrix(rep(beta_all[, target_index], K), nrow = d)
  
  score <- sapply(1:K, function(k){
    Euc_norm(beta_diff[, k])
  })
  A <- which(score <= c*r)
  
  
  return(A)
} 
 
# Federated DP regression that aggregates noisy batch gradients across sites.
LinearReg_FDP <- function(data, T, rho, epsilon, delta, beta0 = NULL, eta = 0.01, private_variance = c("diff", "nodiff")) {
  K <- length(data)
  n <- sapply(1:K, function(k){length(data[[k]]$Y)})
  private_variance <- match.arg(private_variance)
  N <- sum(n)
  d <- ncol(data[[1]]$X)
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  b <- floor(n/T)
  R <- sqrt(d + 2*sqrt(d*log(n/eta)) + 2*log(n/eta))
  ind_batch <- sapply(1:K, function(k){
    sapply(1:T, function(t){
      if (t != T) {
        ((t-1)*b[k]+1):(t*b[k])
      } else {
        ((t-1)*b[k]+1):n[k]
      }
    }, simplify = F)
  }, simplify = F)
  
  beta_t <- beta0
  
  for (t in 1:T) {
    Z_t <- matrix(0, nrow = d, ncol = K)
    for (k in 1:K) {
      ind <- ind_batch[[k]][[t]]
      res <- data[[k]]$Y[ind] - data[[k]]$X[ind,] %*% beta_t
      if (private_variance == "diff") {
        R_t <- sqrt(log(n[k]/eta))*PrivateVariance(res, epsilon/2, delta/2)
      } else {
        R_t <- sqrt(log(n[k]/eta))*PrivateVariance_nodiff(res, epsilon/2, delta/2)
      }
      Z_t[, k] <- n[k]/N*rho*(colMeans(Row_proj(data[[k]]$X[ind, ], R[k])*Proj(-res, R_t)) + sqrt(2*log(2.5/delta))*R[k]*R_t/(b[k]*epsilon/2)*rnorm(d))
    }
    beta_t <- beta_t - rowSums(Z_t)
  }
  
  return(beta_t)
} 
 
# Sample splitting variant used by the detection experiment.
Data_splitting <- function(data, split_ratio = 0.5) {
  K <- length(data)
  D1 <- rep(list(list(X = NULL, Y = NULL)), K)
  D2 <- rep(list(list(X = NULL, Y = NULL)), K)
  
  for (k in 1:K) {
    ind <- sample(length(data[[k]]$Y), floor(split_ratio*length(data[[k]]$Y)), replace = F)
    D1[[k]]$X <- data[[k]]$X[ind, ]
    D1[[k]]$Y <- data[[k]]$Y[ind]
    D2[[k]]$X <- data[[k]]$X[-ind, ]
    D2[[k]]$Y <- data[[k]]$Y[-ind]
  }
  return(list(D1, D2))
}

R_epsilon_r <- function(x, r, epsilon) {
  d <- length(x)
  pr <- min(Euc_norm(x)/(2*r), 1/2)
  x_tilde <- sample(c(-1, 1), 1, prob = c(1/2-pr, 1/2+pr))*r*x/Euc_norm(x)
  T <- sample(c(0, 1), 1, prob = c(1/(exp(epsilon) + 1), exp(epsilon)/(exp(epsilon) + 1)))
  if (T == 1) {
    while (1) {
      u <- rnorm(d)
      if (sum(u*x_tilde) > 0) {
        u <- u/Euc_norm(u)
        break
      }
    }
  } else {
    while (1) {
      u <- rnorm(d)
      if (sum(u*x_tilde) <= 0) {
        u <- u/Euc_norm(u)
        break
      }
    }
  }
  B <- r*(exp(epsilon)+1)/(exp(epsilon)-1)*sqrt(pi)/2*d*gamma((d+1)/2)/gamma(d/2+1)
  return(B*u)
}

LinearReg_LDP <- function(X, Y, T, epsilon, beta0 = NULL, eta) {
  n <- nrow(X)
  d <- ncol(X)
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  b <- floor(n/T)
  
  ind_batch <- sapply(1:T, function(t){
    if (t != T) {
      ((t-1)*b+1):(t*b)
    } else {
      ((t-1)*b+1):n
    }
  }, simplify = F)
  beta_t <- beta0
  
  for (t in 1:T) {
    ind <- ind_batch[[t]]
    Z <- t(sapply(ind, function(i){
      R_epsilon_r(as.numeric(X[i,] %*% beta_t - Y[i])*X[i,], r = d+log(n), epsilon)
    }))
    
    beta_t <- Vec_proj(beta_t - eta*colMeans(Z), 1)
    
  }
  
  return(beta_t)
} 
