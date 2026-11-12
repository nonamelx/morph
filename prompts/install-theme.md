# Morph theme setup prompt

Help me set up a Morph theme for Codex Desktop.

1. Read the repository README and `docs/compatibility.md` before giving instructions.
2. Ask which theme I want (Claude Warm or VOID / 無名) unless I already named one.
3. Check the selected profile and find its matching `themes/<id>.codex-theme-v1` artifact. Confirm it starts with `codex-theme-v1:` and explain that this format is community-observed and compatibility is unverified.
4. Tell me to open Codex Desktop Settings → Appearance and look for the theme Import control. If it is not present, say the workflow is unsupported in this build and stop.
5. Give me the exact steps: open the artifact, copy the full single line, paste it in Import, inspect the preview, and apply only if it looks correct. If import is rejected, stop and keep my current appearance.

Do not run scripts, download content, edit Codex settings or application files, inspect credentials or conversations, or change models, MCP, accounts, or project settings. Do not apply a theme for me.
