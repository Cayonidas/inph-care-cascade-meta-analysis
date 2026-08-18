# Statistical Analysis Plan

## Diagnostic and care-cascade gaps in idiopathic normal-pressure hydrocephalus

Version 1.0 — 22 July 2026

## 1. Central contribution

The manuscript should not be framed as another meta-analysis of shunt outcomes or diagnostic-test accuracy. Its distinct contribution is to quantify where people leave the iNPH care pathway and to distinguish three phenomena that previous pooled proportions often conflate:

1. **Failure to recognize or complete evaluation**: no consultation, no specialized work-up or non-completion of an indicated test.
2. **Clinically appropriate non-progression**: alternative diagnosis, failure to meet iNPH criteria, insufficient expected benefit or medical contraindication.
3. **Potentially modifiable treatment attrition**: refusal after eligibility, non-attendance, prolonged waiting, lack of local capability or failure to implement a recommendation.

The review therefore uses a care-cascade framework rather than one universal “treatment-gap” proportion.

## 2. Primary research questions

1. Among adults entering care with suspected iNPH, what proportion receives a shunt?
2. Among adults diagnosed with probable/definite iNPH, what proportion receives a shunt?
3. At which intermediate stages does observed non-progression occur, and what reasons are reported?
4. What evidence links delay or protocol organization to diagnostic completion, treatment and patient outcome?
5. Which facility, geographic and demographic factors may contribute to differential ascertainment or access?

## 3. Unit-of-analysis rule

Every quantitative effect must identify:

- numerator;
- denominator and its exact entry point;
- care stage;
- data level: patient, participant, facility, claim/discharge or examination;
- setting;
- outcome definition and timepoint;
- overlap cluster.

Only effects with the same care stage, comparable denominator and same data level are pooled. Facility surveys, claims/discharges and clinical patient cohorts are never combined.

## 4. Estimand hierarchy

### 4.1 Co-primary estimands

| ID | Estimand | Numerator | Denominator | Interpretation |
|---|---|---|---|---|
| P1_REFERRAL_TO_SHUNT | End-to-end shunt receipt | Shunted patients | Initial clinically suspected/referral cohort | Cumulative observed completion of the clinical pathway |
| P2_DIAGNOSED_TO_SHUNT | Treatment receipt after diagnosis | Shunted patients | Diagnosed/probable iNPH | Treatment-stage completion after diagnostic classification |

The primary result is the completion proportion. Its complement is reported as **observed non-progression** and is not called avoidable under-treatment unless reasons support that interpretation.

### 4.2 Secondary quantitative estimands

| ID | Estimand | Main role |
|---|---|---|
| S1_REFERRAL_TO_DIAGNOSIS | Confirmed/probable iNPH among initial referrals | Diagnostic yield and reclassification |
| S2_TEST_COMPLETION | Completed specialized/invasive evaluation among those selected or intended for it | Procedural completion |
| S3_TEST_POSITIVE_TO_SHUNT | Shunted after a positive prognostic test | Treatment completion after positive test |
| S4_RECOMMENDATION_TO_SHUNT | Shunted after surgical referral/recommendation | Implementation of a treatment decision |
| S5_POSTSHUNT_RESPONSE_6_12M | Clinical responders among treated patients at approximately 6–12 months | Consequence/benefit context, not a gap estimate |

`S4` is exploratory because only three compatible studies are currently available. `S5` is secondary because response definitions remain heterogeneous.

### 4.3 Structured syntheses without forced pooling

- population and high-risk screening yield;
- prior recognition or prior treatment among screen-detected cases;
- alternative diagnoses and diagnostic reclassification;
- patient-level reasons for non-progression;
- delay intervals with non-equivalent anchors;
- facility capability and reported hesitation;
- administrative diagnosis/procedure rates;
- demographic and socioeconomic disparities.

These modules follow SWiM principles when meta-analysis is inappropriate.

## 5. Quantitative model

### 5.1 Primary model

For each eligible estimand with at least three independent studies, fit a random-effects binomial-normal generalized linear mixed model:

```r
metafor::rma.glmm(
  measure = "PLO",
  xi = numerator,
  ni = denominator,
  method = "ML"
)
```

This models event counts directly on the logit scale and avoids a routine continuity correction for studies with 0% or 100% proportions. Report:

- pooled proportion and 95% CI;
- observed non-progression, `1 − pooled proportion`;
- tau-squared;
- I-squared;
- Cochran Q and p-value;
- 95% prediction interval whenever estimable;
- number of studies and summed participants, without presenting the crude aggregate as the pooled result.

Study-level confidence intervals use exact Clopper–Pearson intervals.

### 5.2 Interpretation of heterogeneity

Prediction intervals receive priority over an isolated pooled mean. If the prediction interval is extremely wide or includes clinically incompatible completion levels, the manuscript will state that there is no single universal gap estimate and will interpret setting-specific patterns.

### 5.3 Main sensitivity model

Use logit-transformed proportions with a 0.5 correction only for boundary studies, REML tau-squared and a Hartung–Knapp-type test:

```r
es <- metafor::escalc(
  measure = "PLO",
  xi = numerator,
  ni = denominator,
  add = 0.5,
  to = "only0"
)
metafor::rma.uni(es$yi, es$vi, method = "REML", test = "knha")
```

The sensitivity result verifies model dependence; it does not replace the binomial GLMM.

## 6. Prespecified sensitivity analyses

For P1 and P2, and for secondary models when feasible:

1. strict primary set;
2. broader denominator set including diagnostically or procedurally selected cohorts;
3. removal of high-risk/high-concern studies after risk-of-bias assessment;
4. prospective cohorts only;
5. exclusion of studies published before the 2005 international diagnostic criteria;
6. exclusion of studies with denominator below 30;
7. leave-one-study-out analysis;
8. leave-one-overlap-cluster-out analysis;
9. overlap swap: Pyykkö versus Junkkari for the Kuopio cluster and Kuriyama versus Nakajima for the Japanese survey cluster;
10. GLMM versus logit-REML/Hartung–Knapp sensitivity model.

If an overlap cannot be resolved, one report per cohort and estimand is used in the primary model. Alternative reports appear only in sensitivity analysis.

## 7. Subgroups and meta-regression

Potential moderators are prespecified:

- entry setting: population/catchment, memory clinic, multidisciplinary referral clinic, invasive-test-selected cohort;
- prospective versus retrospective design;
- standardized/multidisciplinary pathway versus usual care;
- region;
- publication year;
- diagnostic-guideline era;
- risk-of-bias concern.

Rules:

- subgroup estimates require at least three studies per level;
- univariable meta-regression requires at least ten independent studies;
- multivariable meta-regression requires at least twenty studies and an adequate events-to-parameter ratio;
- no stepwise or significance-driven moderator selection;
- with the current evidence base, meta-regression is expected **not** to run.

## 8. Comparative analyses

The following comparisons are kept separate from single-proportion meta-analysis:

1. Acosta pre-protocol versus standardized protocol: test completion, cognitive assessment, shunt receipt, response and delay intervals.
2. Andrén delayed versus early treatment: deterioration during waiting and postoperative response.
3. Poudel operated versus non-operated cohort: short-term functional improvement, interpreted as non-randomized contextual evidence.
4. Vakili symptom-duration associations: adjusted relative risks per additional year, presented without reconstructing unreported confidence intervals.

Binary comparisons use RR and 95% CI. Continuous comparisons use mean difference only when means, SDs and compatible anchors are available. Single-study comparative estimates are displayed but not mislabeled as meta-analytic effects.

## 9. Delay synthesis

Delay intervals are classified before analysis:

1. symptom onset/documentation to diagnosis;
2. symptom onset to treatment;
3. initial specialist assessment to diagnostic test;
4. diagnostic test to neurosurgical evaluation;
5. test or treatment decision to shunt;
6. total specialist assessment to shunt.

Means and medians are not combined in the primary analysis. Medians are not automatically converted to means because the delay distributions are highly skewed and definitions differ. Compatible comparative effects are calculated; otherwise a log-scale harvest/dot plot reports estimate, statistic and dispersion.

## 10. Barrier synthesis

Each reason is mapped to one of the following categories without assuming mutual exclusivity:

- diagnostic reclassification/alternative diagnosis;
- diagnostic-test non-completion;
- medical or surgical non-eligibility;
- insufficient expected benefit/negative clinical assessment;
- patient or family preference;
- waiting/system capacity;
- referral or follow-up loss;
- research selection/attrition;
- other/unclear.

Pooling is allowed only if at least three studies report the same category from a comparable stage denominator. Otherwise, distributions are shown without a pooled diamond. Categories reported only among non-shunted patients are not used to estimate prevalence among all eligible patients.

## 11. Facility and disparity evidence

Facility surveys are displayed as exact proportions with study-specific denominators. Measures are pooled only if at least three surveys ask conceptually equivalent questions of comparable facilities; this criterion is not currently met.

Administrative diagnosis rates and adjusted odds ratios are shown in separate panels. They are not interpreted as biological incidence because coding, referral, access and disease occurrence are entangled.

## 12. Risk of bias and certainty

Use a design-informed framework based on JBI domains shared across the heterogeneous observational evidence: sample frame, analytic coverage, identification/measurement, response/follow-up, analysis/reporting, and overall judgment. The framework is explicitly described as JBI-informed rather than as one unmodified design-specific checklist. One author completes the initial assessment, a second author checks each judgment against the source report, disagreements are resolved by consensus, and all authors approve the final judgments.

No summed quality score will be calculated. Domain-level judgments are visualized. Certainty for each primary estimand is assessed transparently using the domains of risk of bias, inconsistency, indirectness, imprecision and publication bias, without treating this observational care-cascade literature as intervention trials.

## 13. Small-study effects

Funnel plots and regression tests are exploratory and run only with at least ten independent studies in a clinically coherent estimand. Funnel asymmetry in single-proportion meta-analysis may reflect real setting differences; it will never be equated automatically with publication bias. With the current P1/P2 evidence, these tests should not be performed.

## 14. Missing or inconsistent data

- Do not impute unreported stage counts.
- Derived effects must be arithmetically reconstructable and labelled as derived.
- Conflicting denominators remain in the audit table and are excluded or placed in sensitivity analysis.
- Author contact is recommended for Mahr 2016, Morel 2026, Poudel 2026, Macki 2020 and Iseki 2022.
- Mortality from Poudel 2026 is not synthesized until the text/table inconsistency is resolved.

## 15. Planned figures

### Main manuscript

1. PRISMA 2020 flow diagram.
2. iNPH care-cascade framework with the number of studies informing each stage; no multiplication of pooled estimates from different cohorts.
3. Co-primary forest plots: P1 referral/suspicion to shunt and P2 diagnosis to shunt.
4. Intermediate-stage forest plots: diagnostic confirmation, test completion, positive test to shunt and recommendation to shunt.
5. Barrier taxonomy/evidence distribution.
6. Delay and implementation evidence, including Acosta and Andrén comparative estimates.

If the target journal restricts the figure count, Figures 5–6 move to the supplement and the main text retains a single combined implementation figure.

### Supplement

- all stage-specific effects;
- test positivity by test type;
- post-diversion response by definition/timepoint;
- population/high-risk screening yields;
- facility-practice plot;
- disparity plot;
- risk-of-bias traffic light;
- influence and overlap-swap analyses;
- funnel plots only if the minimum study threshold is later reached.

## 16. Planned tables

1. Study and pathway characteristics.
2. Summary of pooled estimands with k, numerator/denominator, pooled estimate, CI, prediction interval, heterogeneity and certainty.
3. Reasons for non-progression by care stage.
4. Facility and disparity evidence summary.
5. Supplementary effect-level extraction, overlap decisions, risk of bias and sensitivity results.

## 17. Reporting framework

- PRISMA 2020 and PRISMA-S for the systematic review and search.
- SWiM for quantitative evidence not meta-analyzed.
- Exact definitions of every numerator and denominator in the supplement.
- Analysis code, effect map and session information supplied as reproducibility material.

## 18. What must not be done

- Do not retain the old SG3 pool that combined population, survey and administrative denominators.
- Do not combine “test performed,” “test positive,” “recommended for surgery” and “shunted.”
- Do not interpret `1 − proportion` as avoidable under-treatment without barrier evidence.
- Do not multiply pooled stage proportions from different study cohorts to create a synthetic patient funnel.
- Do not run meta-regression, Egger testing or multivariable models merely because software permits it.
- Do not convert every median delay to a mean or pool intervals with different starting points.
- Do not count overlapping registry reports as independent.

## 19. Expected novelty statement

Based on the literature search performed through 22 July 2026, existing reviews primarily address shunt outcomes, complications, predictors or diagnostic-test accuracy. No identified review quantitatively maps the full iNPH recognition, diagnostic and treatment cascade while preserving stage-specific denominators and integrating patient barriers, delay, facility capacity and disparity evidence. This should be phrased as “to our knowledge” and rechecked immediately before submission.

## 20. Methodological references

- PRISMA 2020: https://www.prisma-statement.org/prisma-2020
- SWiM: https://www.bmj.com/content/368/bmj.l6890
- Cochrane Handbook, Chapter 10: https://www.cochrane.org/authors/handbooks-and-manuals/handbook/current/chapter-10
- metafor `rma.glmm`: https://wviechtb.github.io/metafor/reference/rma.glmm.html
- JBI appraisal tools: https://jbi.global/critical-appraisal-tools

