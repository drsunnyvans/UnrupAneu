source(file.path(getwd(), "R", "utils.R"))
source(file.path(getwd(), "R", "calculator.R"))

root <- find_project_root()
calculator_dir <- file.path(root, "calculator")
models_dir <- file.path(calculator_dir, "models")
metrics_dir <- file.path(calculator_dir, "metrics")
data_dir <- file.path(calculator_dir, "data")
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(metrics_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

model_files <- c(
  "ensemble_stacked_logistic.rds",
  "xgboost_final_full.rds",
  "ann_smote_final_full.rds",
  "xgboost_weighted_final_full.rds",
  "full_preprocessor.rds",
  "full_preprocessor_smote.rds",
  "full_preprocessor_weighted.rds"
)

metric_files <- c(
  "ensemble_internal_selected_thresholds.csv",
  "ensemble_internal_test_metrics.csv",
  "ensemble_external_validation_metrics.csv"
)

for (filename in model_files) {
  file.copy(file.path(root, "results", "models", filename), file.path(models_dir, filename), overwrite = TRUE)
}

for (filename in metric_files) {
  file.copy(file.path(root, "results", "metrics", filename), file.path(metrics_dir, filename), overwrite = TRUE)
}

bundle <- load_stacked_ensemble_calculator_bundle(root)
saveRDS(bundle$development_probabilities, file.path(data_dir, "development_probability_reference.rds"))
saveRDS(bundle$development_summary, file.path(data_dir, "development_summary.rds"))

cat("Calculator deployment assets bundled successfully.\n")
