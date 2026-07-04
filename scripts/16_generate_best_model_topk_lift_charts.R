root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "reporting.R"))

publication_fig_dir <- file.path(root, "publication_summary", "figures")
publication_table_dir <- file.path(root, "publication_summary", "tables")
dir.create(publication_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(publication_table_dir, recursive = TRUE, showWarnings = FALSE)

main_summary <- read_csv_config(file.path(publication_table_dir, "publication_key_results_table.csv"))
asa_summary <- read_csv_config(file.path(publication_table_dir, "publication_asa_sensitivity_summary.csv"))

main_candidates <- main_summary[, c("arm", "model", "external_pr_auc", "external_roc_auc"), drop = FALSE]
asa_candidates <- asa_summary[, c("arm", "model", "external_pr_auc", "external_roc_auc"), drop = FALSE]
candidate_table <- rbind(main_candidates, asa_candidates)
candidate_table <- candidate_table[order(-as.numeric(candidate_table$external_pr_auc), -as.numeric(candidate_table$external_roc_auc)), , drop = FALSE]
candidate_table$key <- paste(candidate_table$arm, candidate_table$model, sep = " | ")
candidate_table <- candidate_table[!duplicated(candidate_table$key), , drop = FALSE]
top_models <- head(candidate_table, 5)

prediction_source_lookup <- function(arm) {
  mapping <- list(
    "Original" = file.path(root, "results", "metrics", "external_validation_predictions.csv"),
    "SMOTE" = file.path(root, "results", "metrics", "external_validation_predictions_smote.csv"),
    "Weighted" = file.path(root, "results", "metrics", "external_validation_predictions_weighted.csv"),
    "Ensemble" = file.path(root, "results", "metrics", "ensemble_external_predictions.csv"),
    "ASA Original" = file.path(root, "results", "metrics", "external_validation_predictions_asa.csv"),
    "ASA SMOTE" = file.path(root, "results", "metrics", "external_validation_predictions_smote_asa.csv"),
    "ASA Weighted" = file.path(root, "results", "metrics", "external_validation_predictions_weighted_asa.csv")
  )
  mapping[[arm]]
}

raw_model_name_lookup <- function(display_model) {
  lookup <- c(
    "Elastic Net" = "elastic_net",
    "Random Forest" = "random_forest",
    "XGBoost" = "xgboost",
    "kNN" = "knn",
    "ANN" = "ann",
    "Stacked Logistic Ensemble" = "stacked_logistic",
    "Soft-Vote Ensemble (PR-Weighted)" = "soft_vote_pr_weighted",
    "Soft-Vote Ensemble (Equal)" = "soft_vote_equal"
  )
  unname(lookup[[display_model]])
}

compute_curve <- function(pred_df, model_label, arm_label) {
  pred_df <- pred_df[order(-pred_df$predicted_probability), , drop = FALSE]
  truth <- ensure_factor_outcome(pred_df$truth)
  y <- as.integer(truth == "Yes")
  n <- nrow(pred_df)
  total_events <- sum(y)
  reviewed <- seq_len(n)
  review_fraction <- reviewed / n
  captured_events <- cumsum(y)
  recall <- if (total_events == 0) rep(NA_real_, n) else captured_events / total_events
  observed_rate <- captured_events / reviewed
  baseline_rate <- if (n == 0) NA_real_ else total_events / n
  lift <- if (!is.finite(baseline_rate) || baseline_rate == 0) rep(NA_real_, n) else observed_rate / baseline_rate
  data.frame(
    arm = arm_label,
    model = model_label,
    review_fraction = review_fraction,
    captured_events = captured_events,
    recall = recall,
    observed_event_rate = observed_rate,
    lift = lift,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

curve_rows <- list()
for (i in seq_len(nrow(top_models))) {
  arm_label <- top_models$arm[i]
  model_label <- top_models$model[i]
  raw_model_name <- raw_model_name_lookup(model_label)
  prediction_path <- prediction_source_lookup(arm_label)
  if (is.null(prediction_path) || !file.exists(prediction_path) || is.na(raw_model_name)) next
  pred_df <- read_csv_config(prediction_path)
  pred_df <- pred_df[pred_df$model_name == raw_model_name, , drop = FALSE]
  if (nrow(pred_df) == 0) next
  curve_rows[[length(curve_rows) + 1]] <- compute_curve(pred_df, model_label, arm_label)
}

curve_df <- do.call(rbind, curve_rows)
curve_df$model_arm <- paste(curve_df$arm, curve_df$model, sep = ": ")
utils::write.csv(curve_df, file.path(publication_table_dir, "publication_best_model_topk_lift_curve_data.csv"), row.names = FALSE, na = "")

plot_topk_curve <- function(df, out_path) {
  groups <- split(df, df$model_arm)
  colors <- grDevices::rainbow(length(groups))
  grDevices::png(out_path, width = 1400, height = 900)
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "Fraction of External Cohort Reviewed", ylab = "Cumulative Severe Events Captured", main = "Top-k Capture Curves: Best External Models")
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  idx <- 1
  for (name in names(groups)) {
    g <- groups[[name]]
    graphics::lines(g$review_fraction, g$recall, lwd = 2, col = colors[idx])
    idx <- idx + 1
  }
  graphics::legend("bottomright", legend = names(groups), col = colors, lwd = 2, cex = 0.85, bg = "white")
  grDevices::dev.off()
}

plot_lift_curve <- function(df, out_path) {
  groups <- split(df, df$model_arm)
  colors <- grDevices::rainbow(length(groups))
  max_lift <- max(df$lift, na.rm = TRUE)
  max_lift <- ifelse(is.finite(max_lift), max_lift, 1)
  grDevices::png(out_path, width = 1400, height = 900)
  graphics::plot(c(0, 1), c(0, max(1.05, max_lift * 1.05)), type = "n", xlab = "Fraction of External Cohort Reviewed", ylab = "Lift over Baseline Event Rate", main = "Lift Curves: Best External Models")
  graphics::abline(h = 1, lty = 2, col = "gray60")
  idx <- 1
  for (name in names(groups)) {
    g <- groups[[name]]
    graphics::lines(g$review_fraction, g$lift, lwd = 2, col = colors[idx])
    idx <- idx + 1
  }
  graphics::legend("topright", legend = names(groups), col = colors, lwd = 2, cex = 0.85, bg = "white")
  grDevices::dev.off()
}

plot_topk_curve(curve_df, file.path(publication_fig_dir, "publication_best_models_topk_capture.png"))
plot_lift_curve(curve_df, file.path(publication_fig_dir, "publication_best_models_lift_curve.png"))

utils::write.csv(top_models, file.path(publication_table_dir, "publication_best_models_for_topk_lift.csv"), row.names = FALSE, na = "")
cat("Best-model Top-k and lift charts generated.\n")
