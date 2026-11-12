# Morph

**Shape your Codex.**

Morph is a small, open-source toolkit for creating and sharing appearance profiles for Codex Desktop. It packages themes as plain JSON and exports the native-looking share string for the app's visible import control. Morph does not modify Codex files, patch application bundles, inject code, or run in the background.

> Morph is an independent community project and is not affiliated with or endorsed by OpenAI or Anthropic.

## Current status

| Capability | Status |
| --- | --- |
| Claude Warm and VOID dark theme profiles | Stable profile artifacts; Desktop import acceptance is build dependent |
| Profile validation and share-string export | Implemented in the PowerShell CLI |
| Backup and restore of an explicitly selected file | Implemented; restore refuses to overwrite |
| Direct Codex Desktop installation | Not implemented; use the app's visible settings |
| Layout, sidebar position, panel arrangement | Planned; no supported interface established |
| Codex CLI adapter | Planned separately; CLI uses TextMate `.tmTheme` files |

## Quick start

Requires PowerShell 7.4 or newer. Clone the repository, then run:

```powershell
 .\scripts\Morph.ps1 list
 .\scripts\Morph.ps1 show claude-warm
 .\scripts\Morph.ps1 export claude-warm
```

The export is a `codex-theme-v1:` share string. Copy the full line and, if your Codex Desktop build visibly offers theme import, open **Settings → Appearance → Dark theme → Import**, paste it, inspect the preview, and apply. Morph cannot guarantee that every build accepts the observed community format. If no import control is present or the payload is rejected, stop and keep your current appearance.

## Beginner: ask Codex to help

Open this repository in Codex and paste the prompt in [`prompts/install-theme.md`](prompts/install-theme.md). It asks Codex to read the profile, explain the manual import steps, and avoid editing Codex settings or application files.

## Themes

- **Claude Warm** — warm charcoal, cream text, terracotta accent.
- **VOID / 無名** — near-black graphite with a muted red accent.

Profiles are data only. They cannot contain scripts or commands. The v1 schema is intentionally narrower than any undocumented app format and permits only known community-reported code theme IDs. Import compatibility is not asserted as officially guaranteed.

## PowerShell commands

```powershell
 .\scripts\Morph.ps1 list
 .\scripts\Morph.ps1 show void
 .\scripts\Morph.ps1 check
 .\scripts\Morph.ps1 export void -Path .\void.share.txt -WhatIf
 .\scripts\Morph.ps1 backup -Path .\settings.json -WhatIf
 .\scripts\Morph.ps1 restore -Path .\settings.json.morph-backup -BackupPath .\settings-restored.json -WhatIf
 .\scripts\Morph.ps1 diagnostics
```

`export` writes only the specified output file. `backup` copies one explicitly selected file to a new backup path; by default the destination is timestamped and next to the source. `restore` copies a backup into a destination that must not already exist. Both operations support `-WhatIf`; neither command targets Codex automatically. Restore to a new file, inspect it, then decide manually whether to use it. `-WhatIf` reports the action without performing it.

## Compatibility

Codex Desktop appearance controls and import behavior can change by platform and app build. Current public product material indicates color and font appearance customization; the detailed `codex-theme-v1:` contract is community-observed and not a formal supported API. Use the built-in code theme ID embedded in each profile and confirm the visible preview before applying. Morph has not been verified against every Windows, macOS, or Linux build.

Typography is included as optional font family strings in the profile format; bundled or downloaded fonts are not provided. UI controls remain the source of truth for the current app behavior.

## Security

- No telemetry, credential access, conversation access, hidden downloads, or background service.
- No administrator privileges required.
- No remote script execution or arbitrary profile code.
- No direct changes to Codex settings, authentication, models, MCP, account, project settings, or application bundles.
- File backup/restore requires explicit paths; restore never overwrites an existing destination.

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). New profiles must validate against [`themes/profile.schema.json`](themes/profile.schema.json), use documented colors and attribution, and avoid undocumented configuration keys or installation code.

## Roadmap

1. Expand supported profile validation as Codex documents a stable format.
2. Add reviewed light variants and contrast checks.
3. Investigate supported layout customization and keep unsupported ideas experimental.
4. Build a separate Codex CLI theme adapter using `.tmTheme` only when useful.

## License

MIT. See [LICENSE](LICENSE).
