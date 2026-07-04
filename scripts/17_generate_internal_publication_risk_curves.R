root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "reporting.R"))

publication_fig_dir <- file.path(root, "publication_summary", "figures")
publication_table_dir <- file.path(root, "publication_summary", "tables")
results_fig_dir <- file.path(root, "results", "figures")
dir.create(publication_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(publication_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(results_fig_dir, recursive = TRUE, showWarnings = FALSE)

arm_configs <- list(
  list(
    arm = "Original",
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics.csv"),
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions.csv")
  ),
  list(
    arm = "SMOTE",
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics_smote.csv"),
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions_smote.csv")
  ),
  list(
    arm = "Weighted",
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv"),
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv")
  )
)

compute_topk_lift_curve <- function(pred_df) {
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
    review_fraction = review_fraction,
    captured_events = captured_events,
    recall = recall,
    observed_event_rate = observed_rate,
    lift = lift,
    stringsAsFactors = FALSE
  )
}

safe_auc <- function(metrics_df, model_name, metric_col) {
  value <- metrics_df[metrics_df$model_name == model_name, metric_col, drop = TRUE]
  if (length(value) == 0 || is.na(value[1])) return(NA_real_)
  as.numeric(value[1])
}

best_models <- list()
curve_rows <- list()
calibration_rows <- list()

for (cfg in arm_configs) {
  metrics_df <- read_csv_config(cfg$metrics_path)
  predictions_df <- read_csv_config(cfg$predictions_path)
  if (nrow(metrics_df) == 0 || nrow(predictions_df) == 0) next
  metrics_df <- metrics_df[order(-as.numeric(metrics_df$pr_auc), -as.numeric(metrics_df$roc_auc)), , drop = FALSE]
  top_models <- head(metrics_df, 3)
  top_models$arm <- cfg$arm
  top_models$model_label <- pretty_model_label(top_models$model_name)
  best_models[[length(best_models) + 1]] <- top_models

  for (i in seq_len(nrow(top_models))) {
    model_name <- top_models$model_name[i]
    pred_df <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
    if (nrow(pred_df) == 0) next
    curve_df <- compute_topk_lift_curve(pred_df)
    curve_df$arm <- cfg$arm
    curve_df$model_name <- model_name
    curve_df$model_label <- pretty_model_label(model_name)
    curve_df$roc_auc <- safe_auc(top_models, model_name, "roc_auc")
    curve_df$pr_auc <- safe_auc(top_models, model_name, "pr_auc")
    curve_rows[[length(curve_rows) + 1]] <- curve_df

    bins <- cut(
      pmin(pmax(as.numeric(pred_df$predicted_probability), 0), 1),
      breaks = seq(0, 1, by = 0.1),
      include.lowest = TRUE
    )
    calib_df <- stats::aggregate(
      data.frame(
        predicted_probability = as.numeric(pred_df$predicted_probability),
        observed_event = as.integer(ensure_factor_outcome(pred_df$truth) == "Yes")
      ),
      by = list(bin = bins),
      FUN = mean
    )
    calib_df <- calib_df[is.finite(calib_df$predicted_probability), , drop = FALSE]
    calib_df$arm <- cfg$arm
    calib_df$model_name <- model_name
    calib_df$model_label <- pretty_model_label(model_name)
    calibration_rows[[length(calibration_rows) + 1]] <- calib_df
  }
}

best_models_df <- do.call(rbind, best_models)
best_models_df <- best_models_df[, c("arm", "model_name", "model_label", "pr_auc", "roc_auc", "brier_score", "calibration_slope"), drop = FALSE]
names(best_models_df) <- c("arm", "model_name", "model", "internal_pr_auc", "internal_roc_auc", "internal_brier_score", "internal_calibration_slope")
utils::write.csv(best_models_df, file.path(publication_table_dir, "publication_internal_best_models_for_curves.csv"), row.names = FALSE, na = "")

curve_df <- do.call(rbind, curve_rows)
utils::write.csv(curve_df, file.path(publication_table_dir, "publication_internal_best_model_curve_data.csv"), row.names = FALSE, na = "")

calibration_df <- do.call(rbind, calibration_rows)
utils::write.csv(calibration_df, file.path(publication_table_dir, "publication_internal_best_model_calibration_data.csv"), row.names = FALSE, na = "")

save_png_both <- function(filename, plot_fun, width, height) {
  publication_path <- file.path(publication_fig_dir, filename)
  results_path <- file.path(results_fig_dir, filename)
  grDevices::png(publication_path, width = width, height = height)
  plot_fun()
  grDevices::dev.off()
  file.copy(publication_path, results_path, overwrite = TRUE)
}

draw_roc_grid <- function() {
  op <- graphics::par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    metrics_df <- metrics_df[order(-as.numeric(metrics_df$pr_auc), -as.numeric(metrics_df$roc_auc)), , drop = FALSE]
    top_models <- head(metrics_df, 3)
    for (i in seq_len(nrow(top_models))) {
      model_name <- top_models$model_name[i]
      pred_df <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
      roc_df <- curve_points_roc(pred_df$truth, pred_df$predicted_probability)
      graphics::plot(
        roc_df$fpr, roc_df$tpr,
        type = "l", lwd = 2, col = "#1f77b4",
        xlab = "False Positive Rate", ylab = "True Positive Rate",
        main = sprintf("%s\n%s", cfg$arm, pretty_model_label(model_name))
      )
      graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
      graphics::legend(
        "bottomright",
        legend = sprintf("ROC AUC = %.3f", as.numeric(top_models$roc_auc[i])),
        bty = "n", cex = 0.9
      )
    }
  }
  graphics::mtext("Internal ROC Curves: Top 3 Models per Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_pr_grid <- function() {
  op <- graphics::par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    metrics_df <- metrics_df[order(-as.numeric(metrics_df$pr_auc), -as.numeric(metrics_df$roc_auc)), , drop = FALSE]
    top_models <- head(metrics_df, 3)
    for (i in seq_len(nrow(top_models))) {
      model_name <- top_models$model_name[i]
      pred_df <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
      pr_df <- curve_points_pr(pred_df$truth, pred_df$predicted_probability)
      baseline_rate <- mean(ensure_factor_outcome(pred_df$truth) == "Yes")
      graphics::plot(
        pr_df$recall, pr_df$precision,
        type = "l", lwd = 2, col = "#d62728",
        xlab = "Recall", ylab = "Precision",
        xlim = c(0, 1), ylim = c(0, 1),
        main = sprintf("%s\n%s", cfg$arm, pretty_model_label(model_name))
      )
      graphics::abline(h = baseline_rate, lty = 2, col = "gray60")
      graphics::legend(
        "topright",
        legend = sprintf("PR AUC = %.3f", as.numeric(top_models$pr_auc[i])),
        bty = "n", cex = 0.9
      )
    }
  }
  graphics::mtext("Internal PR Curves: Top 3 Models per Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_topk_panels <- function() {
  op <- graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  color_values <- c("#1f77b4", "#d62728", "#2ca02c")
  for (arm_label in vapply(arm_configs, `[[`, character(1), "arm")) {
    arm_curves <- curve_df[curve_df$arm == arm_label, , drop = FALSE]
    arm_models <- unique(arm_curves$model_name)
    graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "Fraction Reviewed", ylab = "Cumulative Recall", main = arm_label)
    graphics::abline(a = 0, b = 1, lty = 2, col = "gray70")
    legend_labels <- character()
    for (i in seq_along(arm_models)) {
      model_name <- arm_models[i]
      model_curve <- arm_curves[arm_curves$model_name == model_name, , drop = FALSE]
      graphics::lines(model_curve$review_fraction, model_curve$recall, lwd = 2, col = color_values[i])
      pr_auc <- unique(model_curve$pr_auc)[1]
      legend_labels <- c(legend_labels, sprintf("%s (PR AUC = %.3f)", pretty_model_label(model_name), pr_auc))
    }
    graphics::legend("bottomright", legend = legend_labels, col = color_values[seq_along(arm_models)], lwd = 2, cex = 0.8, bg = "white")
  }
  graphics::mtext("Internal Top-k Capture: Top 3 Models per Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_lift_panels <- function() {
  op <- graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  color_values <- c("#1f77b4", "#d62728", "#2ca02c")
  for (arm_label in vapply(arm_configs, `[[`, character(1), "arm")) {
    arm_curves <- curve_df[curve_df$arm == arm_label, , drop = FALSE]
    arm_models <- unique(arm_curves$model_name)
    max_lift <- max(arm_curves$lift, na.rm = TRUE)
    if (!is.finite(max_lift)) max_lift <- 1
    graphics::plot(c(0, 1), c(0, max(1.1, max_lift * 1.05)), type = "n", xlab = "Fraction Reviewed", ylab = "Lift", main = arm_label)
    graphics::abline(h = 1, lty = 2, col = "gray70")
    legend_labels <- character()
    for (i in seq_along(arm_models)) {
      model_name <- arm_models[i]
      model_curve <- arm_curves[arm_curves$model_name == model_name, , drop = FALSE]
      graphics::lines(model_curve$review_fraction, model_curve$lift, lwd = 2, col = color_values[i])
      pr_auc <- unique(model_curve$pr_auc)[1]
      legend_labels <- c(legend_labels, sprintf("%s (PR AUC = %.3f)", pretty_model_label(model_name), pr_auc))
    }
    graphics::legend("topright", legend = legend_labels, col = color_values[seq_along(arm_models)], lwd = 2, cex = 0.8, bg = "white")
  }
  graphics::mtext("Internal Lift Curves: Top 3 Models per Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_pr_panels <- function() {
  op <- graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    draw_arm_pr_panel(predictions_df, metrics_df, cfg$arm)
  }
  graphics::mtext("Internal PR Curves by Analysis Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_calibration_grid <- function() {
  op <- graphics::par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 0))
  on.exit(graphics::par(op))
  for (cfg in arm_configs) {
    arm_calibration <- calibration_df[calibration_df$arm == cfg$arm, , drop = FALSE]
    arm_models <- unique(arm_calibration$model_name)
    for (model_name in arm_models) {
      model_calibration <- arm_calibration[arm_calibration$model_name == model_name, , drop = FALSE]
      graphics::plot(
        model_calibration$predicted_probability,
        model_calibration$observed_event,
        type = "b", lwd = 2, pch = 19, col = "#9467bd",
        xlim = c(0, 1), ylim = c(0, 1),
        xlab = "Mean Predicted Probability", ylab = "Observed Event Rate",
        main = sprintf("%s\n%s", cfg$arm, pretty_model_label(model_name))
      )
      graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
      slope_value <- best_models_df$internal_calibration_slope[best_models_df$arm == cfg$arm & best_models_df$model_name == model_name][1]
      graphics::legend(
        "topleft",
        legend = sprintf("Slope = %.3f", as.numeric(slope_value)),
        bty = "n", cex = 0.9
      )
    }
  }
  graphics::mtext("Internal Calibration Curves: Top 3 Models per Arm", outer = TRUE, cex = 1.3, font = 2)
}

draw_arm_roc_panel <- function(predictions_df, metrics_df, arm_label) {
  model_names <- unique(predictions_df$model_name)
  colors <- grDevices::rainbow(length(model_names))
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "False Positive Rate", ylab = "True Positive Rate", main = arm_label)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
  legend_labels <- character()
  for (i in seq_along(model_names)) {
    model_name <- model_names[i]
    model_predictions <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
    curve_df <- curve_points_roc(model_predictions$truth, model_predictions$predicted_probability)
    graphics::lines(curve_df$fpr, curve_df$tpr, col = colors[i], lwd = 2)
    auc_value <- metrics_df$roc_auc[match(model_name, metrics_df$model_name)]
    legend_labels <- c(legend_labels, sprintf("%s (AUC = %.3f)", pretty_model_label(model_name), as.numeric(auc_value)))
  }
  graphics::legend("bottomright", legend = legend_labels, col = colors, lwd = 2, cex = 0.7, bg = "white")
}

draw_arm_pr_panel <- function(predictions_df, metrics_df, arm_label) {
  model_names <- unique(predictions_df$model_name)
  colors <- grDevices::rainbow(length(model_names))
  baseline_rate <- mean(ensure_factor_outcome(predictions_df$truth) == "Yes")
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "Recall", ylab = "Precision", main = arm_label)
  graphics::abline(h = baseline_rate, lty = 2, col = "gray60")
  legend_labels <- character()
  for (i in seq_along(model_names)) {
    model_name <- model_names[i]
    model_predictions <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
    curve_df <- curve_points_pr(model_predictions$truth, model_predictions$predicted_probability)
    graphics::lines(curve_df$recall, curve_df$precision, col = colors[i], lwd = 2)
    auc_value <- metrics_df$pr_auc[match(model_name, metrics_df$model_name)]
    legend_labels <- c(legend_labels, sprintf("%s (PR = %.3f)", pretty_model_label(model_name), as.numeric(auc_value)))
  }
  graphics::legend("topright", legend = legend_labels, col = colors, lwd = 2, cex = 0.7, bg = "white")
}

draw_arm_topk_panel <- function(curve_df_arm, arm_label) {
  model_names <- unique(curve_df_arm$model_name)
  colors <- grDevices::rainbow(length(model_names))
  graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "Fraction Reviewed", ylab = "Cumulative Recall", main = arm_label)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray70")
  legend_labels <- character()
  for (i in seq_along(model_names)) {
    model_name <- model_names[i]
    model_curve <- curve_df_arm[curve_df_arm$model_name == model_name, , drop = FALSE]
    graphics::lines(model_curve$review_fraction, model_curve$recall, lwd = 2, col = colors[i])
    pr_auc <- unique(model_curve$pr_auc)[1]
    legend_labels <- c(legend_labels, sprintf("%s (PR = %.3f)", pretty_model_label(model_name), as.numeric(pr_auc)))
  }
  graphics::legend("bottomright", legend = legend_labels, col = colors, lwd = 2, cex = 0.7, bg = "white")
}

draw_summary_grid_3x3 <- function() {
  op <- graphics::par(mfrow = c(3, 3), mar = c(4, 4, 3, 1), oma = c(2, 2, 3, 0))
  on.exit(graphics::par(op))

  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    draw_arm_roc_panel(predictions_df, metrics_df, cfg$arm)
  }
  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    draw_arm_pr_panel(predictions_df, metrics_df, cfg$arm)
  }
  for (cfg in arm_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    arm_curve_rows <- list()
    for (model_name in unique(predictions_df$model_name)) {
      pred_df <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
      model_curve <- compute_topk_lift_curve(pred_df)
      model_curve$model_name <- model_name
      model_curve$pr_auc <- safe_auc(metrics_df, model_name, "pr_auc")
      arm_curve_rows[[length(arm_curve_rows) + 1]] <- model_curve
    }
    arm_curve_df <- do.call(rbind, arm_curve_rows)
    draw_arm_topk_panel(arm_curve_df, cfg$arm)
  }

  graphics::mtext("Internal Model Performance Summary", outer = TRUE, cex = 1.4, font = 2)
  graphics::mtext("ROC Curves", side = 2, line = 0.2, at = 0.84, outer = TRUE, cex = 1)
  graphics::mtext("PR Curves", side = 2, line = 0.2, at = 0.50, outer = TRUE, cex = 1)
  graphics::mtext("Top-k Capture", side = 2, line = 0.2, at = 0.17, outer = TRUE, cex = 1)
}

draw_original_weighted_2x2 <- function() {
  selected_configs <- arm_configs[vapply(arm_configs, function(x) x$arm %in% c("Original", "Weighted"), logical(1))]
  op <- graphics::par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(0, 0, 3, 9), xpd = NA)
  on.exit(graphics::par(op))

  legend_entries <- list()

  for (cfg in selected_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    model_names <- unique(predictions_df$model_name)
    colors <- grDevices::rainbow(length(model_names))
    graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "False Positive Rate", ylab = "True Positive Rate", main = paste(cfg$arm, "ROC"))
    graphics::abline(a = 0, b = 1, lty = 2, col = "gray60")
    for (i in seq_along(model_names)) {
      model_name <- model_names[i]
      model_predictions <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
      curve_df <- curve_points_roc(model_predictions$truth, model_predictions$predicted_probability)
      graphics::lines(curve_df$fpr, curve_df$tpr, col = colors[i], lwd = 2)
      auc_value <- metrics_df$roc_auc[match(model_name, metrics_df$model_name)]
      legend_key <- paste(cfg$arm, model_name, "roc", sep = "|")
      legend_entries[[legend_key]] <- list(
        label = sprintf("%s %s (ROC = %.3f)", cfg$arm, pretty_model_label(model_name), as.numeric(auc_value)),
        color = colors[i]
      )
    }
  }

  for (cfg in selected_configs) {
    metrics_df <- read_csv_config(cfg$metrics_path)
    predictions_df <- read_csv_config(cfg$predictions_path)
    model_names <- unique(predictions_df$model_name)
    colors <- grDevices::rainbow(length(model_names))
    baseline_rate <- mean(ensure_factor_outcome(predictions_df$truth) == "Yes")
    graphics::plot(c(0, 1), c(0, 1), type = "n", xlab = "Recall", ylab = "Precision", main = paste(cfg$arm, "PR"))
    graphics::abline(h = baseline_rate, lty = 2, col = "gray60")
    for (i in seq_along(model_names)) {
      model_name <- model_names[i]
      model_predictions <- predictions_df[predictions_df$model_name == model_name, , drop = FALSE]
      curve_df <- curve_points_pr(model_predictions$truth, model_predictions$predicted_probability)
      graphics::lines(curve_df$recall, curve_df$precision, col = colors[i], lwd = 2)
      auc_value <- metrics_df$pr_auc[match(model_name, metrics_df$model_name)]
      legend_key <- paste(cfg$arm, model_name, "pr", sep = "|")
      legend_entries[[legend_key]] <- list(
        label = sprintf("%s %s (PR = %.3f)", cfg$arm, pretty_model_label(model_name), as.numeric(auc_value)),
        color = colors[i]
      )
    }
  }

  legend_labels <- vapply(legend_entries, `[[`, character(1), "label")
  legend_colors <- vapply(legend_entries, `[[`, character(1), "color")
  graphics::legend(
    "topright",
    inset = c(-0.42, 0.02),
    legend = legend_labels,
    col = legend_colors,
    lwd = 2,
    cex = 0.85,
    bg = "white",
    title = "Shared Legend"
  )
  graphics::mtext("Internal Original vs Weighted Model Performance", outer = TRUE, cex = 1.35, font = 2)
}

save_png_both("publication_internal_best_models_roc_grid_3x3.png", draw_roc_grid, width = 2200, height = 2200)
save_png_both("publication_internal_best_models_pr_grid_3x3.png", draw_pr_grid, width = 2200, height = 2200)
save_png_both("publication_internal_best_models_topk_capture.png", draw_topk_panels, width = 2200, height = 900)
save_png_both("publication_internal_best_models_lift_curve.png", draw_lift_panels, width = 2200, height = 900)
save_png_both("publication_internal_best_models_calibration_grid_3x3.png", draw_calibration_grid, width = 2200, height = 2200)
save_png_both("publication_internal_summary_grid_3x3.png", draw_summary_grid_3x3, width = 2400, height = 2400)
save_png_both("publication_internal_pr_row.png", draw_pr_panels, width = 2400, height = 900)
save_png_both("publication_internal_topk_row.png", draw_topk_panels, width = 2400, height = 900)
save_png_both("publication_internal_lift_row.png", draw_lift_panels, width = 2400, height = 900)
save_png_both("publication_internal_original_weighted_roc_pr_2x2.png", draw_original_weighted_2x2, width = 2600, height = 1800)

cat("Internal publication ROC, PR, Top-k, lift, and calibration figures generated.\n")
