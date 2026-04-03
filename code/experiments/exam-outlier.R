library(dplyr)
library(rmutil)

source(file.path("code", "repro_utils.R"))
source(file.path("code", "funcs.R"))

Sys.setenv(LANG = "en_US.UTF-8")
seed <- get_seed()
cat("seed=", seed, "\n")

filename <- result_file("exam-outlier", seed)
if (file.exists(filename)) {
  stop("Done!")
}

set.seed(seed, kind = "L'Ecuyer-CMRG")

# ---------------------------------------------------

# Run this script from the repository root so the relative paths below resolve.
D <- read.csv(file.path("data", "Exam_Score_Prediction.csv"))

# fit_lm <- lm(exam_score ~ ., data = D)
# summary(fit_lm)

selected_variables <- c("study_hours", "class_attendance", "sleep_hours", "sleep_quality", "study_method", "facility_rating", "exam_score", "course")

# ------------------------
# Preprocess the data
# ------------------------
cat_vars <- c("sleep_quality", 
              "study_method", 
              "facility_rating")

# transform categorical variables to dummies
D <- D |>
  select(selected_variables) |>
  mutate(across(all_of(cat_vars), as.factor))

dummy_formula <- as.formula(paste("~", paste(cat_vars, collapse = " + ")))
dummy_df <- model.matrix(dummy_formula, data = D) |>
  as.data.frame()


D <- D |>
  bind_cols(dummy_df) |>
  select(`(Intercept)`, everything(), -all_of(cat_vars))

colnames(D)[1] <- "intercept"


# standardize continuous variables
cont_vars <- c(
  "study_hours",
  "class_attendance",
  "sleep_hours",
  "exam_score"
)

# # standardize the whole data
# 
# mean_sd_info <- numeric(2)
# names(mean_sd_info) <- c("mean", "sd")
# mean_sd_info["mean"] <- mean(D$exam_score)
# mean_sd_info["sd"] <- sd(D$exam_score)
# 
# D <- D |>
#   mutate(across(all_of(cont_vars), ~ (. - mean(.)) / sd(.)))



# split data by course into named list and drop the identifier afterwards
course_datasets <- split(D, D$course)
course_datasets <- lapply(course_datasets, function(df) {
  df |>
    select(-course)
})
K <- length(course_datasets)


# standardize each dataset separately
mean_sd_info <- matrix(nrow = K, ncol = 2, dimnames = list(names(course_datasets), c("mean", "sd")))


# contaminate a target course dataset by adding Gaussian noise
# course_datasets[[1]]$exam_score <- course_datasets[[1]]$exam_score +
#   as.matrix(course_datasets[[1]][, colnames(course_datasets[[1]])!="exam_score"]) %*% rnorm(ncol(course_datasets[[1]])-1, 0, 50) # nolint: infix_spaces_linter.


for (k in 1:K) {
  mean_sd_info[k, "mean"] <- mean(course_datasets[[k]]$exam_score)
  mean_sd_info[k, "sd"] <- sd(course_datasets[[k]]$exam_score)
  course_datasets[[k]] <- course_datasets[[k]] %>% mutate(across(all_of(cont_vars), ~ (. - mean(.)) / sd(.)))
}


# contaminate a target course dataset by adding Gaussian noise
course_datasets[[1]]$exam_score <- course_datasets[[1]]$exam_score + rnorm(nrow(course_datasets[[1]]), mean = 5, sd = 1)

# ------------------------
# Run different DP algorithms
# ------------------------

# sample the training and test datasets
test_index <- sapply(1:length(course_datasets), function(i) {
  sample(nrow(course_datasets[[i]]), floor(0.1 * nrow(course_datasets[[i]])))
})

# DP parameters
epsilon_list <- seq(1, 10, 0.5)
error <- rep(list(matrix(nrow = 10, ncol = length(epsilon_list), 
                         dimnames = list(c("None-DP", "None-DP-all", "zero", "CDP-all", "CDP-target", "FDP", "FDP-detection", "FDP-detection2", "LDP-all", "LDP-target"), 
                                         epsilon_list))), 7)

K <- length(course_datasets)
delta <- 0.001
eta <- 0.01
rho <- 18/(1 + 81)

for (k in 1:7) {
  for (i in 1:length(epsilon_list)) {
    epsilon <- epsilon_list[i]
    
    D_train <- sapply(
      1:length(course_datasets),
      function(j) {
        if (j == k) {
          course_datasets[[k]][-test_index[[k]], ]
        } else {
          course_datasets[[j]]
        }
      },
      simplify = F
    )
    
    D_test <- course_datasets[[k]][test_index[[k]], ]
    
    X_test <- as.matrix(D_test[, colnames(D_test) != "exam_score"])
    
    Y_test <- D_test[, "exam_score"]
    
    X_train <- sapply(
      1:length(course_datasets),
      function(i) {
        as.matrix(D_train[[i]][, colnames(D_train[[i]]) != "exam_score"])
      },
      simplify = F
    )
    
    Y_train <- sapply(
      1:length(course_datasets),
      function(i) {
        D_train[[i]][, "exam_score"]
      },
      simplify = F
    )
    
    train_data <- sapply(
      1:length(X_train),
      function(i) {
        list(X = X_train[[i]], Y = Y_train[[i]])
      },
      simplify = F
    )
    
    X_combined <- Reduce(rbind, sapply(1:K, function(k){train_data[[k]]$X}, simplify = F))
    Y_combined <- Reduce(c, sapply(1:K, function(k){train_data[[k]]$Y}, simplify = F))
    
    N <- nrow(X_combined)
    n <- nrow(X_train[[k]])
    
    # DP algorithms
    beta_LR_single <- LinearReg(
      X = X_train[[k]],
      Y = Y_train[[k]]
    )
    Y_pred_LR_single <- X_test %*% beta_LR_single
    
    beta_LR_all <- LinearReg(
      X = X_combined,
      Y = Y_combined
    )
    Y_pred_LR_all <- X_test %*% beta_LR_all
    
    beta_CDP <- LinearReg_CDP(
      X = X_train[[k]],
      Y = Y_train[[k]],
      T = floor(log(n)),
      rho,
      epsilon,
      delta,
      eta = eta,
      private_variance = "nodiff",
      beta0 = NULL
    )
    Y_pred_CDP <- X_test %*% beta_CDP
    
    beta_FDP <- LinearReg_FDP(train_data, T=floor(log(N)), rho, epsilon, delta, eta = eta, private_variance = "nodiff")
    Y_pred_FDP <- X_test %*% beta_FDP
    
    beta_CDP_all <- LinearReg_CDP(X = X_combined, Y = Y_combined, T = floor(log(N)), rho, epsilon, delta, eta = eta, private_variance = "nodiff")
    Y_pred_CDP_all <- X_test %*% beta_CDP_all
    
    beta_LDP_all <- LinearReg_LDP(X = X_combined, Y = Y_combined, T = floor(log(N)), epsilon, eta = rho)
    Y_pred_LDP_all <- X_test %*% beta_LDP_all
    
    beta_LDP <- LinearReg_LDP(X = X_train[[k]], Y = Y_train[[k]], T = floor(log(n)), epsilon, eta = rho)
    Y_pred_LDP <- X_test %*% beta_LDP
    
    
    A <- Priviate_detection(train_data, rho, epsilon/2, delta/2, beta0 = NULL, eta, target_index = k, c = 1, epsilon_r = epsilon, delta_r = delta, private_variance = "nodiff")
    beta_FDP_detection <- LinearReg_FDP(train_data[A], T=floor(log(N)), rho, epsilon/2, delta/2, eta = eta, private_variance = "nodiff")
    Y_pred_FDP_detection <- X_test %*% beta_FDP_detection
    
    splitted_data <- Data_splitting(train_data, 0.5)
    A2 <- Priviate_detection(splitted_data[[1]], rho, epsilon, delta, beta0 = NULL, eta, target_index = k, c = 1, 
                             epsilon_r = epsilon, delta_r = delta, split_option = "sample", private_variance = "nodiff")
    beta_FDP_detection2 <- LinearReg_FDP(splitted_data[[2]][A2], T=floor(log(N*0.5)), rho, epsilon, delta, eta = eta, private_variance = "nodiff")
    Y_pred_FDP_detection2 <- X_test %*% beta_FDP_detection2
    
    
    # Calculate errors
    error[[k]]["None-DP", i] <- sqrt(mean((Y_test - Y_pred_LR_single)^2))*mean_sd_info[k, "sd"]
    error[[k]]["None-DP-all", i] <- sqrt(mean((Y_test - Y_pred_LR_all)^2))*mean_sd_info[k, "sd"]
    error[[k]]["zero", i] <- sqrt(mean((Y_test - 0)^2))*mean_sd_info[k, "sd"]
    error[[k]]["CDP-target", i] <- sqrt(mean((Y_test - Y_pred_CDP)^2))*mean_sd_info[k, "sd"]
    error[[k]]["FDP", i] <- sqrt(mean((Y_test - Y_pred_FDP)^2))*mean_sd_info[k, "sd"]
    error[[k]]["CDP-all", i] <- sqrt(mean((Y_test - Y_pred_CDP_all)^2))*mean_sd_info[k, "sd"]
    error[[k]]["LDP-all", i] <- sqrt(mean((Y_test - Y_pred_LDP_all)^2))*mean_sd_info[k, "sd"]
    error[[k]]["LDP-target", i] <- sqrt(mean((Y_test - Y_pred_LDP)^2))*mean_sd_info[k, "sd"]
    error[[k]]["FDP-detection", i] <- sqrt(mean((Y_test - Y_pred_FDP_detection)^2))*mean_sd_info[k, "sd"]
    error[[k]]["FDP-detection2", i] <- sqrt(mean((Y_test - Y_pred_FDP_detection2)^2))*mean_sd_info[k, "sd"]
    cat("Course ", k, ", epsilon=", epsilon, " done.\n")
    
  }
}

save(error, file = filename)
