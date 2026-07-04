root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "reporting.R"))

external <- read_csv_config(file.path(root, "results", "datasets", "external_model_dataset.csv"))
external$severe_outcome <- ensure_factor_outcome(external$severe_outcome)
full_preprocessor <- readRDS(file.path(root, "results", "models", "full_preprocessor.rds"))
x_external <- apply_preprocessor(external, full_preprocessor, outcome_col = "severe_outcome")
y_external <- ensure_factor_outcome(external$severe_outcome)
training_status <- read_csv_config(file.path(root, "results", "metrics", "training_status.csv"))
successful <- training_status[training_status$status == "trained", , drop = FALSE]
threshold_defs <- read_csv_config(file.path(root, "results", "metrics", "internal_test_selected_thresholds.csv"))

metric_rows <- list()
topk_rows <- list()
prediction_rows <- list()
threshold_rule_rows <- list()
for (i in seq_len(nrow(successful))) {
  model_name <- successful$model_name[i]
  final_fit <- readRDS(file.path(root, "results", "models", sprintf("%s_final_full.rds", model_name)))
  probs <- predict_probabilities(final_fit, x_external)
  bundle <- build_prediction_artifacts(y_external, probs, model_name, "external_validation")
  metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
  topk_rows[[length(topk_rows) + 1]] <- bundle$topk
  prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
  model_thresholds <- threshold_defs[threshold_defs$model_name == model_name, , drop = FALSE]
  if (nrow(model_thresholds) > 0) {
    threshold_rule_rows[[length(threshold_rule_rows) + 1]] <- apply_threshold_rules(
      truth = y_external,
      probs = probs,
      model_name = model_name,
      dataset = "external_validation",
      threshold_rules = model_thresholds
    )
  }
  save_performance_plots(y_external, probs, file.path(root, "results", "figures", sprintf("%s_external", model_name)), sprintf("%s External Validation", model_name))
}

external_metrics <- do.call(rbind, metric_rows)
external_metrics <- external_metrics[order(-external_metrics$pr_auc, -external_metrics$roc_auc), ]
external_topk <- do.call(rbind, topk_rows)
external_topk <- external_topk[order(external_topk$model_name, external_topk$proportion_flagged), ]
external_predictions <- do.call(rbind, prediction_rows)
external_threshold_rule_metrics <- do.call(rbind, threshold_rule_rows)
utils::write.csv(external_metrics, file.path(root, "results", "metrics", "external_validation_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(external_topk, file.path(root, "results", "metrics", "external_validation_topk_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(external_predictions, file.path(root, "results", "metrics", "external_validation_predictions.csv"), row.names = FALSE, na = "")
utils::write.csv(external_threshold_rule_metrics, file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "05 External Validation",
  c(
    sprintf("- External validation rows scored: %s", nrow(external)),
    sprintf("- Models externally validated: %s", paste(successful$model_name, collapse = ", ")),
    sprintf("- External severe outcome events: %s", sum(y_external == "Yes", na.rm = TRUE)),
    "- Applied locked internal threshold rules to the external cohort."
  )
)
