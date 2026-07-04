root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "ensemble.R"))
source(file.path(root, "R", "reporting.R"))

oof_stack <- read_csv_config(file.path(root, "results", "metrics", "ensemble_oof_train_predictions.csv"))
internal_test_stack <- read_csv_config(file.path(root, "results", "metrics", "ensemble_internal_test_predictions.csv"))
component_ids <- get_ensemble_components()$component_id

equal_weights <- data.frame(component_id = component_ids, weight = rep(1 / length(component_ids), length(component_ids)), stringsAsFactors = FALSE)
pr_weights <- compute_soft_vote_weights(oof_stack, component_ids)
stack_fit <- fit_stacked_logistic(oof_stack, component_ids)
stack_coefs <- data.frame(term = names(stats::coef(stack_fit)), coefficient = as.numeric(stats::coef(stack_fit)), stringsAsFactors = FALSE)

ensemble_predictions <- list(
  stacked_logistic = predict_stacked_logistic(stack_fit, internal_test_stack, component_ids),
  soft_vote_equal = soft_vote_predict(internal_test_stack, equal_weights),
  soft_vote_pr_weighted = soft_vote_predict(internal_test_stack, pr_weights)
)

metric_rows <- list()
topk_rows <- list()
threshold_grid_rows <- list()
prediction_rows <- list()
for (ensemble_name in names(ensemble_predictions)) {
  probs <- ensemble_predictions[[ensemble_name]]
  bundle <- build_prediction_artifacts(internal_test_stack$truth, probs, ensemble_name, "internal_test_ensemble")
  metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
  topk_rows[[length(topk_rows) + 1]] <- bundle$topk
  threshold_grid_rows[[length(threshold_grid_rows) + 1]] <- bundle$threshold_grid
  prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
  save_performance_plots(internal_test_stack$truth, probs, file.path(root, "results", "figures", sprintf("%s_internal_ensemble", ensemble_name)), sprintf("%s Internal Ensemble", ensemble_name))
}

internal_metrics <- do.call(rbind, metric_rows)
internal_metrics <- internal_metrics[order(-internal_metrics$pr_auc, -internal_metrics$roc_auc), ]
internal_topk <- do.call(rbind, topk_rows)
internal_threshold_grid <- do.call(rbind, threshold_grid_rows)
internal_predictions <- do.call(rbind, prediction_rows)

selected_threshold_defs <- list()
selected_threshold_metrics <- list()
for (ensemble_name in unique(internal_predictions$model_name)) {
  model_predictions <- internal_predictions[internal_predictions$model_name == ensemble_name, , drop = FALSE]
  model_grid <- internal_threshold_grid[internal_threshold_grid$model_name == ensemble_name, , drop = FALSE]
  rules <- select_threshold_rules(model_grid, model_predictions$predicted_probability)
  rules$model_name <- ensemble_name
  rules$dataset <- "internal_test_ensemble"
  selected_threshold_defs[[length(selected_threshold_defs) + 1]] <- rules[, c("model_name", "dataset", "rule_name", "threshold", "flagged_fraction")]
  selected_threshold_metrics[[length(selected_threshold_metrics) + 1]] <- apply_threshold_rules(
    truth = model_predictions$truth,
    probs = model_predictions$predicted_probability,
    model_name = ensemble_name,
    dataset = "internal_test_ensemble",
    threshold_rules = rules
  )
}

internal_threshold_defs <- do.call(rbind, selected_threshold_defs)
internal_threshold_rule_metrics <- do.call(rbind, selected_threshold_metrics)

utils::write.csv(equal_weights, file.path(root, "results", "metrics", "ensemble_equal_weights.csv"), row.names = FALSE, na = "")
utils::write.csv(pr_weights, file.path(root, "results", "metrics", "ensemble_pr_weights.csv"), row.names = FALSE, na = "")
utils::write.csv(stack_coefs, file.path(root, "results", "metrics", "ensemble_stacked_logistic_coefficients.csv"), row.names = FALSE, na = "")
saveRDS(stack_fit, file.path(root, "results", "models", "ensemble_stacked_logistic.rds"))

utils::write.csv(internal_metrics, file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_topk, file.path(root, "results", "metrics", "ensemble_internal_topk_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_grid, file.path(root, "results", "metrics", "ensemble_internal_threshold_grid.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_defs, file.path(root, "results", "metrics", "ensemble_internal_selected_thresholds.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_threshold_rule_metrics, file.path(root, "results", "metrics", "ensemble_internal_threshold_rule_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_predictions, file.path(root, "results", "metrics", "ensemble_internal_test_predictions_scored.csv"), row.names = FALSE, na = "")

selected <- build_internal_selection_summary(internal_metrics, internal_topk, selection_col = "primary_ensemble")
utils::write.csv(selected, file.path(root, "results", "metrics", "ensemble_model_selection.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "04d Internal Ensemble Evaluation",
  c(
    sprintf("- Ensemble candidates evaluated: %s", paste(unique(internal_metrics$model_name), collapse = ", ")),
    sprintf("- Selected primary ensemble: `%s`", selected$primary_ensemble[1]),
    "- Saved ensemble weights, stacked logistic coefficients, top-k capture, and locked threshold-rule outputs."
  )
)
