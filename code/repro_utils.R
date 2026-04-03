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

result_file <- function(experiment, seed) {
  # Each experiment stores one .RData file per replicate/seed.
  file.path(
    ensure_dir(file.path("output", "results", experiment)),
    paste0(seed, ".RData")
  )
}

result_files <- function(experiment) {
  result_dir <- file.path("output", "results", experiment)
  if (!dir.exists(result_dir)) {
    return(character())
  }

  sort(list.files(result_dir, pattern = "\\.RData$", full.names = TRUE))
}

figure_file <- function(stem, extension = "pdf") {
  file.path(
    ensure_dir(file.path("output", "figures")),
    paste0(stem, ".", extension)
  )
}
