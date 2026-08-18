analysis_data <- function(manifest, analysis_id, set_ids = "primary") {
  manifest |>
    dplyr::filter(
      .data$analysis_id == .env$analysis_id,
      .data$set_id %in% .env$set_ids,
      .data$include_pool %in% TRUE
    )
}

validate_model_independence <- function(data, analysis_id) {
  duplicated_studies <- data |>
    dplyr::count(study_id) |>
    dplyr::filter(n > 1L)

  duplicated_clusters <- data |>
    dplyr::filter(!is.na(overlap_cluster), overlap_cluster != "") |>
    dplyr::count(overlap_cluster) |>
    dplyr::filter(n > 1L)

  stop_if(
    nrow(duplicated_studies) > 0L,
    paste("More than one effect per study entered", analysis_id)
  )
  stop_if(
    nrow(duplicated_clusters) > 0L,
    paste("More than one report from an overlap cluster entered", analysis_id)
  )
  invisible(TRUE)
}

extract_model_number <- function(model, field) {
  value <- model[[field]]
  if (is.null(value) || length(value) == 0L) NA_real_ else as.numeric(value[[1]])
}

fit_glmm_proportion <- function(data, analysis_id, minimum_k = 3L) {
  data <- data |>
    dplyr::filter(!is.na(numerator), !is.na(denominator))
  validate_model_independence(data, analysis_id)

  if (nrow(data) < minimum_k) {
    return(list(
      status = "not_pooled",
      reason = paste0("k=", nrow(data), " < minimum k=", minimum_k),
      analysis_id = analysis_id,
      data = add_exact_intervals(data),
      model = NULL,
      summary = tibble::tibble(
        analysis_id = analysis_id, model = "GLMM", status = "not_pooled",
        k = nrow(data), n_total = sum(data$denominator), events_total = sum(data$numerator),
        estimate = NA_real_, ci_low = NA_real_, ci_high = NA_real_,
        nonprogression = NA_real_, pi_low = NA_real_, pi_high = NA_real_,
        tau2 = NA_real_, i2 = NA_real_, q = NA_real_, q_p = NA_real_
      )
    ))
  }

  fit <- tryCatch(
    metafor::rma.glmm(
      measure = "PLO",
      xi = numerator,
      ni = denominator,
      data = data,
      method = "ML"
    ),
    error = function(e) e
  )

  if (inherits(fit, "error")) {
    return(list(
      status = "failed", reason = conditionMessage(fit), analysis_id = analysis_id,
      data = add_exact_intervals(data), model = NULL,
      summary = tibble::tibble(
        analysis_id = analysis_id, model = "GLMM", status = "failed",
        k = nrow(data), n_total = sum(data$denominator), events_total = sum(data$numerator),
        estimate = NA_real_, ci_low = NA_real_, ci_high = NA_real_,
        nonprogression = NA_real_, pi_low = NA_real_, pi_high = NA_real_,
        tau2 = NA_real_, i2 = NA_real_, q = NA_real_, q_p = NA_real_
      )
    ))
  }

  prediction <- predict(fit, transf = metafor::transf.ilogit)
  estimate <- safe_prediction_field(prediction, "pred")
  summary_row <- tibble::tibble(
    analysis_id = analysis_id,
    model = "Binomial-normal GLMM (logit, ML)",
    status = "pooled",
    k = fit$k,
    n_total = sum(data$denominator),
    events_total = sum(data$numerator),
    estimate = estimate,
    ci_low = safe_prediction_field(prediction, "ci.lb"),
    ci_high = safe_prediction_field(prediction, "ci.ub"),
    nonprogression = 1 - estimate,
    pi_low = safe_prediction_field(prediction, "pi.lb"),
    pi_high = safe_prediction_field(prediction, "pi.ub"),
    tau2 = extract_model_number(fit, "tau2"),
    i2 = extract_model_number(fit, "I2"),
    q = extract_model_number(fit, "QE"),
    q_p = extract_model_number(fit, "QEp")
  )

  list(
    status = "pooled", reason = NA_character_, analysis_id = analysis_id,
    data = add_exact_intervals(data), model = fit, summary = summary_row
  )
}

fit_iv_sensitivity <- function(data, analysis_id, minimum_k = 3L) {
  validate_model_independence(data, analysis_id)
  if (nrow(data) < minimum_k) return(NULL)

  es <- metafor::escalc(
    measure = "PLO", xi = numerator, ni = denominator,
    add = 0.5, to = "only0", data = data
  )
  fit <- metafor::rma.uni(
    yi = es$yi, vi = es$vi,
    method = "REML", test = "knha"
  )
  prediction <- predict(fit, transf = metafor::transf.ilogit)

  list(
    model = fit,
    summary = tibble::tibble(
      analysis_id = analysis_id,
      model = "Logit inverse-variance (REML, Hartung-Knapp)",
      status = "pooled",
      k = fit$k,
      n_total = sum(data$denominator),
      events_total = sum(data$numerator),
      estimate = safe_prediction_field(prediction, "pred"),
      ci_low = safe_prediction_field(prediction, "ci.lb"),
      ci_high = safe_prediction_field(prediction, "ci.ub"),
      nonprogression = 1 - safe_prediction_field(prediction, "pred"),
      pi_low = safe_prediction_field(prediction, "pi.lb"),
      pi_high = safe_prediction_field(prediction, "pi.ub"),
      tau2 = extract_model_number(fit, "tau2"),
      i2 = extract_model_number(fit, "I2"),
      q = extract_model_number(fit, "QE"),
      q_p = extract_model_number(fit, "QEp")
    )
  )
}

run_primary_model_grid <- function(manifest, config) {
  ids <- c(config$primary_analyses, config$secondary_analyses)
  purrr::set_names(ids) |>
    purrr::map(function(id) {
      data <- analysis_data(manifest, id, config$strict_set)
      glmm <- fit_glmm_proportion(data, id, config$minimum_k_pool)
      iv <- if (glmm$status == "pooled") {
        fit_iv_sensitivity(data, id, config$minimum_k_pool)
      } else NULL
      list(glmm = glmm, iv = iv)
    })
}

apply_sensitivity_definition <- function(manifest, definition) {
  sets <- stringr::str_split(definition$set_ids[[1]], "\\|", simplify = TRUE) |>
    as.character()
  data <- analysis_data(manifest, definition$analysis_id[[1]], sets)

  excluded <- definition$exclude_studies[[1]]
  if (!is.na(excluded) && excluded != "") {
    excluded <- stringr::str_split(excluded, "\\|", simplify = TRUE) |>
      as.character()
    data <- dplyr::filter(data, !study_id %in% excluded)
  }

  design_pattern <- definition$design_pattern[[1]]
  if (!is.na(design_pattern) && design_pattern != "") {
    data <- dplyr::filter(
      data, stringr::str_detect(design, stringr::regex(design_pattern, ignore_case = TRUE))
    )
  }
  if (!is.na(definition$year_min[[1]])) {
    data <- dplyr::filter(data, year >= definition$year_min[[1]])
  }
  if (!is.na(definition$denominator_min[[1]])) {
    data <- dplyr::filter(data, denominator >= definition$denominator_min[[1]])
  }

  data
}

run_sensitivity_grid <- function(manifest, sensitivity_sets, config) {
  purrr::map(seq_len(nrow(sensitivity_sets)), function(i) {
    definition <- sensitivity_sets[i, , drop = FALSE]
    data <- apply_sensitivity_definition(manifest, definition)
    result <- fit_glmm_proportion(
      data, definition$analysis_id[[1]], config$minimum_k_pool
    )
    result$summary |>
      dplyr::mutate(
        sensitivity_id = definition$sensitivity_id[[1]],
        description = definition$description[[1]],
        .before = model
      )
  }) |>
    dplyr::bind_rows()
}

run_leave_one_out <- function(model_result, minimum_k = 3L) {
  data <- model_result$data
  if (nrow(data) <= minimum_k || model_result$status != "pooled") {
    return(tibble::tibble())
  }

  purrr::map_dfr(data$study_id, function(omitted) {
    fit <- fit_glmm_proportion(
      dplyr::filter(data, study_id != omitted),
      paste0(model_result$analysis_id, "_omit_", omitted),
      minimum_k
    )
    fit$summary |>
      dplyr::transmute(
        analysis_id = model_result$analysis_id,
        omitted_study = omitted,
        k, estimate, ci_low, ci_high, tau2, i2
      )
  })
}

calculate_binary_comparisons <- function(data) {
  purrr::map_dfr(seq_len(nrow(data)), function(i) {
    row <- data[i, , drop = FALSE]
    es <- metafor::escalc(
      measure = "RR",
      ai = row$event1, bi = row$total1 - row$event1,
      ci = row$event0, di = row$total0 - row$event0,
      add = 0.5, to = "only0"
    )
    se <- sqrt(es$vi[[1]])
    tibble::tibble(
      comparison_id = row$comparison_id,
      study_id = row$study_id,
      outcome = row$outcome,
      group1_label = row$group1_label,
      group0_label = row$group0_label,
      estimate = exp(es$yi[[1]]),
      ci_low = exp(es$yi[[1]] - stats::qnorm(0.975) * se),
      ci_high = exp(es$yi[[1]] + stats::qnorm(0.975) * se),
      measure = "Risk ratio",
      role = row$role,
      notes = row$notes
    )
  })
}

calculate_continuous_comparisons <- function(data) {
  purrr::map_dfr(seq_len(nrow(data)), function(i) {
    row <- data[i, , drop = FALSE]
    es <- metafor::escalc(
      measure = "MD",
      m1i = row$mean1, sd1i = row$sd1, n1i = row$n1,
      m2i = row$mean0, sd2i = row$sd0, n2i = row$n0
    )
    se <- sqrt(es$vi[[1]])
    tibble::tibble(
      comparison_id = row$comparison_id,
      study_id = row$study_id,
      outcome = row$outcome,
      group1_label = row$group1_label,
      group0_label = row$group0_label,
      estimate = es$yi[[1]],
      ci_low = es$yi[[1]] - stats::qnorm(0.975) * se,
      ci_high = es$yi[[1]] + stats::qnorm(0.975) * se,
      unit = row$unit,
      measure = "Mean difference",
      role = row$role,
      notes = row$notes
    )
  })
}

run_all_models <- function(imported, contextual, config) {
  model_grid <- run_primary_model_grid(imported$manifest, config)
  sensitivity <- run_sensitivity_grid(
    imported$manifest, contextual$sensitivity_sets, config
  )
  leave_one_out <- purrr::imap_dfr(model_grid, function(result, id) {
    run_leave_one_out(result$glmm, config$minimum_k_pool)
  })

  meta_summary <- purrr::map_dfr(model_grid, ~ .x$glmm$summary)
  iv_summary <- purrr::map_dfr(model_grid, function(x) {
    if (is.null(x$iv)) tibble::tibble() else x$iv$summary
  })

  list(
    grid = model_grid,
    meta_summary = meta_summary,
    iv_summary = iv_summary,
    sensitivity = sensitivity,
    leave_one_out = leave_one_out,
    binary_comparisons = calculate_binary_comparisons(contextual$binary_comparisons),
    continuous_comparisons = calculate_continuous_comparisons(
      contextual$continuous_comparisons
    )
  )
}
