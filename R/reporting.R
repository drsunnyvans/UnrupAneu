source(file.path(find_project_root(), "R", "utils.R"))
source(file.path(find_project_root(), "R", "modeling.R"))

curve_points_roc <- function(truth, probs) {
  truth <- ensure_factor_outcome(truth)
  ord <- order(probs, decreasing = TRUE)
  truth <- truth[ord]
  probs <- probs[ord]
  thresholds <- unique(probs)
  points <- lapply(thresholds, function(threshold) {
    pred <- probs >= threshold
    tp <- sum(pred & truth == "Yes")
    tn <- sum(!pred & truth == "No")
    fp <- sum(pred & truth == "No")
    fn <- sum(!pred & truth == "Yes")
    data.frame(
      fpr = if ((fp + tn) == 0) 0 else fp / (fp + tn),
      tpr = if ((tp + fn) == 0) 0 else tp / (tp + fn)
    )
  })
  unique(do.call(rbind, points))
}

curve_points_pr <- function(truth, probs) {
  truth <- ensure_factor_outcome(truth)
  ord <- order(probs, decreasing = TRUE)
  y <- truth[ord] == "Yes"
  tp <- cumsum(y)
  fp <- cumsum(!y)
  data.frame(recall = tp / sum(y), precision = tp / pmax(tp + fp, 1))
}

save_performance_plots <- function(truth, probs, out_prefix, main_title) {
  roc_points <- curve_points_roc(truth, probs)
  pr_points <- curve_points_pr(truth, probs)

  grDevices::png(sprintf("%s_roc.png", out_prefix), width = 900, height = 700)
  graphics::plot(roc_points$fpr, roc_points$tpr, type = "l", lwd = 2, xlab = "False Positive Rate", ylab = "True Positive Rate", main = paste(main_title, "ROC"))
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  grDevices::dev.off()

  grDevices::png(sprintf("%s_pr.png", out_prefix), width = 900, height = 700)
  graphics::plot(pr_points$recall, pr_points$precision, type = "l", lwd = 2, xlab = "Recall", ylab = "Precision", main = paste(main_title, "PR Curve"))
  grDevices::dev.off()

  bins <- cut(probs, breaks = seq(0, 1, by = 0.1), include.lowest = TRUE)
  calib <- stats::aggregate(
    data.frame(prob = probs, truth = as.integer(ensure_factor_outcome(truth) == "Yes")),
    by = list(bin = bins),
    FUN = mean
  )
  grDevices::png(sprintf("%s_calibration.png", out_prefix), width = 900, height = 700)
  graphics::plot(calib$prob, calib$truth, xlim = c(0, 1), ylim = c(0, 1), pch = 19, xlab = "Mean Predicted Probability", ylab = "Observed Event Rate", main = paste(main_title, "Calibration"))
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  grDevices::dev.off()
}

build_prediction_artifacts <- function(truth, probs, model_name, dataset, topk_props = c(0.05, 0.10, 0.20), thresholds = seq(0.01, 0.99, by = 0.01)) {
  truth <- ensure_factor_outcome(truth)
  probs <- pmin(pmax(as.numeric(probs), 0), 1)
  metrics <- evaluate_predictions(truth, probs)
  metrics$model_name <- model_name
  metrics$dataset <- dataset
  metrics <- metrics[, c("model_name", "dataset", names(metrics)[!(names(metrics) %in% c("model_name", "dataset"))])]

  predictions <- data.frame(
    model_name = model_name,
    dataset = dataset,
    row_id = seq_along(probs),
    truth = as.character(truth),
    predicted_probability = probs,
    stringsAsFactors = FALSE
  )

  list(
    metrics = metrics,
    topk = top_k_capture_metrics(truth, probs, model_name, dataset, proportions = topk_props),
    threshold_grid = threshold_performance_grid(truth, probs, model_name, dataset, thresholds = thresholds),
    predictions = predictions
  )
}

build_internal_selection_summary <- function(internal_metrics, topk_metrics, primary_topk = "top_10_pct", selection_col = "primary_model") {
  focus_topk <- topk_metrics[topk_metrics$top_k == primary_topk, c("model_name", "events_captured", "event_rate", "recall", "ppv", "lift"), drop = FALSE]
  names(focus_topk) <- c("model_name", "topk_events_captured", "topk_event_rate", "topk_recall", "topk_ppv", "topk_lift")
  merged <- merge(internal_metrics, focus_topk, by = "model_name", all.x = TRUE)
  merged <- merged[order(-merged$pr_auc, -merged$topk_recall, -merged$topk_lift, -merged$roc_auc, merged$brier_score), , drop = FALSE]
  selected <- merged[1, , drop = FALSE]
  out <- selected[, c("model_name", "pr_auc", "roc_auc", "brier_score", "calibration_slope", "topk_recall", "topk_ppv", "topk_lift"), drop = FALSE]
  names(out) <- c(selection_col, "internal_pr_auc", "internal_roc_auc", "internal_brier_score", "internal_calibration_slope", "top10_recall", "top10_ppv", "top10_lift")
  out
}

read_optional_csv <- function(path) {
  if (!file.exists(path)) return(data.frame())
  read_csv_config(path)
}

pretty_model_label <- function(model_name) {
  mapping <- c(
    elastic_net = "Elastic Net",
    random_forest = "Random Forest",
    xgboost = "XGBoost",
    knn = "kNN",
    ann = "ANN",
    stacked_logistic = "Stacked Logistic Ensemble",
    soft_vote_equal = "Soft-Vote Ensemble (Equal)",
    soft_vote_pr_weighted = "Soft-Vote Ensemble (PR-Weighted)"
  )
  out <- as.character(model_name)
  matched <- out %in% names(mapping)
  out[matched] <- unname(mapping[out[matched]])
  out
}

label_with_arm <- function(data, arm_label) {
  if (is.null(data) || nrow(data) == 0) return(data.frame())
  data$arm <- arm_label
  data$model_arm <- paste(arm_label, data$model_name, sep = ": ")
  data
}

write_publication_comparison_tables <- function(root) {
  internal_original <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics.csv")), "Original")
  internal_smote <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics_smote.csv")), "SMOTE")
  internal_weighted <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv")), "Weighted")
  internal_combined <- do.call(rbind, Filter(function(x) nrow(x) > 0, list(internal_original, internal_smote, internal_weighted)))
  if (nrow(internal_combined) > 0) {
    internal_combined <- internal_combined[order(internal_combined$arm, -internal_combined$pr_auc, -internal_combined$roc_auc), c("arm", "model_name", "pr_auc", "roc_auc", "brier_score", "calibration_slope", "sensitivity", "specificity", "ppv", "npv"), drop = FALSE]
    utils::write.csv(internal_combined, file.path(root, "results", "metrics", "publication_internal_model_comparison.csv"), row.names = FALSE, na = "")
  }

  external_original <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics.csv")), "Original")
  external_smote <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics_smote.csv")), "SMOTE")
  external_weighted <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics_weighted.csv")), "Weighted")
  external_combined <- do.call(rbind, Filter(function(x) nrow(x) > 0, list(external_original, external_smote, external_weighted)))
  if (nrow(external_combined) > 0) {
    external_combined <- external_combined[order(external_combined$arm, -external_combined$pr_auc, -external_combined$roc_auc), c("arm", "model_name", "pr_auc", "roc_auc", "brier_score", "calibration_slope", "sensitivity", "specificity", "ppv", "npv"), drop = FALSE]
    utils::write.csv(external_combined, file.path(root, "results", "metrics", "publication_external_model_comparison.csv"), row.names = FALSE, na = "")
  }

  list(internal = internal_combined, external = external_combined)
}

write_publication_key_results_table <- function(root) {
  internal <- read_optional_csv(file.path(root, "results", "metrics", "publication_internal_model_comparison.csv"))
  external <- read_optional_csv(file.path(root, "results", "metrics", "publication_external_model_comparison.csv"))
  ext_topk_original <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics.csv")), "Original")
  ext_topk_smote <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics_smote.csv")), "SMOTE")
  ext_topk_weighted <- label_with_arm(read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics_weighted.csv")), "Weighted")
  ext_topk <- do.call(rbind, Filter(function(x) nrow(x) > 0, list(ext_topk_original, ext_topk_smote, ext_topk_weighted)))
  ext_topk <- ext_topk[ext_topk$top_k == "top_10_pct", c("arm", "model_name", "recall", "event_rate", "lift"), drop = FALSE]
  names(ext_topk) <- c("arm", "model_name", "external_top10_recall", "external_top10_event_rate", "external_top10_lift")

  merged <- merge(
    internal[, c("arm", "model_name", "pr_auc", "roc_auc"), drop = FALSE],
    external[, c("arm", "model_name", "pr_auc", "roc_auc"), drop = FALSE],
    by = c("arm", "model_name"),
    suffixes = c("_internal", "_external"),
    all = TRUE
  )
  merged <- merge(merged, ext_topk, by = c("arm", "model_name"), all.x = TRUE)
  merged <- merged[order(merged$arm, -merged$pr_auc_external, -merged$roc_auc_external), , drop = FALSE]
  names(merged) <- c("arm", "model_name", "internal_pr_auc", "internal_roc_auc", "external_pr_auc", "external_roc_auc", "external_top10_recall", "external_top10_event_rate", "external_top10_lift")
  merged$model_label <- pretty_model_label(merged$model_name)
  merged <- merged[, c("arm", "model_label", "internal_pr_auc", "internal_roc_auc", "external_pr_auc", "external_roc_auc", "external_top10_recall", "external_top10_event_rate", "external_top10_lift"), drop = FALSE]
  names(merged)[names(merged) == "model_label"] <- "model"

  ensemble_internal <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"))
  ensemble_external <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_external_validation_metrics.csv"))
  ensemble_topk <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_external_topk_metrics.csv"))
  if (nrow(ensemble_internal) > 0 && nrow(ensemble_external) > 0) {
    ensemble_topk <- ensemble_topk[ensemble_topk$top_k == "top_10_pct", c("model_name", "recall", "event_rate", "lift"), drop = FALSE]
    names(ensemble_topk) <- c("model_name", "external_top10_recall", "external_top10_event_rate", "external_top10_lift")
    ensemble_merged <- merge(
      ensemble_internal[, c("model_name", "pr_auc", "roc_auc"), drop = FALSE],
      ensemble_external[, c("model_name", "pr_auc", "roc_auc"), drop = FALSE],
      by = "model_name",
      suffixes = c("_internal", "_external"),
      all = TRUE
    )
    ensemble_merged <- merge(ensemble_merged, ensemble_topk, by = "model_name", all.x = TRUE)
    ensemble_merged$arm <- "Ensemble"
    ensemble_merged$model <- pretty_model_label(ensemble_merged$model_name)
    ensemble_merged <- ensemble_merged[, c("arm", "model", "pr_auc_internal", "roc_auc_internal", "pr_auc_external", "roc_auc_external", "external_top10_recall", "external_top10_event_rate", "external_top10_lift"), drop = FALSE]
    names(ensemble_merged) <- c("arm", "model", "internal_pr_auc", "internal_roc_auc", "external_pr_auc", "external_roc_auc", "external_top10_recall", "external_top10_event_rate", "external_top10_lift")
    merged <- rbind(merged, ensemble_merged)
  }

  merged <- merged[order(merged$arm, -merged$external_pr_auc, -merged$external_roc_auc), , drop = FALSE]
  utils::write.csv(merged, file.path(root, "results", "metrics", "publication_key_results_table.csv"), row.names = FALSE, na = "")
  merged
}

read_prediction_bundle <- function(path, arm_label) {
  data <- read_optional_csv(path)
  if (nrow(data) == 0) return(data.frame())
  data$arm <- arm_label
  data$model_arm <- paste(arm_label, data$model_name, sep = ": ")
  data
}

save_combined_roc_plot <- function(predictions, out_path, main_title) {
  if (is.null(predictions) || nrow(predictions) == 0) return(invisible(NULL))
  groups <- split(predictions, predictions$model_arm)
  roc_curves <- lapply(groups, function(group_df) {
    curve_points_roc(group_df$truth, group_df$predicted_probability)
  })
  colors <- grDevices::rainbow(length(roc_curves))
  grDevices::png(out_path, width = 1200, height = 900)
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "False Positive Rate", ylab = "True Positive Rate", main = main_title)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  idx <- 1
  for (name in names(roc_curves)) {
    curve_df <- roc_curves[[name]]
    graphics::lines(curve_df$fpr, curve_df$tpr, col = colors[idx], lwd = 2)
    idx <- idx + 1
  }
  graphics::legend("bottomright", legend = names(roc_curves), col = colors, lwd = 2, cex = 0.8, bg = "white")
  grDevices::dev.off()
  invisible(NULL)
}

save_arm_roc_plot <- function(predictions, metrics, out_path, main_title) {
  if (is.null(predictions) || nrow(predictions) == 0 || is.null(metrics) || nrow(metrics) == 0) {
    return(invisible(NULL))
  }
  model_names <- unique(predictions$model_name)
  colors <- grDevices::rainbow(length(model_names))
  grDevices::png(out_path, width = 1200, height = 900)
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "False Positive Rate", ylab = "True Positive Rate", main = main_title)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  legend_labels <- character()
  legend_colors <- character()
  idx <- 1
  for (model_name in model_names) {
    model_predictions <- predictions[predictions$model_name == model_name, , drop = FALSE]
    curve_df <- curve_points_roc(model_predictions$truth, model_predictions$predicted_probability)
    graphics::lines(curve_df$fpr, curve_df$tpr, col = colors[idx], lwd = 2)
    auc_value <- metrics$roc_auc[match(model_name, metrics$model_name)]
    legend_labels <- c(legend_labels, sprintf("%s (AUC = %.3f)", pretty_model_label(model_name), auc_value))
    legend_colors <- c(legend_colors, colors[idx])
    idx <- idx + 1
  }
  graphics::legend("bottomright", legend = legend_labels, col = legend_colors, lwd = 2, cex = 0.8, bg = "white")
  grDevices::dev.off()
  invisible(NULL)
}

summarize_modeling_features <- function(root) {
  mapping <- load_feature_mapping(root)
  mapping[mapping$include_in_model, c("canonical_name", "feature_type", "notes"), drop = FALSE]
}

render_final_results_report <- function(root) {
  publication_tables <- write_publication_comparison_tables(root)
  publication_key_results <- write_publication_key_results_table(root)
  internal_original_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "internal_test_predictions.csv"), "Original")
  internal_smote_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "internal_test_predictions_smote.csv"), "SMOTE")
  internal_weighted_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv"), "Weighted")
  external_original_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "external_validation_predictions.csv"), "Original")
  external_smote_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "external_validation_predictions_smote.csv"), "SMOTE")
  external_weighted_predictions <- read_prediction_bundle(file.path(root, "results", "metrics", "external_validation_predictions_weighted.csv"), "Weighted")

  mapping <- summarize_modeling_features(root)
  exclusions <- load_feature_exclusions(root)
  dev_summary <- read_csv_config(file.path(root, "results", "metrics", "development_dataset_summary.csv"))
  ext_summary <- read_csv_config(file.path(root, "results", "metrics", "external_dataset_summary.csv"))
  training_status <- read_optional_csv(file.path(root, "results", "metrics", "training_status.csv"))
  training_status_smote <- read_optional_csv(file.path(root, "results", "metrics", "training_status_smote.csv"))
  training_status_weighted <- read_optional_csv(file.path(root, "results", "metrics", "training_status_weighted.csv"))
  internal_metrics <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics.csv"))
  internal_metrics_smote <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics_smote.csv"))
  internal_metrics_weighted <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv"))
  internal_topk <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_topk_metrics.csv"))
  internal_topk_smote <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_topk_metrics_smote.csv"))
  internal_topk_weighted <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_topk_metrics_weighted.csv"))
  internal_threshold_rules <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics.csv"))
  internal_threshold_rules_smote <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics_smote.csv"))
  internal_threshold_rules_weighted <- read_optional_csv(file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics_weighted.csv"))
  external_metrics <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics.csv"))
  external_metrics_smote <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics_smote.csv"))
  external_metrics_weighted <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_metrics_weighted.csv"))
  external_topk <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics.csv"))
  external_topk_smote <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics_smote.csv"))
  external_topk_weighted <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_topk_metrics_weighted.csv"))
  external_threshold_rules <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics.csv"))
  external_threshold_rules_smote <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics_smote.csv"))
  external_threshold_rules_weighted <- read_optional_csv(file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics_weighted.csv"))
  save_arm_roc_plot(internal_original_predictions, internal_metrics, file.path(root, "results", "figures", "publication_internal_original_roc.png"), "Internal ROC Curves: Original Models")
  save_arm_roc_plot(internal_smote_predictions, internal_metrics_smote, file.path(root, "results", "figures", "publication_internal_smote_roc.png"), "Internal ROC Curves: SMOTE Models")
  save_arm_roc_plot(internal_weighted_predictions, internal_metrics_weighted, file.path(root, "results", "figures", "publication_internal_weighted_roc.png"), "Internal ROC Curves: Weighted Models")
  save_arm_roc_plot(external_original_predictions, external_metrics, file.path(root, "results", "figures", "publication_external_original_roc.png"), "External ROC Curves: Original Models")
  save_arm_roc_plot(external_smote_predictions, external_metrics_smote, file.path(root, "results", "figures", "publication_external_smote_roc.png"), "External ROC Curves: SMOTE Models")
  save_arm_roc_plot(external_weighted_predictions, external_metrics_weighted, file.path(root, "results", "figures", "publication_external_weighted_roc.png"), "External ROC Curves: Weighted Models")
  selection <- read_optional_csv(file.path(root, "results", "metrics", "model_selection.csv"))
  selection_smote <- read_optional_csv(file.path(root, "results", "metrics", "model_selection_smote.csv"))
  selection_weighted <- read_optional_csv(file.path(root, "results", "metrics", "model_selection_weighted.csv"))
  ensemble_internal_metrics <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"))
  ensemble_internal_topk <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_internal_topk_metrics.csv"))
  ensemble_internal_thresholds <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_internal_threshold_rule_metrics.csv"))
  ensemble_external_metrics <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_external_validation_metrics.csv"))
  ensemble_external_topk <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_external_topk_metrics.csv"))
  ensemble_external_thresholds <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_external_threshold_rule_metrics.csv"))
  ensemble_selection <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_model_selection.csv"))
  ensemble_weights <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_pr_weights.csv"))
  ensemble_coefficients <- read_optional_csv(file.path(root, "results", "metrics", "ensemble_stacked_logistic_coefficients.csv"))
  shap_summary <- read_optional_csv(file.path(root, "results", "metrics", "primary_model_external_shap_summary.csv"))
  shap_summary_smote <- read_optional_csv(file.path(root, "results", "metrics", "primary_model_smote_external_shap_summary.csv"))
  shap_summary_weighted <- read_optional_csv(file.path(root, "results", "metrics", "primary_model_weighted_external_shap_summary.csv"))
  smoke_tests <- read_optional_csv(file.path(root, "results", "metrics", "pipeline_smoke_tests.csv"))

  lines <- c(
    "# Final Results",
    "",
    "This Markdown report is generated automatically by the R pipeline.",
    "",
    "## Analysis Summary",
    "",
    "- Primary development endpoint: `dindo_scores >= 3`.",
    "- Modeling restricted to harmonized pre-operative predictors only.",
    "- Excluded from modeling: identifiers, ASA and other aggregate scores, post-operative or peri-operative variables, CPT fields, and external-only descriptive fields.",
    "- External validation uses a prespecified severe-event composite because Dindo-Clavien is not present in the external file.",
    "- SHAP outputs remain in the repository as exploratory artifacts, but they are omitted from the publication-facing summary because the feature attributions were not judged clinically reliable enough to report.",
    "",
    "## Cohort Sizes",
    ""
  )
  lines <- c(lines, markdown_table(rbind(dev_summary, ext_summary), digits = 3))
  lines <- c(lines, "## Final Modeling Feature Set", "")
  lines <- c(lines, markdown_table(mapping, digits = 3))
  lines <- c(lines, "## Exclusion Inventory", "")
  lines <- c(lines, markdown_table(exclusions[, c("scope", "rule_type", "rule_value", "reason")], digits = 3, max_rows = 80))
  lines <- c(lines, "## Benchmark Models Tried", "")
  lines <- c(lines, markdown_table(training_status, digits = 3))
  lines <- c(lines, "## Publication Comparison Table: Internal", "")
  lines <- c(lines, markdown_table(publication_tables$internal, digits = 3))
  lines <- c(lines, "## Publication Comparison Table: External", "")
  lines <- c(lines, markdown_table(publication_tables$external, digits = 3))
  lines <- c(lines, "## Publication Key Results Table", "")
  lines <- c(lines, markdown_table(publication_key_results, digits = 3))
  lines <- c(
    lines,
    "## Publication ROC Figures",
    "",
    "- Internal original ROC figure: `results/figures/publication_internal_original_roc.png`",
    "- Internal SMOTE ROC figure: `results/figures/publication_internal_smote_roc.png`",
    "- Internal weighted ROC figure: `results/figures/publication_internal_weighted_roc.png`",
    "- External original ROC figure: `results/figures/publication_external_original_roc.png`",
    "- External SMOTE ROC figure: `results/figures/publication_external_smote_roc.png`",
    "- External weighted ROC figure: `results/figures/publication_external_weighted_roc.png`",
    ""
  )
  lines <- c(lines, "## Internal Test Results", "")
  lines <- c(lines, markdown_table(internal_metrics, digits = 3))
  lines <- c(lines, "## Internal High-Risk Capture", "")
  lines <- c(lines, markdown_table(internal_topk, digits = 3))
  lines <- c(lines, "## Internal Threshold Rule Performance", "")
  lines <- c(lines, markdown_table(internal_threshold_rules, digits = 3))
  lines <- c(lines, "## External Validation Results", "")
  lines <- c(lines, markdown_table(external_metrics, digits = 3))
  lines <- c(lines, "## External High-Risk Capture", "")
  lines <- c(lines, markdown_table(external_topk, digits = 3))
  lines <- c(lines, "## External Threshold Rule Performance", "")
  lines <- c(lines, markdown_table(external_threshold_rules, digits = 3))
  lines <- c(lines, "## Selected Primary Model", "")
  if (nrow(selection) > 0) {
    lines <- c(lines, markdown_table(selection, digits = 3))
  } else {
    lines <- c(lines, "_Model selection has not been generated yet._", "")
  }
  lines <- c(lines, "## Benchmark Models Tried With SMOTE", "")
  lines <- c(lines, markdown_table(training_status_smote, digits = 3))
  lines <- c(lines, "## Internal Test Results With SMOTE", "")
  lines <- c(lines, markdown_table(internal_metrics_smote, digits = 3))
  lines <- c(lines, "## Internal High-Risk Capture With SMOTE", "")
  lines <- c(lines, markdown_table(internal_topk_smote, digits = 3))
  lines <- c(lines, "## Internal Threshold Rule Performance With SMOTE", "")
  lines <- c(lines, markdown_table(internal_threshold_rules_smote, digits = 3))
  lines <- c(lines, "## External Validation Results With SMOTE", "")
  lines <- c(lines, markdown_table(external_metrics_smote, digits = 3))
  lines <- c(lines, "## External High-Risk Capture With SMOTE", "")
  lines <- c(lines, markdown_table(external_topk_smote, digits = 3))
  lines <- c(lines, "## External Threshold Rule Performance With SMOTE", "")
  lines <- c(lines, markdown_table(external_threshold_rules_smote, digits = 3))
  lines <- c(lines, "## Selected Primary SMOTE Model", "")
  if (nrow(selection_smote) > 0) {
    lines <- c(lines, markdown_table(selection_smote, digits = 3))
  } else {
    lines <- c(lines, "_SMOTE model selection has not been generated yet._", "")
  }
  lines <- c(lines, "## Benchmark Models Tried With Class Weights", "")
  lines <- c(lines, markdown_table(training_status_weighted, digits = 3))
  lines <- c(lines, "## Internal Test Results With Class Weights", "")
  lines <- c(lines, markdown_table(internal_metrics_weighted, digits = 3))
  lines <- c(lines, "## Internal High-Risk Capture With Class Weights", "")
  lines <- c(lines, markdown_table(internal_topk_weighted, digits = 3))
  lines <- c(lines, "## Internal Threshold Rule Performance With Class Weights", "")
  lines <- c(lines, markdown_table(internal_threshold_rules_weighted, digits = 3))
  lines <- c(lines, "## External Validation Results With Class Weights", "")
  lines <- c(lines, markdown_table(external_metrics_weighted, digits = 3))
  lines <- c(lines, "## External High-Risk Capture With Class Weights", "")
  lines <- c(lines, markdown_table(external_topk_weighted, digits = 3))
  lines <- c(lines, "## External Threshold Rule Performance With Class Weights", "")
  lines <- c(lines, markdown_table(external_threshold_rules_weighted, digits = 3))
  lines <- c(lines, "## Selected Primary Class-Weighted Model", "")
  if (nrow(selection_weighted) > 0) {
    lines <- c(lines, markdown_table(selection_weighted, digits = 3))
  } else {
    lines <- c(lines, "_Weighted model selection has not been generated yet._", "")
  }
  lines <- c(lines, "## Ensemble Candidates", "")
  lines <- c(lines, markdown_table(ensemble_internal_metrics, digits = 3))
  lines <- c(lines, "## Ensemble Internal High-Risk Capture", "")
  lines <- c(lines, markdown_table(ensemble_internal_topk, digits = 3))
  lines <- c(lines, "## Ensemble Internal Threshold Rule Performance", "")
  lines <- c(lines, markdown_table(ensemble_internal_thresholds, digits = 3))
  lines <- c(lines, "## Ensemble External Validation Results", "")
  lines <- c(lines, markdown_table(ensemble_external_metrics, digits = 3))
  lines <- c(lines, "## Ensemble External High-Risk Capture", "")
  lines <- c(lines, markdown_table(ensemble_external_topk, digits = 3))
  lines <- c(lines, "## Ensemble External Threshold Rule Performance", "")
  lines <- c(lines, markdown_table(ensemble_external_thresholds, digits = 3))
  lines <- c(lines, "## Selected Ensemble", "")
  if (nrow(ensemble_selection) > 0) {
    lines <- c(lines, markdown_table(ensemble_selection, digits = 3))
  } else {
    lines <- c(lines, "_Ensemble selection has not been generated yet._", "")
  }
  lines <- c(lines, "## Ensemble Weights And Coefficients", "")
  lines <- c(lines, "### PR-Weighted Soft Voting", "")
  lines <- c(lines, markdown_table(ensemble_weights, digits = 4))
  lines <- c(lines, "### Stacked Logistic Coefficients", "")
  lines <- c(lines, markdown_table(ensemble_coefficients, digits = 4))
  lines <- c(lines, "## Smoke Tests", "")
  if (nrow(smoke_tests) > 0) {
    lines <- c(lines, markdown_table(smoke_tests, digits = 3))
  } else {
    lines <- c(lines, "_Smoke test outputs have not been generated yet._", "")
  }
  lines <- c(
    lines,
    "## Output Artifacts",
    "",
    "- Internal metrics: `results/metrics/internal_test_metrics.csv`",
    "- Internal top-k metrics: `results/metrics/internal_test_topk_metrics.csv`",
    "- Internal threshold metrics: `results/metrics/internal_test_threshold_rule_metrics.csv`",
    "- External metrics: `results/metrics/external_validation_metrics.csv`",
    "- External top-k metrics: `results/metrics/external_validation_topk_metrics.csv`",
    "- External threshold metrics: `results/metrics/external_validation_threshold_rule_metrics.csv`",
    "- SMOTE internal metrics: `results/metrics/internal_test_metrics_smote.csv`",
    "- SMOTE internal top-k metrics: `results/metrics/internal_test_topk_metrics_smote.csv`",
    "- SMOTE external metrics: `results/metrics/external_validation_metrics_smote.csv`",
    "- SMOTE external top-k metrics: `results/metrics/external_validation_topk_metrics_smote.csv`",
    "- Weighted internal metrics: `results/metrics/internal_test_metrics_weighted.csv`",
    "- Weighted external metrics: `results/metrics/external_validation_metrics_weighted.csv`",
    "- Publication internal comparison table: `results/metrics/publication_internal_model_comparison.csv`",
    "- Publication external comparison table: `results/metrics/publication_external_model_comparison.csv`",
    "- Publication key results table: `results/metrics/publication_key_results_table.csv`",
    "- Ensemble internal metrics: `results/metrics/ensemble_internal_test_metrics.csv`",
    "- Ensemble external metrics: `results/metrics/ensemble_external_validation_metrics.csv`",
    "- Ensemble selection: `results/metrics/ensemble_model_selection.csv`",
    "- Internal original ROC figure: `results/figures/publication_internal_original_roc.png`",
    "- Internal SMOTE ROC figure: `results/figures/publication_internal_smote_roc.png`",
    "- Internal weighted ROC figure: `results/figures/publication_internal_weighted_roc.png`",
    "- External original ROC figure: `results/figures/publication_external_original_roc.png`",
    "- External SMOTE ROC figure: `results/figures/publication_external_smote_roc.png`",
    "- External weighted ROC figure: `results/figures/publication_external_weighted_roc.png`",
    "- Smoke tests: `results/metrics/pipeline_smoke_tests.csv`",
    "- Saved models: `results/models/`",
    "- Figures: `results/figures/`",
    ""
  )
  write_markdown(file.path(root, "reports", "final_results.md"), lines)
}
