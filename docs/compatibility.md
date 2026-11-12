# Compatibility notes

## Stable within Morph

- Theme source JSON is validated by Morph's schema, adapted from the upstream theme collection schema.
- The generator maps theme source fields into the community-derived `codex-theme-v1:` share-string shape.
- Checked-in `import.txt` artifacts and illustrative SVG previews are reproducibly generated from each source definition.

## Experimental

- Desktop import payload compatibility: community repositories contain examples, but public OpenAI documentation does not publish a formal schema or version matrix. A community report notes that an unknown `codeThemeId` can disable import; Morph constrains IDs to the upstream collection's reported built-in set. One Windows user reported an accepted import, as described below; acceptance on other builds remains unverified.
- Fonts: theme payloads can include font fields in observed examples, but actual font availability and rendering depend on the host and app build.

## Planned

- Layout profiles for sidebar placement, panel positions, density, focus mode, and Claude-inspired arrangements. No supported mechanism was established for these controls.
- Direct install/rollback adapters. Morph currently exports data and does not modify Codex settings.
- Codex CLI adapter. The CLI's official customization docs describe TextMate `.tmTheme` files under `$CODEX_HOME/themes`; this differs from Desktop theme payloads.

Morph does not patch executables, inject JavaScript/CSS, or edit internal app files.

## User-reported Windows test

A user manually imported a Morph theme into Codex Desktop on Windows and reported that the app accepted the import. The main application background, chat sidebar, and accent colors changed, and text remained readable in the tested interface. The far-left navigation rail and top application bar retained their original styling. This observation was reported by the user and was not independently reproduced by the Morph development workflow.

The theme name and Codex Desktop version or build were not provided. Persistence after restarting Codex has not been verified. This single observation does not establish compatibility across versions or full interface coverage. Users must confirm that their build shows an Import control and accepts the artifact. The previews are generic visual representations generated from source colors; they do not depict Codex Desktop.

## Sources (reviewed 2026-11-12)

- [Codex CLI customization (OpenAI documentation)](https://learn.chatgpt.com/docs/cli-customization) documents the separate `.tmTheme` workflow for the CLI.
- [Codex app appearance settings (OpenAI documentation)](https://learn.chatgpt.com/docs/reference/settings) describes Desktop theme, color, and font controls and theme sharing, but does not specify the observed import string contract.
- [Codex config basics (OpenAI documentation)](https://learn.chatgpt.com/docs/config-file/config-basic) describes the user-level `config.toml`; Morph does not write it.
- [Anthropic Codex Theme](https://github.com/miniLV/Anthropic-codex-theme) and [Claude Warm Codex App Theme](https://github.com/YuChenSSR/claude-warm-codex-app-theme) are community research references, not trusted installer instructions. The latter includes sample `codex-theme-v1:` payloads.
- [Codex Themes](https://github.com/shaw-baobao/codex-themes) provides the adapted source-to-import mapping approach and source-theme definitions; Morph's notices document exact licensing and commit provenance.
- [Codex issue #14766](https://github.com/openai/codex/issues/14766) reports a macOS importer build that rejected unknown code theme IDs. This is a user report, not a formal compatibility guarantee.
- [Codex issue #25374](https://github.com/openai/codex/issues/25374) reports a Windows 10 Desktop rendering issue where opaque windows served as a workaround in a specific build context.

No public formal Desktop theme schema or tested version matrix was found during this review. Morph's imported format and compatibility therefore remain build dependent.
