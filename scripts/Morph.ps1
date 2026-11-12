#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)][ValidateSet('list','show','check','export','backup','restore','diagnostics','help','preview')][string]$Command = 'help',
    [Parameter(Position = 1)][string]$Theme,
    [string]$Path,
    [string]$BackupPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent $PSScriptRoot
$script:ThemesDir = Join-Path $script:Root 'themes'
$script:SchemaPath = Join-Path $script:Root 'schemas/theme.schema.json'

function Read-Profile([string]$Id) {
    if ($Id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Invalid theme identifier: $Id" }
    $file = Join-Path (Join-Path $script:ThemesDir $Id) 'theme.json'
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Unknown theme '$Id'. Run: .\scripts\Morph.ps1 list" }
    $rawProfile = Get-Content -LiteralPath $file -Raw
    if (-not (Test-Json -Json $rawProfile -SchemaFile $script:SchemaPath)) { throw "Theme source failed JSON schema validation: $file" }
    $p = $rawProfile | ConvertFrom-Json -AsHashtable
    if ($p.slug -cne $Id) { throw "Theme slug does not match folder name: $file" }
    return $p
}

function Get-ThemeFiles { Get-ChildItem -LiteralPath $script:ThemesDir -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'theme.json') } | Sort-Object Name }

function Get-Artifact([string]$Id) {
    $p = Read-Profile $Id
    $source = $p.theme
    $semantic = $source['semanticColors']
    if (-not $semantic) {
        if ($p.mode -eq 'dark') { $added='#4ade80'; $removed='#f87171' } else { $added='#16a34a'; $removed='#dc2626' }
        $semantic = [ordered]@{ diffAdded=$added; diffRemoved=$removed; skill=$source.accent }
    }
    $canonical = [ordered]@{
        codeThemeId = $p.codeThemeId
        theme = [ordered]@{
            accent = $source.accent
            contrast = $source.contrast
            fonts = [ordered]@{ code = $source.fonts.code; ui = $source.fonts.ui }
            ink = $source.foreground
            opaqueWindows = if ($null -ne $source['opaqueWindows']) { $source['opaqueWindows'] } else { $false }
            semanticColors = [ordered]@{}
            surface = if ($source['surface']) { $source['surface'] } else { $source.background }
        }
        variant = $p.mode
    }
    foreach ($key in @($semantic.Keys | Sort-Object)) { $canonical.theme.semanticColors[$key] = $semantic[$key] }
    'codex-theme-v1:' + ($canonical | ConvertTo-Json -Depth 20 -Compress)
}

switch ($Command) {
    'help' { @'
Morph — Shape your Codex.
Commands: help | list | show <id> | preview <id> | check | export <id> [-Path file] | backup -Path <source> [-BackupPath <destination>] | restore -Path <backup> -BackupPath <destination> | diagnostics
Export writes an observed theme share string. Import remains build dependent and unverified; use Codex Desktop Settings > Appearance only if Import is visible.
'@ }
    'list' { foreach ($f in Get-ThemeFiles) { $p = Read-Profile $f.Name; [pscustomobject]@{ Id=$p.slug; Name=$p.name; Variant=$p.mode; Author=$p.author } } }
    'show' { if (-not $Theme) { throw 'Specify a theme id.' }; Read-Profile $Theme | ConvertTo-Json -Depth 20 }
    'preview' {
        if (-not $Theme) { throw 'Specify a theme id.' }
        $null = Read-Profile $Theme
        $svg = Join-Path (Join-Path $script:ThemesDir $Theme) 'preview.svg'
        if (-not (Test-Path -LiteralPath $svg -PathType Leaf)) { throw "Preview not found for '$Theme'. Run tools/Build-Themes.ps1." }
        Get-Content -LiteralPath $svg -Raw
    }
    'check' { foreach ($f in Get-ThemeFiles) { $null = Read-Profile $f.Name }; "Validated $(@(Get-ThemeFiles).Count) theme sources against the Morph theme schema."; 'Codex Desktop compatibility: unknown. Check whether Settings > Appearance visibly offers theme import; no build matrix is verified.' }
    'export' {
        if (-not $Theme) { throw 'Specify a theme id.' }
        $serialized = Get-Artifact $Theme
        if ($Path) {
            $target = [IO.Path]::GetFullPath($Path)
            if (Test-Path -LiteralPath $target) { throw "Refusing to overwrite existing path: $target" }
            if ($PSCmdlet.ShouldProcess($target, 'Write theme share string')) { Set-Content -LiteralPath $target -Value $serialized -Encoding utf8NoBOM }
        } else { $serialized }
    }
    'backup' {
        if (-not $Path) { throw 'Specify -Path for a file to back up.' }
        $source = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        if ((Get-Item -LiteralPath $source).PSIsContainer) { throw 'Backup accepts a single file, not a directory.' }
        if (-not $BackupPath) { $BackupPath = "$source.morph-backup-$(Get-Date -Format yyyyMMdd-HHmmss)" }
        $dest = [IO.Path]::GetFullPath($BackupPath)
        if (Test-Path -LiteralPath $dest) { throw "Backup destination already exists: $dest" }
        if ($PSCmdlet.ShouldProcess($source, "Copy backup to $dest")) { Copy-Item -LiteralPath $source -Destination $dest }
        $dest
    }
    'restore' {
        if (-not $Path) { throw 'Specify -Path as the backup file.' }
        if (-not $BackupPath) { throw 'Specify -BackupPath as the destination file to restore.' }
        $source = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        if ((Get-Item -LiteralPath $source).PSIsContainer) { throw 'Restore source must be a single backup file.' }
        $dest = [IO.Path]::GetFullPath($BackupPath)
        if (Test-Path -LiteralPath $dest -PathType Container) { throw 'Restore destination must be a file path.' }
        if (Test-Path -LiteralPath $dest) { throw "Refusing to overwrite existing file: $dest" }
        if ($PSCmdlet.ShouldProcess($dest, "Restore from $source")) { Copy-Item -LiteralPath $source -Destination $dest }
        $dest
    }
    'diagnostics' {
        [pscustomobject]@{ OS=[Environment]::OSVersion.VersionString; PowerShell=$PSVersionTable.PSVersion.ToString(); MorphRoot=$script:Root; CodexHome=if ($env:CODEX_HOME) {$env:CODEX_HOME} else {Join-Path $HOME '.codex'}; CodexDesktop='Not modified or inspected'; ThemeCount=(Get-ThemeFiles).Count }
    }
}
