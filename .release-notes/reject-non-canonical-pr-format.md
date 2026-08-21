## Reject non-canonical PR reference formats in changelog entries

Previously, only the exact `[PR #N](url)` format was counted when checking for multiple PR references per entry. Variant spellings like `[pr #N](url)` or `[PR#N](url)` bypassed the check. All PR references are now detected regardless of case or spacing, and non-canonical formats are rejected outright.
