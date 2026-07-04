root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "ensemble.R"))
source(file.path(root, "R", "reporting.R"))

external_stack <- read_csv_config(file.path(root, "results", "metrics", "ensemble_external_predictions.csv"))
component_ids <- get_ensemble_components()$component_id
equal_weights <- read_csv_config(file.path(root, "results", "metrics", "ensemble_equal_weights.csv"))
pr_weights <- read_csv_config(file.path(root, "results", "metrics", "ensemble_pr_weights.csv"))
stack_fit <- readRDS(file.path(root, "results", "models", "ensemble_stacked_logistic.rds"))
threshold_defs <- read_csv_config(file.path(root, "results", "metrics", "ensemble_internal_selected_thresholds.csv"))

ensemble_predictions <- list(
  stacked_logistic = predict_stacked_logistic(stack_fit, external_stack, component_ids),
  soft_vote_equal = soft_vote_predict(external_stack, equal_weights),
  soft_vote_pr_weighted = soft_vote_predict(external_stack, pr_weights)
)

metric_rows <- list()
topk_rows <- list()
prediction_rows <- list()
threshold_rule_rows <- list()
for (ensemble_name in names(ensemble_predictions)) {
  probs <- ensemble_predictions[[ensemble_name]]
  bundle <- build_prediction_artifacts(external_stack$truth, probs, ensemble_name, "external_validation_ensemble")
  metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
  topk_rows[[length(topk_rows) + 1]] <- bundle$topk
  prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
  model_thresholds <- threshold_defs[threshold_defs$model_name == ensemble_name, , drop = FALSE]
  threshold_rule_rows[[length(threshold_rule_rows) + 1]] <- apply_threshold_rules(
    truth = external_stack$truth,
    probs = probs,
    model_name = ensemble_name,
    dataset = "external_validation_ensemble",
    threshold_rules = model_thresholds
  )
  save_performance_plots(external_stack$truth, probs, file.path(root, "results", "figures", sprintf("%s_external_ensemble", ensemble_name)), sprintf("%s External Ensemble", ensemble_name))
}

external_metrics <- do.call(rbind, metric_rows)
external_metrics <- external_metrics[order(-external_metrics$pr_auc, -external_metrics$roc_auc), ]
external_topk <- do.call(rbind, topk_rows)
external_threshold_rule_metrics <- do.call(rbind, threshold_rule_rows)
external_predictions <- do.call(rbind, prediction_rows)

utils::write.csv(external_metrics, file.path(root, "results", "metrics", "ensemble_external_validation_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(external_topk, file.path(root, "results", "metrics", "ensemble_external_topk_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(external_threshold_rule_metrics, file.path(root, "results", "metrics", "ensemble_external_threshold_rule_metrics.csv"), row.names = FALSE, na = "")
utils::write.csv(external_predictions, file.path(root, "results", "metrics", "ensemble_external_predictions_scored.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "05g External Ensemble Validation",
  c(
    sprintf("- Ensemble candidates externally validated: %s", paste(unique(external_metrics$model_name), collapse = ", ")),
    sprintf("- External rows scored for ensemble analysis: %s", nrow(external_stack)),
    "- Applied locked internal ensemble threshold rules to the external cohort."
  )
)
