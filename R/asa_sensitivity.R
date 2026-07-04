source(file.path(find_project_root(), "R", "utils.R"))
source(file.path(find_project_root(), "R", "data_prep.R"))
source(file.path(find_project_root(), "R", "modeling.R"))
source(file.path(find_project_root(), "R", "reporting.R"))

tag_suffix <- function(tag) {
  if (!nzchar(tag)) "" else paste0("_", tag)
}

analysis_paths <- function(root, dataset_tag = "", analysis_tag = "") {
  data_suffix <- tag_suffix(dataset_tag)
  analysis_suffix <- tag_suffix(analysis_tag)
  list(
    development_dataset = file.path(root, "results", "datasets", paste0("development_model_dataset", data_suffix, ".csv")),
    external_dataset = file.path(root, "results", "datasets", paste0("external_model_dataset", data_suffix, ".csv")),
    development_summary = file.path(root, "results", "metrics", paste0("development_dataset_summary", data_suffix, ".csv")),
    external_summary = file.path(root, "results", "metrics", paste0("external_dataset_summary", data_suffix, ".csv")),
    internal_split = file.path(root, "results", "datasets", paste0("internal_split", analysis_suffix, ".rds")),
    train_preprocessor = file.path(root, "results", "models", paste0("train_preprocessor", analysis_suffix, ".rds")),
    full_preprocessor = file.path(root, "results", "models", paste0("full_preprocessor", analysis_suffix, ".rds")),
    training_status = file.path(root, "results", "metrics", paste0("training_status", analysis_suffix, ".csv")),
    internal_metrics = file.path(root, "results", "metrics", paste0("internal_test_metrics", analysis_suffix, ".csv")),
    internal_topk = file.path(root, "results", "metrics", paste0("internal_test_topk_metrics", analysis_suffix, ".csv")),
    internal_threshold_grid = file.path(root, "results", "metrics", paste0("internal_test_threshold_grid", analysis_suffix, ".csv")),
    internal_threshold_defs = file.path(root, "results", "metrics", paste0("internal_test_selected_thresholds", analysis_suffix, ".csv")),
    internal_threshold_rule_metrics = file.path(root, "results", "metrics", paste0("internal_test_threshold_rule_metrics", analysis_suffix, ".csv")),
    internal_predictions = file.path(root, "results", "metrics", paste0("internal_test_predictions", analysis_suffix, ".csv")),
    model_selection = file.path(root, "results", "metrics", paste0("model_selection", analysis_suffix, ".csv")),
    external_metrics = file.path(root, "results", "metrics", paste0("external_validation_metrics", analysis_suffix, ".csv")),
    external_topk = file.path(root, "results", "metrics", paste0("external_validation_topk_metrics", analysis_suffix, ".csv")),
    external_predictions = file.path(root, "results", "metrics", paste0("external_validation_predictions", analysis_suffix, ".csv")),
    external_threshold_rule_metrics = file.path(root, "results", "metrics", paste0("external_validation_threshold_rule_metrics", analysis_suffix, ".csv"))
  )
}

model_artifact_path <- function(root, model_name, analysis_tag, artifact) {
  file.path(root, "results", "models", paste0(model_name, tag_suffix(analysis_tag), "_", artifact, ".rds"))
}

cv_results_path <- function(root, model_name, analysis_tag) {
  file.path(root, "results", "metrics", paste0(model_name, "_cv_results", tag_suffix(analysis_tag), ".csv"))
}

metric_dataset_label <- function(prefix, analysis_tag) {
  if (!nzchar(analysis_tag)) prefix else paste(prefix, analysis_tag, sep = "_")
}

selection_column_name <- function(analysis_tag) {
  if (!nzchar(analysis_tag)) "primary_model" else paste0("primary_model_", analysis_tag)
}

build_dataset_with_mapping <- function(root, mapping_file, dataset_tag, stage_prefix) {
  raw <- as.data.frame(read_development_raw(root), stringsAsFactors = FALSE, check.names = FALSE)
  mapping <- load_feature_mapping_file(root, mapping_file)
  modeled <- extract_harmonized_features(raw, mapping, "development")
  modeled$severe_outcome <- derive_development_outcome(raw)
  modeled <- modeled[!is.na(modeled$severe_outcome), , drop = FALSE]
  paths <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = dataset_tag)
  utils::write.csv(modeled, paths$development_dataset, row.names = FALSE, na = "")
  summary_df <- data.frame(
    cohort = paste0("development_", dataset_tag),
    n_rows = nrow(modeled),
    n_events = sum(modeled$severe_outcome == "Yes", na.rm = TRUE),
    event_rate = mean(modeled$severe_outcome == "Yes", na.rm = TRUE)
  )
  utils::write.csv(summary_df, paths$development_summary, row.names = FALSE, na = "")
  append_project_log(
    root,
    stage_prefix,
    c(
      sprintf("- Source file: `%s`", get_data_sources(root)$development_raw),
      sprintf("- Mapping file: `%s`", mapping_file),
      sprintf("- Rows retained: %s", nrow(modeled)),
      sprintf("- Severe outcomes (`dindo_scores >= 3`): %s", sum(modeled$severe_outcome == "Yes", na.rm = TRUE)),
      sprintf("- Modeling features retained: %s", ncol(modeled) - 1)
    )
  )
  invisible(modeled)
}

build_external_dataset_with_mapping <- function(root, mapping_file, dataset_tag, stage_prefix) {
  raw <- read_external_raw(root)
  mapping <- load_feature_mapping_file(root, mapping_file)
  modeled <- extract_harmonized_features(raw, mapping, "external")
  modeled$severe_outcome <- derive_external_outcome(raw, root)
  paths <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = dataset_tag)
  utils::write.csv(modeled, paths$external_dataset, row.names = FALSE, na = "")
  summary_df <- data.frame(
    cohort = paste0("external_", dataset_tag),
    n_rows = nrow(modeled),
    n_events = sum(modeled$severe_outcome == "Yes", na.rm = TRUE),
    event_rate = mean(modeled$severe_outcome == "Yes", na.rm = TRUE)
  )
  utils::write.csv(summary_df, paths$external_summary, row.names = FALSE, na = "")
  append_project_log(
    root,
    stage_prefix,
    c(
      sprintf("- Source file: `%s`", get_data_sources(root)$external_raw),
      sprintf("- Mapping file: `%s`", mapping_file),
      sprintf("- Rows retained for validation: %s", nrow(modeled)),
      sprintf("- External severe outcomes: %s", sum(modeled$severe_outcome == "Yes", na.rm = TRUE)),
      sprintf("- Modeling features retained: %s", ncol(modeled) - 1)
    )
  )
  invisible(modeled)
}

run_train_benchmarks_arm <- function(root, dataset_tag, analysis_tag, use_smote = FALSE, use_weights = FALSE, stage_label) {
  paths <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = analysis_tag)
  if (!file.exists(paths$development_dataset)) stop(sprintf("Missing %s", paths$development_dataset))

  development <- read_csv_config(paths$development_dataset)
  development$severe_outcome <- ensure_factor_outcome(development$severe_outcome)

  base_split <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = dataset_tag)$internal_split
  if ((use_smote || use_weights) && file.exists(base_split)) {
    split_obj <- readRDS(base_split)
    train_data <- split_obj$train_data
    test_data <- split_obj$test_data
  } else {
    train_index <- stratified_split(development$severe_outcome, p = 0.70, seed = 20260327)
    train_data <- development[train_index, , drop = FALSE]
    test_data <- development[-train_index, , drop = FALSE]
  }

  saveRDS(list(train_data = train_data, test_data = test_data), paths$internal_split)
  if (!file.exists(base_split)) saveRDS(list(train_data = train_data, test_data = test_data), base_split)

  preprocessor <- fit_preprocessor(train_data, outcome_col = "severe_outcome")
  saveRDS(preprocessor, paths$train_preprocessor)
  x_train <- apply_preprocessor(train_data, preprocessor, outcome_col = "severe_outcome")
  y_train <- ensure_factor_outcome(train_data$severe_outcome)
  folds <- create_stratified_folds(y_train, k = 5, seed = 20260327)

  benchmarks <- load_model_benchmarks(root)
  benchmarks <- benchmarks[benchmarks$enabled, , drop = FALSE]
  status_rows <- list()
  for (i in seq_len(nrow(benchmarks))) {
    model_row <- benchmarks[i, , drop = FALSE]
    tuned <- tryCatch(
      cross_validate_model(model_row$model_name, x_train, y_train, folds, use_smote = use_smote, use_weights = use_weights),
      error = function(e) e
    )
    if (inherits(tuned, "error")) {
      status_rows[[length(status_rows) + 1]] <- data.frame(model_name = model_row$model_name, status = "failed", message = conditionMessage(tuned), best_pr_auc = NA_real_, best_roc_auc = NA_real_, best_tuning = NA_character_)
      next
    }

    fit_params <- tuned$best_params
    train_x <- x_train
    train_y <- y_train
    message_text <- "Cross-validation completed"
    if (use_smote) {
      smote_train <- apply_simple_smote(x_train, y_train, k = 5, seed = 20260327 + i)
      train_x <- smote_train$x
      train_y <- smote_train$y
      message_text <- "Cross-validation with SMOTE completed"
    }
    if (use_weights) {
      fit_params$use_weights <- TRUE
      message_text <- "Cross-validation with class weights completed"
    }

    best_fit <- fit_model_object(model_row$model_name, train_x, train_y, fit_params)
    saveRDS(best_fit, model_artifact_path(root, model_row$model_name, analysis_tag, "train_fit"))
    saveRDS(tuned, model_artifact_path(root, model_row$model_name, analysis_tag, "tuning"))
    utils::write.csv(tuned$results, cv_results_path(root, model_row$model_name, analysis_tag), row.names = FALSE, na = "")
    best_tuning <- paste(names(fit_params), unlist(fit_params, use.names = FALSE), sep = "=", collapse = "; ")

    status_rows[[length(status_rows) + 1]] <- data.frame(
      model_name = model_row$model_name,
      status = "trained",
      message = message_text,
      best_pr_auc = tuned$results$mean_pr_auc[1],
      best_roc_auc = tuned$results$mean_roc_auc[1],
      best_tuning = best_tuning
    )
  }

  training_status <- do.call(rbind, status_rows)
  utils::write.csv(training_status, paths$training_status, row.names = FALSE, na = "")
  append_project_log(root, stage_label, c(
    sprintf("- Dataset tag: `%s`", dataset_tag),
    sprintf("- Analysis tag: `%s`", analysis_tag),
    sprintf("- Development training rows: %s", nrow(train_data)),
    sprintf("- Internal test rows held out: %s", nrow(test_data)),
    sprintf("- Models trained successfully: %s", sum(training_status$status == "trained", na.rm = TRUE))
  ))
}

run_internal_evaluation_arm <- function(root, dataset_tag, analysis_tag, use_smote = FALSE, use_weights = FALSE, stage_label) {
  paths <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = analysis_tag)
  split_obj <- readRDS(paths$internal_split)
  training_status <- read_csv_config(paths$training_status)
  successful <- training_status[training_status$status == "trained", , drop = FALSE]
  if (nrow(successful) == 0) stop(sprintf("No trained models for %s", analysis_tag))

  train_preprocessor <- readRDS(paths$train_preprocessor)
  x_test <- apply_preprocessor(split_obj$test_data, train_preprocessor, outcome_col = "severe_outcome")
  y_test <- ensure_factor_outcome(split_obj$test_data$severe_outcome)
  dataset_label <- metric_dataset_label("internal_test", analysis_tag)

  metric_rows <- list(); topk_rows <- list(); threshold_grid_rows <- list(); prediction_rows <- list()
  for (i in seq_len(nrow(successful))) {
    model_name <- successful$model_name[i]
    fit <- readRDS(model_artifact_path(root, model_name, analysis_tag, "train_fit"))
    probs <- predict_probabilities(fit, x_test)
    bundle <- build_prediction_artifacts(y_test, probs, model_name, dataset_label)
    metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
    topk_rows[[length(topk_rows) + 1]] <- bundle$topk
    threshold_grid_rows[[length(threshold_grid_rows) + 1]] <- bundle$threshold_grid
    prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
  }

  internal_metrics <- do.call(rbind, metric_rows)
  internal_metrics <- internal_metrics[order(-internal_metrics$pr_auc, -internal_metrics$roc_auc), ]
  internal_topk <- do.call(rbind, topk_rows)
  internal_topk <- internal_topk[order(internal_topk$model_name, internal_topk$proportion_flagged), ]
  internal_threshold_grid <- do.call(rbind, threshold_grid_rows)
  internal_predictions <- do.call(rbind, prediction_rows)

  selected_threshold_defs <- list(); selected_threshold_metrics <- list()
  for (model_name in unique(internal_predictions$model_name)) {
    model_predictions <- internal_predictions[internal_predictions$model_name == model_name, , drop = FALSE]
    model_grid <- internal_threshold_grid[internal_threshold_grid$model_name == model_name, , drop = FALSE]
    rules <- select_threshold_rules(model_grid, model_predictions$predicted_probability)
    rules$model_name <- model_name
    rules$dataset <- dataset_label
    selected_threshold_defs[[length(selected_threshold_defs) + 1]] <- rules[, c("model_name", "dataset", "rule_name", "threshold", "flagged_fraction")]
    selected_threshold_metrics[[length(selected_threshold_metrics) + 1]] <- apply_threshold_rules(model_predictions$truth, model_predictions$predicted_probability, model_name, dataset_label, rules)
  }

  internal_threshold_defs <- do.call(rbind, selected_threshold_defs)
  internal_threshold_rule_metrics <- do.call(rbind, selected_threshold_metrics)
  utils::write.csv(internal_metrics, paths$internal_metrics, row.names = FALSE, na = "")
  utils::write.csv(internal_topk, paths$internal_topk, row.names = FALSE, na = "")
  utils::write.csv(internal_threshold_grid, paths$internal_threshold_grid, row.names = FALSE, na = "")
  utils::write.csv(internal_threshold_defs, paths$internal_threshold_defs, row.names = FALSE, na = "")
  utils::write.csv(internal_threshold_rule_metrics, paths$internal_threshold_rule_metrics, row.names = FALSE, na = "")
  utils::write.csv(internal_predictions, paths$internal_predictions, row.names = FALSE, na = "")

  selection_col <- selection_column_name(analysis_tag)
  selected <- build_internal_selection_summary(internal_metrics, internal_topk, selection_col = selection_col)
  utils::write.csv(selected, paths$model_selection, row.names = FALSE, na = "")

  development <- read_csv_config(paths$development_dataset)
  development$severe_outcome <- ensure_factor_outcome(development$severe_outcome)
  full_preprocessor <- fit_preprocessor(development, outcome_col = "severe_outcome")
  saveRDS(full_preprocessor, paths$full_preprocessor)
  x_full <- apply_preprocessor(development, full_preprocessor, outcome_col = "severe_outcome")
  y_full <- ensure_factor_outcome(development$severe_outcome)

  for (i in seq_len(nrow(successful))) {
    model_name <- successful$model_name[i]
    tuned_fit <- readRDS(model_artifact_path(root, model_name, analysis_tag, "tuning"))
    fit_params <- tuned_fit$best_params
    train_x <- x_full
    train_y <- y_full
    if (use_smote) {
      smote_full <- apply_simple_smote(x_full, y_full, k = 5, seed = 20260327 + i)
      train_x <- smote_full$x
      train_y <- smote_full$y
    }
    if (use_weights) fit_params$use_weights <- TRUE
    final_fit <- fit_model_object(model_name, train_x, train_y, fit_params)
    saveRDS(final_fit, model_artifact_path(root, model_name, analysis_tag, "final_full"))
  }

  append_project_log(root, stage_label, c(
    sprintf("- Internal test metrics generated for: %s", paste(successful$model_name, collapse = ", ")),
    sprintf("- Selected primary model: `%s`", as.character(selected[[selection_col]][1]))
  ))
}

run_external_validation_arm <- function(root, dataset_tag, analysis_tag, stage_label) {
  paths <- analysis_paths(root, dataset_tag = dataset_tag, analysis_tag = analysis_tag)
  external <- read_csv_config(paths$external_dataset)
  external$severe_outcome <- ensure_factor_outcome(external$severe_outcome)
  full_preprocessor <- readRDS(paths$full_preprocessor)
  x_external <- apply_preprocessor(external, full_preprocessor, outcome_col = "severe_outcome")
  y_external <- ensure_factor_outcome(external$severe_outcome)
  training_status <- read_csv_config(paths$training_status)
  successful <- training_status[training_status$status == "trained", , drop = FALSE]
  threshold_defs <- read_csv_config(paths$internal_threshold_defs)
  dataset_label <- metric_dataset_label("external_validation", analysis_tag)

  metric_rows <- list(); topk_rows <- list(); prediction_rows <- list(); threshold_rule_rows <- list()
  for (i in seq_len(nrow(successful))) {
    model_name <- successful$model_name[i]
    final_fit <- readRDS(model_artifact_path(root, model_name, analysis_tag, "final_full"))
    probs <- predict_probabilities(final_fit, x_external)
    bundle <- build_prediction_artifacts(y_external, probs, model_name, dataset_label)
    metric_rows[[length(metric_rows) + 1]] <- bundle$metrics
    topk_rows[[length(topk_rows) + 1]] <- bundle$topk
    prediction_rows[[length(prediction_rows) + 1]] <- bundle$predictions
    model_thresholds <- threshold_defs[threshold_defs$model_name == model_name, , drop = FALSE]
    if (nrow(model_thresholds) > 0) {
      threshold_rule_rows[[length(threshold_rule_rows) + 1]] <- apply_threshold_rules(y_external, probs, model_name, dataset_label, model_thresholds)
    }
  }

  external_metrics <- do.call(rbind, metric_rows)
  external_metrics <- external_metrics[order(-external_metrics$pr_auc, -external_metrics$roc_auc), ]
  external_topk <- do.call(rbind, topk_rows)
  external_predictions <- do.call(rbind, prediction_rows)
  external_threshold_rule_metrics <- do.call(rbind, threshold_rule_rows)
  utils::write.csv(external_metrics, paths$external_metrics, row.names = FALSE, na = "")
  utils::write.csv(external_topk, paths$external_topk, row.names = FALSE, na = "")
  utils::write.csv(external_predictions, paths$external_predictions, row.names = FALSE, na = "")
  utils::write.csv(external_threshold_rule_metrics, paths$external_threshold_rule_metrics, row.names = FALSE, na = "")
  append_project_log(root, stage_label, c(
    sprintf("- External validation rows scored: %s", nrow(external)),
    sprintf("- Models externally validated: %s", paste(successful$model_name, collapse = ", "))
  ))
}

write_asa_sensitivity_summary <- function(root) {
  combos <- data.frame(arm = c("ASA Original", "ASA SMOTE", "ASA Weighted"), analysis_tag = c("asa", "smote_asa", "weighted_asa"), stringsAsFactors = FALSE)
  rows <- list()
  for (i in seq_len(nrow(combos))) {
    paths <- analysis_paths(root, dataset_tag = "asa", analysis_tag = combos$analysis_tag[i])
    internal <- if (file.exists(paths$internal_metrics)) read_csv_config(paths$internal_metrics) else data.frame()
    external <- if (file.exists(paths$external_metrics)) read_csv_config(paths$external_metrics) else data.frame()
    if (nrow(internal) == 0 || nrow(external) == 0) next
    merged <- merge(internal[, c("model_name", "pr_auc", "roc_auc")], external[, c("model_name", "pr_auc", "roc_auc")], by = "model_name", suffixes = c("_internal", "_external"))
    merged$arm <- combos$arm[i]
    rows[[length(rows) + 1]] <- merged
  }
  if (length(rows) == 0) return(invisible(NULL))
  summary_df <- do.call(rbind, rows)
  summary_df$model <- pretty_model_label(summary_df$model_name)
  summary_df <- summary_df[, c("arm", "model", "pr_auc_internal", "roc_auc_internal", "pr_auc_external", "roc_auc_external")]
  names(summary_df) <- c("arm", "model", "internal_pr_auc", "internal_roc_auc", "external_pr_auc", "external_roc_auc")
  utils::write.csv(summary_df, file.path(root, "results", "metrics", "asa_sensitivity_summary.csv"), row.names = FALSE, na = "")
  dir.create(file.path(root, "publication_summary", "tables"), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(summary_df, file.path(root, "publication_summary", "tables", "publication_asa_sensitivity_summary.csv"), row.names = FALSE, na = "")
  invisible(summary_df)
}
