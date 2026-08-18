# Provenance, audit trail, and limitations

## Source and data level

This repository contains aggregate data extracted from published studies. No individual participant data were requested, received, or stored. Each extracted value is tied to a study identifier, source location or explanatory note, and source URL. Copyrighted article PDFs are not included.

## Search and screening records

The final PRISMA accounting is stored in `config/prisma_fields.csv`: 1,680 records identified, 654 duplicates removed, 1,026 records screened, 953 excluded at title/abstract assessment, 73 full-text reports assessed, 34 full-text reports excluded, and 39 reports retained.

The workbook's `Search_Dedup` sheet is a development-only broad PubMed candidate-staging export. It is not the final deduplicated corpus and must not be used to reconstruct PRISMA totals. The `New_Candidates` sheet likewise preserves historical candidate triage and does not indicate unresolved screening in the completed review.

Record-level citations and study-specific reasons survived for four full-text records that could appear eligible from their title or source. They are listed in `config/apparently_eligible_full_text_exclusions.csv`. Only aggregate legacy reason categories survived for the other 30 excluded full texts. The authors did not reconstruct missing record-level decisions after the fact.

## Protocol chronology

The review was registered in PROSPERO on 23 July 2026 after review initiation. It is therefore not described as prospectively registered. Before final analysis, the authors made three material changes:

1. Freeman–Tukey/DerSimonian–Laird pooling was replaced by binomial-normal GLMMs to model binomial counts directly.
2. The Newcastle–Ottawa Scale was replaced by a design-informed framework based on common JBI domains because the evidence included heterogeneous observational designs.
3. A broad cascade concept was resolved into explicit denominator-defined coprimary and secondary estimands to avoid multiplying non-sequential cohort estimates.

The chronology and rationale are also reported in the manuscript supplement.

## Human verification and AI disclosure

One author completed each initial risk-of-bias judgment; a second author checked every judgment against the source report; disagreements were resolved by consensus; and all authors reviewed and approved the final risk-of-bias and certainty judgments.

OpenAI ChatGPT was used for language refinement, assistance with debugging analytical code, and assistance in preparing selected publication materials. It did not perform study selection, data extraction, risk-of-bias or certainty assessment, statistical analysis, or generate study results. All AI-assisted material was checked and revised by the authors; all data, code, analyses, judgments, and manuscript content were verified and approved by all authors, who take full responsibility for the work.

## Preserved source caveats

- **Mahr 2016:** 74 participants were enrolled and 68 analysed; 65 completed external lumbar drainage and three received a high-volume tap. Two patients initially received endoscopic third ventriculostomy, so the follow-up outcome is interpreted as post-CSF-diversion context rather than a pure post-shunt estimate.
- **Morel 2026:** some recommended patients were still awaiting surgery at publication; the recommendation-to-shunt result is therefore explicitly limited to the publication cut-off.
- **Poudel 2026:** only internally coherent pathway counts were used; an inconsistent secondary outcome was not pooled.
- **Marmarou 2005:** entry followed procedural selection for an external lumbar drainage protocol. A targeted sensitivity analysis excluding this cohort yielded 34.8% (95% CI 25.4–45.6; tau-squared 0.284; six studies) for suspicion/referral to shunt.

## Interpretive limits

The stages were estimated from different, non-sequential cohorts, settings, and eligibility thresholds. They cannot be multiplied into a synthetic longitudinal funnel and cannot localise patient-level attrition. Wide prediction intervals preclude a universal pathway benchmark. The complement of a completion proportion is observed non-progression, not automatically avoidable undertreatment.
