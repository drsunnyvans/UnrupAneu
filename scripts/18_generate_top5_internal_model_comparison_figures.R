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

model_specs <- list(
  list(
    key = "stacked_logistic",
    display = "Stacked Logistic Ensemble",
    source = "ensemble",
    predictions_path = file.path(root, "results", "metrics", "ensemble_internal_test_predictions_scored.csv"),
    metrics_path = file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"),
    color = "#1f77b4"
  ),
  list(
    key = "xgboost",
    display = "Weighted XGBoost",
    source = "weighted",
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv"),
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv"),
    color = "#d62728"
  ),
  list(
    key = "random_forest",
    display = "SMOTE Random Forest",
    source = "smote",
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions_smote.csv"),
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics_smote.csv"),
    color = "#2ca02c"
  ),
  list(
    key = "soft_vote_pr_weighted",
    display = "Soft-Vote Ensemble (PR-Weighted)",
    source = "ensemble",
    predictions_path = file.path(root, "results", "metrics", "ensemble_internal_test_predictions_scored.csv"),
    metrics_path = file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"),
    color = "#9467bd"
  ),
  list(
    key = "ann",
    display = "Weighted ANN",
    source = "weighted",
    predictions_path = file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv"),
    metrics_path = file.path(root, "results", "metrics", "internal_test_metrics_weighted.csv"),
    color = "#ff7f0e"
  )
)

compute_topk_curve <- function(pred_df) {
  pred_df <- pred_df[order(-pred_df$predicted_probability), , drop = FALSE]
  truth <- ensure_factor_outcome(pred_df$truth)
  y <- as.integer(truth == "Yes")
  n <- nrow(pred_df)
  total_events <- sum(y)
  reviewed <- seq_len(n)
  data.frame(
    review_fraction = reviewed / n,
    recall = if (total_events == 0) rep(NA_real_, n) else cumsum(y) / total_events,
    stringsAsFactors = FALSE
  )
}

compute_calibration_curve <- function(pred_df) {
  probs <- pmin(pmax(as.numeric(pred_df$predicted_probability), 0), 1)
  truth <- as.integer(ensure_factor_outcome(pred_df$truth) == "Yes")
  bins <- cut(probs, breaks = seq(0, 1, by = 0.1), include.lowest = TRUE)
  calib <- stats::aggregate(
    data.frame(predicted_probability = probs, observed_event = truth),
    by = list(bin = bins),
    FUN = mean
  )
  calib[is.finite(calib$predicted_probability), , drop = FALSE]
}

curve_rows <- list()
metric_rows <- list()
roc_curves <- list()
pr_curves <- list()
topk_curves <- list()
calibration_curves <- list()

for (spec in model_specs) {
  pred_df <- read_csv_config(spec$predictions_path)
  pred_df <- pred_df[pred_df$model_name == spec$key, , drop = FALSE]
  metrics_df <- read_csv_config(spec$metrics_path)
  metrics_df <- metrics_df[metrics_df$model_name == spec$key, , drop = FALSE]
  if (nrow(pred_df) == 0 || nrow(metrics_df) == 0) next

  roc_df <- curve_points_roc(pred_df$truth, pred_df$predicted_probability)
  pr_df <- curve_points_pr(pred_df$truth, pred_df$predicted_probability)
  topk_df <- compute_topk_curve(pred_df)
  calib_df <- compute_calibration_curve(pred_df)

  roc_df$display <- spec$display
  pr_df$display <- spec$display
  topk_df$display <- spec$display
  calib_df$display <- spec$display
  roc_df$color <- spec$color
  pr_df$color <- spec$color
  topk_df$color <- spec$color
  calib_df$color <- spec$color

  roc_curves[[spec$display]] <- roc_df
  pr_curves[[spec$display]] <- pr_df
  topk_curves[[spec$display]] <- topk_df
  calibration_curves[[spec$display]] <- calib_df

  metric_row <- data.frame(
    display = spec$display,
    model_name = spec$key,
    source = spec$source,
    roc_auc = as.numeric(metrics_df$roc_auc[1]),
    pr_auc = as.numeric(metrics_df$pr_auc[1]),
    brier_score = as.numeric(metrics_df$brier_score[1]),
    calibration_slope = as.numeric(metrics_df$calibration_slope[1]),
    stringsAsFactors = FALSE
  )
  metric_rows[[length(metric_rows) + 1]] <- metric_row

  curve_rows[[length(curve_rows) + 1]] <- data.frame(
    curve_type = "roc",
    x = roc_df$fpr,
    y = roc_df$tpr,
    display = spec$display,
    stringsAsFactors = FALSE
  )
  curve_rows[[length(curve_rows) + 1]] <- data.frame(
    curve_type = "pr",
    x = pr_df$recall,
    y = pr_df$precision,
    display = spec$display,
    stringsAsFactors = FALSE
  )
  curve_rows[[length(curve_rows) + 1]] <- data.frame(
    curve_type = "topk",
    x = topk_df$review_fraction,
    y = topk_df$recall,
    display = spec$display,
    stringsAsFactors = FALSE
  )
  curve_rows[[length(curve_rows) + 1]] <- data.frame(
    curve_type = "calibration",
    x = calib_df$predicted_probability,
    y = calib_df$observed_event,
    display = spec$display,
    stringsAsFactors = FALSE
  )
}

metrics_summary <- do.call(rbind, metric_rows)
curve_data <- do.call(rbind, curve_rows)

safe_write_csv <- function(data, path) {
  tryCatch(
    utils::write.csv(data, path, row.names = FALSE, na = ""),
    error = function(e) message(sprintf("Skipping write for locked file: %s", path))
  )
}

safe_write_csv(metrics_summary, file.path(publication_table_dir, "publication_internal_top5_model_metrics.csv"))
safe_write_csv(curve_data, file.path(publication_table_dir, "publication_internal_top5_curve_data.csv"))

legend_labels <- metrics_summary$display

legend_colors <- vapply(model_specs, function(x) x$color, character(1))
names(legend_colors) <- vapply(model_specs, function(x) x$display, character(1))
legend_colors <- legend_colors[metrics_summary$display]

save_png_both <- function(filename, plot_fun, width_px = 3000, height_px = 2200, res = 600) {
  publication_path <- file.path(publication_fig_dir, filename)
  results_path <- file.path(results_fig_dir, filename)

  grDevices::png(
    filename = publication_path,
    width = width_px,
    height = height_px,
    res = res
  )
  plot_fun()
  grDevices::dev.off()

  file.copy(publication_path, results_path, overwrite = TRUE)
}


draw_2x2_panel <- function() {
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par))

  graphics::layout(
    matrix(c(1, 2,
             3, 4), nrow = 2, byrow = TRUE)
  )

  common_cex_lab  <- 0.55
  common_cex_axis <- 0.55
  common_cex_main <- 0.68
  common_lwd      <- 1.4
  common_pt_cex   <- 0.55
  panel_label_cex <- 0.70

  # ---------------- ROC ----------------
  graphics::par(
    mar = c(2.2, 2.3, 1.0, 0.4),
    family = "sans",
    cex.lab = common_cex_lab,
    cex.axis = common_cex_axis,
    cex.main = common_cex_main,
    mgp = c(0.9, 0.2, 0),
    tcl = -0.22,
    las = 1
  )
  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "False Positive Rate",
    ylab = "True Positive Rate",
    main = "ROC Curves"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60", lwd = 1.2)
  for (name in names(roc_curves)) {
    df <- roc_curves[[name]]
    graphics::lines(df$fpr, df$tpr, col = df$color[1], lwd = common_lwd)
  }
  graphics::mtext("A", side = 3, line = 0.05, adj = 0, cex = panel_label_cex, font = 2)

  graphics::legend(
    "bottomright",
    legend = legend_labels,
    col = legend_colors,
    lwd = 1.5,
    cex = 0.46,
    bty = "n",
    y.intersp = 0.72,
    seg.len = 1.6,
    inset = 0.01
  )

  # ---------------- PR ----------------
  first_pred_df <- read_csv_config(model_specs[[1]]$predictions_path)
  first_pred_df <- first_pred_df[first_pred_df$model_name == model_specs[[1]]$key, , drop = FALSE]
  baseline_rate <- mean(ensure_factor_outcome(first_pred_df$truth) == "Yes")

  graphics::par(
    mar = c(2.2, 2.3, 1.0, 0.4),
    family = "sans",
    cex.lab = common_cex_lab,
    cex.axis = common_cex_axis,
    cex.main = common_cex_main,
    mgp = c(0.9, 0.2, 0),
    tcl = -0.22,
    las = 1
  )
  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "Recall",
    ylab = "Precision",
    main = "Precision-Recall Curves"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(h = baseline_rate, lty = 2, col = "gray60", lwd = 1.2)
  for (name in names(pr_curves)) {
    df <- pr_curves[[name]]
    graphics::lines(df$recall, df$precision, col = df$color[1], lwd = common_lwd)
  }
  graphics::mtext("B", side = 3, line = 0.05, adj = 0, cex = panel_label_cex, font = 2)

  # ---------------- Top-k ----------------
  graphics::par(
    mar = c(2.2, 2.3, 1.0, 0.4),
    family = "sans",
    cex.lab = common_cex_lab,
    cex.axis = common_cex_axis,
    cex.main = common_cex_main,
    mgp = c(0.9, 0.2, 0),
    tcl = -0.22,
    las = 1
  )
  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "Fraction Reviewed",
    ylab = "Cumulative Recall",
    main = "Top-k Capture"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray70", lwd = 1.2)
  for (name in names(topk_curves)) {
    df <- topk_curves[[name]]
    graphics::lines(df$review_fraction, df$recall, col = df$color[1], lwd = common_lwd)
  }
  graphics::mtext("C", side = 3, line = 0.05, adj = 0, cex = panel_label_cex, font = 2)

  # ---------------- Calibration ----------------
  graphics::par(
    mar = c(2.2, 2.3, 1.0, 0.4),
    family = "sans",
    cex.lab = common_cex_lab,
    cex.axis = common_cex_axis,
    cex.main = common_cex_main,
    mgp = c(0.9, 0.2, 0),
    tcl = -0.22,
    las = 1
  )
  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "Mean Predicted Probability",
    ylab = "Observed Event Rate",
    main = "Calibration"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60", lwd = 1.2)
  for (name in names(calibration_curves)) {
    df <- calibration_curves[[name]]
    graphics::lines(df$predicted_probability, df$observed_event, col = df$color[1], lwd = common_lwd)
    graphics::points(df$predicted_probability, df$observed_event, col = df$color[1], pch = 16, cex = common_pt_cex)
  }
  graphics::mtext("D", side = 3, line = 0.05, adj = 0, cex = panel_label_cex, font = 2)

 }

draw_topk_figure <- function() {
  op <- graphics::par(
    mar = c(5.2, 5.2, 4.2, 11),
    xpd = NA,
    family = "sans",
    cex.lab = 1.35,
    cex.axis = 1.2,
    cex.main = 1.35,
    las = 1
  )
  on.exit(graphics::par(op))

  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "Fraction Reviewed",
    ylab = "Cumulative Recall",
    main = "Internal Top-k Capture: Top 5 Models"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray70", lwd = 2)
  for (name in names(topk_curves)) {
    df <- topk_curves[[name]]
    graphics::lines(df$review_fraction, df$recall, col = df$color[1], lwd = 2.2)
  }

  graphics::legend(
    "bottomright",
    inset = c(-0.28, 0),
    legend = legend_labels,
    col = legend_colors,
    lwd = 4,
    cex = 1.15,
    bty = "n",
    xpd = NA,
    title = "Models"
  )
}

draw_calibration_figure <- function() {
  op <- graphics::par(
    mar = c(5.2, 5.2, 4.2, 11),
    xpd = NA,
    family = "sans",
    cex.lab = 1.35,
    cex.axis = 1.2,
    cex.main = 1.2,
    las = 1
  )
  on.exit(graphics::par(op))

  graphics::plot(
    c(0, 1), c(0, 1),
    type = "n",
    xlab = "Mean Predicted Probability",
    ylab = "Observed Event Rate",
    main = "Internal Calibration: Top 5 Models"
  )
  graphics::grid(col = "gray90", lty = 1)
  graphics::abline(a = 0, b = 1, lty = 2, col = "gray60", lwd = 2)
  for (name in names(calibration_curves)) {
    df <- calibration_curves[[name]]
    graphics::lines(df$predicted_probability, df$observed_event, col = df$color[1], lwd = 2.2)
    graphics::points(df$predicted_probability, df$observed_event, col = df$color[1], pch = 16, cex = 1.15)
  }

  graphics::legend(
    "bottomright",
    inset = c(-0.28, 0),
    legend = legend_labels,
    col = legend_colors,
    lwd = 4,
    cex = 1.15,
    bty = "n",
    xpd = NA,
    title = "Models"
  )
}

save_png_both(
  "publication_internal_top5_performance_2x2.png",
  draw_2x2_panel,
  width_px = 4200,
  height_px = 2500,
  res = 600
)

save_png_both(
  "publication_internal_top5_topk.png",
  draw_topk_figure,
  width_px = 2600,
  height_px = 1400,
  res = 600
)

save_png_both(
  "publication_internal_top5_calibration.png",
  draw_calibration_figure,
  width_px = 2600,
  height_px = 1400,
  res = 600
)

cat("Top 5 internal comparison figures generated.\n")
