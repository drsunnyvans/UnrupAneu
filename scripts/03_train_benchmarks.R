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

train_index <- stratified_split(development$severe_outcome, p = 0.70, seed = 20260327)
train_data <- development[train_index, , drop = FALSE]
test_data <- development[-train_index, , drop = FALSE]
saveRDS(list(train_index = train_index, train_data = train_data, test_data = test_data), file.path(root, "results", "datasets", "internal_split.rds"))

preprocessor <- fit_preprocessor(train_data, outcome_col = "severe_outcome")
saveRDS(preprocessor, file.path(root, "results", "models", "train_preprocessor.rds"))
x_train <- apply_preprocessor(train_data, preprocessor, outcome_col = "severe_outcome")
y_train <- ensure_factor_outcome(train_data$severe_outcome)
folds <- create_stratified_folds(y_train, k = 5, seed = 20260327)

benchmarks <- load_model_benchmarks(root)
benchmarks <- benchmarks[benchmarks$enabled, , drop = FALSE]
status_rows <- list()

for (i in seq_len(nrow(benchmarks))) {
  model_row <- benchmarks[i, , drop = FALSE]
  tuned <- tryCatch(
    cross_validate_model(model_row$model_name, x_train, y_train, folds),
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

  best_fit <- fit_model_object(model_row$model_name, x_train, y_train, tuned$best_params)
  saveRDS(best_fit, file.path(root, "results", "models", sprintf("%s_train_fit.rds", model_row$model_name)))
  saveRDS(tuned, file.path(root, "results", "models", sprintf("%s_tuning.rds", model_row$model_name)))
  utils::write.csv(tuned$results, file.path(root, "results", "metrics", sprintf("%s_cv_results.csv", model_row$model_name)), row.names = FALSE, na = "")

  best_pr <- tuned$results$mean_pr_auc[1]
  best_roc <- tuned$results$mean_roc_auc[1]
  best_tuning <- paste(names(tuned$best_params), unlist(tuned$best_params, use.names = FALSE), sep = "=", collapse = "; ")

  status_rows[[length(status_rows) + 1]] <- data.frame(
    model_name = model_row$model_name,
    status = "trained",
    message = "Cross-validation completed",
    best_pr_auc = best_pr,
    best_roc_auc = best_roc,
    best_tuning = best_tuning
  )
}

training_status <- do.call(rbind, status_rows)
utils::write.csv(training_status, file.path(root, "results", "metrics", "training_status.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "03 Train Benchmarks",
  c(
    sprintf("- Development training rows: %s", nrow(train_data)),
    sprintf("- Internal test rows held out: %s", nrow(test_data)),
    sprintf("- Models attempted: %s", paste(benchmarks$model_name, collapse = ", ")),
    sprintf("- Models trained successfully: %s", sum(training_status$status == "trained", na.rm = TRUE))
  )
)
