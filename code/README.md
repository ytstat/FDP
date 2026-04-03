# Code Directory

This directory contains the scripts needed to reproduce the analyses and figures in the repository.

- `funcs.R`: core estimation, detection, and utility functions used by the experiments.
- `repro_utils.R`: small helpers for seed handling and repository-relative paths.
- `experiments/`: main analysis scripts. Each script writes `.RData` output into `output/results/<experiment>/`.
- `slurm/`: SLURM submission scripts that run the corresponding experiment from the repository root.
- `plot.R`: post-processing script that reads available `.RData` files from `output/results/` and saves figures to `output/figures/`.

The main experiment entry points in the current repository are:

- `experiments/dp-comparison-n.R`
- `experiments/dp-comparison-epsilon.R`
- `experiments/h-outlier.R`
- `experiments/detection-sensitivity.R`
- `experiments/exam.R`
- `experiments/exam-outlier.R`

All scripts are written to be run from the repository root so that relative paths remain stable across machines.
