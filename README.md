# Unruptured Aneurysm ML

Transparent R pipeline for severe outcome prediction in unruptured aneurysm patients using the local development cohort files for training and the external cohort for validation.

## Repository Structure

- `config/`: data sources, harmonized feature map, exclusions, model benchmarks, and outcome definitions
- `R/`: reusable R functions for data preparation, modeling, evaluation, and reporting
- `scripts/`: ordered entrypoints for rebuilding the full analysis
- `calculator/`: Shiny web calculator built around the locked weighted XGBoost model
- `reports/`: Markdown audit trail and final results summary
- `results/`: generated datasets, metrics, figures, and saved models
- `data_dictionary/`: notes about variable harmonization and reporting intent

## Planned Analysis Rules

- Primary development outcome: `dindo_scores >= 3`
- Modeling uses pre-operative harmonized predictors only
- `caseid`, post-operative fields, CPT fields, ASA, model-generated risk scores, completeness flags, and external-only descriptive variables are excluded from modeling
- External-only aneurysm detail is retained for descriptive cohort reporting only
- Hyperparameter tuning is optimized primarily for PR AUC

## Run Order

From the repository root, run:

```powershell
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/01_build_development_dataset.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/02_build_external_dataset.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/03_train_benchmarks.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/03b_train_benchmarks_smote.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/04_internal_evaluation.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/04b_internal_evaluation_smote.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/05_external_validation.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/05c_external_validation_smote.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/05b_generate_shap_explanations.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/05d_generate_shap_explanations_smote.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/06_render_report.R
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/00_run_smoke_tests.R
```

## Explainability and Testing

- `scripts/05b_generate_shap_explanations.R` computes Monte Carlo Shapley-style explanations for the selected primary model on the external cohort.
- `scripts/05d_generate_shap_explanations_smote.R` computes the same explanation workflow for the selected primary SMOTE model on the external cohort.
- `scripts/00_run_smoke_tests.R` runs smoke tests that verify core pipeline artifacts, harmonized columns, excluded-variable removal, and SHAP/report outputs.
- `scripts/07_smoke_test_calculator.R` verifies that the weighted XGBoost calculator can load, source its app file, and return a valid sample prediction.

## Calculator

The weighted XGBoost calculator is a Shiny app intended for cautious clinical trialing, not autonomous decision-making.

Run it from the repository root:

```powershell
"C:\Program Files\R\R-4.4.1\bin\Rscript.exe" scripts/run_weighted_xgboost_calculator.R
```

## Required R Packages

The workflow expects these packages to be available:

- `readxl`
- `caret`
- `glmnet`
- `randomForest`
- `xgboost`

If a benchmark package is unavailable, that model will be marked as failed in `results/metrics/training_status.csv` and the rest of the pipeline can continue.
