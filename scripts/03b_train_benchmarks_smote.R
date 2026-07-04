root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))

dataset_path <- file.path(root, "results", "datasets", "development_model_dataset.csv")
if (!file.exists(dataset_path)) {
  stop("Run scripts/01_build_development_dataset.R first.")
}

development <- read_csv_config(dataset_path)
development$severe_outcome <- ensure_factor_outcome(development$severe_outcome)

split_path <- file.path(root, "results", "datasets", "internal_split.rds")
if (file.exists(split_path)) {
  split_obj <- readRDS(split_path)
  train_data <- split_obj$train_data
  test_data <- split_obj$test_data
} else {
  train_index <- stratified_split(development$severe_outcome, p = 0.70, seed = 20260327)
  train_data <- development[train_index, , drop = FALSE]
  test_data <- development[-train_index, , drop = FALSE]
}

saveRDS(list(train_data = train_data, test_data = test_data), file.path(root, "results", "datasets", "internal_split_smote.rds"))

preprocessor <- fit_preprocessor(train_data, outcome_col = "severe_outcome")
saveRDS(preprocessor, file.path(root, "results", "models", "train_preprocessor_smote.rds"))
x_train <- apply_preprocessor(train_data, preprocessor, outcome_col = "severe_outcome")
y_train <- ensure_factor_outcome(train_data$severe_outcome)
folds <- create_stratified_folds(y_train, k = 5, seed = 20260327)

benchmarks <- load_model_benchmarks(root)
benchmarks <- benchmarks[benchmarks$enabled, , drop = FALSE]
status_rows <- list()

for (i in seq_len(nrow(benchmarks))) {
  model_row <- benchmarks[i, , drop = FALSE]
  tuned <- tryCatch(
    cross_validate_model(model_row$model_name, x_train, y_train, folds, use_smote = TRUE),
    error = function(e) e
  )

  if (inherits(tuned, "error")) {
    status_rows[[length(status_rows) + 1]] <- data.frame(
      model_name = model_row$model_name,
      status = "failed",
      message = conditionMessage(tuned),
      best_pr_auc = NA_real_,
      best_roc_auc = NA_real_,
      best_tuning = NA_character_
    )
    next
  }

  smote_train <- apply_simple_smote(x_train, y_train, k = 5, seed = 20260327 + i)
  best_fit <- fit_model_object(model_row$model_name, smote_train$x, smote_train$y, tuned$best_params)
  saveRDS(best_fit, file.path(root, "results", "models", sprintf("%s_smote_train_fit.rds", model_row$model_name)))
  saveRDS(tuned, file.path(root, "results", "models", sprintf("%s_smote_tuning.rds", model_row$model_name)))
  utils::write.csv(tuned$results, file.path(root, "results", "metrics", sprintf("%s_cv_results_smote.csv", model_row$model_name)), row.names = FALSE, na = "")

  status_rows[[length(status_rows) + 1]] <- data.frame(
    model_name = model_row$model_name,
    status = "trained",
    message = "Cross-validation with SMOTE completed",
    best_pr_auc = tuned$results$mean_pr_auc[1],
    best_roc_auc = tuned$results$mean_roc_auc[1],
    best_tuning = paste(names(tuned$best_params), unlist(tuned$best_params, use.names = FALSE), sep = "=", collapse = "; ")
  )
}

training_status <- do.call(rbind, status_rows)
utils::write.csv(training_status, file.path(root, "results", "metrics", "training_status_smote.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "03b Train Benchmarks With SMOTE",
  c(
    sprintf("- Development training rows before SMOTE: %s", nrow(train_data)),
    sprintf("- Internal test rows held out unchanged: %s", nrow(test_data)),
    sprintf("- Models attempted with SMOTE: %s", paste(benchmarks$model_name, collapse = ", ")),
    sprintf("- SMOTE models trained successfully: %s", sum(training_status$status == "trained", na.rm = TRUE))
  )
)
