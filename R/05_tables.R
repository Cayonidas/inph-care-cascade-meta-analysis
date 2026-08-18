write_model_object <- function(result, id) {
  if (!is.null(result$glmm$model)) {
    saveRDS(result$glmm$model, file.path("results/models", paste0(id, "_GLMM.rds")))
  }
  if (!is.null(result$iv) && !is.null(result$iv$model)) {
    saveRDS(result$iv$model, file.path("results/models", paste0(id, "_IV_REML_HK.rds")))
  }
}

model_eligibility_table <- function(imported, config) {
  imported$manifest |>
    dplyr::filter(set_id == config$strict_set, include_pool %in% TRUE) |>
    dplyr::group_by(analysis_id, analysis_label) |>
    dplyr::summarise(
      k = dplyr::n_distinct(study_id),
      n_total = sum(denominator, na.rm = TRUE),
      distinct_countries = dplyr::n_distinct(country),
      min_year = min(year, na.rm = TRUE),
      max_year = max(year, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      synthesis = dplyr::if_else(
        k >= config$minimum_k_pool, "Random-effects meta-analysis", "Structured synthesis"
      ),
      meta_regression = dplyr::if_else(
        k >= config$minimum_k_meta_regression, "Eligible if clinically coherent", "Not eligible"
      ),
      small_study_tests = dplyr::if_else(
        k >= config$minimum_k_small_study, "Exploratory only", "Not performed"
      )
    )
}

study_characteristics_table <- function(imported) {
  used_ids <- imported$manifest |>
    dplyr::filter(include_pool %in% TRUE) |>
    dplyr::distinct(study_id)

  imported$studies |>
    dplyr::semi_join(used_ids, by = "study_id") |>
    dplyr::arrange(year, study_id)
}

study_effects_table <- function(models) {
  purrr::imap_dfr(models$grid, function(result, id) {
    result$glmm$data |>
      dplyr::transmute(
        analysis_id = id,
        study_id, year, country, design, entry_setting, test_type,
        numerator, denominator, proportion, ci_low, ci_high,
        observed_nonprogression = 1 - proportion,
        source_type, decision_note
      )
  })
}

format_meta_summary_for_manuscript <- function(meta_summary) {
  meta_summary |>
    dplyr::mutate(
      analysis_label = unname(analysis_labels[analysis_id]),
      pooled_completion_95_ci = dplyr::if_else(
        status == "pooled", format_pct_ci(estimate, ci_low, ci_high), NA_character_
      ),
      observed_nonprogression = dplyr::if_else(
        status == "pooled", scales::percent(nonprogression, accuracy = 0.1), NA_character_
      ),
      prediction_interval = dplyr::if_else(
        status == "pooled" & !is.na(pi_low),
        paste0(
          scales::percent(pi_low, accuracy = 0.1), " to ",
          scales::percent(pi_high, accuracy = 0.1)
        ),
        NA_character_
      )
    ) |>
    dplyr::select(
      analysis_id, analysis_label, status, k, n_total, events_total,
      pooled_completion_95_ci, observed_nonprogression, prediction_interval,
      tau2, i2, q, q_p
    )
}

write_analysis_tables <- function(imported, contextual, models, config) {
  eligibility <- model_eligibility_table(imported, config)
  characteristics <- study_characteristics_table(imported)
  effects <- study_effects_table(models)
  manuscript_meta <- format_meta_summary_for_manuscript(models$meta_summary)

  tables <- list(
    meta_summary = models$meta_summary,
    manuscript_meta = manuscript_meta,
    iv_sensitivity = models$iv_summary,
    sensitivity_grid = models$sensitivity,
    leave_one_out = models$leave_one_out,
    model_eligibility = eligibility,
    study_characteristics = characteristics,
    study_effects = effects,
    binary_comparisons = models$binary_comparisons,
    continuous_comparisons = models$continuous_comparisons,
    barriers = contextual$barriers,
    delays = contextual$delays,
    facilities = contextual$facilities,
    disparities = contextual$disparities,
    risk_of_bias = contextual$risk_of_bias,
    certainty = contextual$certainty
  )

  purrr::iwalk(tables, function(data, name) {
    readr::write_csv(data, file.path("results/tables", paste0(name, ".csv")))
  })

  openxlsx::write.xlsx(
    tables,
    file = "results/tables/iNPH_Analysis_Results.xlsx",
    asTable = TRUE,
    overwrite = TRUE,
    keepNA = TRUE
  )

  purrr::iwalk(models$grid, write_model_object)
  invisible(tables)
}
