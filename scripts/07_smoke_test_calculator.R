source(file.path(getwd(), "R", "utils.R"))

root <- find_project_root()
script_path <- file.path(root, "scripts", "21_bundle_calculator_assets.R")
source(script_path)

bundle_env <- new.env(parent = globalenv())
sys.source(file.path(root, "calculator", "R", "app_bundle.R"), envir = bundle_env)
bundle <- bundle_env$load_stacked_ensemble_calculator_bundle_local(file.path(root, "calculator"))
sample_row <- as.list(stats::setNames(rep(NA, length(bundle$field_spec$field)), bundle$field_spec$field))
prediction <- bundle_env$calculate_stacked_ensemble_risk_local(sample_row, bundle)
stopifnot(is.finite(prediction$probability), prediction$probability >= 0, prediction$probability <= 1)
stopifnot(is.finite(prediction$percentile), prediction$percentile >= 0, prediction$percentile <= 100)
stopifnot(nrow(prediction$component_table) == 3)

app_env <- new.env(parent = globalenv())
sys.source(file.path(root, "calculator", "app.R"), envir = app_env)
stopifnot(exists("app", envir = app_env))

cat("Calculator smoke test passed.\n")
