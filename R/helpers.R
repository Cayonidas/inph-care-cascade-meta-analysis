`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) y else x
}

stop_if <- function(condition, message) {
  if (isTRUE(condition)) stop(message, call. = FALSE)
}

ensure_output_dirs <- function() {
  dirs <- c(
    "results/figures", "results/tables", "results/models", "results/logs"
  )
  purrr::walk(dirs, fs::dir_create)
  invisible(dirs)
}

clean_text <- function(x) {
  x |>
    stringr::str_replace_all("[\u2013\u2014]", "-") |>
    stringr::str_squish()
}

make_effect_key <- function(study_id, stage, estimand) {
  paste(clean_text(study_id), clean_text(stage), clean_text(estimand), sep = "||")
}

exact_binomial_ci <- function(numerator, denominator, conf.level = 0.95) {
  ci <- binom::binom.confint(
    x = numerator,
    n = denominator,
    conf.level = conf.level,
    methods = "exact"
  )
  tibble::tibble(
    estimate = numerator / denominator,
    ci_low = ci$lower,
    ci_high = ci$upper
  )
}

theme_inph <- function(base_size = 10) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = "#17365D"),
      plot.subtitle = ggplot2::element_text(color = "#595959"),
      strip.text = ggplot2::element_text(face = "bold", color = "#17365D"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_blank(),
      legend.position = "bottom",
      plot.caption = ggplot2::element_text(color = "#595959", hjust = 0),
      plot.margin = ggplot2::margin(8, 30, 8, 8)
    )
}

save_publication_plot <- function(plot, filename, width = 11, height = 7) {
  png_path <- file.path("results/figures", paste0(filename, ".png"))
  tif_path <- file.path("results/figures", paste0(filename, ".tiff"))

  ggplot2::ggsave(
    png_path, plot = plot, width = width, height = height, units = "in",
    dpi = 300, bg = "white", device = ragg::agg_png
  )
  ggplot2::ggsave(
    tif_path, plot = plot, width = width, height = height, units = "in",
    dpi = 600, bg = "white", compression = "lzw"
  )
  invisible(c(png_path, tif_path))
}

analysis_labels <- c(
  P1_REFERRAL_TO_SHUNT = "Initial suspicion/referral to shunt",
  P2_DIAGNOSED_TO_SHUNT = "Diagnosed/probable iNPH to shunt",
  S1_REFERRAL_TO_DIAGNOSIS = "Initial suspicion/referral to iNPH diagnosis",
  S2_TEST_COMPLETION = "Completion of study-defined planned specialized/invasive work-up",
  S3_TEST_POSITIVE_TO_SHUNT = "Positive prognostic test to shunt",
  S4_RECOMMENDATION_TO_SHUNT = "Surgical referral/recommendation to shunt",
  S5_POSTSHUNT_RESPONSE_6_12M = "Clinical response approximately 6-12 months after CSF diversion"
)

safe_prediction_field <- function(prediction, field) {
  value <- prediction[[field]]
  if (is.null(value) || length(value) == 0L) NA_real_ else as.numeric(value[[1]])
}

format_pct_ci <- function(est, low, high, digits = 1) {
  paste0(
    scales::percent(est, accuracy = 10^-digits), " [",
    scales::percent(low, accuracy = 10^-digits), ", ",
    scales::percent(high, accuracy = 10^-digits), "]"
  )
}

format_pct_range <- function(low, high, digits = 1) {
  paste0(
    scales::percent(low, accuracy = 10^-digits), "-",
    scales::percent(high, accuracy = 10^-digits)
  )
}

author_only <- function(study_id) {
  author_key <- study_id |>
    stringr::str_remove("_[A-Z]+.*$") |>
    stringr::str_remove("[0-9]{4}$")

  author_names <- c(
    ACOSTA = "Acosta",
    ALHUSAINI = "Alhusaini",
    ALTARAWNI = "Al-Tarawni",
    ANDREN = "Andren",
    ANILE = "Anile",
    BECHAZEDDINE = "Bech-Azeddine",
    BELZILE = "Belzile-Marsolais",
    BREAN = "Brean",
    GALLINA = "Gallina",
    GHAFFARIRAFI = "Ghaffari-Rafi",
    GIANNINI = "Giannini",
    HASSELBALCH = "Hasselbalch",
    ISEKI = "Iseki",
    JARAJ = "Jaraj",
    JUNKKARI = "Junkkari",
    KAWAI = "Kawai",
    KAZUI = "Kazui",
    KLASSEN = "Klassen",
    KURIYAMA = "Kuriyama",
    MACKI = "Macki",
    MAHR = "Mahr",
    MARMAROU = "Marmarou",
    MARTINLAEZ = "Martin-Laez",
    MOREL = "Morel",
    NAKAJIMA = "Nakajima",
    OIKE = "Oike",
    PETRELLA = "Petrella",
    POUDEL = "Poudel",
    PYYKKO = "Pyykko",
    RAZAY = "Razay",
    SADAGOPAN = "Sadagopan",
    THAVARAJASINGAM = "Thavarajasingam",
    TSENG = "Tseng",
    TUDOR = "Tudor",
    VAKILI = "Vakili",
    WILLIAMS = "Williams",
    YU = "Yu"
  )

  author <- unname(author_names[author_key])
  missing_author <- is.na(author)
  author[missing_author] <- stringr::str_to_title(author_key[missing_author])
  author
}

citation_label <- function(study_id, year) {
  paste0(author_only(study_id), " et al., ", year)
}
