library(ggplot2)
library(latex2exp)
library(ggpubr)
library(dplyr)

source(file.path("code", "repro_utils.R"))

# Run this script from the repository root after the .RData files have been
# generated or copied into output/results/.
n_rep <- 100
seeds <- seq_len(n_rep)

method_colors <- c(
  "CDP-all" = "#000000",
  "CDP-target" = "#E69F00",
  "FDP" = "#56B4E9",
  "FDP-detection" = "purple",
  "LDP-all" = "#009E73",
  "LDP-target" = "#999999"
)

method_shapes <- c(
  "CDP-all" = 16,
  "CDP-target" = 17,
  "FDP" = 15,
  "FDP-detection" = 23,
  "LDP-all" = 3,
  "LDP-target" = 7
)

load_result <- function(experiment, seed, scenario = NULL) {
  file <- file.path(result_dir(experiment, scenario), paste0(seed, ".RData"))
  if (!file.exists(file)) {
    stop("Missing result file: ", file)
  }

  env <- new.env(parent = emptyenv())
  load(file, envir = env)
  env
}

summarize_matrix <- function(experiment, scenario = NULL, object = "error") {
  mats <- lapply(seeds, function(seed) {
    get(object, envir = load_result(experiment, seed, scenario))
  })

  arr <- simplify2array(mats)
  avg <- apply(arr, c(1, 2), mean)
  sdev <- apply(arr, c(1, 2), sd)
  dimnames(avg) <- dimnames(mats[[1]])
  dimnames(sdev) <- dimnames(mats[[1]])
  list(avg = avg, sd = sdev)
}

summarize_exam <- function(experiment, courses, methods) {
  mats <- lapply(seeds, function(seed) {
    error <- get("error", envir = load_result(experiment, seed))
    course_errors <- lapply(courses, function(k) {
      error[[k]][methods, , drop = FALSE]
    })
    Reduce("+", course_errors) / length(course_errors)
  })

  arr <- simplify2array(mats)
  avg <- apply(arr, c(1, 2), mean)
  sdev <- apply(arr, c(1, 2), sd)
  dimnames(avg) <- dimnames(mats[[1]])
  dimnames(sdev) <- dimnames(mats[[1]])
  list(avg = avg, sd = sdev)
}

error_df <- function(summary, x_values, methods) {
  avg <- summary$avg[methods, , drop = FALSE]
  sdev <- summary$sd[methods, , drop = FALSE]
  data.frame(
    error = as.vector(avg),
    sd = as.vector(sdev),
    x = rep(x_values, each = length(methods)),
    method = rep(rownames(avg), length(x_values))
  )
}

standardize_detection_label <- function(df) {
  df %>%
    filter(!method %in% c("None-DP", "FDP-detection")) %>%
    mutate(method = recode(method, "FDP-detection-sample" = "FDP-detection"))
}

method_plot <- function(df, x_breaks, x_label = NULL, scientific_x = FALSE) {
  x_labels <- if (scientific_x) {
    format(x_breaks, scientific = FALSE)
  } else {
    waiver()
  }

  ggplot(df, aes(x = x, y = log(error), group = method, color = method, shape = method)) +
    geom_point(size = 3) +
    geom_line() +
    scale_color_manual(values = method_colors) +
    scale_shape_manual(values = method_shapes) +
    scale_x_continuous(breaks = x_breaks, labels = x_labels) +
    xlab(x_label) +
    theme_bw() +
    theme(legend.position = "bottom") +
    guides(colour = guide_legend(nrow = 1))
}

save_figure <- function(plot, stem, width = 8, height = 4) {
  ggsave(figure_file(stem), plot, width = width, height = height, units = "in")
  invisible(plot)
}

plot_dp_pair <- function(scenario, stem, n_min = 30000) {
  n_list <- (1:10) * 10000
  epsilon_list <- seq(0.6, 2.4, 0.2)
  methods <- c("None-DP", "CDP-all", "CDP-target", "FDP",
               "FDP-detection", "FDP-detection-sample", "LDP-all", "LDP-target")

  dp_n <- error_df(summarize_matrix("dp-comparison", scenario), n_list, methods) %>%
    standardize_detection_label() %>%
    filter(x >= n_min)
  p_n <- method_plot(
    dp_n,
    x_breaks = seq(n_min, 100000, 20000),
    scientific_x = TRUE
  )

  dp_eps <- error_df(summarize_matrix("dp-comparison-epsilon", scenario), epsilon_list, methods) %>%
    standardize_detection_label()
  p_eps <- method_plot(dp_eps, x_breaks = epsilon_list, x_label = TeX(r"($\epsilon$)"))

  save_figure(ggarrange(p_n, p_eps, nrow = 1, common.legend = TRUE, legend = "bottom"), stem)
}

plot_logistic_pair <- function(scenario, stem) {
  n_list <- (1:10) * 10000
  epsilon_list <- seq(0.6, 2.4, 0.2)
  methods <- c("None-DP", "CDP-all", "CDP-target", "FDP",
               "FDP-detection", "FDP-detection-sample", "LDP-all", "LDP-target")

  logistic_n <- error_df(summarize_matrix("dp-comparison-logistic", scenario), n_list, methods) %>%
    standardize_detection_label() %>%
    filter(x >= 30000)
  p_n <- method_plot(
    logistic_n,
    x_breaks = seq(30000, 100000, 20000),
    scientific_x = TRUE
  )

  logistic_eps <- error_df(summarize_matrix("dp-comparison-epsilon-logistic", scenario), epsilon_list, methods) %>%
    standardize_detection_label()
  p_eps <- method_plot(logistic_eps, x_breaks = epsilon_list, x_label = TeX(r"($\epsilon$)"))

  save_figure(ggarrange(p_n, p_eps, nrow = 1, common.legend = TRUE, legend = "bottom"), stem)
}

## Figure 2
plot_dp_pair(scenario_name(10, 20), "dp-comparison-combined-Fig-2")

## Figure 3
h_list <- seq(0, 1, 0.1)
h_methods <- c("None-DP", "CDP-all", "CDP-target", "FDP",
               "FDP-detection", "FDP-detection-sample", "LDP-all", "LDP-target")
h_plot_data <- error_df(summarize_matrix("h-outlier", scenario_name(10, 20)), h_list, h_methods) %>%
  standardize_detection_label()
h_plot <- method_plot(h_plot_data, x_breaks = h_list)
save_figure(h_plot, "h-outlier-Fig-3")

## Figure 4
epsilon_list <- seq(1, 10, 0.5)
exam_methods <- c("CDP-all", "CDP-target", "FDP",
                  "FDP-detection-sample", "LDP-all", "LDP-target")
exam_data <- error_df(summarize_exam("exam", 1:7, exam_methods), epsilon_list, exam_methods) %>%
  mutate(method = recode(method, "FDP-detection-sample" = "FDP-detection")) %>%
  filter(x >= 5, x <= 9)
exam_plot <- method_plot(exam_data, x_breaks = epsilon_list, x_label = TeX(r"($\epsilon$)"))
save_figure(exam_plot, "exam-Fig-4")

## Figure 5
outlier_methods <- c("CDP-all", "CDP-target", "FDP", "FDP-detection", "LDP-all", "LDP-target")
exam_outlier_data <- error_df(summarize_exam("exam-outlier", 2:7, outlier_methods), epsilon_list, outlier_methods) %>%
  filter(x >= 5, x <= 9)
exam_outlier_plot <- method_plot(exam_outlier_data, x_breaks = epsilon_list, x_label = TeX(r"($\epsilon$)"))
save_figure(exam_outlier_plot, "exam-outlier-Fig-5")

## Figure 7
small_n_list <- c(1000, 2000, 3000, 5000, 8000, 10000, 15000)
small_n_data <- error_df(summarize_matrix("dp-comparison-small-n", scenario_name(10, 20)), small_n_list, h_methods) %>%
  standardize_detection_label() %>%
  filter(x > 1000)
small_n_plot <- method_plot(
  small_n_data,
  x_breaks = small_n_list,
  scientific_x = TRUE
)
save_figure(small_n_plot, "dp-comparison-small-n-Fig-7")

## Figures 8 and 9
plot_dp_pair(scenario_name(20, 50), "dp-comparison-d20-K50-Fig-8")
plot_dp_pair(scenario_name(5, 20), "dp-comparison-d5-K20-Fig-9")

## Figure 10
plot_logistic_pair(scenario_name(10, 20), "dp-comparison-logistic-Fig-10")

## Figure 11
rho_summary <- summarize_matrix("fdp-rho-sensitivity", scenario_name(10, 20))
rho_list <- as.numeric(rownames(rho_summary$avg))
rho_epsilon_list <- as.numeric(colnames(rho_summary$avg))
rho_data <- data.frame(
  error = as.vector(rho_summary$avg),
  sd = as.vector(rho_summary$sd),
  rho = rep(rho_list, length(rho_epsilon_list)),
  epsilon = factor(rep(rho_epsilon_list, each = length(rho_list)))
)
rho_plot <- ggplot(rho_data, aes(x = rho, y = error, group = epsilon, color = epsilon, shape = epsilon)) +
  geom_point(size = 3) +
  geom_line() +
  scale_x_continuous(breaks = rho_list) +
  scale_color_manual(values = c("#000000", "#E69F00", "#56B4E9", "purple", "#009E73", "#999999")) +
  xlab(TeX(r"($\rho$)")) +
  labs(color = TeX(r"($\epsilon$)"), shape = TeX(r"($\epsilon$)")) +
  theme_bw() +
  theme(legend.position = "bottom") +
  guides(colour = guide_legend(nrow = 1))
save_figure(rho_plot, "fdp-rho-sensitivity-Fig-11")

## Figure 12
detection_summary <- summarize_matrix("detection-sensitivity", object = "error_detection")
detection_c_list <- as.numeric(rownames(detection_summary$avg))
detection_h_list <- as.numeric(colnames(detection_summary$avg))
detection_data <- data.frame(
  error = as.vector(detection_summary$avg),
  sd = as.vector(detection_summary$sd),
  c = factor(rep(detection_c_list, length(detection_h_list))),
  h = rep(detection_h_list, each = length(detection_c_list))
)
detection_plot <- ggplot(detection_data, aes(x = h, y = log(error), group = c, color = c, shape = c)) +
  geom_point(size = 3) +
  geom_line() +
  xlab(TeX(r"($h$)")) +
  labs(color = TeX(r"($\tilde{c}$)"), shape = TeX(r"($\tilde{c}$)")) +
  theme_bw() +
  theme(legend.position = "bottom") +
  guides(colour = guide_legend(nrow = 1))
save_figure(detection_plot, "detection-sensitivity-Fig-12")

## Figure 13
exam_outlier_2_data <- error_df(summarize_exam("exam-outlier-2", 3:7, outlier_methods), epsilon_list, outlier_methods) %>%
  filter(x >= 5, x <= 9)
exam_outlier_2_plot <- method_plot(exam_outlier_2_data, x_breaks = epsilon_list, x_label = TeX(r"($\epsilon$)"))
save_figure(exam_outlier_2_plot, "exam-outlier-2-Fig-13")
