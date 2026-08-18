options(stringsAsFactors = FALSE, scipen = 999)

source("R/helpers.R")
ensure_output_dirs()

required_packages <- c(
  "binom", "dplyr", "forcats", "fs", "ggplot2", "ggrepel", "gt",
  "janitor", "metafor", "openxlsx", "patchwork", "purrr", "ragg",
  "readr", "readxl", "scales", "stringr", "tibble", "tidyr", "yaml"
)
missing_packages <- required_packages[!vapply(
  required_packages, requireNamespace, logical(1), quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing R packages: ", paste(missing_packages, collapse = ", "),
    ". Run source('R/00_packages.R') and rerun the pipeline.",
    call. = FALSE
  )
}

source("R/01_import_validate.R")
source("R/02_prepare_context.R")
source("R/03_meta_models.R")
source("R/04_figures.R")
source("R/05_tables.R")

config <- yaml::read_yaml("config/analysis_config.yml")
set.seed(config$seed)

message("1/5 Importing and validating the master extraction...")
imported <- import_and_validate(config)

message("2/5 Preparing barriers, delays, facility, disparity and comparison modules...")
contextual <- prepare_contextual_data(imported)

message("3/5 Fitting prespecified models and sensitivity analyses...")
models <- run_all_models(imported, contextual, config)

message("4/5 Writing manuscript and supplementary tables...")
tables <- write_analysis_tables(imported, contextual, models, config)

message("5/5 Generating publication figures...")
generate_all_figures(imported, contextual, models, config)

writeLines(capture.output(sessionInfo()), "results/logs/sessionInfo.txt")
writeLines(
  c(
    paste("Pipeline completed:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
    paste("Master workbook:", normalizePath(config$master_workbook)),
    paste("Mapped analysis rows:", nrow(imported$manifest)),
    paste("Unmapped extracted effects:", nrow(imported$unmapped_effects))
  ),
  "results/logs/run_summary.txt"
)

message("Analysis complete. See results/tables and results/figures.")
