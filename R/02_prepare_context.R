classify_barrier <- function(reason, stage, note = NA_character_) {
  text <- stringr::str_to_lower(paste(reason, stage, note, sep = " | "))

  dplyr::case_when(
    stringr::str_detect(text, "alternative|not inph|not i?nph|other diagn|reclass|differential") ~
      "Diagnostic reclassification / alternative diagnosis",
    stringr::str_detect(text, "test|tap|lumbar|drain|eld|infusion|work-up|workup|assessment") &
      stringr::str_detect(text, "refus|declin|fail|impossible|not complete|stopp|not performed|did not") ~
      "Diagnostic-test non-completion",
    stringr::str_detect(text, "contraind|comorbid|frail|medical|surgical risk|ineligible|not eligible") ~
      "Medical or surgical non-eligibility",
    stringr::str_detect(text, "negative|no benefit|insufficient|poor candidate|not recommend|low likelihood") ~
      "Insufficient expected benefit / negative assessment",
    stringr::str_detect(text, "refus|declin|preference|family|patient choice") ~
      "Patient or family preference",
    stringr::str_detect(text, "wait|capacity|resource|availability|ongoing|not yet|delay") ~
      "Waiting or system capacity",
    stringr::str_detect(text, "lost|follow-up|follow up|non-attend|referral") ~
      "Referral or follow-up loss",
    stringr::str_detect(text, "participation|research|consent|study exclusion") ~
      "Research selection / attrition",
    TRUE ~ "Other / unclear"
  )
}

classify_delay <- function(interval_definition) {
  text <- stringr::str_to_lower(interval_definition)

  dplyr::case_when(
    stringr::str_detect(text, "documentation.*diagnosis|onset.*diagnosis|duration at diagnosis") ~
      "Onset/documentation to diagnosis",
    stringr::str_detect(text, "onset.*treatment|onset.*shunt|symptom.*treatment|first symptom.*shunt") ~
      "Symptom onset to treatment",
    stringr::str_detect(text, "assessment.*hvlp|assessment.*tap|assessment.*test") ~
      "Specialist assessment to diagnostic test",
    stringr::str_detect(text, "hvlp.*neurosurg|tap.*neurosurg|test.*neurosurg") ~
      "Diagnostic test to neurosurgical evaluation",
    stringr::str_detect(text, "hvlp.*shunt|tap.*shunt|decision.*shunt|test.*shunt") ~
      "Diagnostic test/decision to shunt",
    stringr::str_detect(text, "assessment.*shunt|evaluation.*shunt") ~
      "Specialist assessment to shunt",
    TRUE ~ "Other symptom or care interval"
  )
}

to_months <- function(value, unit) {
  unit <- stringr::str_to_lower(clean_text(unit))
  dplyr::case_when(
    unit %in% c("day", "days") ~ as.numeric(value) / 30.4375,
    unit %in% c("week", "weeks") ~ as.numeric(value) * 7 / 30.4375,
    unit %in% c("month", "months") ~ as.numeric(value),
    unit %in% c("year", "years") ~ as.numeric(value) * 12,
    TRUE ~ NA_real_
  )
}

add_exact_intervals <- function(data, numerator = "numerator", denominator = "denominator") {
  data <- data |>
    dplyr::select(-dplyr::any_of(c("ci_low", "ci_high")))
  ci <- purrr::map2_dfr(
    data[[numerator]], data[[denominator]],
    ~ exact_binomial_ci(as.numeric(.x), as.numeric(.y))
  )
  dplyr::bind_cols(data, ci |>
    dplyr::select(ci_low, ci_high))
}

read_comparison_config <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, trim_ws = TRUE, na = c("", "NA")) |>
    janitor::clean_names() |>
    dplyr::mutate(dplyr::across(where(is.character), clean_text))
}

prepare_contextual_data <- function(imported) {
  barriers <- imported$barriers |>
    dplyr::mutate(
      count = as.numeric(count),
      denominator = as.numeric(denominator),
      proportion = count / denominator,
      barrier_category = classify_barrier(
        barrier_reason, stage, interpretation_note
      )
    ) |>
    add_exact_intervals("count", "denominator")

  facilities <- imported$facilities |>
    dplyr::mutate(
      numerator = as.numeric(numerator),
      denominator = as.numeric(denominator),
      proportion = numerator / denominator
    ) |>
    add_exact_intervals()

  delays <- imported$delays |>
    dplyr::mutate(
      value = as.numeric(value),
      n = as.numeric(n),
      delay_domain = classify_delay(interval_definition),
      value_months = to_months(value, unit),
      statistic_group = dplyr::case_when(
        stringr::str_detect(stringr::str_to_lower(statistic), "median") ~ "Median",
        stringr::str_detect(stringr::str_to_lower(statistic), "mean") ~ "Mean",
        TRUE ~ "Other/approximate"
      ),
      full_text_status = dplyr::if_else(
        stringr::str_detect(stringr::str_to_lower(meta_analysis_note), "candidate|full text required"),
        "Pending full-text verification", "Full-text extracted"
      )
    )

  disparities <- imported$disparities |>
    dplyr::mutate(estimate = as.numeric(estimate))

  binary_comparisons <- read_comparison_config("config/binary_comparisons.csv") |>
    dplyr::mutate(
      dplyr::across(c(event1, total1, event0, total0), as.numeric)
    )

  continuous_comparisons <- read_comparison_config("config/continuous_comparisons.csv") |>
    dplyr::mutate(
      dplyr::across(c(mean1, sd1, n1, mean0, sd0, n0), as.numeric)
    )

  sensitivity_sets <- read_comparison_config("config/sensitivity_sets.csv") |>
    dplyr::mutate(
      year_min = as.numeric(year_min),
      denominator_min = as.numeric(denominator_min)
    )

  risk_of_bias <- read_comparison_config("config/risk_of_bias.csv")
  certainty <- read_comparison_config("config/certainty_assessment.csv")

  stop_if(any(barriers$count > barriers$denominator, na.rm = TRUE),
          "A barrier count exceeds its denominator.")
  stop_if(any(facilities$numerator > facilities$denominator, na.rm = TRUE),
          "A facility numerator exceeds its denominator.")
  stop_if(any(binary_comparisons$event1 > binary_comparisons$total1 |
                binary_comparisons$event0 > binary_comparisons$total0),
          "A binary comparison event count exceeds its group total.")

  list(
    barriers = barriers,
    facilities = facilities,
    delays = delays,
    disparities = disparities,
    binary_comparisons = binary_comparisons,
    continuous_comparisons = continuous_comparisons,
    sensitivity_sets = sensitivity_sets,
    risk_of_bias = risk_of_bias,
    certainty = certainty
  )
}
