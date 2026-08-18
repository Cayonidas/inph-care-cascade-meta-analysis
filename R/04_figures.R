forest_plot <- function(model_result, title = NULL, include_caption = TRUE) {
  data <- model_result$data |>
    dplyr::arrange(year, study_id) |>
    dplyr::mutate(
      display_label = citation_label(study_id, year),
      estimate_text = format_pct_ci(proportion, ci_low, ci_high),
      y = rev(seq_len(dplyr::n()))
    )

  summary <- model_result$summary
  pooled <- model_result$status == "pooled"
  pooled_text <- if (pooled) {
    format_pct_ci(summary$estimate, summary$ci_low, summary$ci_high)
  } else {
    paste0("Not pooled: ", model_result$reason)
  }

  subtitle <- paste0(
    "Exact study confidence intervals; ",
    if (pooled) "random-effects binomial-normal GLMM" else "structured study estimates"
  )
  caption <- if (pooled && !is.na(summary$pi_low)) {
    paste0(
      "Pooled estimate ", pooled_text,
      "; 95% prediction interval ",
      format_pct_range(summary$pi_low, summary$pi_high),
      ". Complement is observed non-progression, not automatically avoidable under-treatment."
    )
  } else {
    "Complement is observed non-progression, not automatically avoidable under-treatment."
  }

  plot <- ggplot2::ggplot(data) +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, y = y, yend = y),
      linewidth = 0.55, color = "#4D4D4D"
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = proportion, y = y, size = denominator),
      shape = 15, color = "#17365D"
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = 1.03, y = y, label = estimate_text),
      hjust = 0, size = 3.1, color = "#262626"
    ) +
    ggplot2::scale_size_continuous(range = c(2.2, 5.5), guide = "none") +
    ggplot2::scale_x_continuous(
      limits = c(0, 1.36),
      breaks = c(0, 0.25, 0.5, 0.75, 1),
      labels = scales::label_percent(accuracy = 1),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::scale_y_continuous(
      breaks = c(0, data$y),
      labels = c("Random-effects model", data$display_label),
      expand = ggplot2::expansion(add = c(0.8, 0.8))
    ) +
    ggplot2::labs(
      title = title %||% analysis_labels[[model_result$analysis_id]],
      subtitle = subtitle,
      x = "Completion proportion", y = NULL,
      caption = if (include_caption) caption else NULL
    ) +
    theme_inph() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(color = "#262626"),
      plot.caption = ggplot2::element_text(size = 8.5)
    )

  if (pooled) {
    plot <- plot +
      ggplot2::geom_segment(
        data = summary,
        ggplot2::aes(x = ci_low, xend = ci_high, y = 0, yend = 0),
        linewidth = 1.1, color = "#B44C43", inherit.aes = FALSE
      ) +
      ggplot2::geom_point(
        data = summary,
        ggplot2::aes(x = estimate, y = 0),
        shape = 23, size = 4.8, fill = "#B44C43", color = "#7F2822",
        inherit.aes = FALSE
      ) +
      ggplot2::annotate(
        "text", x = 1.03, y = 0, label = pooled_text,
        hjust = 0, size = 3.1, fontface = "bold", color = "#7F2822"
      )
  } else {
    plot <- plot +
      ggplot2::annotate(
        "text", x = 1.03, y = 0, label = pooled_text,
        hjust = 0, size = 3.0, color = "#7F2822"
      )
  }

  plot
}

barrier_matrix_plot <- function(barriers) {
  plot_data <- barriers |>
    dplyr::filter(level %in% c("Patient", "Patient/procedure")) |>
    dplyr::mutate(
      stage_group = dplyr::case_when(
        stringr::str_detect(stage, stringr::regex("particip|recogn|screen|referral|follow", ignore_case = TRUE)) ~ "Recognition/referral",
        stringr::str_detect(stage, stringr::regex("diagnos|work-up|test", ignore_case = TRUE)) ~ "Diagnostic evaluation",
        stringr::str_detect(stage, stringr::regex("eligib|recommend|decision", ignore_case = TRUE)) ~ "Treatment selection",
        stringr::str_detect(stage, stringr::regex("uptake|shunt|surgery|treatment", ignore_case = TRUE)) ~ "Treatment uptake",
        TRUE ~ "Other/unclear stage"
      )
    ) |>
    dplyr::distinct(study_id, stage_group, barrier_category) |>
    dplyr::count(stage_group, barrier_category, name = "k") |>
    tidyr::complete(stage_group, barrier_category, fill = list(k = 0L))

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = stage_group, y = barrier_category, fill = k)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.8) +
    ggplot2::geom_text(ggplot2::aes(label = dplyr::if_else(k == 0L, "", paste0("k=", k))), size = 3.2) +
    ggplot2::scale_fill_gradient(low = "#EFF4F7", high = "#2F6B8A", breaks = scales::breaks_width(1)) +
    ggplot2::labs(
      title = "Where reasons for non-progression are reported",
      subtitle = "Number of distinct studies reporting each reason category; cells do not represent pooled prevalence",
      x = "Care-cascade stage", y = NULL, fill = "Studies"
    ) +
    theme_inph(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))
}

evidence_map_plot <- function(manifest) {
  counts <- manifest |>
    dplyr::filter(set_id == "primary", include_pool %in% TRUE) |>
    dplyr::count(analysis_id, analysis_label, name = "k") |>
    dplyr::mutate(
      analysis_label = factor(
        analysis_label,
        levels = rev(unname(analysis_labels))
      )
    )

  ggplot2::ggplot(counts, ggplot2::aes(x = k, y = analysis_label)) +
    ggplot2::geom_col(width = 0.58, fill = "#3B6E8F") +
    ggplot2::geom_text(
      ggplot2::aes(label = paste0("k=", k)),
      hjust = -0.15, color = "#17365D", fontface = "bold"
    ) +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0, 0.15))) +
    ggplot2::labs(
      title = "Evidence available across the iNPH care cascade",
      subtitle = "Counts are independent study reports in the prespecified strict set; stages are not multiplied across cohorts",
      x = "Number of studies", y = NULL
    ) +
    theme_inph()
}

barrier_plot <- function(barriers) {
  plot_data <- barriers |>
    dplyr::filter(level %in% c("Patient", "Patient/procedure")) |>
    dplyr::mutate(
      label = paste0(study_id, ": ", barrier_reason),
      label = stringr::str_trunc(label, 62),
      label = forcats::fct_reorder(label, proportion)
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = proportion, y = label)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = label),
      color = "#8C8C8C", linewidth = 0.45
    ) +
    ggplot2::geom_point(color = "#B44C43", size = 2.2) +
    ggplot2::facet_wrap(~barrier_category, scales = "free_y", ncol = 2) +
    ggplot2::scale_x_continuous(
      labels = scales::label_percent(accuracy = 1), limits = c(0, 1)
    ) +
    ggplot2::labs(
      title = "Reported reasons for non-progression in the iNPH care pathway",
      subtitle = "Study-specific proportions with exact 95% CIs; denominators remain stage-specific and are not pooled by default",
      x = "Proportion within the reported stage denominator", y = NULL
    ) +
    theme_inph(base_size = 9) +
    ggplot2::theme(strip.text = ggplot2::element_text(size = 8.5))
}

delay_plot <- function(delays) {
  plot_data <- delays |>
    dplyr::filter(
      !is.na(value_months), value_months > 0,
      full_text_status == "Full-text extracted"
    ) |>
    dplyr::mutate(
      label = paste0(author_only(study_id), " - ", statistic_group),
      label = forcats::fct_reorder(label, value_months)
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = value_months, y = label, shape = statistic_group, color = full_text_status)
  ) +
    ggplot2::geom_point(size = 2.8) +
    ggplot2::facet_wrap(~delay_domain, scales = "free_y", ncol = 2) +
    ggplot2::scale_x_log10(
      breaks = c(0.25, 0.5, 1, 3, 6, 12, 24, 48, 96),
      labels = c("0.25", "0.5", "1", "3", "6", "12", "24", "48", "96")
    ) +
    ggplot2::scale_color_manual(values = c("Full-text extracted" = "#17365D")) +
    ggplot2::labs(
      title = "Delays reported across non-equivalent points in the care pathway",
      subtitle = "Displayed on a log scale in months; means, medians and approximate values are intentionally not pooled",
      x = "Reported interval (months, log scale)", y = NULL,
      shape = "Statistic", color = "Evidence status"
    ) +
    theme_inph(base_size = 9)
}

facility_plot <- function(facilities) {
  plot_data <- facilities |>
    dplyr::mutate(
      label = measure,
      label = stringr::str_trunc(label, 68),
      label = forcats::fct_reorder(label, proportion)
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = proportion, y = label)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = label),
      linewidth = 0.45, color = "#8C8C8C"
    ) +
    ggplot2::geom_point(color = "#2F6B8A", size = 2.1) +
    ggplot2::facet_wrap(~study_id, scales = "free_y", ncol = 1) +
    ggplot2::scale_x_continuous(labels = scales::label_percent(), limits = c(0, 1)) +
    ggplot2::labs(
      title = "Facility capability, practice and hesitation",
      subtitle = "Facility-level estimates with exact 95% CIs; these are not patient treatment-gap proportions",
      x = "Proportion of the stated facility denominator", y = NULL
    ) +
    theme_inph(base_size = 9)
}

disparity_plot <- function(disparities) {
  plot_data <- disparities |>
    dplyr::filter(!is.na(estimate)) |>
    dplyr::mutate(label = paste0(domain, ": ", group))

  ggplot2::ggplot(plot_data, ggplot2::aes(x = estimate, y = forcats::fct_reorder(label, estimate))) +
    ggplot2::geom_point(color = "#6B4C8A", size = 2.5) +
    ggplot2::facet_wrap(~unit, scales = "free_x", ncol = 1) +
    ggplot2::labs(
      title = "Differential diagnosis and ascertainment signals",
      subtitle = "Administrative rates and association measures are separated by unit and are not pooled",
      x = "Reported estimate", y = NULL
    ) +
    theme_inph(base_size = 9)
}

binary_comparison_plot <- function(data) {
  plot_data <- data |>
    dplyr::mutate(
      label = paste0(author_only(study_id), ": ", outcome),
      estimate_text = sprintf("%.2f [%.2f, %.2f]", estimate, ci_low, ci_high)
    )

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = estimate, y = forcats::fct_reorder(label, estimate))
  ) +
    ggplot2::geom_vline(xintercept = 1, linetype = 2, color = "#737373") +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = label),
      linewidth = 0.55, color = "#4D4D4D"
    ) +
    ggplot2::geom_point(ggplot2::aes(color = role), size = 2.7) +
    ggplot2::geom_text(
      ggplot2::aes(x = ci_high * 1.12, label = estimate_text),
      hjust = 0, size = 3.0, show.legend = FALSE
    ) +
    ggplot2::facet_wrap(~role, scales = "free_y", ncol = 1) +
    ggplot2::scale_x_log10(
      expand = ggplot2::expansion(mult = c(0.05, 0.28))
    ) +
    ggplot2::labs(
      title = "Within-study comparative evidence",
      subtitle = "Unadjusted risk ratios; each row is a separate non-randomized comparison and no across-outcome pooling is performed",
      x = "Risk ratio (log scale; values >1 favor the first named group for beneficial outcomes)", y = NULL, color = "Evidence role"
    ) +
    theme_inph() +
    ggplot2::coord_cartesian(clip = "off")
}

continuous_comparison_plot <- function(data) {
  plot_data <- data |>
    dplyr::mutate(estimate_text = sprintf("%.1f [%.1f, %.1f]", estimate, ci_low, ci_high))

  ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = estimate, y = forcats::fct_reorder(outcome, estimate))
  ) +
    ggplot2::geom_vline(xintercept = 0, linetype = 2, color = "#737373") +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = outcome),
      linewidth = 0.55, color = "#4D4D4D"
    ) +
    ggplot2::geom_point(color = "#B44C43", size = 2.7) +
    ggplot2::geom_text(
      ggplot2::aes(x = ci_high + 8, label = estimate_text),
      hjust = 0, size = 3.0
    ) +
    ggplot2::labs(
      title = "Effect of protocolization on care intervals",
      subtitle = "Mean difference in days (standardized protocol minus pre-protocol); negative values indicate shorter intervals",
      x = "Mean difference (days)", y = NULL
    ) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.05, 0.30))
    ) +
    theme_inph() +
    ggplot2::coord_cartesian(xlim = c(-450, 220), clip = "off")
}

sensitivity_plot <- function(data) {
  plot_data <- data |>
    dplyr::filter(
      analysis_id %in% c("P1_REFERRAL_TO_SHUNT", "P2_DIAGNOSED_TO_SHUNT"),
      status == "pooled"
    ) |>
    dplyr::mutate(
      analysis = unname(analysis_labels[analysis_id]),
      description = stringr::str_wrap(description, 45),
      description = forcats::fct_reorder(description, estimate),
      primary = sensitivity_id == "strict_primary"
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = estimate, y = description)) +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = description),
      linewidth = 0.55, color = "#666666"
    ) +
    ggplot2::geom_point(ggplot2::aes(fill = primary), shape = 21, size = 3.0, color = "#17365D") +
    ggplot2::facet_wrap(~analysis, scales = "free_y", ncol = 1) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#B44C43", `FALSE` = "white"), guide = "none") +
    ggplot2::scale_x_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = "Prespecified sensitivity analyses",
      subtitle = "Pooled proportions with 95% confidence intervals; filled points denote the strict primary analysis",
      x = "Pooled proportion", y = NULL
    ) +
    theme_inph(base_size = 9)
}

leave_one_out_plot <- function(data, meta_summary) {
  plot_data <- data |>
    dplyr::filter(analysis_id %in% c("P1_REFERRAL_TO_SHUNT", "P2_DIAGNOSED_TO_SHUNT")) |>
    dplyr::mutate(
      analysis = unname(analysis_labels[analysis_id]),
      omitted = paste0("Omit ", author_only(omitted_study)),
      omitted = forcats::fct_reorder(omitted, estimate)
    )
  references <- meta_summary |>
    dplyr::filter(analysis_id %in% c("P1_REFERRAL_TO_SHUNT", "P2_DIAGNOSED_TO_SHUNT")) |>
    dplyr::transmute(analysis = unname(analysis_labels[analysis_id]), estimate)

  ggplot2::ggplot(plot_data, ggplot2::aes(x = estimate, y = omitted)) +
    ggplot2::geom_vline(
      data = references, ggplot2::aes(xintercept = estimate),
      linetype = 2, color = "#B44C43", inherit.aes = FALSE
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(x = ci_low, xend = ci_high, yend = omitted),
      linewidth = 0.5, color = "#666666"
    ) +
    ggplot2::geom_point(color = "#17365D", size = 2.6) +
    ggplot2::facet_wrap(~analysis, scales = "free_y", ncol = 1) +
    ggplot2::scale_x_continuous(labels = scales::label_percent(accuracy = 1), limits = c(0, 1)) +
    ggplot2::labs(
      title = "Leave-one-out influence analysis",
      subtitle = "Dashed lines denote the corresponding all-study pooled estimate",
      x = "Pooled proportion after omitting one study", y = NULL
    ) +
    theme_inph(base_size = 9)
}

risk_of_bias_plot <- function(risk_of_bias) {
  if (nrow(risk_of_bias) == 0L) return(NULL)

  plot_data <- risk_of_bias |>
    dplyr::mutate(
      domain = paste0(domain_id, ". ", domain_label),
      judgment = stringr::str_to_sentence(judgment),
      year = as.numeric(stringr::str_extract(study_id, "[0-9]{4}$")),
      study_label = citation_label(study_id, year),
      domain = factor(domain, levels = unique(domain)),
      study_label = factor(study_label, levels = rev(unique(study_label)))
    )

  ggplot2::ggplot(plot_data, ggplot2::aes(x = domain, y = study_label, fill = judgment)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.8) +
    ggplot2::scale_fill_manual(values = c(
      "Low" = "#4C9F70", "Some concerns" = "#E5B84B", "High" = "#C75B58",
      "Unclear" = "#BFBFBF"
    ), drop = FALSE) +
    ggplot2::labs(
      title = "Risk-of-bias judgments",
      subtitle = "JBI prevalence/proportion domains adapted to stage-specific care-cascade estimates; no summed score",
      x = NULL, y = NULL, fill = "Judgment"
    ) +
    theme_inph(base_size = 9) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 32, hjust = 1),
      panel.grid = ggplot2::element_blank()
    )
}

generate_all_figures <- function(imported, contextual, models, config) {
  primary_plots <- purrr::map(config$primary_analyses, ~ forest_plot(models$grid[[.x]]$glmm))
  intermediate_ids <- setdiff(config$secondary_analyses, "S5_POSTSHUNT_RESPONSE_6_12M")
  intermediate_plots <- purrr::map(
    intermediate_ids,
    ~ forest_plot(models$grid[[.x]]$glmm, include_caption = FALSE)
  )
  response_plot <- forest_plot(models$grid[["S5_POSTSHUNT_RESPONSE_6_12M"]]$glmm)

  save_publication_plot(
    patchwork::wrap_plots(primary_plots, ncol = 1),
    "Figure_3_Coprimary_Forest", width = 11, height = 12
  )
  save_publication_plot(
    patchwork::wrap_plots(intermediate_plots, ncol = 2),
    "Figure_4_Intermediate_Stages_Forest", width = 15, height = 11
  )
  save_publication_plot(
    evidence_map_plot(imported$manifest),
    "Figure_2_Care_Cascade_Evidence_Map", width = 10, height = 5.8
  )
  save_publication_plot(
    barrier_matrix_plot(contextual$barriers),
    "Figure_5_Barrier_Evidence_Matrix", width = 12, height = 7.5
  )
  save_publication_plot(
    patchwork::wrap_plots(
      binary_comparison_plot(models$binary_comparisons),
      continuous_comparison_plot(models$continuous_comparisons),
      ncol = 1, heights = c(1.1, 1)
    ),
    "Figure_6_Implementation_and_Delay", width = 15, height = 13
  )
  save_publication_plot(
    response_plot,
    "Supplement_Postshunt_Response_Forest", width = 10.5, height = 6.5
  )
  save_publication_plot(
    barrier_plot(contextual$barriers),
    "Supplement_Reported_Barriers_Detailed", width = 13, height = 16
  )
  save_publication_plot(
    delay_plot(contextual$delays),
    "Supplement_Delays", width = 12, height = 12
  )
  save_publication_plot(
    facility_plot(contextual$facilities),
    "Supplement_Facility_Evidence", width = 12, height = 14
  )
  save_publication_plot(
    disparity_plot(contextual$disparities),
    "Supplement_Disparity_Evidence", width = 11, height = 9
  )
  save_publication_plot(
    binary_comparison_plot(models$binary_comparisons),
    "Supplement_Binary_Comparisons", width = 11, height = 8.5
  )
  save_publication_plot(
    continuous_comparison_plot(models$continuous_comparisons),
    "Supplement_Protocol_Delay_Comparisons", width = 11, height = 7
  )
  save_publication_plot(
    sensitivity_plot(models$sensitivity),
    "Supplement_Prespecified_Sensitivity", width = 11, height = 9
  )
  save_publication_plot(
    leave_one_out_plot(models$leave_one_out, models$meta_summary),
    "Supplement_Leave_One_Out", width = 11, height = 10
  )

  rob <- risk_of_bias_plot(contextual$risk_of_bias)
  if (!is.null(rob)) {
    save_publication_plot(rob, "Supplement_Risk_of_Bias", width = 14, height = 10.5)
  } else {
    writeLines(
      "Risk-of-bias figure skipped: config/risk_of_bias.csv contains no completed judgments.",
      "results/logs/risk_of_bias_figure_status.txt"
    )
  }

  invisible(TRUE)
}
