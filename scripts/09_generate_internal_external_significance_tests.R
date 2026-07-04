source(file.path(getwd(), "R", "utils.R"))

root <- find_project_root()
publication_tables_dir <- file.path(root, "publication_summary", "tables")
dir.create(publication_tables_dir, recursive = TRUE, showWarnings = FALSE)

mapping <- load_feature_mapping(root)
development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
external <- read_csv_config(file.path(root, "results", "datasets", "external_model_dataset.csv"))

publication_label_map <- c(
  age = "Age, years",
  sex = "Sex",
  race = "Race",
  admission_source = "Admission source",
  elective_surgery = "Elective surgery",
  functional_status = "Functional status",
  diabetes = "Diabetes",
  smoking = "Current smoking",
  dyspnea = "Dyspnea",
  copd = "Chronic obstructive pulmonary disease",
  heart_failure = "Heart failure",
  dialysis = "Dialysis dependence",
  active_malignancy = "Active malignancy",
  coagulopathy = "Coagulopathy / bleeding disorder",
  bmi = "Body mass index, kg/m^2",
  sodium = "Sodium",
  bun = "Blood urea nitrogen",
  creatinine = "Creatinine",
  albumin = "Albumin",
  bilirubin = "Bilirubin",
  ast = "AST",
  alk_phos = "Alkaline phosphatase",
  wbc = "White blood cell count",
  platelets = "Platelet count",
  ptt = "PTT",
  inr = "INR"
)

format_p_value <- function(p) {
  if (!is.finite(p) || is.na(p)) return(NA_character_)
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

safe_chisq <- function(x, y) {
  tab <- table(x, y)
  if (nrow(tab) < 2 || ncol(tab) < 2) {
    return(list(
      test = "Chi-square",
      statistic = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      note = "Insufficient category variation for chi-square test."
    ))
  }

  result <- tryCatch(
    suppressWarnings(chisq.test(tab)),
    error = function(e) e
  )

  if (inherits(result, "error")) {
    sim <- suppressWarnings(chisq.test(tab, simulate.p.value = TRUE, B = 10000))
    return(list(
      test = "Chi-square (simulated p-value)",
      statistic = unname(sim$statistic),
      df = NA_real_,
      p_value = sim$p.value,
      note = "Simulated p-value used because asymptotic chi-square test failed."
    ))
  }

  expected_small <- any(result$expected < 5)
  list(
    test = "Chi-square",
    statistic = unname(result$statistic),
    df = unname(result$parameter),
    p_value = result$p.value,
    note = if (expected_small) "At least one expected cell count was <5; interpret cautiously." else ""
  )
}

safe_anova <- function(values, cohort) {
  fit <- tryCatch(stats::aov(values ~ cohort), error = function(e) e)
  if (inherits(fit, "error")) {
    return(list(
      test = "One-way ANOVA",
      statistic = NA_real_,
      df = NA_real_,
      p_value = NA_real_,
      note = "ANOVA failed."
    ))
  }
  aov_summary <- summary(fit)[[1]]
  list(
    test = "One-way ANOVA",
    statistic = unname(aov_summary[1, "F value"]),
    df = paste0(unname(aov_summary[1, "Df"]), ", ", unname(aov_summary[2, "Df"])),
    p_value = unname(aov_summary[1, "Pr(>F)"]),
    note = ""
  )
}

modeled <- mapping[mapping$include_in_model, , drop = FALSE]
results <- vector("list", nrow(modeled))

for (i in seq_len(nrow(modeled))) {
  field <- modeled$canonical_name[i]
  label <- publication_label_map[[field]]
  if (is.null(label) || !nzchar(label)) label <- field

  dev_col <- development[[field]]
  ext_col <- external[[field]]
  feature_type <- modeled$feature_type[i]

  if (feature_type == "numeric") {
    dev_num <- suppressWarnings(as.numeric(dev_col))
    ext_num <- suppressWarnings(as.numeric(ext_col))
    combined <- data.frame(
      value = c(dev_num, ext_num),
      cohort = factor(c(rep("Development", length(dev_num)), rep("External", length(ext_num))), levels = c("Development", "External"))
    )
    combined <- combined[is.finite(combined$value), , drop = FALSE]
    anova_result <- safe_anova(combined$value, combined$cohort)

    results[[i]] <- data.frame(
      variable = field,
      publication_label = label,
      feature_type = feature_type,
      test_used = anova_result$test,
      development_nonmissing_n = sum(is.finite(dev_num)),
      external_nonmissing_n = sum(is.finite(ext_num)),
      statistic = anova_result$statistic,
      degrees_freedom = as.character(anova_result$df),
      p_value = anova_result$p_value,
      p_value_display = format_p_value(anova_result$p_value),
      note = anova_result$note,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    next
  }

  dev_cat <- normalize_missing_strings(dev_col)
  ext_cat <- normalize_missing_strings(ext_col)
  combined_values <- c(dev_cat, ext_cat)
  combined_cohort <- factor(
    c(rep("Development", length(dev_cat)), rep("External", length(ext_cat))),
    levels = c("Development", "External")
  )
  keep <- !is.na(combined_values)
  chisq_result <- safe_chisq(combined_values[keep], combined_cohort[keep])

  results[[i]] <- data.frame(
    variable = field,
    publication_label = label,
    feature_type = feature_type,
    test_used = chisq_result$test,
    development_nonmissing_n = sum(!is.na(dev_cat)),
    external_nonmissing_n = sum(!is.na(ext_cat)),
    statistic = chisq_result$statistic,
    degrees_freedom = as.character(chisq_result$df),
    p_value = chisq_result$p_value,
    p_value_display = format_p_value(chisq_result$p_value),
    note = chisq_result$note,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

results_df <- do.call(rbind, results)
results_df$p_value_fdr <- stats::p.adjust(results_df$p_value, method = "fdr")
results_df$p_value_fdr_display <- vapply(results_df$p_value_fdr, format_p_value, character(1))

utils::write.csv(
  results_df,
  file.path(publication_tables_dir, "publication_internal_vs_external_significance_tests.csv"),
  row.names = FALSE,
  na = ""
)

append_project_log(
  root,
  "09 Generate Internal vs External Significance Tests",
  c(
    "- Generated simple cohort-comparison tests across harmonized modeled variables.",
    "- Used one-way ANOVA for numeric variables and chi-square tests for categorical variables.",
    "- Added both raw and FDR-adjusted p-values to the publication table."
  )
)

cat("Internal vs external significance tests generated.\n")
