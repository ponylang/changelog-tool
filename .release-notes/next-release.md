## Reject changelog entries with multiple PR references

`changelog-tool verify` accepted entries with more than one `[PR #N](url)` link. Each entry should reference a single PR. Verification and the add command now reject entries with multiple PR references.

## Update ponylang/peg dependency to 0.1.6

We've updated the PEG library dependency in this project to 0.1.6.

