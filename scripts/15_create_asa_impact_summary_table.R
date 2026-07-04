root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))

publication_dir <- file.path(root, "publication_summary", "tables")
dir.create(publication_dir, recursive = TRUE, showWarnings = FALSE)

base <- read_csv_config(file.path(root, "publication_summary", "tables", "publication_key_results_table.csv"))
asa <- read_csv_config(file.path(root, "publication_summary", "tables", "publication_asa_sensitivity_summary.csv"))

pick_row <- function(df, arm, model) {
  row <- df[df$arm == arm & df$model == model, , drop = FALSE]
  if (nrow(row) == 0) return(NULL)
  row[1, , drop = FALSE]
}

make_delta <- function(new, old) round(as.numeric(new) - as.numeric(old), 3)

rows <- list()

comparisons <- list(
  list(label = "Original XGBoost", base_arm = "Original", base_model = "XGBoost", asa_arm = "ASA Original", asa_model = "XGBoost"),
  list(label = "SMOTE XGBoost", base_arm = "SMOTE", base_model = "XGBoost", asa_arm = "ASA SMOTE", asa_model = "XGBoost"),
  list(label = "Weighted XGBoost", base_arm = "Weighted", base_model = "XGBoost", asa_arm = "ASA Weighted", asa_model = "XGBoost"),
  list(label = "Weighted ANN", base_arm = "Weighted", base_model = "ANN", asa_arm = "ASA Weighted", asa_model = "ANN")
)

for (cmp in comparisons) {
  b <- pick_row(base, cmp$base_arm, cmp$base_model)
  a <- pick_row(asa, cmp$asa_arm, cmp$asa_model)
  if (is.null(b) || is.null(a)) next
  rows[[length(rows) + 1]] <- data.frame(
    comparison = cmp$label,
    baseline_internal_pr_auc = round(as.numeric(b$internal_pr_auc), 3),
    asa_internal_pr_auc = round(as.numeric(a$internal_pr_auc), 3),
    delta_internal_pr_auc = make_delta(a$internal_pr_auc, b$internal_pr_auc),
    baseline_external_pr_auc = round(as.numeric(b$external_pr_auc), 3),
    asa_external_pr_auc = round(as.numeric(a$external_pr_auc), 3),
    delta_external_pr_auc = make_delta(a$external_pr_auc, b$external_pr_auc),
    baseline_external_roc_auc = round(as.numeric(b$external_roc_auc), 3),
    asa_external_roc_auc = round(as.numeric(a$external_roc_auc), 3),
    delta_external_roc_auc = make_delta(a$external_roc_auc, b$external_roc_auc),
    interpretation = "",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

summary_df <- do.call(rbind, rows)
summary_df$interpretation[summary_df$comparison == "Original XGBoost"] <- "ASA improved both internal and external XGBoost performance in the original arm."
summary_df$interpretation[summary_df$comparison == "SMOTE XGBoost"] <- "ASA produced little meaningful change in the SMOTE XGBoost arm."
summary_df$interpretation[summary_df$comparison == "Weighted XGBoost"] <- "ASA improved external ROC AUC but slightly reduced external PR AUC for weighted XGBoost."
summary_df$interpretation[summary_df$comparison == "Weighted ANN"] <- "ASA substantially improved the weighted ANN and yielded the best external PR AUC among the ASA models."

utils::write.csv(summary_df, file.path(publication_dir, "publication_asa_impact_summary.csv"), row.names = FALSE, na = "")
cat("ASA impact summary table created.\n")
