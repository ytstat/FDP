#!/bin/sh
# Run the exam experiment from the repository root.
#SBATCH --account=stats
#SBATCH --job-name=exam
#SBATCH -c 1
#SBATCH -t 00-00:50
#SBATCH --mem-per-cpu=2gb
#SBATCH --output=output/logs/exam-%A_%a.out

export OMP_NUM_THREADS=1

module load R/4.1.0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

mkdir -p output/logs/exam
R CMD BATCH --no-save --vanilla code/experiments/exam.R "output/logs/exam/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.txt"
