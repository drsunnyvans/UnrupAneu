source(file.path(find_project_root(), "R", "utils.R"))

decode_xml_entities <- function(x) {
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&lt;", "<", x, fixed = TRUE)
  x <- gsub("&gt;", ">", x, fixed = TRUE)
  x <- gsub("&quot;", "\"", x, fixed = TRUE)
  gsub("&apos;", "'", x, fixed = TRUE)
}

excel_col_to_index <- function(ref) {
  letters <- strsplit(gsub("[0-9]", "", ref), "", fixed = TRUE)[[1]]
  index <- 0
  for (letter in letters) {
    index <- index * 26 + match(letter, LETTERS)
  }
  index
}

read_xlsx_sheet1_base <- function(path) {
  temp_dir <- tempfile("xlsx_")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)
  utils::unzip(path, exdir = temp_dir)

  shared_path <- file.path(temp_dir, "xl", "sharedStrings.xml")
  shared_strings <- character()
  if (file.exists(shared_path)) {
    shared_xml <- paste(readLines(shared_path, warn = FALSE, encoding = "UTF-8"), collapse = "")
    shared_blocks <- regmatches(shared_xml, gregexpr("<si.*?>.*?</si>", shared_xml, perl = TRUE))[[1]]
    shared_strings <- vapply(shared_blocks, function(block) {
      text_nodes <- regmatches(block, gregexpr("<t[^>]*>.*?</t>", block, perl = TRUE))[[1]]
      text <- paste(gsub("</?t[^>]*>", "", text_nodes, perl = TRUE), collapse = "")
      decode_xml_entities(text)
    }, character(1))
  }

  sheet_xml <- paste(readLines(file.path(temp_dir, "xl", "worksheets", "sheet1.xml"), warn = FALSE, encoding = "UTF-8"), collapse = "")
  row_blocks <- regmatches(sheet_xml, gregexpr("<row[^>]*r=\"[0-9]+\"[^>]*>.*?</row>", sheet_xml, perl = TRUE))[[1]]
  parsed_rows <- lapply(row_blocks, function(row_block) {
    cell_blocks <- regmatches(row_block, gregexpr("<c[^>]*r=\"[A-Z]+[0-9]+\"[^>]*>.*?</c>", row_block, perl = TRUE))[[1]]
    if (length(cell_blocks) == 0) return(list())
    row_values <- list()
    for (cell in cell_blocks) {
      ref <- sub(".*r=\"([A-Z]+[0-9]+)\".*", "\\1", cell)
      cell_type <- if (grepl(" t=\"([^\"]+)\"", cell, perl = TRUE)) sub(".* t=\"([^\"]+)\".*", "\\1", cell) else ""
      value <- ""
      if (cell_type == "s") {
        idx <- as.integer(sub(".*<v>([^<]+)</v>.*", "\\1", cell))
        if (!is.na(idx) && length(shared_strings) >= (idx + 1)) value <- shared_strings[idx + 1]
      } else if (cell_type == "inlineStr") {
        inline <- regmatches(cell, regexpr("<t[^>]*>.*?</t>", cell, perl = TRUE))
        value <- decode_xml_entities(gsub("</?t[^>]*>", "", inline, perl = TRUE))
      } else if (grepl("<v>.*</v>", cell, perl = TRUE)) {
        value <- sub(".*<v>([^<]*)</v>.*", "\\1", cell)
      }
      row_values[[as.character(excel_col_to_index(ref))]] <- value
    }
    row_values
  })

  max_cols <- max(vapply(parsed_rows, function(x) if (length(x) == 0) 0 else max(as.integer(names(x))), numeric(1)))
  matrix_data <- matrix("", nrow = length(parsed_rows), ncol = max_cols)
  for (i in seq_along(parsed_rows)) {
    row_values <- parsed_rows[[i]]
    if (length(row_values) == 0) next
    indices <- as.integer(names(row_values))
    matrix_data[i, indices] <- unlist(row_values, use.names = FALSE)
  }

  headers <- make.names(matrix_data[1, ], unique = TRUE)
  data <- as.data.frame(matrix_data[-1, , drop = FALSE], stringsAsFactors = FALSE, check.names = FALSE)
  names(data) <- headers
  data[data == ""] <- NA
  data
}

read_development_raw <- function(root) {
  sources <- get_data_sources(root)
  read_xlsx_sheet1_base(sources$development_raw)
}

read_external_raw <- function(root) {
  sources <- get_data_sources(root)
  utils::read.csv(sources$external_raw, stringsAsFactors = FALSE, check.names = FALSE)
}

derive_development_outcome <- function(df) {
  score <- suppressWarnings(as.numeric(df$dindo_scores))
  severe <- ifelse(!is.na(score) & score >= 3, "Yes", "No")
  factor(severe, levels = c("No", "Yes"))
}

derive_external_outcome <- function(df, root) {
  config <- load_external_outcome_fields(root)
  positive <- rep(FALSE, nrow(df))
  for (field in config$field_name) {
    if (!field %in% names(df)) next
    values <- normalize_missing_strings(df[[field]])
    positive <- positive | (!is.na(values) & values %in% c("1", "TRUE", "true", "Yes", "yes"))
  }
  factor(ifelse(positive, "Yes", "No"), levels = c("No", "Yes"))
}

extract_harmonized_features <- function(raw_df, mapping, source) {
  feature_map <- mapping[mapping$include_in_model, , drop = FALSE]
  output <- vector("list", nrow(feature_map))
  names(output) <- feature_map$canonical_name
  for (i in seq_len(nrow(feature_map))) {
    source_var <- if (source == "development") feature_map$development_var[i] else feature_map$external_var[i]
    if (!source_var %in% names(raw_df)) {
      output[[feature_map$canonical_name[i]]] <- rep(NA, nrow(raw_df))
      next
    }
    transformed <- apply_transform(raw_df[[source_var]], feature_map$transform[i], source)
    output[[feature_map$canonical_name[i]]] <- coerce_feature_column(transformed, feature_map$feature_type[i])
  }
  as.data.frame(output, stringsAsFactors = FALSE, check.names = FALSE)
}

list_descriptive_only_columns <- function(raw_df, mapping, exclusions, source) {
  modeled <- unique(c(mapping$development_var[mapping$include_in_model], mapping$external_var[mapping$include_in_model]))
  modeled <- modeled[!is.na(modeled) & nzchar(modeled)]
  scoped <- exclusions[exclusions$scope == source, , drop = FALSE]
  flagged <- character()
  for (i in seq_len(nrow(scoped))) {
    if (scoped$rule_type[i] == "exact") {
      flagged <- c(flagged, scoped$rule_value[i])
    } else {
      flagged <- c(flagged, grep(scoped$rule_value[i], names(raw_df), value = TRUE))
    }
  }
  unique(setdiff(intersect(names(raw_df), flagged), modeled))
}

build_development_dataset <- function(root) {
  raw <- as.data.frame(read_development_raw(root), stringsAsFactors = FALSE, check.names = FALSE)
  mapping <- load_feature_mapping(root)
  modeled <- extract_harmonized_features(raw, mapping, "development")
  modeled$severe_outcome <- derive_development_outcome(raw)
  modeled <- modeled[!is.na(modeled$severe_outcome), , drop = FALSE]
  utils::write.csv(modeled, file.path(root, "results", "datasets", "development_model_dataset.csv"), row.names = FALSE, na = "")
  metadata <- data.frame(
    cohort = "development",
    n_rows = nrow(modeled),
    n_events = sum(modeled$severe_outcome == "Yes", na.rm = TRUE),
    event_rate = mean(modeled$severe_outcome == "Yes", na.rm = TRUE)
  )
  utils::write.csv(metadata, file.path(root, "results", "metrics", "development_dataset_summary.csv"), row.names = FALSE, na = "")
  append_project_log(
    root,
    "01 Build Development Dataset",
    c(
      sprintf("- Source file: `%s`", get_data_sources(root)$development_raw),
      sprintf("- Rows retained: %s", nrow(modeled)),
      sprintf("- Severe outcomes (`dindo_scores >= 3`): %s", sum(modeled$severe_outcome == "Yes", na.rm = TRUE)),
      sprintf("- Modeling features retained: %s", ncol(modeled) - 1)
    )
  )
  invisible(modeled)
}

build_external_dataset <- function(root) {
  raw <- read_external_raw(root)
  mapping <- load_feature_mapping(root)
  exclusions <- load_feature_exclusions(root)
  modeled <- extract_harmonized_features(raw, mapping, "external")
  modeled$severe_outcome <- derive_external_outcome(raw, root)
  utils::write.csv(modeled, file.path(root, "results", "datasets", "external_model_dataset.csv"), row.names = FALSE, na = "")
  descriptive_columns <- list_descriptive_only_columns(raw, mapping, exclusions, "external")
  descriptive <- raw[, descriptive_columns, drop = FALSE]
  utils::write.csv(descriptive, file.path(root, "results", "datasets", "external_descriptive_only_dataset.csv"), row.names = FALSE, na = "")
  inventory <- data.frame(column_name = descriptive_columns, description_role = "Descriptive only")
  utils::write.csv(inventory, file.path(root, "results", "metrics", "external_descriptive_columns.csv"), row.names = FALSE, na = "")
  metadata <- data.frame(
    cohort = "external",
    n_rows = nrow(modeled),
    n_events = sum(modeled$severe_outcome == "Yes", na.rm = TRUE),
    event_rate = mean(modeled$severe_outcome == "Yes", na.rm = TRUE)
  )
  utils::write.csv(metadata, file.path(root, "results", "metrics", "external_dataset_summary.csv"), row.names = FALSE, na = "")
  append_project_log(
    root,
    "02 Build External Dataset",
    c(
      sprintf("- Source file: `%s`", get_data_sources(root)$external_raw),
      sprintf("- Rows retained for validation: %s", nrow(modeled)),
      sprintf("- Prespecified severe external outcomes: %s", sum(modeled$severe_outcome == "Yes", na.rm = TRUE)),
      sprintf("- Descriptive-only columns retained outside the model matrix: %s", length(descriptive_columns))
    )
  )
  invisible(modeled)
}
