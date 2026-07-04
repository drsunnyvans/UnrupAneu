source(file.path(find_project_root(), "R", "utils.R"))
source(file.path(find_project_root(), "R", "modeling.R"))
source(file.path(find_project_root(), "R", "ensemble.R"))

calculator_field_spec <- function() {
  data.frame(
    field = c(
      "age", "sex", "race", "admission_source", "elective_surgery", "functional_status",
      "diabetes", "smoking", "dyspnea", "copd", "heart_failure", "dialysis",
      "active_malignancy", "coagulopathy", "bmi", "sodium", "bun", "creatinine",
      "albumin", "bilirubin", "ast", "alk_phos", "wbc", "platelets", "ptt", "inr"
    ),
    label = c(
      "Age (years)", "Sex", "Race", "Admission source", "Elective surgery",
      "Functional status", "Diabetes", "Current smoking", "Dyspnea", "COPD",
      "History of heart failure", "Dialysis dependence", "Active malignancy",
      "Coagulopathy or bleeding disorder", "Body mass index (kg/m^2)", "Sodium",
      "BUN", "Creatinine", "Albumin", "Bilirubin", "AST", "Alkaline phosphatase",
      "White blood cell count", "Platelet count", "PTT", "INR"
    ),
    field_type = c(
      rep("numeric", 1), rep("categorical", 13), rep("numeric", 12)
    ),
    section = c(
      "Demographics and Admission", "Demographics and Admission", "Demographics and Admission",
      "Demographics and Admission", "Demographics and Admission", "Demographics and Admission",
      "Comorbidities", "Comorbidities", "Comorbidities", "Comorbidities", "Comorbidities",
      "Comorbidities", "Comorbidities", "Comorbidities",
      "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs",
      "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs",
      "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs", "Pre-operative Labs"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

calculator_choice_map <- function() {
  choice_vector <- function(values, labels = values) {
    stats::setNames(values, labels)
  }
  list(
    sex = choice_vector(c("", "Female", "Male"), c("Unknown / unavailable", "Female", "Male")),
    race = choice_vector(c("", "White", "Black", "Asian", "Hispanic", "Other", "Unknown"), c("Unknown / unavailable", "White", "Black", "Asian", "Hispanic", "Other", "Unknown")),
    admission_source = choice_vector(c("", "Home", "Emergency Department", "Transfer", "Other"), c("Unknown / unavailable", "Home", "Emergency Department", "Transfer", "Other")),
    elective_surgery = choice_vector(c("", "Yes", "No"), c("Unknown / unavailable", "Yes", "No")),
    functional_status = choice_vector(c("", "Independent", "Partially dependent", "Totally dependent"), c("Unknown / unavailable", "Independent", "Partially dependent", "Totally dependent")),
    diabetes = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    smoking = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    dyspnea = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    copd = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    heart_failure = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    dialysis = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    active_malignancy = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes")),
    coagulopathy = choice_vector(c("", "No", "Yes"), c("Unknown / unavailable", "No", "Yes"))
  )
}

calculator_numeric_defaults <- function(bundle) {
  defaults <- bundle$preprocessor$medians
  defaults[intersect(names(defaults), c("age", "bmi", "sodium", "bun", "creatinine", "albumin", "bilirubin", "ast", "alk_phos", "wbc", "platelets", "ptt", "inr"))]
}

load_weighted_calculator_bundle <- function(root = find_project_root()) {
  initialize_r_library_paths()
  ensure_packages(c("xgboost"))

  model <- readRDS(file.path(root, "results", "models", "xgboost_weighted_final_full.rds"))
  preprocessor <- readRDS(file.path(root, "results", "models", "full_preprocessor_weighted.rds"))

  selection <- read_csv_config(file.path(root, "results", "metrics", "model_selection_weighted.csv"))
  external_metrics <- read_csv_config(file.path(root, "results", "metrics", "external_validation_metrics_weighted.csv"))
  threshold_defs <- read_csv_config(file.path(root, "results", "metrics", "internal_test_selected_thresholds_weighted.csv"))
  threshold_defs <- threshold_defs[threshold_defs$model_name == "xgboost", , drop = FALSE]

  development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
  x_development <- apply_preprocessor(development, preprocessor, outcome_col = "severe_outcome")
  development_probs <- predict_probabilities(model, x_development)

  thresholds <- stats::setNames(threshold_defs$threshold, threshold_defs$rule_name)
  development_summary <- list(
    n = nrow(development),
    events = sum(ensure_factor_outcome(development$severe_outcome) == "Yes"),
    event_rate = mean(ensure_factor_outcome(development$severe_outcome) == "Yes"),
    median_probability = stats::median(development_probs),
    q75_probability = stats::quantile(development_probs, 0.75, names = FALSE),
    q90_probability = stats::quantile(development_probs, 0.90, names = FALSE),
    q95_probability = stats::quantile(development_probs, 0.95, names = FALSE)
  )

  list(
    root = root,
    model = model,
    preprocessor = preprocessor,
    thresholds = thresholds,
    threshold_definitions = threshold_defs,
    development_probabilities = development_probs,
    development_summary = development_summary,
    weighted_selection = selection,
    weighted_external_metrics = external_metrics[external_metrics$model_name == "xgboost", , drop = FALSE],
    field_spec = calculator_field_spec(),
    choice_map = calculator_choice_map(),
    numeric_defaults = calculator_numeric_defaults(list(preprocessor = preprocessor))
  )
}

empty_string_to_na <- function(x) {
  if (length(x) == 0) return(NA_character_)
  x <- trimws(as.character(x))
  ifelse(x == "", NA_character_, x)
}

coerce_calculator_numeric <- function(x) {
  x <- empty_string_to_na(x)
  suppressWarnings(as.numeric(x))
}

coerce_calculator_row <- function(input_values, bundle) {
  fields <- bundle$field_spec$field
  row <- vector("list", length(fields))
  names(row) <- fields
  for (field in fields) {
    value <- input_values[[field]]
    if (field %in% c("age", "bmi", "sodium", "bun", "creatinine", "albumin", "bilirubin", "ast", "alk_phos", "wbc", "platelets", "ptt", "inr")) {
      row[[field]] <- coerce_calculator_numeric(value)
    } else {
      row[[field]] <- empty_string_to_na(value)
    }
  }
  as.data.frame(row, stringsAsFactors = FALSE, check.names = FALSE)
}

calculator_missing_count <- function(raw_row) {
  sum(vapply(raw_row, function(x) length(x) == 0 || all(is.na(x) | trimws(as.character(x)) == ""), logical(1)))
}

calculate_weighted_xgboost_risk <- function(input_values, bundle) {
  raw_row <- coerce_calculator_row(input_values, bundle)
  missing_count <- calculator_missing_count(raw_row)
  processed <- apply_preprocessor(raw_row, bundle$preprocessor, outcome_col = "severe_outcome")
  probability <- predict_probabilities(bundle$model, processed)[1]

  percentile <- mean(bundle$development_probabilities <= probability) * 100
  top10_threshold <- unname(bundle$thresholds["top_10_pct"])
  top20_threshold <- unname(bundle$thresholds["top_20_pct"])
  recall_threshold <- unname(bundle$thresholds["target_sensitivity_0_30"])

  risk_bucket <- if (is.finite(top10_threshold) && probability >= top10_threshold) {
    "At or above the model's top-10% development-cohort risk threshold"
  } else if (is.finite(top20_threshold) && probability >= top20_threshold) {
    "At or above the model's top-20% development-cohort risk threshold"
  } else {
    "Below the model's top-20% development-cohort risk threshold"
  }

  threshold_table <- data.frame(
    rule = c("Top 10% review threshold", "Top 20% review threshold", "Recall-oriented threshold"),
    threshold = c(top10_threshold, top20_threshold, recall_threshold),
    exceeds = c(probability >= top10_threshold, probability >= top20_threshold, probability >= recall_threshold),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  list(
    probability = probability,
    percentile = percentile,
    missing_count = missing_count,
    risk_bucket = risk_bucket,
    threshold_table = threshold_table,
    recall_rule_flag = isTRUE(probability >= recall_threshold)
  )
}

format_pct <- function(x, digits = 1) {
  sprintf(paste0("%.", digits, "f%%"), 100 * x)
}

component_full_preprocessor_path <- function(root, arm) {
  if (arm == "original") return(file.path(root, "results", "models", "full_preprocessor.rds"))
  if (arm == "smote") return(file.path(root, "results", "models", "full_preprocessor_smote.rds"))
  if (arm == "weighted") return(file.path(root, "results", "models", "full_preprocessor_weighted.rds"))
  stop(sprintf("Unsupported arm '%s' for calculator preprocessor.", arm))
}

load_stacked_ensemble_calculator_bundle <- function(root = find_project_root()) {
  initialize_r_library_paths()
  ensure_packages(c("xgboost", "nnet"))

  component_table <- get_ensemble_components()
  component_ids <- component_table$component_id
  component_models <- vector("list", length(component_ids))
  names(component_models) <- component_ids

  for (component_id in component_ids) {
    artifacts <- get_component_artifacts(root, component_id)
    component_models[[component_id]] <- list(
      component_id = component_id,
      arm = artifacts$arm,
      model_name = artifacts$model_name,
      model = readRDS(artifacts$final_full),
      preprocessor = readRDS(component_full_preprocessor_path(root, artifacts$arm))
    )
  }

  ensemble_fit <- readRDS(file.path(root, "results", "models", "ensemble_stacked_logistic.rds"))
  threshold_defs <- read_csv_config(file.path(root, "results", "metrics", "ensemble_internal_selected_thresholds.csv"))
  threshold_defs <- threshold_defs[threshold_defs$model_name == "stacked_logistic", , drop = FALSE]
  internal_metrics <- read_csv_config(file.path(root, "results", "metrics", "ensemble_internal_test_metrics.csv"))
  internal_metrics <- internal_metrics[internal_metrics$model_name == "stacked_logistic", , drop = FALSE]
  external_metrics <- read_csv_config(file.path(root, "results", "metrics", "ensemble_external_validation_metrics.csv"))
  external_metrics <- external_metrics[external_metrics$model_name == "stacked_logistic", , drop = FALSE]
  selection <- read_csv_config(file.path(root, "results", "metrics", "ensemble_model_selection.csv"))

  development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
  component_predictions <- vector("list", length(component_ids))
  names(component_predictions) <- component_ids
  for (component_id in component_ids) {
    model_bundle <- component_models[[component_id]]
    x_dev <- apply_preprocessor(development, model_bundle$preprocessor, outcome_col = "severe_outcome")
    component_predictions[[component_id]] <- predict_probabilities(model_bundle$model, x_dev)
  }
  stack_dev <- as.data.frame(component_predictions, check.names = FALSE, stringsAsFactors = FALSE)
  development_probs <- predict_stacked_logistic(ensemble_fit, stack_dev, component_ids)

  thresholds <- stats::setNames(threshold_defs$threshold, threshold_defs$rule_name)
  development_summary <- list(
    n = nrow(development),
    events = sum(ensure_factor_outcome(development$severe_outcome) == "Yes"),
    event_rate = mean(ensure_factor_outcome(development$severe_outcome) == "Yes"),
    median_probability = stats::median(development_probs),
    q75_probability = stats::quantile(development_probs, 0.75, names = FALSE),
    q90_probability = stats::quantile(development_probs, 0.90, names = FALSE),
    q95_probability = stats::quantile(development_probs, 0.95, names = FALSE)
  )

  reference_preprocessor <- component_models[["original_xgboost"]]$preprocessor

  list(
    root = root,
    ensemble_fit = ensemble_fit,
    component_models = component_models,
    component_ids = component_ids,
    preprocessor = reference_preprocessor,
    thresholds = thresholds,
    threshold_definitions = threshold_defs,
    development_probabilities = development_probs,
    development_summary = development_summary,
    ensemble_selection = selection,
    ensemble_internal_metrics = internal_metrics,
    ensemble_external_metrics = external_metrics,
    field_spec = calculator_field_spec(),
    choice_map = calculator_choice_map(),
    numeric_defaults = calculator_numeric_defaults(list(preprocessor = reference_preprocessor))
  )
}

calculate_stacked_ensemble_risk <- function(input_values, bundle) {
  raw_row <- coerce_calculator_row(input_values, bundle)
  missing_count <- calculator_missing_count(raw_row)

  component_probs <- lapply(bundle$component_ids, function(component_id) {
    model_bundle <- bundle$component_models[[component_id]]
    processed <- apply_preprocessor(raw_row, model_bundle$preprocessor, outcome_col = "severe_outcome")
    predict_probabilities(model_bundle$model, processed)[1]
  })
  names(component_probs) <- bundle$component_ids
  stack_row <- as.data.frame(component_probs, check.names = FALSE, stringsAsFactors = FALSE)
  probability <- predict_stacked_logistic(bundle$ensemble_fit, stack_row, bundle$component_ids)[1]

  percentile <- mean(bundle$development_probabilities <= probability) * 100
  top10_threshold <- unname(bundle$thresholds["top_10_pct"])
  top20_threshold <- unname(bundle$thresholds["top_20_pct"])
  recall_threshold <- unname(bundle$thresholds["target_sensitivity_0_30"])

  risk_bucket <- if (is.finite(top10_threshold) && probability >= top10_threshold) {
    "At or above the ensemble's top-10% development-cohort risk threshold"
  } else if (is.finite(top20_threshold) && probability >= top20_threshold) {
    "At or above the ensemble's top-20% development-cohort risk threshold"
  } else {
    "Below the ensemble's top-20% development-cohort risk threshold"
  }

  threshold_table <- data.frame(
    rule = c("Top 10% review threshold", "Top 20% review threshold", "Recall-oriented threshold"),
    threshold = c(top10_threshold, top20_threshold, recall_threshold),
    exceeds = c(probability >= top10_threshold, probability >= top20_threshold, probability >= recall_threshold),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  component_table <- data.frame(
    component = c("Original XGBoost", "SMOTE ANN", "Weighted XGBoost"),
    predicted_probability = unname(unlist(component_probs[c("original_xgboost", "smote_ann", "weighted_xgboost")])),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  list(
    probability = probability,
    percentile = percentile,
    missing_count = missing_count,
    risk_bucket = risk_bucket,
    threshold_table = threshold_table,
    recall_rule_flag = isTRUE(probability >= recall_threshold),
    component_table = component_table
  )
}
