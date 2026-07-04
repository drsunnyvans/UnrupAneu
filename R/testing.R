source(file.path(find_project_root(), "R", "utils.R"))

check_true <- function(condition, name, details_success, details_failure) {
  data.frame(
    test_name = name,
    status = if (isTRUE(condition)) "PASS" else "FAIL",
    details = if (isTRUE(condition)) details_success else details_failure,
    stringsAsFactors = FALSE
  )
}

run_pipeline_smoke_tests <- function(root) {
  tests <- list()
  dev_path <- file.path(root, "results", "datasets", "development_model_dataset.csv")
  ext_path <- file.path(root, "results", "datasets", "external_model_dataset.csv")
  tests[[length(tests) + 1]] <- check_true(file.exists(dev_path), "development_dataset_exists", "Development dataset exists.", "Development dataset is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(ext_path), "external_dataset_exists", "External dataset exists.", "External dataset is missing.")

  if (file.exists(dev_path) && file.exists(ext_path)) {
    development <- read_csv_config(dev_path)
    external <- read_csv_config(ext_path)
    dev_features <- setdiff(names(development), "severe_outcome")
    ext_features <- setdiff(names(external), "severe_outcome")
    excluded_dev <- c("caseid", "asaclas", "dindo_scores", "optime", "returnor", "cpt_proc1_cpt1")
    tests[[length(tests) + 1]] <- check_true(
      identical(dev_features, ext_features),
      "harmonized_feature_columns_match",
      "Development and external model matrices share the same feature columns.",
      "Development and external feature columns do not match."
    )
    tests[[length(tests) + 1]] <- check_true(
      !any(excluded_dev %in% names(development)),
      "excluded_columns_absent",
      "Excluded identifier, ASA, post-op, and CPT fields are absent from the development model dataset.",
      "One or more excluded fields are still present in the development model dataset."
    )
    tests[[length(tests) + 1]] <- check_true(
      all(unique(development$severe_outcome) %in% c("No", "Yes")) && all(unique(external$severe_outcome) %in% c("No", "Yes")),
      "outcome_is_binary_yes_no",
      "Development and external outcomes are encoded as No/Yes.",
      "Outcome encoding is not limited to No/Yes."
    )
  }

  training_status_path <- file.path(root, "results", "metrics", "training_status.csv")
  training_status_smote_path <- file.path(root, "results", "metrics", "training_status_smote.csv")
  training_status_weighted_path <- file.path(root, "results", "metrics", "training_status_weighted.csv")
  tests[[length(tests) + 1]] <- check_true(file.exists(training_status_path), "training_status_exists", "Training status file exists.", "Training status file is missing.")
  if (file.exists(training_status_path)) {
    training_status <- read_csv_config(training_status_path)
    tests[[length(tests) + 1]] <- check_true(
      any(training_status$status == "trained"),
      "at_least_one_model_trained",
      "At least one benchmark model trained successfully.",
      "No benchmark models trained successfully."
    )
  }
  tests[[length(tests) + 1]] <- check_true(file.exists(training_status_smote_path), "training_status_smote_exists", "SMOTE training status file exists.", "SMOTE training status file is missing.")
  if (file.exists(training_status_smote_path)) {
    training_status_smote <- read_csv_config(training_status_smote_path)
    tests[[length(tests) + 1]] <- check_true(
      any(training_status_smote$status == "trained"),
      "at_least_one_smote_model_trained",
      "At least one SMOTE benchmark model trained successfully.",
      "No SMOTE benchmark models trained successfully."
    )
  }
  tests[[length(tests) + 1]] <- check_true(file.exists(training_status_weighted_path), "training_status_weighted_exists", "Weighted training status file exists.", "Weighted training status file is missing.")
  if (file.exists(training_status_weighted_path)) {
    training_status_weighted <- read_csv_config(training_status_weighted_path)
    tests[[length(tests) + 1]] <- check_true(
      any(training_status_weighted$status == "trained"),
      "at_least_one_weighted_model_trained",
      "At least one weighted benchmark model trained successfully.",
      "No weighted benchmark models trained successfully."
    )
  }

  selection_path <- file.path(root, "results", "metrics", "model_selection.csv")
  selection_smote_path <- file.path(root, "results", "metrics", "model_selection_smote.csv")
  selection_weighted_path <- file.path(root, "results", "metrics", "model_selection_weighted.csv")
  external_metrics_path <- file.path(root, "results", "metrics", "external_validation_metrics.csv")
  external_metrics_smote_path <- file.path(root, "results", "metrics", "external_validation_metrics_smote.csv")
  external_metrics_weighted_path <- file.path(root, "results", "metrics", "external_validation_metrics_weighted.csv")
  tests[[length(tests) + 1]] <- check_true(file.exists(selection_path), "model_selection_exists", "Model selection file exists.", "Model selection file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(external_metrics_path), "external_metrics_exist", "External metrics file exists.", "External metrics file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(selection_smote_path), "model_selection_smote_exists", "SMOTE model selection file exists.", "SMOTE model selection file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(external_metrics_smote_path), "external_metrics_smote_exist", "SMOTE external metrics file exists.", "SMOTE external metrics file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(selection_weighted_path), "model_selection_weighted_exists", "Weighted model selection file exists.", "Weighted model selection file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(external_metrics_weighted_path), "external_metrics_weighted_exist", "Weighted external metrics file exists.", "Weighted external metrics file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(file.path(root, "results", "metrics", "ensemble_model_selection.csv")), "ensemble_selection_exists", "Ensemble model selection file exists.", "Ensemble model selection file is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(file.path(root, "results", "metrics", "ensemble_external_validation_metrics.csv")), "ensemble_external_metrics_exist", "Ensemble external metrics file exists.", "Ensemble external metrics file is missing.")

  high_risk_files <- c(
    internal_topk = file.path(root, "results", "metrics", "internal_test_topk_metrics.csv"),
    internal_thresholds = file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics.csv"),
    external_topk = file.path(root, "results", "metrics", "external_validation_topk_metrics.csv"),
    external_thresholds = file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics.csv"),
    internal_topk_smote = file.path(root, "results", "metrics", "internal_test_topk_metrics_smote.csv"),
    internal_thresholds_smote = file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics_smote.csv"),
    external_topk_smote = file.path(root, "results", "metrics", "external_validation_topk_metrics_smote.csv"),
    external_thresholds_smote = file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics_smote.csv"),
    internal_topk_weighted = file.path(root, "results", "metrics", "internal_test_topk_metrics_weighted.csv"),
    internal_thresholds_weighted = file.path(root, "results", "metrics", "internal_test_threshold_rule_metrics_weighted.csv"),
    external_topk_weighted = file.path(root, "results", "metrics", "external_validation_topk_metrics_weighted.csv"),
    external_thresholds_weighted = file.path(root, "results", "metrics", "external_validation_threshold_rule_metrics_weighted.csv")
  )
  for (name in names(high_risk_files)) {
    tests[[length(tests) + 1]] <- check_true(
      file.exists(high_risk_files[[name]]),
      paste0(name, "_exists"),
      sprintf("%s exists.", name),
      sprintf("%s is missing.", name)
    )
  }
  ensemble_files <- c(
    ensemble_oof = file.path(root, "results", "metrics", "ensemble_oof_train_predictions.csv"),
    ensemble_internal_topk = file.path(root, "results", "metrics", "ensemble_internal_topk_metrics.csv"),
    ensemble_internal_thresholds = file.path(root, "results", "metrics", "ensemble_internal_threshold_rule_metrics.csv"),
    ensemble_external_topk = file.path(root, "results", "metrics", "ensemble_external_topk_metrics.csv"),
    ensemble_external_thresholds = file.path(root, "results", "metrics", "ensemble_external_threshold_rule_metrics.csv")
  )
  for (name in names(ensemble_files)) {
    tests[[length(tests) + 1]] <- check_true(
      file.exists(ensemble_files[[name]]),
      paste0(name, "_exists"),
      sprintf("%s exists.", name),
      sprintf("%s is missing.", name)
    )
  }
  publication_files <- c(
    publication_internal_table = file.path(root, "results", "metrics", "publication_internal_model_comparison.csv"),
    publication_external_table = file.path(root, "results", "metrics", "publication_external_model_comparison.csv"),
    publication_internal_original_roc = file.path(root, "results", "figures", "publication_internal_original_roc.png"),
    publication_internal_smote_roc = file.path(root, "results", "figures", "publication_internal_smote_roc.png"),
    publication_internal_weighted_roc = file.path(root, "results", "figures", "publication_internal_weighted_roc.png"),
    publication_external_original_roc = file.path(root, "results", "figures", "publication_external_original_roc.png"),
    publication_external_smote_roc = file.path(root, "results", "figures", "publication_external_smote_roc.png"),
    publication_external_weighted_roc = file.path(root, "results", "figures", "publication_external_weighted_roc.png")
  )
  for (name in names(publication_files)) {
    tests[[length(tests) + 1]] <- check_true(
      file.exists(publication_files[[name]]),
      paste0(name, "_exists"),
      sprintf("%s exists.", name),
      sprintf("%s is missing.", name)
    )
  }

  shap_summary_path <- file.path(root, "results", "metrics", "primary_model_external_shap_summary.csv")
  shap_summary_smote_path <- file.path(root, "results", "metrics", "primary_model_smote_external_shap_summary.csv")
  shap_summary_weighted_path <- file.path(root, "results", "metrics", "primary_model_weighted_external_shap_summary.csv")
  tests[[length(tests) + 1]] <- check_true(file.exists(shap_summary_path), "shap_summary_exists", "Primary-model SHAP summary exists.", "Primary-model SHAP summary is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(shap_summary_smote_path), "shap_summary_smote_exists", "Primary SMOTE-model SHAP summary exists.", "Primary SMOTE-model SHAP summary is missing.")
  tests[[length(tests) + 1]] <- check_true(file.exists(shap_summary_weighted_path), "shap_summary_weighted_exists", "Primary weighted-model SHAP summary exists.", "Primary weighted-model SHAP summary is missing.")

  results <- do.call(rbind, tests)
  utils::write.csv(results, file.path(root, "results", "metrics", "pipeline_smoke_tests.csv"), row.names = FALSE, na = "")
  append_project_log(
    root,
    "Smoke Tests",
    c(
      sprintf("- Smoke tests run: %s", nrow(results)),
      sprintf("- Passed: %s", sum(results$status == "PASS")),
      sprintf("- Failed: %s", sum(results$status == "FAIL"))
    )
  )
  results
}
