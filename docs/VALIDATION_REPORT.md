# Validation report

Independent input-audit date: 18 August 2026

## Input integrity

- master transition effects: 140;
- transparent derived effects: 5;
- analysis-map rows: 59;
- unique mapped source effects: 57;
- unmatched mapped effects: 0;
- duplicated map rows within an analysis/set: 0;
- unknown study IDs: 0;
- R delimiter smoke-test errors: 0.

The master workbook was also imported through an independent spreadsheet reader. Analysis-critical tabs were structurally inspected, and the workbook/configuration linkages were checked independently of the R pipeline.

## Strict-set feasibility

| Analysis | k | Events | Sum of denominators |
|---|---:|---:|---:|
| P1_REFERRAL_TO_SHUNT | 7 | 706 | 1,646 |
| P2_DIAGNOSED_TO_SHUNT | 7 | 644 | 837 |
| S1_REFERRAL_TO_DIAGNOSIS | 6 | 660 | 1,251 |
| S2_TEST_COMPLETION | 7 | 474 | 522 |
| S3_TEST_POSITIVE_TO_SHUNT | 5 | 282 | 312 |
| S4_RECOMMENDATION_TO_SHUNT | 3 | 216 | 248 |
| S5_POSTSHUNT_RESPONSE_6_12M | 5 | 256 | 318 |

These sums are descriptive checks only and are not pooled estimates.

## Runtime and reference-output status

The archived reference outputs were generated under R 4.5.2 on Windows 11; exact package versions are recorded in `environment/sessionInfo.txt`. During the independent 18 August 2026 packaging audit, the R models were not re-fitted because R was unavailable in that audit environment. No numerical result was generated or altered during packaging. Source/configuration linkage, counts, identifiers, denominators, required files, archive integrity, and R delimiter balance were independently validated.

The complete reproduction command is:

```r
source("R/00_packages.R")
source("run_all.R")
```

The repository contains the reference `sessionInfo.txt`, serialized model objects, and CSV/XLSX tables. Before tagging a public release for journal submission, the authors should run these commands from a clean clone and compare `results/tables/meta_summary.csv` with the reference results reported in `README.md`.
