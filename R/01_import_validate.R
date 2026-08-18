read_master_sheet <- function(path, sheet) {
  readxl::read_excel(path, sheet = sheet, skip = 3) |>
    janitor::clean_names() |>
    dplyr::mutate(dplyr::across(where(is.character), clean_text))
}

import_and_validate <- function(config) {
  workbook_path <- config$master_workbook
  stop_if(!file.exists(workbook_path), paste("Master workbook not found:", workbook_path))

  transitions <- read_master_sheet(workbook_path, "Transitions") |>
    dplyr::mutate(source_type = "reported")

  studies <- read_master_sheet(workbook_path, "Study_Master")
  barriers <- read_master_sheet(workbook_path, "Barriers")
  facilities <- read_master_sheet(workbook_path, "Facility_Survey")
  delays <- read_master_sheet(workbook_path, "Delays")
  disparities <- read_master_sheet(workbook_path, "Disparities")
  overlap <- read_master_sheet(workbook_path, "Overlap_Risk")
  audit <- read_master_sheet(workbook_path, "Audit_Notes")

  derived <- readr::read_csv(
    "config/derived_effects.csv", show_col_types = FALSE, trim_ws = TRUE
  ) |>
    janitor::clean_names() |>
    dplyr::mutate(
      dplyr::across(where(is.character), clean_text),
      source_type = "derived",
      proportion = numerator / denominator,
      complement = 1 - proportion
    )

  all_effects <- dplyr::bind_rows(transitions, derived) |>
    dplyr::mutate(
      numerator = as.numeric(numerator),
      denominator = as.numeric(denominator),
      proportion = numerator / denominator,
      complement = 1 - proportion,
      effect_key = make_effect_key(study_id, stage, estimand)
    )

  invalid <- all_effects |>
    dplyr::filter(
      is.na(numerator) | is.na(denominator) | denominator <= 0 |
        numerator < 0 | numerator > denominator
    )
  if (nrow(invalid) > 0L) {
    readr::write_csv(invalid, "results/logs/invalid_effects.csv")
    stop("Invalid numerator/denominator values found; see results/logs/invalid_effects.csv.", call. = FALSE)
  }

  duplicated_effects <- all_effects |>
    dplyr::count(effect_key, name = "n") |>
    dplyr::filter(n > 1L)
  if (nrow(duplicated_effects) > 0L) {
    readr::write_csv(duplicated_effects, "results/logs/duplicated_effect_keys.csv")
    stop("Duplicated source effect keys found; see results/logs/duplicated_effect_keys.csv.", call. = FALSE)
  }

  effect_map <- readr::read_csv(
    "config/effect_map.csv", show_col_types = FALSE, trim_ws = TRUE,
    na = c("", "NA")
  ) |>
    janitor::clean_names() |>
    dplyr::mutate(
      dplyr::across(where(is.character), clean_text),
      effect_key = make_effect_key(study_id, stage, estimand),
      include_pool = as.logical(include_pool),
      timepoint_months = as.numeric(timepoint_months)
    )

  duplicate_map <- effect_map |>
    dplyr::count(effect_key, analysis_id, set_id, name = "n") |>
    dplyr::filter(n > 1L)
  if (nrow(duplicate_map) > 0L) {
    readr::write_csv(duplicate_map, "results/logs/duplicated_effect_map.csv")
    stop("Duplicated analysis-map rows found; see results/logs/duplicated_effect_map.csv.", call. = FALSE)
  }

  unmatched_map <- effect_map |>
    dplyr::anti_join(all_effects, by = "effect_key")
  if (nrow(unmatched_map) > 0L) {
    readr::write_csv(unmatched_map, "results/logs/unmatched_effect_map.csv")
    stop(
      "The analysis map contains effects not found in the workbook/derived file; see results/logs/unmatched_effect_map.csv.",
      call. = FALSE
    )
  }

  manifest <- effect_map |>
    dplyr::select(
      analysis_id, analysis_label, set_id, entry_setting, test_type,
      timepoint_months, overlap_cluster, include_pool, decision_note, effect_key
    ) |>
    dplyr::inner_join(all_effects, by = "effect_key", relationship = "many-to-one") |>
    dplyr::left_join(
      studies |>
        dplyr::select(
          study_id, study_year = year, country, design, base_population,
          synthesis_status, main_bias_limitation
        ),
      by = "study_id"
    ) |>
    dplyr::mutate(
      year = dplyr::coalesce(as.numeric(study_year), as.numeric(year)),
      study_label = paste0(study_id, " (", year, ")")
    )

  unmapped_effects <- all_effects |>
    dplyr::anti_join(effect_map |>
      dplyr::distinct(effect_key), by = "effect_key")

  readr::write_csv(manifest, "results/tables/analysis_manifest.csv")
  readr::write_csv(unmapped_effects, "results/tables/unmapped_effects.csv")

  list(
    workbook_path = workbook_path,
    transitions = transitions,
    derived = derived,
    all_effects = all_effects,
    studies = studies,
    barriers = barriers,
    facilities = facilities,
    delays = delays,
    disparities = disparities,
    overlap = overlap,
    audit = audit,
    effect_map = effect_map,
    manifest = manifest,
    unmapped_effects = unmapped_effects
  )
}

