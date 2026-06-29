# Output Directory

This directory stores files created by the analysis scripts and the precomputed results used by `code/plot.R`.

- `results/`: `.RData` files written by the experiment scripts. Parameterized simulations use scenario subdirectories such as `dp-comparison/d10_K20/`.
- `figures/`: figure PDFs created by `code/plot.R`.

These subdirectories are included so the repository can be uploaded directly and regenerated as analyses are rerun.
