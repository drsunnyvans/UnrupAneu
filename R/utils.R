initialize_r_library_paths <- function() {
  workspace_libs <- c(
    normalizePath(file.path(getwd(), "r_libs"), winslash = "/", mustWork = FALSE),
    normalizePath(file.path(getwd(), "..", "r_libs"), winslash = "/", mustWork = FALSE)
  )
  local_lib <- Sys.getenv("R_LIBS_USER")
  if (!nzchar(local_lib)) {
    version_parts <- strsplit(R.version$minor, ".", fixed = TRUE)[[1]]
    local_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library", paste(R.version$major, version_parts[1], sep = "."))
  }
  candidate_libs <- c(workspace_libs, local_lib, .libPaths())
  candidate_libs <- unique(candidate_libs[file.exists(candidate_libs)])
  .libPaths(candidate_libs)
  invisible(.libPaths())
}

find_project_root <- function() {
  candidates <- unique(normalizePath(c(getwd(), file.path(getwd(), "..")), winslash = "/", mustWork = FALSE))
  for (candidate in candidates) {
    if (file.exists(file.path(candidate, "config", "feature_mapping.csv"))) {
      return(candidate)
    }
  }
  stop("Could not find project root containing config/feature_mapping.csv")
}

ensure_packages <- function(packages) {
  initialize_r_library_paths()
  missing <- packages[!vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
  if (length(missing) > 0) {
    stop(sprintf("Missing required packages: %s", paste(missing, collapse = ", ")), call. = FALSE)
  }
}

read_csv_config <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

get_data_sources <- function(root) {
  config <- read_csv_config(file.path(root, "config", "data_sources.csv"))
  paths <- stats::setNames(vector("list", nrow(config)), config$dataset)
  for (i in seq_len(nrow(config))) {
    paths[[config$dataset[i]]] <- normalizePath(file.path(root, config$relative_path[i]), winslash = "/", mustWork = FALSE)
  }
  paths
}

load_feature_mapping <- function(root) {
  mapping <- read_csv_config(file.path(root, "config", "feature_mapping.csv"))
  mapping$include_in_model <- tolower(mapping$include_in_model) %in% c("true", "t", "1", "yes")
  mapping
}

load_feature_mapping_file <- function(root, filename) {
  mapping <- read_csv_config(file.path(root, "config", filename))
  mapping$include_in_model <- tolower(mapping$include_in_model) %in% c("true", "t", "1", "yes")
  mapping
}

load_feature_exclusions <- function(root) {
  read_csv_config(file.path(root, "config", "feature_exclusions.csv"))
}

load_external_outcome_fields <- function(root) {
  read_csv_config(file.path(root, "config", "external_severe_outcome_fields.csv"))
}

load_model_benchmarks <- function(root) {
  benchmarks <- read_csv_config(file.path(root, "config", "model_benchmarks.csv"))
  benchmarks$enabled <- tolower(benchmarks$enabled) %in% c("true", "t", "1", "yes")
  benchmarks
}

timestamp_string <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

initialize_project_log <- function(root) {
  path <- file.path(root, "reports", "project_log.md")
  if (!file.exists(path)) {
    lines <- c(
      "# Project Log",
      "",
      "This file is automatically updated by the analysis pipeline.",
      ""
    )
    writeLines(lines, con = path, useBytes = TRUE)
  }
  invisible(path)
}

append_project_log <- function(root, stage, bullets = character()) {
  path <- initialize_project_log(root)
  section <- c(
    sprintf("## %s", stage),
    "",
    sprintf("- Timestamp: %s", timestamp_string()),
    bullets,
    ""
  )
  cat(paste0(section, collapse = "\n"), file = path, append = TRUE)
}

write_markdown <- function(path, lines) {
  writeLines(lines, con = path, useBytes = TRUE)
}

markdown_table <- function(data, digits = 3, max_rows = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(c("_No rows available._", ""))
  }
  if (!is.null(max_rows) && nrow(data) > max_rows) {
    data <- data[seq_len(max_rows), , drop = FALSE]
  }
  formatted <- data
  for (col in names(formatted)) {
    if (is.numeric(formatted[[col]])) {
      formatted[[col]] <- format(round(formatted[[col]], digits), nsmall = digits, trim = TRUE)
    } else {
      formatted[[col]] <- ifelse(is.na(formatted[[col]]), "", as.character(formatted[[col]]))
    }
  }
  header <- paste0("| ", paste(names(formatted), collapse = " | "), " |")
  separator <- paste0("| ", paste(rep("---", ncol(formatted)), collapse = " | "), " |")
  rows <- apply(formatted, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  c(header, separator, rows, "")
}

normalize_missing_strings <- function(x) {
  if (is.factor(x)) {
    x <- as.character(x)
  }
  x <- trimws(as.character(x))
  x[x %in% c("", "NA", "N/A", "NULL", "null", "Missing", "missing")] <- NA_character_
  x
}

as_binary_yes_no <- function(x) {
  x <- normalize_missing_strings(x)
  lower <- tolower(x)
  out <- rep(NA_character_, length(x))
  out[lower %in% c("1", "true", "t", "yes", "y", "present", "positive")] <- "Yes"
  out[lower %in% c("0", "false", "f", "no", "n", "absent", "negative")] <- "No"
  out
}

as_numeric_clean <- function(x) {
  x <- normalize_missing_strings(x)
  suppressWarnings(as.numeric(x))
}

harmonize_race <- function(x, source) {
  x <- normalize_missing_strings(x)
  out <- rep(NA_character_, length(x))
  if (source == "external") {
    mapping <- c("1" = "White", "2" = "Black", "3" = "Asian", "4" = "Hispanic", "5" = "Other", "6" = "Unknown")
    out <- unname(mapping[x])
  } else {
    lower <- tolower(x)
    out[grepl("white", lower)] <- "White"
    out[grepl("black", lower)] <- "Black"
    out[grepl("asian", lower)] <- "Asian"
    out[grepl("hispanic", lower)] <- "Hispanic"
    out[grepl("unknown", lower)] <- "Unknown"
    out[is.na(out) & !is.na(lower)] <- "Other"
  }
  out
}

harmonize_sex <- function(x) {
  x <- normalize_missing_strings(x)
  lower <- tolower(x)
  out <- rep(NA_character_, length(x))
  out[lower %in% c("m", "male", "1")] <- "Male"
  out[lower %in% c("f", "female", "2")] <- "Female"
  out
}

harmonize_admission_source <- function(x, source) {
  x <- normalize_missing_strings(x)
  out <- rep(NA_character_, length(x))
  if (source == "external") {
    mapping <- c("1" = "Home", "2" = "Transfer", "3" = "Emergency Department", "4" = "Other")
    out <- unname(mapping[x])
  } else {
    lower <- tolower(x)
    out[grepl("home", lower)] <- "Home"
    out[grepl("emergency", lower)] <- "Emergency Department"
    out[grepl("chronic care", lower) | grepl("transfer", lower)] <- "Transfer"
    out[is.na(out) & !is.na(lower)] <- "Other"
  }
  out
}

harmonize_functional_status <- function(x, source) {
  x <- normalize_missing_strings(x)
  out <- rep(NA_character_, length(x))
  if (source == "external") {
    mapping <- c("1" = "Independent", "2" = "Partially dependent", "3" = "Totally dependent")
    out <- unname(mapping[x])
  } else {
    lower <- tolower(x)
    out[grepl("independent", lower)] <- "Independent"
    out[grepl("partially", lower)] <- "Partially dependent"
    out[grepl("totally", lower)] <- "Totally dependent"
  }
  out
}

harmonize_diabetes_binary <- function(x, source) {
  x <- normalize_missing_strings(x)
  out <- rep(NA_character_, length(x))
  lower <- tolower(x)
  if (source == "external") {
    out[lower %in% c("0", "no")] <- "No"
    out[lower %in% c("1", "2", "yes")] <- "Yes"
  } else {
    out[lower %in% c("0", "no", "none")] <- "No"
    out[lower %in% c("1", "2", "yes", "insulin", "oral", "non-insulin")] <- "Yes"
    fill <- as_binary_yes_no(x)
    out[is.na(out)] <- fill[is.na(out)]
  }
  out
}

harmonize_asa_class <- function(x, source) {
  x <- normalize_missing_strings(x)
  lower <- tolower(x)
  out <- rep(NA_character_, length(x))
  code_map <- c("1" = "ASA I", "2" = "ASA II", "3" = "ASA III", "4" = "ASA IV", "5" = "ASA V")
  matched <- lower %in% names(code_map)
  out[matched] <- unname(code_map[lower[matched]])
  if (source == "development") {
    out[grepl("^i$", lower)] <- "ASA I"
    out[grepl("^ii$", lower)] <- "ASA II"
    out[grepl("^iii$", lower)] <- "ASA III"
    out[grepl("^iv$", lower)] <- "ASA IV"
    out[grepl("^v$", lower)] <- "ASA V"
  }
  out
}

apply_transform <- function(x, transform, source) {
  if (transform == "identity") return(as_numeric_clean(x))
  if (transform == "sex") return(harmonize_sex(x))
  if (transform == "race") return(harmonize_race(x, source))
  if (transform == "admission_source") return(harmonize_admission_source(x, source))
  if (transform == "functional_status") return(harmonize_functional_status(x, source))
  if (transform == "binary_yes_no") return(as_binary_yes_no(x))
  if (transform == "diabetes_binary") return(harmonize_diabetes_binary(x, source))
  if (transform == "asa_class") return(harmonize_asa_class(x, source))
  stop(sprintf("Unsupported transform '%s'", transform))
}

coerce_feature_column <- function(x, feature_type) {
  if (feature_type == "numeric") return(as.numeric(x))
  as.character(x)
}

ensure_factor_outcome <- function(x) {
  lower <- tolower(normalize_missing_strings(x))
  out <- ifelse(lower %in% c("1", "yes", "y", "true", "case"), "Yes", "No")
  factor(out, levels = c("No", "Yes"))
}
