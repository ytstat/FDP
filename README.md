# Federated Transfer Learning with Differential Privacy

This repository contains reproducibility materials for the paper *Federated Transfer Learning with Differential Privacy* by Mengchu Li, Ye Tian, Yang Feng, and Yi Yu.

The paper studies transfer learning in federated settings where two issues arise simultaneously: source-target heterogeneity across sites and privacy protection for each site's local data. It introduces a federated differential privacy framework, analyzes the tradeoff between privacy and statistical efficiency, and studies how privacy and heterogeneity jointly affect the benefit of transfer. The current public repository focuses on the numerical experiments for the linear regression setting and the empirical outlier illustration included in the manuscript.

## Repository Structure

- `README.md`: paper overview and instructions for reproducing the analyses.
- `manuscript/`: manuscript source files. This directory is intentionally left as a placeholder so the LaTeX source can be added later.
- `data/`: input data files used by the empirical analysis.
- `code/`: experiment scripts, helper functions, plotting code, and SLURM job scripts.
- `output/`: generated `.RData` files and figures.

## Analyses In This Repository

- `code/experiments/dp-comparison-n.R`: simulation comparing nonprivate, centralized DP, federated DP, and local DP estimators as the per-site sample size `n` varies.
- `code/experiments/dp-comparison-epsilon.R`: simulation comparing the same methods as the privacy budget `epsilon` varies.
- `code/experiments/h-outlier.R`: simulation studying the effect of source heterogeneity and outlier contamination, including detection-based variants.
- `code/experiments/detection-sensitivity.R`: sensitivity analysis for the private source-detection step as the heterogeneity level `h` and threshold parameter `c` vary.
- `code/experiments/exam.R`: empirical exam-score prediction analysis without artificial contamination.
- `code/experiments/exam-outlier.R`: empirical exam-score prediction example with one contaminated course to illustrate robustness of the transfer procedures.
- `code/plot.R`: section-based plotting script that aggregates saved `.RData` files and recreates the figures corresponding to the experiment blocks already coded there.

## Software Requirements

The code is written in R. The current scripts use the following packages:

- `dplyr`
- `rmutil`
- `ggplot2`
- `ggpubfigs`
- `ggpubr`
- `latex2exp`
- `conflicted`

The SLURM scripts in `code/slurm/` assume an HPC environment with `sbatch` and an R module such as `R/4.1.0`. Adjust those settings if you run on a different system.

## How To Reproduce The Analyses

Run all commands from the repository root.

1. Generate experiment outputs.

```bash
SEED=1 Rscript code/experiments/dp-comparison-n.R
SEED=1 Rscript code/experiments/dp-comparison-epsilon.R
SEED=1 Rscript code/experiments/h-outlier.R
SEED=1 Rscript code/experiments/detection-sensitivity.R
SEED=1 Rscript code/experiments/exam.R
SEED=1 Rscript code/experiments/exam-outlier.R
```

If you are using SLURM, the matching submission scripts are:

```bash
sbatch --array=1-200 code/slurm/dp-comparison.sh
sbatch --array=1-200 code/slurm/dp-comparison-epsilon.sh
sbatch --array=1-200 code/slurm/h-outlier.sh
sbatch --array=1-200 code/slurm/detection-sensitivity.sh
sbatch --array=1-200 code/slurm/exam.sh
sbatch --array=1-200 code/slurm/exam-outlier.sh
```

2. Each experiment writes one `.RData` file per replicate to `output/results/<experiment>/`.

Current output directories used by the scripts are:

- `output/results/dp-comparison-n/`
- `output/results/dp-comparison-epsilon/`
- `output/results/h-outlier/`
- `output/results/detection-sensitivity/`
- `output/results/exam/`
- `output/results/exam-outlier/`

3. After the needed result files have been created, run:

```bash
Rscript code/plot.R
```

The plotting script is organized in independent blocks. It assumes the corresponding result files already exist and currently uses `n_rep <- 200` when averaging over Monte Carlo replicates. If you run fewer replicates or only a subset of experiments, adjust the relevant section in `code/plot.R` before plotting.

4. Add the manuscript source files to `manuscript/` when they are ready.

## Data

- `data/Exam_Score_Prediction.csv` is used by `code/experiments/exam.R` and `code/experiments/exam-outlier.R`.
- The remaining experiment scripts generate synthetic data internally.
