<div align="center">

# MORPH
### Shape your Codex.

**Browse themes. Open `import.txt`. Copy one line. Import it in Codex Desktop.**

</div>

Morph is an open-source Codex Desktop theme collection and generator. Theme folders contain readable source definitions, generated previews, and a direct import file. Morph never edits Codex settings or application files.

## Import a theme

1. Choose a theme in the gallery and open its **Import theme** link. Each link opens that theme’s `import.txt` directly; `schemas/theme.schema.json` is only a source validation schema, not a theme.
2. Copy the full single line beginning with `codex-theme-v1:`.
3. In Codex Desktop, open **Settings → Appearance** and choose **Import** in the matching Light or Dark theme section.
4. Paste the line, review the preview, and confirm the import.

The `codex-theme-v1:` format is community-derived. OpenAI’s public documentation describes appearance customization but does not document this import payload or guarantee compatibility. If your installed build has no Import control or rejects a theme, stop. Morph has not verified these imports against the installed Codex Desktop UI in this environment.

## Theme gallery

Preview images are generated from the source colors. They are illustrative theme previews, not screenshots of Codex Desktop.

| Theme | Mode | Preview | Import | Theme attribution |
| --- | --- | --- | --- | --- |
| Absolutely Light | light | [absolutely-light/preview.svg](themes/absolutely-light/preview.svg) | [**Import theme**](themes/absolutely-light/import.txt) | OpenAI / Codex Themes |
| Ayu Dark | dark | [ayu-dark/preview.svg](themes/ayu-dark/preview.svg) | [**Import theme**](themes/ayu-dark/import.txt) | teabyii / Codex Themes |
| Ayu Light | light | [ayu-light/preview.svg](themes/ayu-light/preview.svg) | [**Import theme**](themes/ayu-light/import.txt) | teabyii / Codex Themes |
| Catppuccin Latte | light | [catppuccin-latte/preview.svg](themes/catppuccin-latte/preview.svg) | [**Import theme**](themes/catppuccin-latte/import.txt) | Catppuccin / Codex Themes |
| Catppuccin Mocha | dark | [catppuccin-mocha/preview.svg](themes/catppuccin-mocha/preview.svg) | [**Import theme**](themes/catppuccin-mocha/import.txt) | Catppuccin / Codex Themes |
| Claude Warm | dark | [claude-warm/preview.svg](themes/claude-warm/preview.svg) | [**Import theme**](themes/claude-warm/import.txt) | Morph (independent adaptation) |
| Codex Dark | dark | [codex-dark/preview.svg](themes/codex-dark/preview.svg) | [**Import theme**](themes/codex-dark/import.txt) | OpenAI / Codex Themes |
| Dracula | dark | [dracula/preview.svg](themes/dracula/preview.svg) | [**Import theme**](themes/dracula/import.txt) | Dracula Theme / Codex Themes |
| Everforest Dark | dark | [everforest-dark/preview.svg](themes/everforest-dark/preview.svg) | [**Import theme**](themes/everforest-dark/import.txt) | sainnhe / Codex Themes |
| Everforest Light | light | [everforest-light/preview.svg](themes/everforest-light/preview.svg) | [**Import theme**](themes/everforest-light/import.txt) | sainnhe / Codex Themes |
| GitHub Dark | dark | [github-dark/preview.svg](themes/github-dark/preview.svg) | [**Import theme**](themes/github-dark/import.txt) | GitHub / Codex Themes |
| GitHub Light | light | [github-light/preview.svg](themes/github-light/preview.svg) | [**Import theme**](themes/github-light/import.txt) | GitHub / Codex Themes |
| Gruvbox Dark | dark | [gruvbox-dark/preview.svg](themes/gruvbox-dark/preview.svg) | [**Import theme**](themes/gruvbox-dark/import.txt) | morhetz / Codex Themes |
| Gruvbox Light | light | [gruvbox-light/preview.svg](themes/gruvbox-light/preview.svg) | [**Import theme**](themes/gruvbox-light/import.txt) | morhetz / Codex Themes |
| Material Lighter | light | [material-lighter/preview.svg](themes/material-lighter/preview.svg) | [**Import theme**](themes/material-lighter/import.txt) | material-theme / Codex Themes |
| Material Ocean | dark | [material-ocean/preview.svg](themes/material-ocean/preview.svg) | [**Import theme**](themes/material-ocean/import.txt) | material-theme / Codex Themes |
| Monokai | dark | [monokai/preview.svg](themes/monokai/preview.svg) | [**Import theme**](themes/monokai/import.txt) | Wimer Hazenberg / Codex Themes |
| Night Owl | dark | [night-owl/preview.svg](themes/night-owl/preview.svg) | [**Import theme**](themes/night-owl/import.txt) | Sarah Drasner / Codex Themes |
| Nord | dark | [nord/preview.svg](themes/nord/preview.svg) | [**Import theme**](themes/nord/import.txt) | arcticicestudio / Codex Themes |
| One Dark | dark | [one-dark/preview.svg](themes/one-dark/preview.svg) | [**Import theme**](themes/one-dark/import.txt) | Atom / Codex Themes |
| Poimandres | dark | [poimandres/preview.svg](themes/poimandres/preview.svg) | [**Import theme**](themes/poimandres/import.txt) | poimandres / Codex Themes |
| Rosé Pine | dark | [rose-pine/preview.svg](themes/rose-pine/preview.svg) | [**Import theme**](themes/rose-pine/import.txt) | rose-pine / Codex Themes |
| Rosé Pine Dawn | light | [rose-pine-dawn/preview.svg](themes/rose-pine-dawn/preview.svg) | [**Import theme**](themes/rose-pine-dawn/import.txt) | rose-pine / Codex Themes |
| Solarized Dark | dark | [solarized-dark/preview.svg](themes/solarized-dark/preview.svg) | [**Import theme**](themes/solarized-dark/import.txt) | Ethan Schoonover / Codex Themes |
| Solarized Light | light | [solarized-light/preview.svg](themes/solarized-light/preview.svg) | [**Import theme**](themes/solarized-light/import.txt) | Ethan Schoonover / Codex Themes |
| Tokyo Day | light | [tokyo-day/preview.svg](themes/tokyo-day/preview.svg) | [**Import theme**](themes/tokyo-day/import.txt) | enkia / Codex Themes |
| Tokyo Night | dark | [tokyo-night/preview.svg](themes/tokyo-night/preview.svg) | [**Import theme**](themes/tokyo-night/import.txt) | enkia / Codex Themes |
| VOID / 無名 | dark | [void/preview.svg](themes/void/preview.svg) | [**Import theme**](themes/void/import.txt) | Morph (original) |

The collection contains **28 themes**: 26 adapted from [shaw-baobao/codex-themes](https://github.com/shaw-baobao/codex-themes), plus Morph’s Claude Warm and VOID / 無名. Per-theme source files retain author attribution. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for licensing and provenance.

## Build and validate

Requires PowerShell 7.4 or newer:

```powershell
./scripts/Morph.ps1 help
./scripts/Morph.ps1 list
./scripts/Morph.ps1 export nord
./tools/Build-Themes.ps1
./tools/Build-Themes.ps1 -Check
./tests/Run-Tests.ps1
```

Edit `themes/<slug>/theme.json` as the source of truth. The build validates it against `schemas/theme.schema.json`, then generates `import.txt`, `preview.svg`, and `themes/index.json`. The JSON schema is for contributors and automation. It is not importable by Codex Desktop.

## PowerShell CLI

- `list` — list available themes.
- `show <id>` — inspect a source definition.
- `preview <id>` — print its generated SVG preview.
- `export <id>` — print its exact import string.
- `check` — validate all theme sources and report compatibility as unknown.
- `diagnostics` — show local Morph and PowerShell details.
- `backup` and `restore` — copy explicitly named files; restore refuses overwrite. Both support `-WhatIf`.

## Compatibility and safety

- The import string shape comes from community projects; it is not an officially documented Codex Desktop contract.
- Built-in code theme IDs are constrained to the upstream collection’s known set, but a specific Codex build may differ.
- Layout, sidebar, panel, and density customization are unsupported and remain planned.
- No telemetry, downloads, credentials, conversations, background services, app patching, or application settings writes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Preserve theme attribution and update generated files with the build script. New source files must pass the schema and use a known built-in code theme ID.

## License

Morph is MIT licensed. Adapted third-party theme sources and licenses are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
