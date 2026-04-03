library(ggplot2)
library(ggpubfigs)  # devtools::install_github("JLSteenwyk/ggpubfigs")
library(latex2exp)
library(ggpubr)
library(dplyr)
conflicted::conflict_prefer("filter", "dplyr")

# Run this script from the repository root.
# The script is organized as independent experiment blocks and assumes
# the corresponding .RData files already exist under output/results/.
result_root <- file.path("output", "results")
figure_root <- file.path("output", "figures")
n_rep <- 200

# -------------------------------------------------------------
## dp-comparsion-n: Figure 2 left panel
n_list <- (1:10) * 10000
error_avg <- matrix(nrow = 6, ncol = length(n_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), n_list))
error_sd <- matrix(nrow = 6, ncol = length(n_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), n_list))

for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "dp-comparison-n", paste0(o, ".RData")))
      error[i, j]
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "dp-comparison-n", paste0(o, ".RData")))
      error[i, j]
    }))
  }
}

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#999999", "#CC79A7")

df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), n = rep(n_list, each = 6), method = rep(rownames(error_avg), 10))

dp1 <- df %>% filter(n >= 20000, method != "None-DP") %>% ggplot(aes(x = n, y = log(error), group = method, color = method, shape = method)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + scale_color_manual(values = cbbPalette) +
  scale_x_continuous(breaks = seq(20000, 100000, 20000), labels = format(seq(20000, 100000, 20000), scientific = F))



# -------------------------------------------------------------
## dp-comparsion-epsilon: Figure 2 right panel
epsilon_list <- seq(0.6, 2.4, 0.2)
error_avg <- matrix(nrow = 6, ncol = length(epsilon_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), epsilon_list))
error_sd <- matrix(nrow = 6, ncol = length(epsilon_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), epsilon_list))

for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "dp-comparison-epsilon", paste0(o, ".RData")))
      error[i, j]
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "dp-comparison-epsilon", paste0(o, ".RData")))
      error[i, j]
    }))
  }
}

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#999999", "#CC79A7")

df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), epsilon = rep(epsilon_list, each = 6), method = rep(rownames(error_avg), length(epsilon_list)))

dp2 <- df %>% filter(method != "None-DP") %>% ggplot(aes(x = epsilon, y = log(error), group = method, color = method, shape = method)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + scale_color_manual(values = cbbPalette) +
  scale_x_continuous(breaks = epsilon_list) + xlab(TeX(r"($\epsilon$)"))


# combine the plots
ggarrange(dp1, dp2, nrow = 1, common.legend = T, legend = "bottom")

# -------------------------------------------------------------
## h-outlier: Figure 3
h_list <- seq(0, 1, 0.1)
error_avg <- matrix(nrow = 7, ncol = length(h_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "FDP-detection", "LDP-all", "LDP-target"), h_list))
error_sd <- matrix(nrow = 7, ncol = length(h_list), dimnames = list(c("None-DP", "CDP-all", "CDP-target", "FDP", "FDP-detection", "LDP-all", "LDP-target"), h_list))

for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "h-outlier", paste0(o, ".RData")))
      error[i, j]
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "h-outlier", paste0(o, ".RData")))
      error[i, j]
    }))
  }
}

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "purple", "#009E73", "#999999")


df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), h = rep(h_list, each = 7), method = rep(rownames(error_avg), 11))

# save it as a 8 x 4 PDF
df %>% filter(method != "None-DP") %>% ggplot(aes(x = h, y = log(error), group = method, color = method, shape = method)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + scale_color_manual(values = cbbPalette) +
  scale_shape_manual(values = c(16, 17, 15, 23, 3, 7, 8)) + guides(colour = guide_legend(nrow = 1))


# -------------------------------------------------------------
## exam: Figure 4
epsilon_list <- seq(1, 10, 0.5)
error_avg <- matrix(nrow = 5, ncol = length(epsilon_list), dimnames = list(c("CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), epsilon_list))
error_sd <- matrix(nrow = 5, ncol = length(epsilon_list), dimnames = list(c("CDP-all", "CDP-target", "FDP", "LDP-all", "LDP-target"), epsilon_list))

for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "exam", paste0(o, ".RData")))
      error <- sapply(1:7, function(k) {
        error[[k]][rownames(error[[k]]) %in% rownames(error_avg), ]
      }, simplify = F)
      Reduce("+", error)[i, j] / 7
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "exam", paste0(o, ".RData")))
      error <- sapply(1:7, function(k) {
        error[[k]][rownames(error[[k]]) %in% rownames(error_avg), ]
      }, simplify = F)
      Reduce("+", error)[i, j] / 7
    }))
  }
}

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", "#999999")
df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), epsilon = rep(epsilon_list, each = 5), method = rep(rownames(error_avg), length(epsilon_list)))

dp2 <- df %>% filter(epsilon >= 3 & epsilon <= 7) %>% ggplot(aes(x = epsilon, y = log(error), group = method, color = method, shape = method)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + scale_color_manual(values = cbbPalette) +
  scale_x_continuous(breaks = epsilon_list) + xlab(TeX(r"($\epsilon$)"))


# output as a 8x4 PDF
dp2


# -------------------------------------------------------------
## exam-outlier: Figure 5
epsilon_list <- seq(1, 10, 0.5)

error_avg <- matrix(nrow = 6, ncol = length(epsilon_list),
                    dimnames = list(c("CDP-all", "CDP-target", "FDP", "FDP-detection", "LDP-all", "LDP-target"), epsilon_list))
error_sd <- matrix(nrow = 6, ncol = length(epsilon_list),
                   dimnames = list(c("CDP-all", "CDP-target", "FDP", "FDP-detection", "LDP-all", "LDP-target"), epsilon_list))


for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "exam-outlier", paste0(o, ".RData")))
      error <- sapply(2:7, function(k) {
        error[[k]][rownames(error[[k]]) %in% rownames(error_avg), ]
      }, simplify = F)
      Reduce("+", error)[i, j] / 6
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "exam-outlier", paste0(o, ".RData")))
      error <- sapply(2:7, function(k) {
        error[[k]][rownames(error[[k]]) %in% rownames(error_avg), ]
      }, simplify = F)
      Reduce("+", error)[i, j] / 6
    }))
  }
}

cbbPalette <- c("#000000", "#E69F00", "#56B4E9", "purple", "#009E73", "#999999")
df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), epsilon = rep(epsilon_list, each = 6), method = rep(rownames(error_avg), length(epsilon_list)))


dp3 <- df %>% filter(epsilon >= 4 & epsilon <= 8) %>% ggplot(aes(x = epsilon, y = log(error), group = method, color = method, shape = method)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + scale_color_manual(values = cbbPalette) +
  scale_x_continuous(breaks = epsilon_list) + xlab(TeX(r"($\epsilon$)"))


# output as a 8x4 PDF
dp3


# -------------------------------------------------------------
## detection-sensitivity: Figure 7
h_list <- seq(0, 1, 0.1)
c_list <- seq(0.5, 3, 0.5)

error_avg <- matrix(nrow = length(c_list), ncol = length(h_list), dimnames = list(c_list, h_list))
error_sd <- matrix(nrow = length(c_list), ncol = length(h_list), dimnames = list(c_list, h_list))

for (i in 1:nrow(error_avg)) {
  for (j in 1:ncol(error_avg)) {
    error_avg[i, j] <- mean(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "detection-sensitivity", paste0(o, ".RData")))
      error_detection[i, j]
    }))

    error_sd[i, j] <- sd(sapply(1:n_rep, function(o) {
      load(file.path(result_root, "detection-sensitivity", paste0(o, ".RData")))
      error_detection[i, j]
    }))

  }
}



df <- data.frame(error = as.vector(error_avg), sd = as.vector(error_sd), c = rep(c_list, length(h_list)), h = rep(h_list, each = length(c_list)))

# save it as a 8 x 4 PDF
df %>% mutate(c = factor(c)) %>% ggplot(aes(x = h, y = log(error), group = c, color = c, shape = c)) + geom_point(size = 3) +
  theme(legend.position = "bottom") + geom_line() + guides(colour = guide_legend(nrow = 1)) + xlab(TeX(r"($\tilde{c}$)")) +
  labs(color = latex2exp::TeX(r"($\tilde{c}$)"),
       shape = latex2exp::TeX(r"($\tilde{c}$)"))
