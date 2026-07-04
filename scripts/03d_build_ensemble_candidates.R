root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "ensemble.R"))

split_obj <- readRDS(file.path(root, "results", "datasets", "internal_split.rds"))
train_data <- split_obj$train_data
folds <- create_stratified_folds(ensure_factor_outcome(train_data$severe_outcome), k = 5, seed = 20260327)
components <- get_ensemble_components()

oof_parts <- list()
test_parts <- list()
external_parts <- list()
for (i in seq_len(nrow(components))) {
  component_id <- components$component_id[i]
  artifacts <- get_component_artifacts(root, component_id)
  oof_parts[[length(oof_parts) + 1]] <- generate_component_oof_predictions(component_id, train_data, folds, root)
  test_parts[[length(test_parts) + 1]] <- read_component_prediction_file(artifacts$internal_predictions, artifacts$model_name, component_id)
  external_parts[[length(external_parts) + 1]] <- read_component_prediction_file(artifacts$external_predictions, artifacts$model_name, component_id)
}

oof_stack <- merge_component_predictions(oof_parts)
internal_test_stack <- merge_component_predictions(test_parts)
external_stack <- merge_component_predictions(external_parts)

utils::write.csv(oof_stack, file.path(root, "results", "metrics", "ensemble_oof_train_predictions.csv"), row.names = FALSE, na = "")
utils::write.csv(internal_test_stack, file.path(root, "results", "metrics", "ensemble_internal_test_predictions.csv"), row.names = FALSE, na = "")
utils::write.csv(external_stack, file.path(root, "results", "metrics", "ensemble_external_predictions.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "03d Build Ensemble Candidates",
  c(
    sprintf("- Ensemble components: %s", paste(components$component_id, collapse = ", ")),
    sprintf("- OOF training rows generated for ensemble stacking: %s", nrow(oof_stack)),
    sprintf("- Internal test prediction rows prepared for ensemble evaluation: %s", nrow(internal_test_stack)),
    sprintf("- External prediction rows prepared for ensemble evaluation: %s", nrow(external_stack))
  )
)
