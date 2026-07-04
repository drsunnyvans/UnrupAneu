source(file.path(getwd(), "R", "utils.R"))
source(file.path(getwd(), "R", "data_prep.R"))

root <- find_project_root()
publication_tables_dir <- file.path(root, "publication_summary", "tables")
dir.create(publication_tables_dir, recursive = TRUE, showWarnings = FALSE)

external_raw <- read.csv(file.path(root, "..", "External_testing.csv"), check.names = FALSE, stringsAsFactors = FALSE)
data_dictionary <- read_csv_config(file.path(root, "..", "PredictionOfOutcomesUnruptured_DataDictionary_2026-03-27.csv"))

parse_choice_string <- function(choice_text) {
  choice_text <- normalize_missing_strings(choice_text)
  if (all(is.na(choice_text))) {
    return(data.frame(code = character(), label = character(), stringsAsFactors = FALSE))
  }
  choice_text <- gsub("[\r\n]+", " ", choice_text)
  parts <- trimws(unlist(strsplit(choice_text, "\\|", perl = TRUE)))
  parts <- parts[nzchar(parts)]
  if (length(parts) == 0) {
    return(data.frame(code = character(), label = character(), stringsAsFactors = FALSE))
  }
  parsed <- lapply(parts, function(part) {
    split_pos <- regexpr(",", part, fixed = TRUE)
    if (split_pos[1] < 0) {
      data.frame(code = trimws(part), label = trimws(part), stringsAsFactors = FALSE)
    } else {
      data.frame(
        code = trimws(substr(part, 1, split_pos[1] - 1)),
        label = trimws(substr(part, split_pos[1] + 1, nchar(part))),
        stringsAsFactors = FALSE
      )
    }
  })
  do.call(rbind, parsed)
}

dictionary_row <- function(field_name) {
  idx <- which(data_dictionary[["Variable / Field Name"]] == field_name)
  if (length(idx) == 0) {
    return(NULL)
  }
  data_dictionary[idx[1], , drop = FALSE]
}

decode_external_value <- function(field_name, values) {
  dict <- dictionary_row(field_name)
  if (is.null(dict)) {
    return(values)
  }
  field_type <- dict[["Field Type"]][1]
  if (field_type == "yesno") {
    return(ifelse(values %in% c("1", 1, "Yes"), "Yes", ifelse(values %in% c("0", 0, "No"), "No", values)))
  }
  choices <- parse_choice_string(dict[["Choices, Calculations, OR Slider Labels"]][1])
  if (nrow(choices) == 0) {
    return(values)
  }
  mapped <- choices$label[match(as.character(values), choices$code)]
  ifelse(is.na(mapped), as.character(values), mapped)
}

binary01 <- function(x) {
  x <- normalize_missing_strings(x)
  suppressWarnings(as.numeric(as.character(x)))
}

any_positive <- function(x) {
  x_num <- binary01(x)
  ifelse(is.na(x_num), NA_real_, ifelse(x_num > 0, 1, 0))
}

sex_male <- function(x) {
  x <- normalize_missing_strings(x)
  ifelse(is.na(x), NA_real_, ifelse(as.character(x) %in% c("Male", "M", "1", "male"), 1, 0))
}

asa_high <- function(x) {
  x_num <- suppressWarnings(as.numeric(as.character(x)))
  ifelse(is.na(x_num), NA_real_, ifelse(x_num >= 3, 1, 0))
}

aneurysm_location_group <- function(x) {
  x_num <- suppressWarnings(as.numeric(as.character(x)))
  ifelse(
    is.na(x_num),
    NA_character_,
    ifelse(x_num %in% c(8, 9, 10, 11, 12), "Posterior", "Anterior_or_ICA")
  )
}

multiple_any <- function(x) {
  x_num <- suppressWarnings(as.numeric(as.character(x)))
  ifelse(is.na(x_num), NA_real_, ifelse(x_num > 1, 1, 0))
}

safe_ci <- function(beta, se) {
  c(exp(beta - 1.96 * se), exp(beta + 1.96 * se))
}

safe_fmt_num <- function(x, digits = 2) {
  ifelse(is.na(x), NA_character_, sprintf(paste0("%.", digits, "f"), x))
}

safe_fmt_p <- function(x) {
  ifelse(is.na(x), NA_character_, formatC(x, format = "f", digits = 3))
}

severe_outcome <- ifelse(derive_external_outcome(external_raw, root) == "Yes", 1, 0)

analysis_data <- data.frame(
  severe_outcome = severe_outcome,
  age_per_10y = suppressWarnings(as.numeric(as.character(external_raw$age))) / 10,
  male_sex = sex_male(external_raw$sex),
  hypertension_any = any_positive(external_raw$hypertension),
  diabetes_any = any_positive(external_raw$diabetes),
  coronary_artery_disease = binary01(external_raw$cad),
  prior_stroke_tia = binary01(external_raw$prior_stroke_tia),
  copd = binary01(external_raw$copd),
  ckd = binary01(external_raw$ckd),
  asa_class_iii_iv = asa_high(external_raw$asa_class),
  aneurysm_size_per_5mm = suppressWarnings(as.numeric(as.character(external_raw$aneurysm_size_mm))) / 5,
  irregular_morphology = binary01(external_raw$irregular_morphology),
  multiple_aneurysms = multiple_any(external_raw$aneurysm_multiple_indicato),
  location_posterior = ifelse(aneurysm_location_group(external_raw$aneurysm_location) == "Posterior", 1, 0),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

candidate_metadata <- data.frame(
  analysis_variable = c(
    "age_per_10y",
    "male_sex",
    "hypertension_any",
    "diabetes_any",
    "coronary_artery_disease",
    "prior_stroke_tia",
    "copd",
    "ckd",
    "asa_class_iii_iv",
    "aneurysm_size_per_5mm",
    "irregular_morphology",
    "multiple_aneurysms",
    "location_posterior"
  ),
  source_variable = c(
    "age", "sex", "hypertension", "diabetes", "cad", "prior_stroke_tia", "copd", "ckd",
    "asa_class", "aneurysm_size_mm", "irregular_morphology", "aneurysm_multiple_indicato", "aneurysm_location"
  ),
  label = c(
    "Age (per 10-year increase)",
    "Male sex",
    "Any hypertension",
    "Any diabetes",
    "Coronary artery disease",
    "Prior stroke or TIA",
    "COPD",
    "Chronic kidney disease",
    "ASA class III-IV",
    "Primary aneurysm size (per 5-mm increase)",
    "Irregular aneurysm morphology",
    "Multiple aneurysms (>1)",
    "Posterior circulation location"
  ),
  type = c(
    "continuous", "binary", "binary", "binary", "binary", "binary", "binary", "binary",
    "binary", "continuous", "binary", "binary", "binary"
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

screen_variable <- function(variable_name, variable_type, label) {
  x <- analysis_data[[variable_name]]
  outcome <- analysis_data$severe_outcome
  complete_idx <- !is.na(x) & !is.na(outcome)
  x <- x[complete_idx]
  outcome <- outcome[complete_idx]
  missing_n <- sum(!complete_idx)
  missing_pct <- if (nrow(analysis_data) == 0) NA_real_ else 100 * missing_n / nrow(analysis_data)
  nonmissing_unique <- unique(x)
  nonmissing_unique <- nonmissing_unique[!is.na(nonmissing_unique)]

  if (length(nonmissing_unique) <= 1) {
    return(data.frame(
      analysis_variable = variable_name,
      variable_label = label,
      variable_type = variable_type,
      n = length(x),
      events = sum(outcome),
      missing_n = missing_n,
      missing_pct = missing_pct,
      univariate_method = "not_tested",
      odds_ratio = NA_real_,
      ci_lower = NA_real_,
      ci_upper = NA_real_,
      p_value = NA_real_,
      selection_reason = "Excluded before screening: no variability in external cohort",
      retained_for_multivariable = FALSE,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  if (missing_pct > 25) {
    return(data.frame(
      analysis_variable = variable_name,
      variable_label = label,
      variable_type = variable_type,
      n = length(x),
      events = sum(outcome),
      missing_n = missing_n,
      missing_pct = missing_pct,
      univariate_method = "not_tested",
      odds_ratio = NA_real_,
      ci_lower = NA_real_,
      ci_upper = NA_real_,
      p_value = NA_real_,
      selection_reason = "Excluded before screening: >25% missingness in external cohort",
      retained_for_multivariable = FALSE,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  tmp <- data.frame(severe_outcome = outcome, x = x, stringsAsFactors = FALSE)
  p_value <- NA_real_
  method <- NA_character_

  if (variable_type == "binary") {
    tab <- table(tmp$x, tmp$severe_outcome)
    if (all(dim(tab) == c(2, 2))) {
      p_value <- stats::fisher.test(tab)$p.value
      method <- "Fisher exact test + univariable logistic regression"
    } else {
      method <- "Univariable logistic regression"
    }
  } else {
    method <- "Univariable logistic regression"
  }

  fit <- tryCatch(
    suppressWarnings(stats::glm(severe_outcome ~ x, data = tmp, family = stats::binomial())),
    error = function(e) NULL
  )

  odds_ratio <- NA_real_
  ci_lower <- NA_real_
  ci_upper <- NA_real_
  glm_p <- NA_real_

  if (!is.null(fit)) {
    coef_table <- summary(fit)$coefficients
    if ("x" %in% rownames(coef_table)) {
      beta <- coef_table["x", "Estimate"]
      se <- coef_table["x", "Std. Error"]
      glm_p <- coef_table["x", "Pr(>|z|)"]
      odds_ratio <- exp(beta)
      ci <- safe_ci(beta, se)
      ci_lower <- ci[1]
      ci_upper <- ci[2]
    }
  }

  if (is.na(p_value)) {
    p_value <- glm_p
  }

  retained <- is.finite(p_value) && !is.na(p_value) && p_value < 0.20
  selection_reason <- if (retained) {
    "Retained: univariate p < 0.20 and acceptable external data support"
  } else {
    "Not retained: univariate p >= 0.20 or insufficient support"
  }

  data.frame(
    analysis_variable = variable_name,
    variable_label = label,
    variable_type = variable_type,
    n = nrow(tmp),
    events = sum(tmp$severe_outcome),
    missing_n = missing_n,
    missing_pct = missing_pct,
    univariate_method = method,
    odds_ratio = odds_ratio,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    p_value = p_value,
    selection_reason = selection_reason,
    retained_for_multivariable = retained,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

univariate_results <- do.call(
  rbind,
  lapply(seq_len(nrow(candidate_metadata)), function(i) {
    screen_variable(
      candidate_metadata$analysis_variable[i],
      candidate_metadata$type[i],
      candidate_metadata$label[i]
    )
  })
)

univariate_results$source_variable <- candidate_metadata$source_variable[
  match(univariate_results$analysis_variable, candidate_metadata$analysis_variable)
]
univariate_results$type <- candidate_metadata$type[
  match(univariate_results$analysis_variable, candidate_metadata$analysis_variable)
]
univariate_results <- univariate_results[order(ifelse(is.na(univariate_results$p_value), Inf, univariate_results$p_value)), ]

selected_variables <- univariate_results$analysis_variable[univariate_results$retained_for_multivariable]
selected_variables <- head(selected_variables, 2)

if (length(selected_variables) == 0) {
  stop("No external explanatory variables met the prespecified univariate retention rule.")
}

multivariable_formula <- stats::as.formula(
  paste("severe_outcome ~", paste(selected_variables, collapse = " + "))
)

multivariable_data <- analysis_data[, c("severe_outcome", selected_variables), drop = FALSE]
multivariable_complete <- stats::complete.cases(multivariable_data)
multivariable_data <- multivariable_data[multivariable_complete, , drop = FALSE]

multivariable_fit <- suppressWarnings(
  stats::glm(multivariable_formula, data = multivariable_data, family = stats::binomial())
)
multivariable_summary <- summary(multivariable_fit)$coefficients

multivariable_results <- do.call(
  rbind,
  lapply(selected_variables, function(variable_name) {
    row <- multivariable_summary[variable_name, ]
    ci <- safe_ci(row["Estimate"], row["Std. Error"])
    meta <- candidate_metadata[candidate_metadata$analysis_variable == variable_name, , drop = FALSE]
    data.frame(
      analysis_variable = variable_name,
      source_variable = meta$source_variable[1],
      variable_label = meta$label[1],
      adjusted_odds_ratio = exp(row["Estimate"]),
      ci_lower = ci[1],
      ci_upper = ci[2],
      p_value = row["Pr(>|z|)"],
      model_n = nrow(multivariable_data),
      model_events = sum(multivariable_data$severe_outcome),
      model_formula = paste(deparse(multivariable_formula), collapse = ""),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
)

multivariable_notes <- data.frame(
  note = c(
    "Exploratory external-cohort analysis intended for discussion only; external cohort contains 50 patients and 6 severe events.",
    "Prespecified univariate retention rule: p < 0.20 after collapsing sparse external variables into clinically readable bins.",
    "Variables with no variability or >25% missingness were excluded before univariate screening.",
    "Final multivariable logistic regression was limited to the top retained predictors to reduce overfitting risk."
  ),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

publication_univariate <- univariate_results[, c(
  "variable_label",
  "source_variable",
  "type",
  "n",
  "events",
  "missing_n",
  "missing_pct",
  "univariate_method",
  "odds_ratio",
  "ci_lower",
  "ci_upper",
  "p_value",
  "retained_for_multivariable",
  "selection_reason"
)]
names(publication_univariate) <- c(
  "Characteristic",
  "External variable",
  "Variable type",
  "N analyzed",
  "Events",
  "Missing n",
  "Missing %",
  "Univariate method",
  "Univariate OR",
  "95% CI lower",
  "95% CI upper",
  "P value",
  "Retained for multivariable model",
  "Selection note"
)

publication_multivariable <- multivariable_results[, c(
  "variable_label",
  "source_variable",
  "adjusted_odds_ratio",
  "ci_lower",
  "ci_upper",
  "p_value",
  "model_n",
  "model_events",
  "model_formula"
)]
names(publication_multivariable) <- c(
  "Characteristic",
  "External variable",
  "Adjusted OR",
  "95% CI lower",
  "95% CI upper",
  "P value",
  "Model N",
  "Model events",
  "Model formula"
)

write.csv(
  publication_univariate,
  file.path(publication_tables_dir, "publication_external_univariate_association_analysis.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  publication_multivariable,
  file.path(publication_tables_dir, "publication_external_multivariable_association_analysis.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  multivariable_notes,
  file.path(publication_tables_dir, "publication_external_multivariable_association_notes.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  univariate_results,
  file.path(root, "results", "metrics", "external_univariate_association_analysis.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  multivariable_results,
  file.path(root, "results", "metrics", "external_multivariable_association_analysis.csv"),
  row.names = FALSE,
  na = ""
)

cat("External explanatory association analysis completed.\n")
cat("Selected variables for multivariable model:\n")
cat(paste(selected_variables, collapse = ", "), "\n")
