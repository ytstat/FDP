library(dplyr)
library(rmutil)

Euc_norm <- function(x) {
  sqrt(sum(x^2))
}

l2_error <- function(beta_hat, beta) {
  Euc_norm(beta_hat - beta)
}

Vec_proj <- function(x, R) {
  x/Euc_norm(x)*min(Euc_norm(x), R)
} 

LogisticGrad <- function(X, Y, beta, R) {
  weight <- sapply(1:nrow(X), function(i){
    norm_Xi <- Euc_norm(X[i,])
    if (norm_Xi == 0) {
      1
    } else {
      min(1, R^2/norm_Xi^2)
    }
  })
  return(X*as.numeric((plogis(X %*% beta) - Y)*weight))
}

LogisticReg <- function(X, Y, beta0 = NULL) {
  d <- ncol(X)
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  beta_hat <- as.numeric(glm.fit(x = X, y = Y, start = beta0, family = binomial(), intercept = F)$coefficients)
  beta_hat[is.na(beta_hat)] <- 0
  return(beta_hat)
}

LogisticReg_CDP <- function(X, Y, T, rho, epsilon, delta, beta0 = NULL, eta = 0.01) {
  n <- nrow(X)
  d <- ncol(X)
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
    beta_t <- beta_t - rho*(colMeans(LogisticGrad(X[ind, ], Y[ind], beta_t, R)) + sqrt(2*log(1.25/delta))*2*R/(b*epsilon)*rnorm(d))
  }
  
  return(beta_t)
} 

Priviate_detection_logistic <- function(data, rho, epsilon, delta, beta0 = NULL, eta = 0.01, target_index = 1, c = 1, epsilon_r = NULL, delta_r = NULL, split_option = c("privacy", "sample")) {
  K <- length(data)
  d <- ncol(data[[1]]$X)
  split_option <- match.arg(split_option)
  
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
    LogisticReg_CDP(data[[k]]$X, data[[k]]$Y, T=floor(log(length(data[[k]]$Y))), rho, epsilon, delta, beta0 = NULL, eta)
  })
  
  beta_diff <- beta_all - matrix(rep(beta_all[, target_index], K), nrow = d)
  
  score <- sapply(1:K, function(k){
    Euc_norm(beta_diff[, k])
  })
  A <- which(score <= c*r)
  
  
  return(A)
} 

LogisticReg_FDP <- function(data, T, rho, epsilon, delta, beta0 = NULL, eta = 0.01) {
  K <- length(data)
  n <- sapply(1:K, function(k){length(data[[k]]$Y)})
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
      Z_t[, k] <- n[k]/N*rho*(colMeans(LogisticGrad(data[[k]]$X[ind, ], data[[k]]$Y[ind], beta_t, R[k])) + sqrt(2*log(1.25/delta))*2*R[k]/(b[k]*epsilon)*rnorm(d))
    }
    beta_t <- beta_t - rowSums(Z_t)
  }
  
  return(beta_t)
} 

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

LogisticReg_LDP <- function(X, Y, T, epsilon, beta0 = NULL, eta) {
  n <- nrow(X)
  d <- ncol(X)
  if (is.null(beta0)) {
    beta0 <- numeric(d)
  }
  b <- floor(n/T)
  R <- sqrt(d + 2*sqrt(d*log(n/0.01)) + 2*log(n/0.01))
  
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
      R_epsilon_r(as.numeric(LogisticGrad(matrix(X[i,], nrow = 1), Y[i], beta_t, R)), r = R, epsilon)
    }))
    
    beta_t <- Vec_proj(beta_t - eta*colMeans(Z), 1)
    
  }
  
  return(beta_t)
} 
