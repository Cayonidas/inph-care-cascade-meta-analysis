from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parent
MASTER = ROOT / "data" / "raw" / "iNPH_Master_ReExtraction_v4.xlsx"


def clean(value: object) -> str:
    if pd.isna(value):
        return ""
    return re.sub(r"\s+", " ", str(value).replace("–", "-").replace("—", "-")).strip()


def key(study_id: object, stage: object, estimand: object) -> str:
    return "||".join(clean(x) for x in (study_id, stage, estimand))


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def validate_r_delimiters(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    pairs = {")": "(", "]": "[", "}": "{"}
    opening = set(pairs.values())
    stack: list[tuple[str, int]] = []
    quote: str | None = None
    escaped = False
    in_comment = False
    errors: list[str] = []

    for index, char in enumerate(text):
        if in_comment:
            if char == "\n":
                in_comment = False
            continue
        if quote is not None:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            continue
        if char == "#":
            in_comment = True
        elif char in ('"', "'", "`"):
            quote = char
        elif char in opening:
            stack.append((char, index))
        elif char in pairs:
            if not stack or stack[-1][0] != pairs[char]:
                errors.append(f"unexpected {char} at character {index}")
            else:
                stack.pop()

    if quote is not None:
        errors.append(f"unterminated quote {quote}")
    errors.extend(f"unclosed {char} at character {index}" for char, index in stack)
    return errors


transitions = pd.read_excel(MASTER, sheet_name="Transitions", skiprows=3)
reported_keys = {
    key(row["Study ID"], row["Stage"], row["Estimand"])
    for _, row in transitions.iterrows()
}

derived = read_csv(ROOT / "config" / "derived_effects.csv")
derived_keys = {key(row["study_id"], row["stage"], row["estimand"]) for row in derived}
all_keys = reported_keys | derived_keys

effect_map = read_csv(ROOT / "config" / "effect_map.csv")
map_keys = [key(row["study_id"], row["stage"], row["estimand"]) for row in effect_map]
map_row_keys = [
    "||".join((source_key, clean(row["analysis_id"]), clean(row["set_id"])))
    for source_key, row in zip(map_keys, effect_map)
]
unmatched = sorted(set(map_keys) - all_keys)
duplicates = sorted({x for x in map_row_keys if map_row_keys.count(x) > 1})

study_master = pd.read_excel(MASTER, sheet_name="Study_Master", skiprows=3)
study_ids = {clean(x) for x in study_master["Study ID"].dropna()}
unknown_studies = sorted({clean(row["study_id"]) for row in effect_map} - study_ids)

reported_lookup = {
    key(row["Study ID"], row["Stage"], row["Estimand"]): (
        float(row["Numerator"]), float(row["Denominator"])
    )
    for _, row in transitions.iterrows()
}
derived_lookup = {
    key(row["study_id"], row["stage"], row["estimand"]): (
        float(row["numerator"]), float(row["denominator"])
    )
    for row in derived
}
effect_lookup = reported_lookup | derived_lookup

strict_summary: dict[str, dict[str, float]] = {}
for row, source_key in zip(effect_map, map_keys):
    if clean(row["set_id"]) != "primary" or clean(row["include_pool"]).lower() != "true":
        continue
    numerator, denominator = effect_lookup[source_key]
    item = strict_summary.setdefault(
        clean(row["analysis_id"]), {"k": 0, "events": 0.0, "n": 0.0}
    )
    item["k"] += 1
    item["events"] += numerator
    item["n"] += denominator

print(f"Master workbook: {MASTER}")
print(f"Reported transition effects: {len(reported_keys)}")
print(f"Derived effects: {len(derived_keys)}")
print(f"Analysis-map rows: {len(effect_map)}")
print(f"Unique mapped source effects: {len(set(map_keys))}")
print(f"Unmatched mapped effects: {len(unmatched)}")
print(f"Duplicated map rows (effect + analysis + set): {len(duplicates)}")
print(f"Unknown study IDs in map: {len(unknown_studies)}")
print("\nStrict-set feasibility (counts are descriptive, not pooled estimates)")
for analysis_id, item in strict_summary.items():
    print(
        f"{analysis_id}: k={int(item['k'])}, events={int(item['events'])}, "
        f"denominators={int(item['n'])}"
    )

r_errors: list[str] = []
for r_file in sorted((ROOT / "R").glob("*.R")) + [ROOT / "run_all.R"]:
    for error in validate_r_delimiters(r_file):
        r_errors.append(f"{r_file.relative_to(ROOT)}: {error}")
print(f"\nR delimiter smoke test: {len(r_errors)} error(s)")
if r_errors:
    print("\n".join(r_errors))

for heading, values in (
    ("UNMATCHED", unmatched),
    ("DUPLICATED", duplicates),
    ("UNKNOWN_STUDY", unknown_studies),
):
    if values:
        print(f"\n{heading}")
        print("\n".join(values))

if unmatched or duplicates or unknown_studies or r_errors:
    sys.exit(1)
