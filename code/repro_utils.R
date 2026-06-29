# Utilities for running the repository from its root directory.
# These helpers keep file paths consistent across local and SLURM runs.

get_seed <- function(default = 1L) {
  # Prefer the SLURM array index when present, otherwise use SEED.
  for (name in c("SLURM_ARRAY_TASK_ID", "SEED")) {
    value <- Sys.getenv(name, unset = "")
    if (!nzchar(value)) {
      next
    }

    seed <- suppressWarnings(as.integer(value))
    if (!is.na(seed)) {
      return(seed)
    }
  }

  default
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

result_dir <- function(experiment, scenario = NULL) {
  parts <- c("output", "results", experiment)
  if (!is.null(scenario) && nzchar(scenario)) {
    parts <- c(parts, scenario)
  }
  do.call(file.path, as.list(parts))
}

result_file <- function(experiment, seed, scenario = NULL) {
  # Each experiment stores one .RData file per replicate/seed.
  file.path(
    ensure_dir(result_dir(experiment, scenario)),
    paste0(seed, ".RData")
  )
}

result_files <- function(experiment, scenario = NULL) {
  path <- result_dir(experiment, scenario)
  if (!dir.exists(path)) {
    return(character())
  }

  sort(list.files(path, pattern = "\\.RData$", full.names = TRUE))
}

scenario_name <- function(d, K) {
  paste0("d", d, "_K", K)
}

get_positive_int_arg <- function(args, position, default, name) {
  value <- default
  if (length(args) >= position) {
    value <- suppressWarnings(as.integer(args[[position]]))
  }

  if (is.na(value) || value <= 0L) {
    stop(sprintf("%s must be a positive integer.", name))
  }

  value
}

figure_file <- function(stem, extension = "pdf") {
  file.path(
    ensure_dir(file.path("output", "figures")),
    paste0(stem, ".", extension)
  )
}
