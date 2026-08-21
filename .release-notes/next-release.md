## Reject changelog entries with multiple PR references

`changelog-tool verify` accepted entries with more than one `[PR #N](url)` link. Each entry should reference a single PR. Verification and the add command now reject entries with multiple PR references.

## Update ponylang/peg dependency to 0.1.6

We've updated the PEG library dependency in this project to 0.1.6.

## Reject non-canonical PR reference formats in changelog entries

Previously, only the exact `[PR #N](url)` format was counted when checking for multiple PR references per entry. Variant spellings like `[pr #N](url)` or `[PR#N](url)` bypassed the check. All PR references are now detected regardless of case or spacing, and non-canonical formats are rejected outright.

