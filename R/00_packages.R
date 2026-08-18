required_packages <- c(
  "binom", "dplyr", "forcats", "fs", "ggplot2", "ggrepel", "gt",
  "janitor", "metafor", "openxlsx", "patchwork", "purrr", "ragg",
  "readr", "readxl", "scales", "stringr", "tibble", "tidyr", "yaml"
)

installed <- rownames(installed.packages())
missing <- setdiff(required_packages, installed)

if (length(missing) > 0L) {
  message("Installing missing packages: ", paste(missing, collapse = ", "))
  install.packages(missing, repos = "https://cloud.r-project.org", dependencies = TRUE)
} else {
  message("All required packages are already installed.")
}

