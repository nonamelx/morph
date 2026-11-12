# Compatibility notes

## Stable

- Profile JSON is locally validated by Morph's deliberately constrained v1 rules.
- Theme export serializes profile appearance data into the community-observed `codex-theme-v1:` share-string shape.
- Codex Desktop users may use a visible Appearance import control if their installed build provides it.

## Experimental

- Desktop import payload compatibility: community repositories contain examples, but public OpenAI documentation does not publish a formal schema or version matrix. A community report notes that an unknown `codeThemeId` can disable import; Morph uses a reported built-in ID and keeps acceptance build-dependent.
- Fonts: theme payloads can include font fields in observed examples, but actual font availability and rendering depend on the host and app build.

## Planned

- Layout profiles for sidebar placement, panel positions, density, focus mode, and Claude-inspired arrangements. No supported mechanism was established for these controls.
- Direct install/rollback adapters. Morph currently exports data and does not modify Codex settings.
- Codex CLI adapter. The CLI's official customization docs describe TextMate `.tmTheme` files under `$CODEX_HOME/themes`; this differs from Desktop theme payloads.

Morph does not patch executables, inject JavaScript/CSS, or edit internal app files.
