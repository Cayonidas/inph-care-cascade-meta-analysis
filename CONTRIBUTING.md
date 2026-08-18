# Contributing and reporting discrepancies

This repository is the versioned analysis archive for a published-data systematic review. Corrections that affect an extracted value, analysis decision, or result should be traceable.

## Reporting an issue

Open a GitHub issue and include:

1. the study ID and source report;
2. the exact file, sheet, row, or code location;
3. the value or decision in question;
4. the proposed correction and its documentary basis; and
5. whether the change could affect a pooled estimate, sensitivity analysis, figure, or conclusion.

Do not upload copyrighted full-text articles, individual participant data, protected health information, credentials, or confidential peer-review material.

## Change control

Any accepted analytical correction should update, as applicable:

- the master workbook or configuration file;
- the analysis manifest and regenerated outputs;
- `CHANGELOG.md`;
- `CHECKSUMS.sha256`; and
- the tagged release and archival repository version.

Changes to a published release should be made in a new version rather than by silently replacing the archived files.
