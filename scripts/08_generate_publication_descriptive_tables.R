source(file.path(getwd(), "R", "utils.R"))

root <- find_project_root()
publication_tables_dir <- file.path(root, "publication_summary", "tables")
dir.create(publication_tables_dir, recursive = TRUE, showWarnings = FALSE)

mapping <- load_feature_mapping(root)
development <- read_csv_config(file.path(root, "results", "datasets", "development_model_dataset.csv"))
external <- read_csv_config(file.path(root, "results", "datasets", "external_model_dataset.csv"))
external_descriptive <- read_csv_config(file.path(root, "results", "datasets", "external_descriptive_only_dataset.csv"))
external_descriptive_columns <- read_csv_config(file.path(root, "results", "metrics", "external_descriptive_columns.csv"))
model_benchmarks <- load_model_benchmarks(root)
external_outcome_fields <- load_external_outcome_fields(root)
feature_exclusions <- load_feature_exclusions(root)
data_dictionary <- read_csv_config(file.path(root, "..", "PredictionOfOutcomesUnruptured_DataDictionary_2026-03-27.csv"))

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

algorithm_definition_table <- function() {
  data.frame(
    group = c(
      "Analysis strategy", "Analysis strategy", "Analysis strategy", "Analysis strategy",
      "Algorithm", "Algorithm", "Algorithm", "Algorithm", "Algorithm", "Algorithm"
    ),
    name = c(
      "Original arm",
      "SMOTE arm",
      "Weighted arm",
      "Exploratory ensemble",
      "Elastic Net",
      "Random Forest",
      "XGBoost",
      "kNN",
      "ANN",
      "Stacked Logistic Ensemble"
    ),
    short_definition = c(
      "Models trained on the observed class distribution without resampling or class weighting.",
      "Models trained after Synthetic Minority Oversampling Technique was applied within the training folds.",
      "Models trained with higher loss weight assigned to severe-event cases to address class imbalance.",
      "Secondary model combining predictions from selected high-performing original, SMOTE, and weighted models.",
      "Penalized logistic regression that mixes ridge and lasso regularization.",
      "Bootstrap-aggregated decision tree ensemble using random feature subsets.",
      "Gradient-boosted decision tree model optimized for binary classification.",
      "Instance-based classifier using nearest-neighbor distance in the processed feature space.",
      "Single-hidden-layer feed-forward neural network.",
      "Logistic meta-model built on out-of-fold predictions from the selected component models."
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

format_pct <- function(x, digits = 1) {
  sprintf(paste0("%.", digits, "f%%"), x)
}

format_n_pct <- function(count, total, digits = 1) {
  pct <- if (total == 0) NA_real_ else 100 * count / total
  sprintf("%s (%s)", count, format_pct(pct, digits = digits))
}

format_median_iqr <- function(x, digits = 1) {
  x <- suppressWarnings(as.numeric(x))
  x <- x[is.finite(x)]
  if (length(x) == 0) return("NA")
  med <- stats::median(x)
  q <- stats::quantile(x, probs = c(0.25, 0.75), names = FALSE)
  sprintf(paste0("%.", digits, "f [%.", digits, "f, %.", digits, "f]"), med, q[1], q[2])
}

nonmissing <- function(x) {
  x <- normalize_missing_strings(x)
  x[!is.na(x)]
}

append_row <- function(rows, variable, characteristic, development_value, external_value) {
  rbind(
    rows,
    data.frame(
      variable = variable,
      characteristic = characteristic,
      development = development_value,
      external = external_value,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}

build_cohort_comparison_table <- function(development, external, mapping) {
  rows <- data.frame(variable = character(), characteristic = character(), development = character(), external = character(), stringsAsFactors = FALSE, check.names = FALSE)
  rows <- append_row(rows, "cohort_size", "Patients, n", as.character(nrow(development)), as.character(nrow(external)))
  rows <- append_row(
    rows,
    "severe_outcome",
    "Severe adverse outcome, n (%)",
    format_n_pct(sum(ensure_factor_outcome(development$severe_outcome) == "Yes"), nrow(development)),
    format_n_pct(sum(ensure_factor_outcome(external$severe_outcome) == "Yes"), nrow(external))
  )

  modeled <- mapping[mapping$include_in_model, , drop = FALSE]
  for (i in seq_len(nrow(modeled))) {
    field <- modeled$canonical_name[i]
    feature_type <- modeled$feature_type[i]
    label <- publication_label_map[[field]]
    if (is.null(label) || !nzchar(label)) label <- field

    dev_col <- development[[field]]
    ext_col <- external[[field]]

    if (feature_type == "numeric") {
      rows <- append_row(rows, field, label, format_median_iqr(dev_col), format_median_iqr(ext_col))
      dev_missing <- sum(is.na(suppressWarnings(as.numeric(dev_col))))
      ext_missing <- sum(is.na(suppressWarnings(as.numeric(ext_col))))
      if (dev_missing > 0 || ext_missing > 0) {
        rows <- append_row(rows, field, paste0(label, ": Missing"), format_n_pct(dev_missing, nrow(development)), format_n_pct(ext_missing, nrow(external)))
      }
      next
    }

    if (feature_type == "binary") {
      dev_yes <- sum(nonmissing(dev_col) == "Yes")
      ext_yes <- sum(nonmissing(ext_col) == "Yes")
      rows <- append_row(rows, field, paste0(label, ": Yes"), format_n_pct(dev_yes, nrow(development)), format_n_pct(ext_yes, nrow(external)))
      dev_missing <- sum(is.na(normalize_missing_strings(dev_col)))
      ext_missing <- sum(is.na(normalize_missing_strings(ext_col)))
      if (dev_missing > 0 || ext_missing > 0) {
        rows <- append_row(rows, field, paste0(label, ": Missing"), format_n_pct(dev_missing, nrow(development)), format_n_pct(ext_missing, nrow(external)))
      }
      next
    }

    levels <- sort(unique(c(nonmissing(dev_col), nonmissing(ext_col))))
    for (level in levels) {
      rows <- append_row(
        rows,
        field,
        paste0(label, ": ", level),
        format_n_pct(sum(nonmissing(dev_col) == level), nrow(development)),
        format_n_pct(sum(nonmissing(ext_col) == level), nrow(external))
      )
    }
    dev_missing <- sum(is.na(normalize_missing_strings(dev_col)))
    ext_missing <- sum(is.na(normalize_missing_strings(ext_col)))
    if (dev_missing > 0 || ext_missing > 0) {
      rows <- append_row(rows, field, paste0(label, ": Missing"), format_n_pct(dev_missing, nrow(development)), format_n_pct(ext_missing, nrow(external)))
    }
  }

  rows
}

parse_choice_string <- function(choice_text) {
  choice_text <- normalize_missing_strings(choice_text)
  if (all(is.na(choice_text))) return(data.frame(code = character(), label = character(), stringsAsFactors = FALSE))
  choice_text <- gsub("[\r\n]+", " ", choice_text)
  parts <- trimws(unlist(strsplit(choice_text, "\\|", perl = TRUE)))
  parts <- parts[nzchar(parts)]
  if (length(parts) == 0) return(data.frame(code = character(), label = character(), stringsAsFactors = FALSE))
  parsed <- lapply(parts, function(part) {
    split_pos <- regexpr(",", part, fixed = TRUE)
    if (split_pos[1] < 0) {
      data.frame(code = trimws(part), label = trimws(part), stringsAsFactors = FALSE)
    } else {
      code <- trimws(substr(part, 1, split_pos[1] - 1))
      label <- trimws(substr(part, split_pos[1] + 1, nchar(part)))
      data.frame(code = code, label = label, stringsAsFactors = FALSE)
    }
  })
  do.call(rbind, parsed)
}

dictionary_row <- function(field_name, data_dictionary) {
  idx <- which(data_dictionary[["Variable / Field Name"]] == field_name)
  if (length(idx) == 0) return(NULL)
  data_dictionary[idx[1], , drop = FALSE]
}

decode_external_value <- function(field_name, values, data_dictionary) {
  dict <- dictionary_row(field_name, data_dictionary)
  if (is.null(dict)) return(values)
  field_type <- dict[["Field Type"]][1]
  if (field_type == "yesno") {
    out <- ifelse(values %in% c("1", 1, "Yes"), "Yes", ifelse(values %in% c("0", 0, "No"), "No", values))
    return(out)
  }
  choices <- parse_choice_string(dict[["Choices, Calculations, OR Slider Labels"]][1])
  if (nrow(choices) == 0) return(values)
  mapped <- choices$label[match(as.character(values), choices$code)]
  ifelse(is.na(mapped), as.character(values), mapped)
}

checkbox_summary_rows <- function(prefix, label, data, data_dictionary) {
  dict <- dictionary_row(prefix, data_dictionary)
  choices <- if (is.null(dict)) data.frame(code = character(), label = character(), stringsAsFactors = FALSE) else parse_choice_string(dict[["Choices, Calculations, OR Slider Labels"]][1])
  rows <- data.frame(characteristic = character(), external = character(), stringsAsFactors = FALSE, check.names = FALSE)
  for (i in seq_len(nrow(choices))) {
    col <- sprintf("%s___%s", prefix, choices$code[i])
    if (!col %in% names(data)) next
    count <- sum(as.character(data[[col]]) %in% c("1", "Yes", "yes", "TRUE", "true"), na.rm = TRUE)
    rows <- rbind(
      rows,
      data.frame(
        characteristic = paste0(label, ": ", choices$label[i]),
        external = format_n_pct(count, nrow(data)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    )
  }
  rows
}

categorical_summary_rows <- function(field, label, data, data_dictionary) {
  raw <- normalize_missing_strings(data[[field]])
  decoded <- normalize_missing_strings(decode_external_value(field, raw, data_dictionary))
  rows <- data.frame(characteristic = character(), external = character(), stringsAsFactors = FALSE, check.names = FALSE)
  levels <- sort(unique(decoded[!is.na(decoded)]))
  for (level in levels) {
    rows <- rbind(
      rows,
      data.frame(
        characteristic = paste0(label, ": ", level),
        external = format_n_pct(sum(decoded == level, na.rm = TRUE), nrow(data)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    )
  }
  missing_n <- sum(is.na(decoded))
  if (missing_n > 0) {
    rows <- rbind(
      rows,
      data.frame(
        characteristic = paste0(label, ": Missing"),
        external = format_n_pct(missing_n, nrow(data)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    )
  }
  rows
}

numeric_summary_row <- function(field, label, data) {
  rows <- data.frame(
    characteristic = label,
    external = format_median_iqr(data[[field]]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  x <- suppressWarnings(as.numeric(data[[field]]))
  missing_n <- sum(!is.finite(x))
  if (missing_n > 0) {
    rows <- rbind(
      rows,
      data.frame(
        characteristic = paste0(label, ": Missing"),
        external = format_n_pct(missing_n, nrow(data)),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    )
  }
  rows
}

build_external_aneurysm_procedure_table <- function(external_descriptive, data_dictionary) {
  rows <- data.frame(characteristic = character(), external = character(), stringsAsFactors = FALSE, check.names = FALSE)
  rows <- rbind(rows, checkbox_summary_rows("presenting_symptoms", "Presenting symptom", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("aneurysm_multiple_indicato", "Number of aneurysms recorded", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("aneurysm_side", "Primary aneurysm side", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("aneurysm_location", "Primary aneurysm location", external_descriptive, data_dictionary))
  rows <- rbind(rows, numeric_summary_row("aneurysm_size_mm", "Primary aneurysm maximum diameter, mm", external_descriptive))
  rows <- rbind(rows, numeric_summary_row("neck_width_mm", "Primary aneurysm neck width, mm", external_descriptive))
  rows <- rbind(rows, categorical_summary_rows("aneurysm_morphology_type", "Primary aneurysm morphology", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("irregular_morphology", "Primary aneurysm irregular morphology", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("procedure_type", "Procedure type", external_descriptive, data_dictionary))
  rows <- rbind(rows, categorical_summary_rows("endovascular", "Endovascular procedure", external_descriptive, data_dictionary))
  rows <- rbind(rows, numeric_summary_row("procedure_duration_min", "Procedure duration, minutes", external_descriptive))
  rows
}

build_model_variable_inventory <- function(mapping) {
  modeled <- mapping[mapping$include_in_model, c("canonical_name", "development_var", "external_var", "feature_type", "notes"), drop = FALSE]
  modeled$publication_label <- unname(publication_label_map[modeled$canonical_name])
  modeled <- modeled[, c("canonical_name", "publication_label", "development_var", "external_var", "feature_type", "notes")]
  names(modeled) <- c("canonical_name", "publication_label", "nsqip_development_variable", "external_variable", "feature_type", "notes")
  modeled
}

classify_external_role <- function(field_name, mapping, external_outcome_fields, feature_exclusions) {
  if (field_name %in% mapping$external_var[mapping$include_in_model]) return("Modeled pre-operative variable")
  if (field_name %in% external_outcome_fields$field_name) return("External severe-outcome component")
  exact_exclusion <- feature_exclusions[feature_exclusions$scope == "external" & feature_exclusions$rule_type == "exact" & feature_exclusions$rule_value == field_name, , drop = FALSE]
  if (nrow(exact_exclusion) > 0) return(paste0("Excluded / descriptive only: ", exact_exclusion$reason[1]))
  pattern_exclusion <- feature_exclusions[
    feature_exclusions$scope == "external" &
      feature_exclusions$rule_type == "pattern" &
      vapply(feature_exclusions$rule_value, function(pattern) grepl(pattern, field_name, perl = TRUE), logical(1)),
    ,
    drop = FALSE
  ]
  if (nrow(pattern_exclusion) > 0) return(paste0("Excluded / descriptive only: ", pattern_exclusion$reason[1]))
  "Collected external field"
}

build_external_variable_inventory <- function(data_dictionary, mapping, external_outcome_fields, feature_exclusions) {
  rows <- data_dictionary
  rows <- rows[, c("Variable / Field Name", "Form Name", "Section Header", "Field Type", "Field Label"), drop = FALSE]
  names(rows) <- c("external_variable", "form_name", "section_header", "field_type", "field_label")
  rows$role <- vapply(rows$external_variable, classify_external_role, character(1), mapping = mapping, external_outcome_fields = external_outcome_fields, feature_exclusions = feature_exclusions)
  rows
}

build_nsqip_variable_inventory <- function(mapping) {
  modeled <- mapping[mapping$include_in_model, c("development_var", "canonical_name", "feature_type", "notes"), drop = FALSE]
  modeled$publication_label <- unname(publication_label_map[modeled$canonical_name])
  modeled[, c("development_var", "publication_label", "canonical_name", "feature_type", "notes")]
}

cohort_comparison <- build_cohort_comparison_table(development, external, mapping)
external_aneurysm_procedure <- build_external_aneurysm_procedure_table(external_descriptive, data_dictionary)
model_definitions <- algorithm_definition_table()
model_variable_inventory <- build_model_variable_inventory(mapping)
external_variable_inventory <- build_external_variable_inventory(data_dictionary, mapping, external_outcome_fields, feature_exclusions)
nsqip_variable_inventory <- build_nsqip_variable_inventory(mapping)

significance_path <- file.path(publication_tables_dir, "publication_internal_vs_external_significance_tests.csv")
if (file.exists(significance_path)) {
  significance <- read_csv_config(significance_path)
  significance <- significance[, c("variable", "test_used", "p_value_display", "p_value_fdr_display"), drop = FALSE]
  names(significance) <- c("variable", "test_used", "p_value", "p_value_fdr")
  cohort_comparison <- merge(cohort_comparison, significance, by = "variable", all.x = TRUE, sort = FALSE)
  if (nrow(cohort_comparison) > 0) {
    repeated <- duplicated(cohort_comparison$variable)
    cohort_comparison$test_used[repeated] <- ""
    cohort_comparison$p_value[repeated] <- ""
    cohort_comparison$p_value_fdr[repeated] <- ""
  }
  cohort_comparison <- cohort_comparison[, c("characteristic", "development", "external", "test_used", "p_value", "p_value_fdr")]
} else {
  cohort_comparison <- cohort_comparison[, c("characteristic", "development", "external", "variable")]
}

utils::write.csv(cohort_comparison, file.path(publication_tables_dir, "publication_internal_vs_external_patient_comparison.csv"), row.names = FALSE, na = "")
utils::write.csv(external_aneurysm_procedure, file.path(publication_tables_dir, "publication_external_aneurysm_and_procedure_characteristics.csv"), row.names = FALSE, na = "")
utils::write.csv(model_definitions, file.path(publication_tables_dir, "publication_models_utilized_and_definitions.csv"), row.names = FALSE, na = "")
utils::write.csv(model_variable_inventory, file.path(publication_tables_dir, "publication_model_variable_map.csv"), row.names = FALSE, na = "")
utils::write.csv(external_variable_inventory, file.path(publication_tables_dir, "publication_external_variable_inventory.csv"), row.names = FALSE, na = "")
utils::write.csv(nsqip_variable_inventory, file.path(publication_tables_dir, "publication_nsqip_model_development_variables.csv"), row.names = FALSE, na = "")

append_project_log(
  root,
  "08 Generate Publication Descriptive Tables",
  c(
    "- Generated internal-versus-external patient comparison table.",
    "- Generated external aneurysm and procedure characteristics table.",
    "- Generated model-definition table for the benchmarked algorithms and analysis strategies.",
    "- Generated NSQIP development-variable and external variable-inventory tables for publication."
  )
)

cat("Publication descriptive tables generated.\n")
