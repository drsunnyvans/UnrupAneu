source(file.path(getwd(), "R", "utils.R"))

initialize_r_library_paths()
ensure_packages(c("shiny", "bslib", "xgboost", "nnet"))

root <- find_project_root()
shiny::runApp(file.path(root, "calculator"), launch.browser = FALSE)
