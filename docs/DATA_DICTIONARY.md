# Data dictionary

## Master extraction workbook

`data/raw/iNPH_Master_ReExtraction_v4.xlsx` is the denominator-first source workbook. The analysis reads the sheets marked **Analytical input** below; the other sheets are preserved for provenance and auditability.

| Sheet | Role | Main content |
|---|---|---|
| `README` | Documentation | Workbook scope, analytical principles, and review counts |
| `Search_Dedup` | Development history only | Broad PubMed candidate-staging export; not the final PRISMA corpus |
| `FullText_Screen` | Audit context | Preserved full-text decisions for locally available reports; not a complete record-level log of all 73 full texts |
| `Study_Master` | **Analytical input** | One row per included or contextual study, country, design, data level, base population, synthesis role, and source URL |
| `Transitions` | **Analytical input** | Study-level stage, estimand, numerator, denominator, notes, source location, and URL |
| `Barriers` | **Analytical input** | Stage-specific reasons for non-progression with explicit denominators |
| `Facility_Survey` | **Analytical input** | Facility-level capability, practice, and hesitation measures |
| `Delays` | **Analytical input** | Time-to-care definitions, anchors, statistics, units, and populations |
| `Disparities` | **Analytical input** | Administrative and specialty-centre disparity measures used contextually |
| `New_Candidates` | Development history only | Historical candidate-triage artefact; not unresolved screening in the completed review |
| `Overlap_Risk` | **Analytical input** | Cohort clusters and rules used to prevent double counting |
| `Audit_Notes` | **Analytical input** | Source inconsistencies and explicit extraction/analysis decisions |
| `Codebook` | Documentation | Stage codes, data levels, and operational estimand definitions |

## Configuration files

| File | Purpose |
|---|---|
| `analysis_config.yml` | Global analysis settings, model hierarchy, thresholds, plot settings, and random seed |
| `effect_map.csv` | Links each source effect to an analysis, set, entry definition, time point, and overlap cluster |
| `derived_effects.csv` | Transparently reconstructed effects not directly stored as a row in the workbook |
| `sensitivity_sets.csv` | Definitions of strict and alternative analytical sets |
| `binary_comparisons.csv` | Within-study binary comparisons |
| `continuous_comparisons.csv` | Within-study continuous comparisons |
| `risk_of_bias.csv` | JBI-informed common-domain judgments, rationale, and human verification trail |
| `certainty_assessment.csv` | GRADE-adapted certainty judgments by pooled estimand |
| `prisma_fields.csv` | Final search, deduplication, screening, eligibility, and inclusion counts |
| `apparently_eligible_full_text_exclusions.csv` | Four record-level exclusions that survived in the source audit trail |

## Core transition fields

| Field | Meaning |
|---|---|
| `study_id` | Stable study or analytical-unit identifier |
| `stage` | Care-pathway stage code |
| `estimand` | Exact numerator/denominator transition definition |
| `numerator` | Number completing the defined transition |
| `denominator` | Population at risk at the defined entry point |
| `data_level` | Patient, examination, facility, or administrative unit |
| `analysis_id` | Prespecified pooled or contextual analytical target |
| `set_id` | Strict or sensitivity-set label |
| `overlap_cluster` | Cluster used to prevent multiple reports from one cohort entering the same model |
| `include_pool` | Whether the mapped row contributes to the specified model |

The pipeline recalculates proportions from numerators and denominators and does not use spreadsheet-displayed percentages as model inputs.
