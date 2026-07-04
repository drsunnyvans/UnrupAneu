root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "R", "utils.R"))
initialize_r_library_paths()
source(file.path(root, "R", "reporting.R"))

render_final_results_report(root)
append_project_log(
  root,
  "06 Render Reports",
  c(
    "- Refreshed `reports/final_results.md` from the latest generated metrics and artifacts.",
    "- Project log remains cumulative and chronological."
  )
)
