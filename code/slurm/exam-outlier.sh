#!/bin/sh
# Run the exam-outlier experiment from the repository root.
#SBATCH --account=stats
#SBATCH --job-name=exam-outlier
#SBATCH -c 1
#SBATCH -t 00-00:50
#SBATCH --mem-per-cpu=2gb
#SBATCH --output=output/logs/exam-outlier-%A_%a.out

export OMP_NUM_THREADS=1

module load R/4.1.0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

mkdir -p output/logs/exam-outlier
R CMD BATCH --no-save --vanilla code/experiments/exam-outlier.R "output/logs/exam-outlier/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.txt"
