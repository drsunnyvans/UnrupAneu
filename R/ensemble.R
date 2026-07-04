source(file.path(find_project_root(), "R", "utils.R"))
source(file.path(find_project_root(), "R", "modeling.R"))

get_ensemble_components <- function() {
  data.frame(
    component_id = c("original_xgboost", "smote_ann", "weighted_xgboost"),
    arm = c("original", "smote", "weighted"),
    model_name = c("xgboost", "ann", "xgboost"),
    stringsAsFactors = FALSE
  )
}

get_component_artifacts <- function(root, component_id) {
  components <- get_ensemble_components()
  row <- components[components$component_id == component_id, , drop = FALSE]
  if (nrow(row) != 1) stop(sprintf("Unknown ensemble component: %s", component_id))

  arm <- row$arm[1]
  model_name <- row$model_name[1]
  if (arm == "original") {
    return(list(
      model_name = model_name,
      arm = arm,
      preprocessor = file.path(root, "results", "models", "train_preprocessor.rds"),
      tuning = file.path(root, "results", "models", sprintf("%s_tuning.rds", model_name)),
      train_fit = file.path(root, "results", "models", sprintf("%s_train_fit.rds", model_name)),
      final_full = file.path(root, "results", "models", sprintf("%s_final_full.rds", model_name)),
      internal_predictions = file.path(root, "results", "metrics", "internal_test_predictions.csv"),
      external_predictions = file.path(root, "results", "metrics", "external_validation_predictions.csv"),
      use_smote = FALSE,
      use_weights = FALSE
    ))
  }
  if (arm == "smote") {
    return(list(
      model_name = model_name,
      arm = arm,
      preprocessor = file.path(root, "results", "models", "train_preprocessor_smote.rds"),
      tuning = file.path(root, "results", "models", sprintf("%s_smote_tuning.rds", model_name)),
      train_fit = file.path(root, "results", "models", sprintf("%s_smote_train_fit.rds", model_name)),
      final_full = file.path(root, "results", "models", sprintf("%s_smote_final_full.rds", model_name)),
      internal_predictions = file.path(root, "results", "metrics", "internal_test_predictions_smote.csv"),
      external_predictions = file.path(root, "results", "metrics", "external_validation_predictions_smote.csv"),
      use_smote = TRUE,
      use_weights = FALSE
    ))
  }
  if (arm == "weighted") {
    return(list(
      model_name = model_name,
      arm = arm,
      preprocessor = file.path(root, "results", "models", "train_preprocessor_weighted.rds"),
      tuning = file.path(root, "results", "models", sprintf("%s_weighted_tuning.rds", model_name)),
      train_fit = file.path(root, "results", "models", sprintf("%s_weighted_train_fit.rds", model_name)),
      final_full = file.path(root, "results", "models", sprintf("%s_weighted_final_full.rds", model_name)),
      internal_predictions = file.path(root, "results", "metrics", "internal_test_predictions_weighted.csv"),
      external_predictions = file.path(root, "results", "metrics", "external_validation_predictions_weighted.csv"),
      use_smote = FALSE,
      use_weights = TRUE
    ))
  }
  stop(sprintf("Unsupported arm: %s", arm))
}

generate_component_oof_predictions <- function(component_id, train_data, folds, root, outcome_col = "severe_outcome") {
  artifacts <- get_component_artifacts(root, component_id)
  preprocessor <- readRDS(artifacts$preprocessor)
  tuning <- readRDS(artifacts$tuning)
  x_train <- apply_preprocessor(train_data, preprocessor, outcome_col = outcome_col)
  y_train <- ensure_factor_outcome(train_data[[outcome_col]])

  oof_probs <- rep(NA_real_, nrow(train_data))
  for (j in seq_along(folds)) {
    val_idx <- folds[[j]]
    train_idx <- setdiff(seq_len(nrow(x_train)), val_idx)
    x_fold <- x_train[train_idx, , drop = FALSE]
    y_fold <- y_train[train_idx]
    if (isTRUE(artifacts$use_smote)) {
      smote_result <- apply_simple_smote(x_fold, y_fold, k = 5, seed = 20260327 + j)
      x_fold <- smote_result$x
      y_fold <- smote_result$y
    }
    fit <- fit_model_object(artifacts$model_name, x_fold, y_fold, tuning$best_params)
    oof_probs[val_idx] <- predict_probabilities(fit, x_train[val_idx, , drop = FALSE])
  }

  data.frame(
    row_id = seq_len(nrow(train_data)),
    truth = as.character(y_train),
    predicted_probability = oof_probs,
    stringsAsFactors = FALSE
  ) -> out
  names(out)[names(out) == "predicted_probability"] <- component_id
  out
}

read_component_prediction_file <- function(path, model_name, component_id) {
  preds <- read_csv_config(path)
  preds <- preds[preds$model_name == model_name, c("row_id", "truth", "predicted_probability"), drop = FALSE]
  names(preds)[names(preds) == "predicted_probability"] <- component_id
  preds
}

merge_component_predictions <- function(component_prediction_list) {
  merged <- component_prediction_list[[1]]
  for (i in 2:length(component_prediction_list)) {
    merged <- merge(merged, component_prediction_list[[i]], by = c("row_id", "truth"), all = FALSE)
  }
  merged <- merged[order(merged$row_id), , drop = FALSE]
  merged
}

compute_soft_vote_weights <- function(oof_stack, component_ids) {
  scores <- numeric(length(component_ids))
  names(scores) <- component_ids
  truth <- ensure_factor_outcome(oof_stack$truth)
  for (component_id in component_ids) {
    scores[[component_id]] <- binary_pr_auc(truth, oof_stack[[component_id]])
  }
  scores[!is.finite(scores) | scores < 0] <- 0
  if (sum(scores) <= 0) {
    scores[] <- 1 / length(scores)
  } else {
    scores <- scores / sum(scores)
  }
  data.frame(component_id = names(scores), weight = as.numeric(scores), stringsAsFactors = FALSE)
}

soft_vote_predict <- function(stack_data, weights_df) {
  component_ids <- weights_df$component_id
  weight_vec <- weights_df$weight
  as.numeric(as.matrix(stack_data[, component_ids, drop = FALSE]) %*% weight_vec)
}

fit_stacked_logistic <- function(oof_stack, component_ids) {
  data <- oof_stack[, c("truth", component_ids), drop = FALSE]
  data$truth_num <- as.integer(ensure_factor_outcome(data$truth) == "Yes")
  stats::glm(truth_num ~ ., data = data[, setdiff(names(data), "truth"), drop = FALSE], family = stats::binomial())
}

predict_stacked_logistic <- function(fit, stack_data, component_ids) {
  pmin(pmax(as.numeric(stats::predict(fit, newdata = stack_data[, component_ids, drop = FALSE], type = "response")), 0), 1)
}
