# Federated Transfer Learning with Differential Privacy

This repository contains reproducibility materials for the paper *Federated Transfer Learning with Differential Privacy* by Mengchu Li, Ye Tian, Yang Feng, and Yi Yu.

The code reproduces the numerical experiments in the manuscript: low-dimensional linear-regression simulations, logistic-regression simulations, sensitivity analyses, and the exam-score real-data experiments with source contamination.

## Repository Structure

- `manuscript/`: latest manuscript PDF.
- `data/`: input data for the empirical exam-score analyses.
- `code/`: experiment scripts, shared helper functions, plotting code, and SLURM wrappers.
- `output/`: precomputed `.RData` files and generated figure PDFs.

## Analyses

- `code/experiments/dp-comparison.R`: homogeneous linear-regression simulation varying the per-site sample size `n`.
- `code/experiments/dp-comparison-epsilon.R`: homogeneous linear-regression simulation varying the privacy budget `epsilon`.
- `code/experiments/h-outlier.R`: heterogeneous-source simulation varying the heterogeneity level `h`.
- `code/experiments/detection-sensitivity.R`: detection-threshold sensitivity analysis varying `h` and `\tilde{c}`.
- `code/experiments/dp-comparison-small-n.R`: additional small-sample-size simulation.
- `code/experiments/dp-comparison-logistic.R`: logistic-regression simulation varying `n`.
- `code/experiments/dp-comparison-epsilon-logistic.R`: logistic-regression simulation varying `epsilon`.
- `code/experiments/fdp-rho-sensitivity.R`: FDP step-size sensitivity analysis.
- `code/experiments/exam.R`: empirical exam-score prediction analysis.
- `code/experiments/exam-outlier.R`: empirical exam-score analysis with one contaminated course.
- `code/experiments/exam-outlier-2.R`: empirical exam-score analysis with two contaminated courses.
- `code/plot.R`: aggregates saved `.RData` files and recreates manuscript Figures 2-5 and 7-13.

## Software Requirements

The code is written in R. The scripts use:

- `dplyr`
- `rmutil`
- `ggplot2`
- `ggpubr`
- `latex2exp`

The SLURM scripts in `code/slurm/` assume an HPC environment with `sbatch` and an R module such as `R/4.1.0`. Adjust those settings if you run on a different system.

## Reproducing The Analyses

Run commands from the repository root. Each experiment writes one `.RData` file per seed to `output/results/`. Parameterized simulations use scenario folders such as `output/results/dp-comparison/d10_K20/`.

For one local replicate of the main experiments:

```bash
SEED=1 Rscript code/experiments/dp-comparison.R 10 20
SEED=1 Rscript code/experiments/dp-comparison-epsilon.R 10 20
SEED=1 Rscript code/experiments/h-outlier.R 10 20
SEED=1 Rscript code/experiments/detection-sensitivity.R
SEED=1 Rscript code/experiments/exam.R
SEED=1 Rscript code/experiments/exam-outlier.R
```

Additional appendix experiments:

```bash
SEED=1 Rscript code/experiments/dp-comparison-small-n.R 10 20
SEED=1 Rscript code/experiments/dp-comparison.R 20 50
SEED=1 Rscript code/experiments/dp-comparison-epsilon.R 20 50
SEED=1 Rscript code/experiments/dp-comparison.R 5 20
SEED=1 Rscript code/experiments/dp-comparison-epsilon.R 5 20
SEED=1 Rscript code/experiments/dp-comparison-logistic.R 10 20
SEED=1 Rscript code/experiments/dp-comparison-epsilon-logistic.R 10 20
SEED=1 Rscript code/experiments/fdp-rho-sensitivity.R 10 20
SEED=1 Rscript code/experiments/exam-outlier-2.R
```

For SLURM runs, use arrays over 100 seeds:

```bash
sbatch --array=1-100 code/slurm/dp-comparison.sh 10 20
sbatch --array=1-100 code/slurm/dp-comparison-epsilon.sh 10 20
sbatch --array=1-100 code/slurm/h-outlier.sh 10 20
sbatch --array=1-100 code/slurm/detection-sensitivity.sh
sbatch --array=1-100 code/slurm/exam.sh
sbatch --array=1-100 code/slurm/exam-outlier.sh
```

After the needed result files are present, recreate all figure PDFs with:

```bash
Rscript code/plot.R
```

The public repository includes the latest precomputed result files used by `code/plot.R`.

## Data

- `data/Exam_Score_Prediction.csv` is used by `exam.R`, `exam-outlier.R`, and `exam-outlier-2.R`.
- Synthetic experiment scripts generate their data internally.
