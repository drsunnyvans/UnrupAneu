source(file.path(find_project_root(), "R", "utils.R"))

coalesce_numeric <- function(x, default = NA_real_) {
  x_num <- suppressWarnings(as.numeric(x))
  x_num[!is.finite(x_num)] <- default
  x_num
}

binary_flag <- function(x, positive_values = c("yes", "1", "true")) {
  vals <- tolower(normalize_missing_strings(x))
  out <- rep(0, length(vals))
  out[!is.na(vals) & vals %in% positive_values] <- 1
  out[is.na(vals)] <- NA_real_
  out
}

engineer_model_features <- function(features) {
  engineered <- features

  numeric_candidates <- intersect(
    c("age", "bmi", "sodium", "bun", "creatinine", "albumin", "bilirubin", "ast", "alk_phos", "wbc", "platelets", "ptt", "inr"),
    names(features)
  )

  for (col in numeric_candidates) {
    raw_numeric <- coalesce_numeric(features[[col]])
    engineered[[paste0(col, "_missing")]] <- ifelse(is.na(raw_numeric), 1, 0)
    engineered[[col]] <- raw_numeric
  }

  square_terms <- intersect(c("age", "bmi", "bun", "creatinine", "albumin", "wbc", "platelets", "ptt", "inr"), names(engineered))
  for (col in square_terms) {
    engineered[[paste0(col, "_sq")]] <- ifelse(is.na(engineered[[col]]), NA_real_, engineered[[col]]^2)
  }

  log_terms <- intersect(c("bun", "creatinine", "bilirubin", "ast", "alk_phos", "wbc", "platelets", "ptt", "inr"), names(engineered))
  for (col in log_terms) {
    engineered[[paste0(col, "_log1p")]] <- ifelse(is.na(engineered[[col]]), NA_real_, log1p(pmax(engineered[[col]], 0)))
  }

  if ("functional_status" %in% names(features) && "age" %in% names(engineered)) {
    status <- tolower(normalize_missing_strings(features$functional_status))
    non_independent <- ifelse(is.na(status), NA_real_, ifelse(status == "independent", 0, 1))
    engineered$functional_status_nonindependent <- non_independent
    engineered$age_x_nonindependent <- ifelse(is.na(engineered$age) | is.na(non_independent), NA_real_, engineered$age * non_independent)
  }

  if ("active_malignancy" %in% names(features) && "albumin" %in% names(engineered)) {
    malignancy <- binary_flag(features$active_malignancy)
    engineered$albumin_x_active_malignancy <- ifelse(is.na(engineered$albumin) | is.na(malignancy), NA_real_, engineered$albumin * malignancy)
  }

  if ("coagulopathy" %in% names(features) && "inr" %in% names(engineered)) {
    coag <- binary_flag(features$coagulopathy)
    engineered$coagulopathy_x_inr <- ifelse(is.na(engineered$inr) | is.na(coag), NA_real_, engineered$inr * coag)
  }

  if ("coagulopathy" %in% names(features) && "ptt" %in% names(engineered)) {
    coag <- binary_flag(features$coagulopathy)
    engineered$coagulopathy_x_ptt <- ifelse(is.na(engineered$ptt) | is.na(coag), NA_real_, engineered$ptt * coag)
  }

  if ("dialysis" %in% names(features) && "creatinine" %in% names(engineered)) {
    dialysis_flag <- binary_flag(features$dialysis)
    engineered$creatinine_x_dialysis <- ifelse(is.na(engineered$creatinine) | is.na(dialysis_flag), NA_real_, engineered$creatinine * dialysis_flag)
  }

  engineered
}

prepare_feature_frame <- function(features, medians, factor_levels) {
  output <- features
  for (col in names(output)) {
    if (col %in% names(medians)) {
      numeric_values <- as.numeric(output[[col]])
      numeric_values[is.na(numeric_values)] <- medians[[col]]
      output[[col]] <- numeric_values
    } else {
      values <- normalize_missing_strings(output[[col]])
      values[is.na(values)] <- "Missing"
      known_levels <- factor_levels[[col]]
      values[!values %in% known_levels] <- "Other"
      output[[col]] <- factor(values, levels = known_levels)
    }
  }
  output
}

apply_simple_smote <- function(x, y, k = 5, seed = 20260327) {
  set.seed(seed)
  y <- ensure_factor_outcome(y)
  class_counts <- table(y)
  if (length(class_counts) < 2) {
    return(list(x = x, y = y))
  }

  minority_label <- names(class_counts)[which.min(class_counts)]
  majority_label <- names(class_counts)[which.max(class_counts)]
  minority_idx <- which(y == minority_label)
  majority_idx <- which(y == majority_label)

  n_needed <- length(majority_idx) - length(minority_idx)
  if (n_needed <= 0) {
    return(list(x = x, y = y))
  }

  minority_x <- x[minority_idx, , drop = FALSE]
  synthetic <- matrix(NA_real_, nrow = n_needed, ncol = ncol(x))
  colnames(synthetic) <- colnames(x)

  if (nrow(minority_x) == 1) {
    synthetic[,] <- matrix(rep(minority_x[1, ], n_needed), nrow = n_needed, byrow = TRUE)
  } else {
    distance_matrix <- as.matrix(stats::dist(minority_x))
    for (i in seq_len(nrow(distance_matrix))) {
      distance_matrix[i, i] <- Inf
    }

    for (i in seq_len(n_needed)) {
      anchor_pos <- sample(seq_len(nrow(minority_x)), 1)
      neighbor_order <- order(distance_matrix[anchor_pos, ], decreasing = FALSE)
      neighbor_order <- neighbor_order[is.finite(distance_matrix[anchor_pos, neighbor_order])]
      neighbor_pool <- head(neighbor_order, min(k, length(neighbor_order)))
      if (length(neighbor_pool) == 0) {
        neighbor_pos <- anchor_pos
      } else {
        neighbor_pos <- sample(neighbor_pool, 1)
      }
      gap <- stats::runif(1)
      synthetic[i, ] <- minority_x[anchor_pos, ] + gap * (minority_x[neighbor_pos, ] - minority_x[anchor_pos, ])
    }
  }

  x_balanced <- rbind(x, synthetic)
  y_balanced <- factor(c(as.character(y), rep(minority_label, n_needed)), levels = levels(y))
  list(x = x_balanced, y = y_balanced)
}

fit_preprocessor <- function(data, outcome_col = "severe_outcome") {
  features <- data[, setdiff(names(data), outcome_col), drop = FALSE]
  features <- engineer_model_features(features)
  numeric_cols <- names(features)[vapply(features, is.numeric, FUN.VALUE = logical(1))]
  categorical_cols <- setdiff(names(features), numeric_cols)

  medians <- stats::setNames(rep(NA_real_, length(numeric_cols)), numeric_cols)
  for (col in numeric_cols) {
    medians[[col]] <- stats::median(features[[col]], na.rm = TRUE)
    if (!is.finite(medians[[col]])) medians[[col]] <- 0
  }

  factor_levels <- vector("list", length(categorical_cols))
  names(factor_levels) <- categorical_cols
  for (col in categorical_cols) {
    values <- normalize_missing_strings(features[[col]])
    values[is.na(values)] <- "Missing"
    factor_levels[[col]] <- sort(unique(c(values, "Missing", "Other")))
  }

  processed <- prepare_feature_frame(features, medians, factor_levels)
  matrix <- as.matrix(stats::model.matrix(~ . - 1, data = processed))

  nzv <- apply(matrix, 2, function(column) stats::var(column, na.rm = TRUE))
  keep_nzv <- is.finite(nzv) & nzv > 0
  matrix <- matrix[, keep_nzv, drop = FALSE]

  if (ncol(matrix) > 1) {
    correlation_matrix <- suppressWarnings(stats::cor(matrix))
    correlation_matrix[is.na(correlation_matrix)] <- 0
    keep <- rep(TRUE, ncol(correlation_matrix))
    for (i in seq_len(ncol(correlation_matrix))) {
      if (!keep[i]) next
      high_corr <- which(abs(correlation_matrix[i, ]) > 0.90 & seq_len(ncol(correlation_matrix)) > i)
      if (length(high_corr) > 0) keep[high_corr] <- FALSE
    }
    matrix <- matrix[, keep, drop = FALSE]
  }

  centers <- colMeans(matrix)
  scales <- apply(matrix, 2, stats::sd)
  scales[!is.finite(scales) | scales == 0] <- 1

  list(
    feature_names = setdiff(names(data), outcome_col),
    medians = medians,
    factor_levels = factor_levels,
    final_columns = colnames(matrix),
    centers = centers,
    scales = scales
  )
}

apply_preprocessor <- function(data, preprocessor, outcome_col = "severe_outcome") {
  features <- data[, preprocessor$feature_names, drop = FALSE]
  processed <- engineer_model_features(features)
  processed <- prepare_feature_frame(processed, preprocessor$medians, preprocessor$factor_levels)
  matrix <- as.matrix(stats::model.matrix(~ . - 1, data = processed))
  missing_columns <- setdiff(preprocessor$final_columns, colnames(matrix))
  if (length(missing_columns) > 0) {
    zeros <- matrix(0, nrow = nrow(matrix), ncol = length(missing_columns))
    colnames(zeros) <- missing_columns
    matrix <- cbind(matrix, zeros)
  }
  extra_columns <- setdiff(colnames(matrix), preprocessor$final_columns)
  if (length(extra_columns) > 0) matrix <- matrix[, setdiff(colnames(matrix), extra_columns), drop = FALSE]
  matrix <- matrix[, preprocessor$final_columns, drop = FALSE]
  scale(matrix, center = preprocessor$centers, scale = preprocessor$scales)
}

binary_pr_auc <- function(truth, probs) {
  truth <- ensure_factor_outcome(truth)
  positive <- truth == "Yes"
  if (sum(positive) == 0 || sum(!positive) == 0) return(NA_real_)
  ord <- order(probs, decreasing = TRUE)
  positive <- positive[ord]
  tp <- cumsum(positive)
  fp <- cumsum(!positive)
  recall <- c(0, tp / sum(positive))
  precision <- c(1, tp / pmax(tp + fp, 1))
  sum((recall[-1] - recall[-length(recall)]) * precision[-1])
}

binary_roc_auc <- function(truth, probs) {
  truth <- ensure_factor_outcome(truth)
  y <- as.integer(truth == "Yes")
  positives <- sum(y == 1)
  negatives <- sum(y == 0)
  if (positives == 0 || negatives == 0) return(NA_real_)
  ranks <- rank(probs, ties.method = "average")
  (sum(ranks[y == 1]) - positives * (positives + 1) / 2) / (positives * negatives)
}

calibration_metrics <- function(truth, probs) {
  truth <- ensure_factor_outcome(truth)
  y <- as.integer(truth == "Yes")
  clipped <- pmin(pmax(probs, 1e-6), 1 - 1e-6)
  fit <- tryCatch(stats::glm(y ~ qlogis(clipped), family = stats::binomial()), error = function(e) NULL)
  if (is.null(fit)) return(c(calibration_intercept = NA_real_, calibration_slope = NA_real_))
  coefs <- stats::coef(fit)
  c(calibration_intercept = unname(coefs[1]), calibration_slope = if (length(coefs) > 1) unname(coefs[2]) else NA_real_)
}

evaluate_predictions <- function(truth, probs, threshold = 0.50) {
  truth <- ensure_factor_outcome(truth)
  pred <- factor(ifelse(probs >= threshold, "Yes", "No"), levels = c("No", "Yes"))
  tp <- sum(pred == "Yes" & truth == "Yes")
  tn <- sum(pred == "No" & truth == "No")
  fp <- sum(pred == "Yes" & truth == "No")
  fn <- sum(pred == "No" & truth == "Yes")
  calib <- calibration_metrics(truth, probs)
  data.frame(
    pr_auc = binary_pr_auc(truth, probs),
    roc_auc = binary_roc_auc(truth, probs),
    brier_score = mean((as.integer(truth == "Yes") - probs)^2),
    calibration_intercept = calib[["calibration_intercept"]],
    calibration_slope = calib[["calibration_slope"]],
    sensitivity = if ((tp + fn) == 0) NA_real_ else tp / (tp + fn),
    specificity = if ((tn + fp) == 0) NA_real_ else tn / (tn + fp),
    ppv = if ((tp + fp) == 0) NA_real_ else tp / (tp + fp),
    npv = if ((tn + fn) == 0) NA_real_ else tn / (tn + fn),
    threshold = threshold,
    n = length(truth),
    events = sum(truth == "Yes")
  )
}

fbeta_score <- function(ppv, sensitivity, beta = 2) {
  if (is.na(ppv) || is.na(sensitivity) || (ppv + sensitivity) == 0) {
    return(NA_real_)
  }
  beta_sq <- beta^2
  (1 + beta_sq) * ppv * sensitivity / (beta_sq * ppv + sensitivity)
}

top_k_capture_metrics <- function(truth, probs, model_name, dataset, proportions = c(0.05, 0.10, 0.20)) {
  truth <- ensure_factor_outcome(truth)
  baseline_rate <- mean(truth == "Yes")
  ord <- order(probs, decreasing = TRUE)
  truth_ord <- truth[ord]
  rows <- vector("list", length(proportions))

  for (i in seq_along(proportions)) {
    prop <- proportions[i]
    k <- max(1, ceiling(length(truth_ord) * prop))
    selected <- truth_ord[seq_len(k)]
    tp <- sum(selected == "Yes")
    event_rate <- tp / k
    recall <- tp / sum(truth == "Yes")
    rows[[i]] <- data.frame(
      model_name = model_name,
      dataset = dataset,
      top_k = sprintf("top_%s_pct", format(round(prop * 100), trim = TRUE)),
      proportion_flagged = prop,
      n_flagged = k,
      events_captured = tp,
      event_rate = event_rate,
      recall = recall,
      ppv = event_rate,
      lift = ifelse(baseline_rate > 0, event_rate / baseline_rate, NA_real_)
    )
  }

  do.call(rbind, rows)
}

threshold_performance_grid <- function(truth, probs, model_name, dataset, thresholds = seq(0.01, 0.99, by = 0.01)) {
  rows <- vector("list", length(thresholds))
  for (i in seq_along(thresholds)) {
    threshold <- thresholds[i]
    metrics <- evaluate_predictions(truth, probs, threshold = threshold)
    flagged <- mean(probs >= threshold)
    metrics$model_name <- model_name
    metrics$dataset <- dataset
    metrics$rule_name <- "grid"
    metrics$flagged_fraction <- flagged
    metrics$f2_score <- fbeta_score(metrics$ppv, metrics$sensitivity, beta = 2)
    metrics$threshold_rule <- threshold
    rows[[i]] <- metrics[, c("model_name", "dataset", "rule_name", "threshold_rule", "flagged_fraction", "f2_score", names(metrics)[!(names(metrics) %in% c("model_name", "dataset", "rule_name", "threshold_rule", "flagged_fraction", "f2_score"))])]
  }
  do.call(rbind, rows)
}

select_threshold_rules <- function(grid_df, probs, sensitivity_targets = c(0.30, 0.50), topk_props = c(0.10, 0.20)) {
  output <- list()
  ordered <- grid_df[order(-grid_df$f2_score, -grid_df$sensitivity, -grid_df$ppv), ]
  output[[length(output) + 1]] <- data.frame(
    rule_name = "max_f2",
    threshold = ordered$threshold_rule[1],
    flagged_fraction = ordered$flagged_fraction[1]
  )

  for (target in sensitivity_targets) {
    candidates <- grid_df[grid_df$sensitivity >= target, , drop = FALSE]
    if (nrow(candidates) == 0) next
    candidates <- candidates[order(-candidates$threshold_rule, -candidates$ppv), ]
    output[[length(output) + 1]] <- data.frame(
      rule_name = sprintf("target_sensitivity_%s", gsub("\\.", "_", format(target, nsmall = 2))),
      threshold = candidates$threshold_rule[1],
      flagged_fraction = candidates$flagged_fraction[1]
    )
  }

  for (prop in topk_props) {
    threshold <- as.numeric(stats::quantile(probs, probs = max(0, 1 - prop), type = 8, na.rm = TRUE))
    output[[length(output) + 1]] <- data.frame(
      rule_name = sprintf("top_%s_pct", format(round(prop * 100), trim = TRUE)),
      threshold = threshold,
      flagged_fraction = mean(probs >= threshold)
    )
  }

  unique(do.call(rbind, output))
}

apply_threshold_rules <- function(truth, probs, model_name, dataset, threshold_rules) {
  rows <- vector("list", nrow(threshold_rules))
  for (i in seq_len(nrow(threshold_rules))) {
    rule <- threshold_rules[i, , drop = FALSE]
    metrics <- evaluate_predictions(truth, probs, threshold = rule$threshold[1])
    metrics$model_name <- model_name
    metrics$dataset <- dataset
    metrics$rule_name <- rule$rule_name[1]
    metrics$threshold_rule <- rule$threshold[1]
    metrics$flagged_fraction <- mean(probs >= rule$threshold[1])
    metrics$f2_score <- fbeta_score(metrics$ppv, metrics$sensitivity, beta = 2)
    rows[[i]] <- metrics[, c("model_name", "dataset", "rule_name", "threshold_rule", "flagged_fraction", "f2_score", names(metrics)[!(names(metrics) %in% c("model_name", "dataset", "rule_name", "threshold_rule", "flagged_fraction", "f2_score"))])]
  }
  do.call(rbind, rows)
}

compute_case_weights <- function(y) {
  y <- ensure_factor_outcome(y)
  counts <- table(y)
  if (any(counts == 0)) {
    weights <- rep(1, length(y))
    classwt <- as.list(stats::setNames(c(1, 1), c("No", "Yes")))
    return(list(sample_weights = weights, class_weights = classwt))
  }
  ratio <- as.numeric(counts["No"] / counts["Yes"])
  weights <- ifelse(y == "Yes", ratio, 1)
  classwt <- as.list(stats::setNames(c(1, ratio), c("No", "Yes")))
  list(sample_weights = weights, class_weights = classwt)
}

stratified_split <- function(y, p = 0.70, seed = 20260327) {
  set.seed(seed)
  y <- ensure_factor_outcome(y)
  train_idx <- integer()
  for (level in levels(y)) {
    idx <- which(y == level)
    if (length(idx) == 0) next
    n_train <- max(1, floor(length(idx) * p))
    train_idx <- c(train_idx, sample(idx, n_train))
  }
  sort(unique(train_idx))
}

create_stratified_folds <- function(y, k = 5, seed = 20260327) {
  set.seed(seed)
  y <- ensure_factor_outcome(y)
  fold_indices <- vector("list", k)
  for (level in levels(y)) {
    idx <- sample(which(y == level))
    if (length(idx) == 0) next
    assignments <- split(idx, rep(seq_len(k), length.out = length(idx)))
    for (i in seq_len(k)) {
      fold_indices[[i]] <- c(fold_indices[[i]], assignments[[i]])
    }
  }
  lapply(fold_indices, sort)
}

model_grid <- function(model_name, n_features) {
  if (model_name == "elastic_net") {
    return(expand.grid(alpha = c(0, 0.5, 1), lambda = 10^c(-3, -2, -1, 0)))
  }
  if (model_name == "random_forest") {
    return(expand.grid(mtry = unique(pmax(1, pmin(n_features, c(floor(sqrt(n_features)), floor(n_features / 3), floor(n_features / 2)))))))
  }
  if (model_name == "xgboost") {
    return(expand.grid(nrounds = c(100, 200), max_depth = c(2, 4), eta = c(0.05, 0.1), subsample = 0.8, colsample_bytree = 0.8))
  }
  if (model_name == "knn") {
    return(expand.grid(k = c(3, 5, 7, 9, 11, 15)))
  }
  if (model_name == "ann") {
    return(expand.grid(size = c(3, 5, 7), decay = c(0.0001, 0.001, 0.01)))
  }
  stop(sprintf("Unsupported model '%s'", model_name))
}

model_available <- function(model_name) {
  initialize_r_library_paths()
  if (model_name == "elastic_net") return(requireNamespace("glmnet", quietly = TRUE))
  if (model_name == "random_forest") return(requireNamespace("randomForest", quietly = TRUE))
  if (model_name == "xgboost") return(requireNamespace("xgboost", quietly = TRUE))
  if (model_name == "knn") return(requireNamespace("class", quietly = TRUE))
  if (model_name == "ann") return(requireNamespace("nnet", quietly = TRUE))
  FALSE
}

fit_model_object <- function(model_name, x, y, params) {
  initialize_r_library_paths()
  y <- ensure_factor_outcome(y)
  weighting <- if (!is.null(params$use_weights) && isTRUE(params$use_weights)) compute_case_weights(y) else NULL
  if (model_name == "elastic_net") {
    y_num <- as.integer(y == "Yes")
    fit <- glmnet::glmnet(
      x = x,
      y = y_num,
      family = "binomial",
      alpha = params$alpha,
      lambda = params$lambda,
      standardize = FALSE,
      weights = if (is.null(weighting)) NULL else weighting$sample_weights
    )
    return(list(model_name = model_name, fit = fit, params = params))
  }
  if (model_name == "random_forest") {
    fit <- randomForest::randomForest(
      x = x,
      y = y,
      mtry = as.integer(params$mtry),
      ntree = 500,
      classwt = if (is.null(weighting)) NULL else unlist(weighting$class_weights)
    )
    return(list(model_name = model_name, fit = fit, params = params))
  }
  if (model_name == "xgboost") {
    dtrain <- xgboost::xgb.DMatrix(
      data = x,
      label = as.integer(y == "Yes"),
      weight = if (is.null(weighting)) NULL else weighting$sample_weights
    )
    fit <- xgboost::xgb.train(
      params = list(
        objective = "binary:logistic",
        eval_metric = "logloss",
        max_depth = as.integer(params$max_depth),
        eta = as.numeric(params$eta),
        subsample = as.numeric(params$subsample),
        colsample_bytree = as.numeric(params$colsample_bytree)
      ),
      data = dtrain,
      nrounds = as.integer(params$nrounds),
      verbose = 0
    )
    return(list(model_name = model_name, fit = fit, params = params))
  }
  if (model_name == "knn") {
    return(list(model_name = model_name, fit = NULL, params = params, train_x = x, train_y = y))
  }
  if (model_name == "ann") {
    ann_data <- as.data.frame(x, check.names = FALSE)
    ann_data$target <- as.integer(y == "Yes")
    fit <- nnet::nnet(
      target ~ .,
      data = ann_data,
      weights = if (is.null(weighting)) rep(1, length(y)) else weighting$sample_weights,
      size = as.integer(params$size),
      decay = as.numeric(params$decay),
      maxit = 300,
      trace = FALSE,
      linout = FALSE
    )
    return(list(model_name = model_name, fit = fit, params = params))
  }
  stop(sprintf("Unsupported model '%s'", model_name))
}

predict_probabilities <- function(model_object, x) {
  model_name <- model_object$model_name
  probs <- NULL
  if (model_name == "elastic_net") {
    probs <- as.numeric(glmnet:::predict.glmnet(model_object$fit, newx = x, type = "response")[, 1])
  }
  if (model_name == "random_forest") {
    probs <- as.numeric(randomForest:::predict.randomForest(model_object$fit, newdata = x, type = "prob")[, "Yes"])
  }
  if (model_name == "xgboost") {
    probs <- as.numeric(predict(model_object$fit, newdata = xgboost::xgb.DMatrix(x)))
  }
  if (model_name == "knn") {
    pred <- class::knn(train = model_object$train_x, test = x, cl = model_object$train_y, k = as.integer(model_object$params$k), prob = TRUE)
    raw_prob <- attr(pred, "prob")
    probs <- ifelse(pred == "Yes", raw_prob, 1 - raw_prob)
  }
  if (model_name == "ann") {
    probs <- as.numeric(nnet:::predict.nnet(model_object$fit, newdata = as.data.frame(x, check.names = FALSE), type = "raw"))
  }
  if (is.null(probs)) stop(sprintf("Unsupported model '%s'", model_name))
  pmin(pmax(as.numeric(probs), 0), 1)
}

cross_validate_model <- function(model_name, x, y, folds, use_smote = FALSE, use_weights = FALSE) {
  if (!model_available(model_name)) stop(sprintf("Required package for %s is unavailable.", model_name))
  if (use_weights && model_name == "knn") stop("Weighted training is not implemented for knn.")
  grid <- model_grid(model_name, ncol(x))
  results <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    params <- as.list(grid[i, , drop = FALSE])
    params$use_weights <- use_weights
    fold_metrics <- vector("list", length(folds))
    failed <- FALSE
    for (j in seq_along(folds)) {
      val_idx <- folds[[j]]
      train_idx <- setdiff(seq_len(nrow(x)), val_idx)
      x_train_fold <- x[train_idx, , drop = FALSE]
      y_train_fold <- y[train_idx]
      if (use_smote) {
        smote_result <- apply_simple_smote(x_train_fold, y_train_fold, k = 5, seed = 20260327 + i * 100 + j)
        x_train_fold <- smote_result$x
        y_train_fold <- smote_result$y
      }
      fit <- tryCatch(fit_model_object(model_name, x_train_fold, y_train_fold, params), error = function(e) e)
      if (inherits(fit, "error")) {
        failed <- TRUE
        break
      }
      probs <- predict_probabilities(fit, x[val_idx, , drop = FALSE])
      metrics <- evaluate_predictions(y[val_idx], probs)
      fold_metrics[[j]] <- metrics
    }
    if (failed) {
      results[[i]] <- cbind(as.data.frame(grid[i, , drop = FALSE]), mean_pr_auc = NA_real_, mean_roc_auc = NA_real_, mean_brier = NA_real_)
    } else {
      fold_df <- do.call(rbind, fold_metrics)
      results[[i]] <- cbind(
        as.data.frame(grid[i, , drop = FALSE]),
        mean_pr_auc = mean(fold_df$pr_auc, na.rm = TRUE),
        mean_roc_auc = mean(fold_df$roc_auc, na.rm = TRUE),
        mean_brier = mean(fold_df$brier_score, na.rm = TRUE)
      )
    }
  }
  results_df <- do.call(rbind, results)
  results_df <- results_df[order(-results_df$mean_pr_auc, -results_df$mean_roc_auc, results_df$mean_brier), ]
  list(results = results_df, best_params = as.list(results_df[1, setdiff(names(results_df), c("mean_pr_auc", "mean_roc_auc", "mean_brier")), drop = FALSE]))
}
