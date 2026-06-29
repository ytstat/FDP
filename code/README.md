# Code Directory

This directory contains scripts for reproducing the analyses and figures in the repository.

- `funcs.R`: linear-regression estimation, detection, and utility functions.
- `funcs-logistic.R`: logistic-regression analogues used by the appendix simulations.
- `repro_utils.R`: seed handling and repository-relative path helpers.
- `experiments/`: main analysis scripts. Each script writes `.RData` output under `output/results/`.
- `slurm/`: SLURM submission scripts that run the corresponding experiment from the repository root.
- `plot.R`: post-processing script that reads `.RData` files from `output/results/` and saves figures to `output/figures/`.

Main entry points:

- `experiments/dp-comparison.R`
- `experiments/dp-comparison-epsilon.R`
- `experiments/h-outlier.R`
- `experiments/detection-sensitivity.R`
- `experiments/exam.R`
- `experiments/exam-outlier.R`

Appendix entry points:

- `experiments/dp-comparison-small-n.R`
- `experiments/dp-comparison-logistic.R`
- `experiments/dp-comparison-epsilon-logistic.R`
- `experiments/fdp-rho-sensitivity.R`
- `experiments/exam-outlier-2.R`

Run scripts from the repository root so relative paths resolve consistently.
