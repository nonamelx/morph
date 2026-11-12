# Contributing

Morph favors simple, reviewable data and scripts. Keep public documentation in English.

## Theme sources

Add a directory under `themes/<slug>/` with a `theme.json` source definition matching `schemas/theme.schema.json`. Preserve source attribution in `author`; then run `tools/Build-Themes.ps1` to generate `import.txt`, `preview.svg`, and the catalog. `import.txt` is the Codex import file. The schema documents source JSON only. Do not add scripts, executable URLs, credentials, Codex settings, or app-bundle modifications. Include a short description and test legibility. Report Desktop build details for any manual import observations.

## Changes

Keep dependencies minimal. Add tests using temporary files and never point tests at the installed Codex application. Describe platform and app build details when reporting manual compatibility observations. Unsupported layout techniques belong in a clearly labeled proposal, not the stable adapter.
