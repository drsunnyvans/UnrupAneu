root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "modeling.R"))
source(file.path(root, "R", "explainability.R"))

selection <- read_csv_config(file.path(root, "results", "metrics", "model_selection.csv"))
primary_model <- selection$primary_model[1]

external <- read_csv_config(file.path(root, "results", "datasets", "external_model_dataset.csv"))
development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
external_features <- external[, setdiff(names(external), "severe_outcome"), drop = FALSE]
background_features <- development[, setdiff(names(development), "severe_outcome"), drop = FALSE]

preprocessor <- readRDS(file.path(root, "results", "models", "full_preprocessor.rds"))
model_object <- readRDS(file.path(root, "results", "models", sprintf("%s_final_full.rds", primary_model)))

shap_matrix <- approximate_shap_values(
  model_object = model_object,
  preprocessor = preprocessor,
  background_data = background_features,
  explain_data = external_features,
  nsim = 25,
  seed = 20260327
)

shap_values <- as.data.frame(shap_matrix, check.names = FALSE)
shap_values$external_row <- seq_len(nrow(shap_values))
summary_df <- summarize_shap_values(shap_matrix)

utils::write.csv(shap_values, file.path(root, "results", "metrics", "primary_model_external_shap_values.csv"), row.names = FALSE, na = "")
utils::write.csv(summary_df, file.path(root, "results", "metrics", "primary_model_external_shap_summary.csv"), row.names = FALSE, na = "")
save_shap_plots(shap_matrix, summary_df, file.path(root, "results", "figures", "primary_model_external_shap"))

append_project_log(
  root,
  "05b Generate SHAP Explanations",
  c(
    sprintf("- Primary model explained: `%s`", primary_model),
    sprintf("- External observations explained: %s", nrow(external_features)),
    sprintf("- SHAP features summarized: %s", ncol(shap_matrix))
  )
)
