root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "reporting.R"))

split_obj <- readRDS(file.path(root, "results", "datasets", "internal_split_weighted.rds"))
training_status <- read_csv_config(file.path(root, "results", "metrics", "training_status_weighted.csv"))
successful <- training_status[training_status$status == "trained", , drop = FALSE]
if (nrow(successful) == 0) {
  stop("No trained weighted benchmark models are available for internal evaluation.")
}

train_preprocessor <- readRDS(file.path(root, "results", "models", "train_preprocessor_weighted.rds"))
x_test <- apply_preprocessor(split_obj$test_data, train_preprocessor, outcome_col = "severe_outcome")
y_test <- ensure_factor_outcome(split_obj$test_data$severe_outcome)

metric_rows <- list()
topk_rows <- list()
threshold_grid_rows <- list()
prediction_rows <- list()
for (i in seq_len(nrow(successful))) {
  model_name <- successful$model_name[i]
  fit <- readRDS(file.path(root, "results", "models", sprintf("%s_weighted_train_fit.rds", model_name)))
  probs <- predict_probabilities(fit, x_test)
  bundle <- build_prediction_artifacts(y_test, probs, model_name, "internal_test_weighted")
  metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
  topk_rows[[length(topk_rows) + 1]] <- bundle$topk
  threshold_grid_rows[[length(threshold_grid_rows) + 1]] <- bundle$threshold_grid
  prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
  save_performance_plots(y_test, probs, file.path(root, "results", "figures", sprintf("%s_internal_weighted", model_name)), sprintf("%s Internal Test Weighted", model_name))
}

internal_metrics <- do.call(rbind, metric_rows)
internal_metrics <- internal_metrics[order(-internal_metrics$pr_auc, -internal_metrics$roc_auc), ]
internal_topk <- do.call(rbind, topk_rows)
internal_topk <- internal_topk[order(internal_topk$model_name, internal_topk$proportion_flagged), ]
internal_threshold_grid <- do.call(rbind, threshold_grid_rows)
internal_threshold_grid <- internal_threshold_grid[order(internal_threshold_grid$model_name, internal_threshold_grid$threshold_rule), ]
internal_predictions <- do.call(rbind, prediction_rows)

selected_threshold_defs <- list()
selected_threshold_metrics <- list()
for (model_name in unique(internal_predictions$model_name)) {
  model_predictions <- internal_predictions[internal_predictions$model_name == model_name, , drop = FALSE]
  model_grid <- internal_threshold_grid[internal_threshold_grid$model_name == model_name, , drop = FALSE]
  rules <- select_threshold_rules(model_grid, model_predictions$predicted_probability)
  rules$model_name <- model_name
  rules$dataset <- "internal_test_weighted"
  selected_threshold_defs[[length(selected_threshold_defs) + 1]] <- rules[, c("model_name", "dataset", "rule_name", "threshold", "flagged_fraction")]
  selected_threshold_metrics[[length(selected_threshold_metrics) + 1]] <- apply_threshold_rules(
    truth = model_predictions$truth,
    probs = model_predictions$predicted_probability,
    model_name = model_name,
    dataset = "internal_test_weighted",
    threshold_rules = rules
  )
}

internal_threshold_defs <- do.call(rbind, selected_threshold_defs)
internal_threshold_rule_metrics <- do.call(rbind, selected_threshold_metrics)

utils::write.csv(internal_metrics, file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_topk, file.path(root, "results", "metrics", "internal_test_topk_metrics_weighted.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_grid, file.path(root, "results", "metrics", "internal_test_threshold_grid_weighted.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_defs, file.path(root, "results", "metrics", "internal_test_selected_thresholds_weighted.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_rule_metrics, file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics_weighted.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_predictions, file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv"), row.names = FALSE, na = "")

selected <- build_internal_selection_summary(internal_metrics, internal_topk, selection_col = "primary_model_weighted")
utils::write.csv(selected, file.path(root, "results", "metrics", "model_selection_weighted.csv"), row.names = FALSE, na = "")

development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
development$severe_outcome <- ensure_factor_outcome(development$severe_outcome)
full_preprocessor <- fit_preprocessor(development, outcome_col = "severe_outcome")
saveRDS(full_preprocessor, file.path(root, "results", "models", "full_preprocessor_weighted.rds"))
x_full <- apply_preprocessor(development, full_preprocessor, outcome_col = "severe_outcome")
y_full <- ensure_factor_outcome(development$severe_outcome)

for (i in seq_len(nrow(successful))) {
  model_name <- successful$model_name[i]
  tuned_fit <- readRDS(file.path(root, "results", "models", sprintf("%s_weighted_tuning.rds", model_name)))
  weighted_params <- tuned_fit$best_params
  weighted_params$use_weights <- TRUE
  final_fit <- fit_model_object(model_name, x_full, y_full, weighted_params)
  saveRDS(final_fit, file.path(root, "results", "models", sprintf("%s_weighted_final_full.rds", model_name)))
}

append_project_log(
  root,
  "04c Internal Evaluation With Class Weights",
  c(
    sprintf("- Internal weighted test metrics generated for: %s", paste(successful$model_name, collapse = ", ")),
    sprintf("- Selected primary weighted model: `%s`", selected$primary_model_weighted[1]),
    "- Saved weighted top-k capture, threshold grid, and locked threshold-rule outputs.",
    "- Final full-development weighted model fits saved for external validation."
  )
)
