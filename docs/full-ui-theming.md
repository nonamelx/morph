# Full UI theming research

**Reviewed:** 2026-11-12  
**Scope:** Codex Desktop appearance and layout customization, based on public documentation, Morph's generated theme format, and one user-reported Windows import test.

## Findings at a glance

Morph currently distributes 28 themes as `codex-theme-v1:` imports. A user manually imported a Morph theme into Codex Desktop on Windows. The import was accepted; the main application background, chat sidebar colors, and accents changed, and text remained readable. The far-left navigation rail and top application bar retained their original styling. The app build was not recorded and persistence after restarting has not been checked. This is evidence for one installation only, not a compatibility guarantee.

The current OpenAI Appearance reference is headed as instructions for the ChatGPT desktop app. It describes light/dark/system selection, accent/background/foreground colors, UI and code fonts, custom-theme import/sharing, translucent sidebar, contrast, and UI/code font sizes. It includes `ThemeConfig` preview snippets using `surface: "sidebar"` and `surface: "sidebar-elevated"`. Because the reference does not establish that those controls or snippets apply to Codex Desktop, their applicability to the tested Codex build is unverified; the snippets are not documented as a stable full-component styling API. The public configuration reference and CLI customization docs do not document a Desktop CSS/theme extension API. The CLI's `.tmTheme` and `tui.theme` settings concern the terminal UI and should not be treated as Desktop controls.

No CSS variables, selectors, or Desktop styling architecture were inspected. Public documentation does not expose a supported contract for them, so their existence or names should not be inferred. No Codex executable, application bundle, running process, credentials, or private data were inspected or modified.

## Coverage and classification

Classifications describe the available Morph route, not every internal capability Codex may have.

| Region or capability | Current evidence and coverage | Classification |
| --- | --- | --- |
| Base light/dark appearance | OpenAI's current Appearance reference for the ChatGPT desktop app documents light, dark, and system modes. Applicability to Codex Desktop is unverified. | Experimental for Codex; documented for ChatGPT |
| Accent, background, foreground | The ChatGPT desktop reference lists these controls. A user report confirms that a Morph import changed these kinds of appearance in one Codex Desktop installation, but does not map all fields independently. | Experimental for Codex; partial user evidence |
| Chat sidebar | User report confirms sidebar colors changed. The ChatGPT desktop reference mentions sidebar translucency and preview surfaces, but Codex applicability and component coverage are unverified. | Experimental, with limited user evidence |
| Far-left navigation rail | Stayed original in the reported test. No documented per-rail theme control found. | Unsupported through Morph imports |
| Top application bar | Stayed original in the reported test. No documented per-bar theme control found. | Unsupported through Morph imports |
| Main content area | Main background changed in the reported test; individual controls and nested surfaces are not mapped. | Supported, partial |
| Composer | Not separately tested; no documented component-level controls found. | Unknown; planned for measurement |
| Buttons and icons | Accent changes observed, but individual component coverage and icon recoloring are not established. | Experimental/partial |
| Modal dialogs and settings panels | Not separately tested or specified as independently styleable. | Unknown; planned for measurement |
| Typography | The ChatGPT desktop reference lists UI/code font selection and size. Codex applicability and exact per-region mapping are unverified; spacing controls are not documented. | Experimental for Codex; documented for ChatGPT fonts; spacing unsupported |
| Sidebar position, panel visibility, and layout | No public Appearance or configuration mechanism found for repositioning/resizing panels or changing their visibility as a theme. | Unsupported through themes |
| CSS variables or custom stylesheets | No public supported interface found. Token names and component mappings remain unknown. | Unsupported |
| Restart persistence | Not tested for this report. | Unknown; planned for measurement |

## Supported mechanisms and boundaries

### Native Appearance settings

Use Codex Desktop's own Settings → Appearance controls and its visible custom-theme import flow when present. OpenAI's current reference describes similar Appearance controls for the ChatGPT desktop app, but does not establish that they are supported or identical in Codex Desktop. The user's manual import demonstrates acceptance on one Windows installation only. An imported theme is a palette, not a full application skin or layout definition.

The import payload format `codex-theme-v1:` has been validated by Morph's generator and one user-reported Desktop import. The format and its component mapping are not documented by OpenAI's public reference, so Morph must continue labeling compatibility as community-derived and build-specific.

### Configuration files

The public Codex config reference documents product settings but does not document CSS selectors or a Desktop full-UI theme adapter. The CLI customization guide describes terminal UI theming using `tui.theme` and `.tmTheme`; that mechanism is not evidence of Desktop support. Avoid copying undocumented Desktop keys from issue reports or forum posts into user configuration: a report that a key worked in one build is not a supported contract.

### Styling architecture and layout

Publicly observable appearance behavior is limited to user-facing settings and rendered output. No inspectable public source established a CSS-variable contract, component token map, or layout extension point. Morph should not reverse engineer private bundles to fill that gap. Layout controls such as rail position, top-bar treatment, panel sizing, visibility, and spacing are not exposed by the documented theme mechanism.

## Potential approaches

1. **Native theme collection (Supported):** keep one clear source format, produce import strings/previews, and state exactly which appearance controls are represented. This is the recommended current product.
2. **Versioned compatibility observations (Planned):** gather opt-in, non-sensitive reports that record app version, OS, imported theme, affected regions, readability, and restart persistence. Do not collect screenshots or conversations by default.
3. **Capability adapter boundary (Experimental):** design a small adapter interface that accepts Morph's normalized palette and reports capabilities such as `accent`, `surface`, `font`, `layout`, and `unsupported`. Initially, ship only a native-import adapter. Add another adapter only when Codex exposes a documented extension point; do not implement CSS injection, runtime hooks, or bundle edits.
4. **Unofficial internal modifications (Unsupported):** editing packaged resources, injecting CSS/JavaScript, patching binaries, or disabling protections would be fragile, security-sensitive, and outside Morph's supported scope. Do not pursue these approaches.

## Security implications

- Keep theme definitions as inert data. Validate values and never evaluate strings from theme profiles.
- Any future adapter should declare exactly which user-owned configuration files it reads or writes and require an explicit user action before writing.
- Do not inspect or alter credentials, account state, private conversations, app bundles, executable code, or runtime process memory.
- Do not install third-party patchers or weaken application security settings.
- Treat community posts and undocumented setting names as untrusted evidence; a successful workaround does not establish safety or support.

## Compatibility risks

- Theme import payloads and component mappings are not publicly specified, so a Codex update may reject imports or change which regions respond.
- Current manual evidence is from one Windows installation with no recorded build number. Restart persistence and other operating systems are unverified.
- Color and contrast behavior may vary by base mode, OS chrome, translucent surfaces, and accessibility settings.
- Any future undocumented key or selector could disappear, be renamed, or change semantics without notice.
- Morph previews are generated illustrations and do not prove the rendered appearance in Codex Desktop.

## Recommended architecture

Keep Morph independent and data-first. Maintain canonical theme sources and a deterministic native import generator. Add a compatibility manifest to reports/tests rather than coupling theme generation to a specific application build. A future adapter interface should be isolated from core theme data and capability-gated; the native importer remains the default. No adapter should write to Codex internals. If an official Desktop extension API appears, implement against its documented versioned contract and keep the native import path available as a fallback.

### Proposed experimental adapter contract

The proposed adapter is an architectural boundary only; this document does not implement an application connector or file writer.

```text
Adapter.describe() -> { name, version, capabilities, evidence }
Adapter.preview(theme) -> { supportedFields, ignoredFields, warnings }
Adapter.apply(theme) -> explicit user action through a documented host API
Adapter.rollback(previousState) -> restore through that same documented API
```

The first implementation should be a read-only capability report around the current native import artifact. It should clearly report that layout, rail, and top-bar styling are unsupported. Only a documented host API may enable an applying adapter in the future.

## Rollback strategy

For current themes, use Codex Desktop's Appearance settings to select the prior theme or re-import the previous theme string. Record the previous theme before experimenting. Morph itself does not mutate Codex configuration. If a future official file-based API is adopted, make a backup of the exact user-owned file, write only documented fields, validate before replacement, and provide a restore action that uses the backup. Never roll back by editing packaged application files.

## Implementation milestones

1. **Document current limits:** publish the single-installation observation with missing version and persistence fields clearly stated.
2. **Build a report matrix:** define a manual checklist for rail, top bar, chat sidebar, main content, composer, buttons/icons, dialogs, settings, typography, spacing, panel position/visibility, and restart persistence. Record OS and exact Desktop build.
3. **Collect evidence safely:** test one theme per supported build with user consent; record outcomes without account or conversation data. Keep import UI testing manual and reversible.
4. **Define adapter types:** add a capability report model and tests that distinguish supported palette fields from unsupported layout regions. Do not add a writer until an official API is identified.
5. **Prototype supported integration:** if Codex publishes a Desktop customization API, create an opt-in adapter against its documented schema and version, preserve native imports, and include a preview/dry-run.
6. **Validate and maintain:** check contrast/readability, import acceptance, restart persistence, rollback, and behavior across supported builds; update the matrix as versions change.

## Sources

- [OpenAI desktop settings reference: Appearance](https://learn.chatgpt.com/docs/reference/settings) — currently describes the ChatGPT desktop app's controls, import/share UI, fonts, sidebar translucency, contrast, and font sizes; Codex Desktop applicability is unverified.
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) — public configuration surface reviewed for documented Desktop styling/layout controls.
- [Codex CLI customization](https://learn.chatgpt.com/docs/cli-customization) — CLI/TUI theme mechanism; not Desktop styling.
- [OpenAI Codex issue #25374](https://github.com/openai/codex/issues/25374) — community report about undocumented appearance-related configuration keys; treated as experimental evidence, not support.
- [OpenAI Codex issue #14766](https://github.com/openai/codex/issues/14766) — community report illustrating code-theme ID compatibility limits.

The documentation and issue pages were reviewed on 2026-11-12. UI behavior statements about Morph are based on the user-reported manual test described above; no independent Codex Desktop UI test was available in this research run.
