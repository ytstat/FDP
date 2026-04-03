#!/bin/sh
#
# Run the h-outlier experiment from the repository root.
#
#SBATCH --account=stats
#SBATCH --job-name=h-outlier
#SBATCH -c 1
#SBATCH -t 00-00:50
#SBATCH --mem-per-cpu=3gb
#SBATCH --output=output/logs/h-outlier-%A_%a.out

export OMP_NUM_THREADS=1

module load R/4.1.0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

mkdir -p output/logs/h-outlier
R CMD BATCH --no-save --vanilla code/experiments/h-outlier.R "output/logs/h-outlier/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.txt"
