#!/bin/sh
# Run the detection-sensitivity experiment from the repository root.
#SBATCH --account=stats
#SBATCH --job-name=detection-sensitivity
#SBATCH -c 1
#SBATCH -t 00-02:00
#SBATCH --mem-per-cpu=3gb
#SBATCH --output=output/logs/detection-sensitivity-%A_%a.out

export OMP_NUM_THREADS=1

module load R/4.1.0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

mkdir -p output/logs/detection-sensitivity
R CMD BATCH --no-save --vanilla code/experiments/detection-sensitivity.R "output/logs/detection-sensitivity/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.txt"
