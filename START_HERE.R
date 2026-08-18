# START HERE ---------------------------------------------------------------
# 1) Clone or fully extract the complete repository.
# 2) Open iNPH_MetaAnalysis.Rproj in RStudio.
# 3) Open this file and click Source.

if (!file.exists("run_all.R") || !file.exists("config/analysis_config.yml")) {
  stop(
    paste(
      "Project files were not found in the current working directory.",
      "Open iNPH_MetaAnalysis.Rproj in RStudio and run START_HERE.R again.",
      sep = "\n"
    ),
    call. = FALSE
  )
}

message("Checking and installing the required R packages...")
source("R/00_packages.R")

message("Running the complete iNPH analysis pipeline...")
source("run_all.R")

message(
  paste(
    "Finished.",
    "The complete reproducibility output is available at:",
    normalizePath("results", mustWork = FALSE),
    sep = "\n"
  )
)
