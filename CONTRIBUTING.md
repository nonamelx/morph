# Contributing

Morph favors simple, reviewable data and scripts. Keep public documentation in English.

## Theme profiles

Add one JSON profile under `themes/` and validate it with `scripts/Morph.ps1 check`. Profiles must match `themes/profile.schema.json`; only appearance data is allowed. Do not add scripts, URLs to execute, credentials, Codex settings, or app-bundle modifications. Include a short description and test both legibility and the import preview in the Codex build you report.

## Changes

Keep dependencies minimal. Add tests using temporary files and never point tests at the installed Codex application. Describe platform and app build details when reporting manual compatibility observations. Unsupported layout techniques belong in a clearly labeled proposal, not the stable adapter.
