# Denominator-specific transitions in the iNPH care pathway

[![Validate analysis inputs](https://github.com/Cayonidas/inph-care-cascade-meta-analysis/actions/workflows/validate-inputs.yml/badge.svg)](https://github.com/Cayonidas/inph-care-cascade-meta-analysis/actions/workflows/validate-inputs.yml)

Public analysis archive for:

> **Denominator-specific transitions from suspicion to shunt in idiopathic normal-pressure hydrocephalus: a systematic review and meta-analysis**

This repository contains the aggregate analysis inputs, data dictionary, prespecified analysis configuration, R code, model objects, tabular outputs, risk-of-bias and certainty assessments, validation records, and software-session information needed to inspect and reproduce the review's quantitative analyses.

- **Protocol registration:** PROSPERO [CRD420261458736](https://www.crd.york.ac.uk/PROSPERO/view/CRD420261458736)
- **Search coverage:** database inception to July 2026
- **Repository version:** 1.0.0
- **Public repository:** <https://github.com/Cayonidas/inph-care-cascade-meta-analysis>
- **Data level:** aggregate data extracted from published reports; no individual participant data

## Primary results reproduced by the pipeline

The primary model is a random-effects binomial-normal generalized linear mixed model with a logit link and maximum-likelihood heterogeneity estimation. The numbers below are targets for a successful reference reproduction, not crude pooled proportions.

| Estimand | Studies | Denominator sum | Pooled estimate (95% CI) |
|---|---:|---:|---:|
| Suspicion/referral to shunt | 7 | 1,646 | 39.1% (27.6–52.0) |
| Diagnosed/probable iNPH to shunt | 7 | 837 | 75.1% (57.3–87.1) |
| Suspicion/referral to diagnosis | 6 | 1,251 | 48.2% (37.0–59.6) |
| Completion of study-defined work-up | 7 | 522 | 93.1% (86.8–96.5) |
| Positive prognostic test to shunt | 5 | 312 | 90.9% (84.6–94.8) |
| Surgical recommendation/referral to shunt | 3 | 248 | 85.2% (62.0–95.3) |
| Post-diversion response at approximately 6–12 months | 5 | 318 | 80.8% (73.7–86.3) |

Full estimates, prediction intervals, heterogeneity measures, and sensitivity analyses are in [`results/tables`](results/tables).

## Repository map

| Path | Purpose |
|---|---|
| [`data/raw/iNPH_Master_ReExtraction_v4.xlsx`](data/raw/iNPH_Master_ReExtraction_v4.xlsx) | Master denominator-first extraction workbook and codebook |
| [`config`](config) | Analysis map, model sets, derived effects, PRISMA counts, risk-of-bias and certainty judgments |
| [`R`](R) | Import, validation, modelling, table, and figure functions |
| [`run_all.R`](run_all.R) | Complete analysis entry point |
| [`validate_inputs.py`](validate_inputs.py) | Independent audit of identifiers, numerator/denominator linkage, mapping, and R delimiter balance |
| [`results`](results) | Reference model objects, tables, figures, logs, and software-session record |
| [`docs/STATISTICAL_ANALYSIS_PLAN.md`](docs/STATISTICAL_ANALYSIS_PLAN.md) | Estimands, model hierarchy, sensitivity analyses, and interpretation rules |
| [`docs/DATA_DICTIONARY.md`](docs/DATA_DICTIONARY.md) | Workbook sheets and configuration-file definitions |
| [`docs/PROVENANCE_AND_LIMITATIONS.md`](docs/PROVENANCE_AND_LIMITATIONS.md) | Data provenance, screening-record limits, protocol changes, and scope of reuse |
| [`environment`](environment) | Recorded R session and Python validation dependencies |

## Quick start

### 1. Clone or download the complete repository

```bash
git clone https://github.com/Cayonidas/inph-care-cascade-meta-analysis.git
cd inph-care-cascade-meta-analysis
```

Git is optional: GitHub's **Code > Download ZIP** archive works if it is fully extracted before execution.

### 2. Run the independent input audit

Python 3.10 or newer is recommended.

```bash
python -m pip install -r environment/requirements-validation.txt
python validate_inputs.py
```

A passing audit reports zero unmatched mapped effects, duplicated map rows, unknown study identifiers, and R delimiter errors. The same check runs automatically through GitHub Actions.

### 3. Run the complete R analysis

R 4.3 or newer is recommended; the archived reference run used R 4.5.2. From the repository root:

```r
source("R/00_packages.R")
source("run_all.R")
```

In RStudio, open `iNPH_MetaAnalysis.Rproj`, then open `START_HERE.R` and click **Source**. Outputs are written to `results/`. Exact versions from the reference run are recorded in [`environment/sessionInfo.txt`](environment/sessionInfo.txt).

## Reproducibility safeguards

- Every pooled effect is linked to an explicit study, numerator, denominator, stage, estimand, analysis set, and overlap cluster.
- The pipeline stops on invalid counts, unmatched mappings, duplicate effect mappings, and unknown study identifiers.
- Patient, examination, facility, and administrative denominators are not pooled together.
- Overlapping reports contribute only one effect per cohort and estimand in a model.
- The reference archive includes the complete analysis manifest, unmapped extracted effects, sensitivity grids, leave-one-out results, serialized model objects, and `sessionInfo()` output.
- `CHECKSUMS.sha256` provides a release-level integrity record for the uploaded files.

## Data provenance and appropriate reuse

The workbook contains aggregate values extracted from cited publications. It contains no names, direct identifiers, protected health information, or individual participant-level records. Copyrighted article PDFs are deliberately excluded. Users should consult and cite the original reports when reusing study-level values; this repository does not replace the source publications.

The `Search_Dedup` and `New_Candidates` worksheets are preserved as development-history artefacts only. They are not the final multi-database screening corpus and were not used for final PRISMA accounting. Final review counts are in [`config/prisma_fields.csv`](config/prisma_fields.csv). Record-level reasons were preserved for four apparently eligible exclusions in [`config/apparently_eligible_full_text_exclusions.csv`](config/apparently_eligible_full_text_exclusions.csv); the remaining 30 full-text exclusions survive only as aggregate legacy categories. No record-level reasons were reconstructed after the fact.

## Protocol chronology

PROSPERO registration occurred on 23 July 2026 after review initiation. The final analysis changed from Freeman–Tukey/DerSimonian–Laird pooling to binomial-normal GLMMs, from the Newcastle–Ottawa Scale to a JBI-informed common-domain framework, and from a broad cascade concept to explicit denominator-defined estimands. These changes were made before the final analyses and are documented in the manuscript supplement and [`docs/PROVENANCE_AND_LIMITATIONS.md`](docs/PROVENANCE_AND_LIMITATIONS.md).

## Artificial-intelligence use

OpenAI ChatGPT was used for language refinement, assistance with debugging analytical code, and assistance in preparing selected publication materials. It did not perform study selection, data extraction, risk-of-bias or certainty assessment, statistical analysis, or generate study results. All AI-assisted material was checked and revised by the authors; all data, code, analyses, judgments, and manuscript content were verified and approved by all authors, who take full responsibility for the work.

## Citation and versioning

Citation metadata are provided in [`CITATION.cff`](CITATION.cff). Cite the exact tagged release used for an analysis. After the repository is connected to Zenodo, cite the version-specific Zenodo DOI shown for that release because it is an immutable archive; the GitHub URL remains the live development location.

## Licensing

- R and Python code: [MIT License](LICENSE)
- Author-created data compilation and documentation: [CC BY 4.0](LICENSE-DATA.md)
- Underlying source publications: remain subject to their original copyright and licensing terms

## Contact

Caio Arruda Maciel, corresponding author  
Faculdade de Medicina da Universidade de São Paulo, São Paulo, Brazil  
Email: caioarrudamaciel@gmail.com  
ORCID: [0009-0007-4514-4891](https://orcid.org/0009-0007-4514-4891)
