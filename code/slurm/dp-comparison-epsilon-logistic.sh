#!/bin/sh
# Run the logistic epsilon comparison experiment from the repository root.
#SBATCH --account=stats
#SBATCH --job-name=dp-comparison-epsilon-logistic
#SBATCH -c 1
#SBATCH -t 00-01:00
#SBATCH --mem-per-cpu=3gb
#SBATCH --output=output/logs/dp-comparison-epsilon-logistic-%A_%a.out

export OMP_NUM_THREADS=1

module load R/4.1.0

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

d=${1:-10}
K=${2:-20}

mkdir -p output/logs/dp-comparison-epsilon-logistic
R CMD BATCH --no-save --vanilla "--args ${d} ${K}" code/experiments/dp-comparison-epsilon-logistic.R "output/logs/dp-comparison-epsilon-logistic/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.txt"
