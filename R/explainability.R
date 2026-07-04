source(file.path(find_project_root(), "R", "utils.R"))
source(file.path(find_project_root(), "R", "modeling.R"))

predict_from_raw_features <- function(model_object, preprocessor, raw_features) {
  transformed <- apply_preprocessor(raw_features, preprocessor, outcome_col = "severe_outcome")
  predict_probabilities(model_object, transformed)
}

approximate_shap_values <- function(model_object, preprocessor, background_data, explain_data, nsim = 25, seed = 20260327) {
  set.seed(seed)
  features <- colnames(explain_data)
  shap_matrix <- matrix(0, nrow = nrow(explain_data), ncol = length(features))
  colnames(shap_matrix) <- features

  for (row_idx in seq_len(nrow(explain_data))) {
    x_row <- explain_data[row_idx, , drop = FALSE]
    for (sim in seq_len(nsim)) {
      baseline_row <- background_data[sample(seq_len(nrow(background_data)), 1), , drop = FALSE]
      permutation <- sample(features)
      current_row <- baseline_row
      previous_pred <- predict_from_raw_features(model_object, preprocessor, current_row)

      for (feature in permutation) {
        current_row[[feature]] <- x_row[[feature]]
        new_pred <- predict_from_raw_features(model_object, preprocessor, current_row)
        shap_matrix[row_idx, feature] <- shap_matrix[row_idx, feature] + (new_pred - previous_pred)
        previous_pred <- new_pred
      }
    }
  }

  shap_matrix / nsim
}

summarize_shap_values <- function(shap_matrix) {
  data.frame(
    feature = colnames(shap_matrix),
    mean_abs_shap = colMeans(abs(shap_matrix), na.rm = TRUE),
    mean_signed_shap = colMeans(shap_matrix, na.rm = TRUE),
    stringsAsFactors = FALSE
  )[order(-colMeans(abs(shap_matrix), na.rm = TRUE)), , drop = FALSE]
}

save_shap_plots <- function(shap_matrix, summary_df, out_prefix) {
  top_features <- head(summary_df$feature, 15)
  top_values <- summary_df$mean_abs_shap[match(top_features, summary_df$feature)]

  grDevices::png(sprintf("%s_importance.png", out_prefix), width = 1100, height = 800)
  graphics::par(mar = c(10, 5, 3, 1))
  graphics::barplot(
    rev(top_values),
    names.arg = rev(top_features),
    horiz = TRUE,
    las = 1,
    main = "External SHAP Importance",
    xlab = "Mean |SHAP|"
  )
  grDevices::dev.off()

  distribution_features <- head(summary_df$feature, 10)
  grDevices::png(sprintf("%s_distribution.png", out_prefix), width = 1100, height = 800)
  graphics::par(mar = c(10, 5, 3, 1))
  plot_data <- shap_matrix[, distribution_features, drop = FALSE]
  graphics::boxplot(
    plot_data,
    las = 2,
    main = "External SHAP Distribution",
    ylab = "SHAP value"
  )
  graphics::abline(h = 0, lty = 2, col = "gray60")
  grDevices::dev.off()
}
