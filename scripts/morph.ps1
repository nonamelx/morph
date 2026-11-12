#Requires -Version 7.4
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)][ValidateSet('list','show','check','export','backup','restore','diagnostics','help')][string]$Command = 'help',
    [Parameter(Position = 1)][string]$Theme,
    [string]$Path,
    [string]$BackupPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent $PSScriptRoot
$script:ThemesDir = Join-Path $script:Root 'themes'
$script:SchemaPath = Join-Path $script:ThemesDir 'profile.schema.json'

function Read-Profile([string]$Id) {
    if ($Id -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw "Invalid theme identifier: $Id" }
    $file = Join-Path $script:ThemesDir "$Id.json"
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Unknown theme '$Id'. Run: .\scripts\Morph.ps1 list" }
    $p = Get-Content -LiteralPath $file -Raw | ConvertFrom-Json -AsHashtable
    if ($p.id -cne $Id) { throw "Profile id does not match filename: $file" }
    $allowedProfile = @('id','name','description','payload')
    $allowedPayload = @('codeThemeId','theme','variant')
    $allowedTheme = @('accent','contrast','fonts','ink','opaqueWindows','semanticColors','surface')
    $allowedSemantic = @('diffAdded','diffRemoved','skill')
    if (@($p.Keys | Where-Object { $_ -cnotin $allowedProfile }).Count -or @($allowedProfile | Where-Object { $_ -cnotin $p.Keys }).Count) { throw 'Profile keys do not match Morph v1 schema.' }
    if (@($p.payload.Keys | Where-Object { $_ -cnotin $allowedPayload }).Count -or @($allowedPayload | Where-Object { $_ -cnotin $p.payload.Keys }).Count) { throw 'Payload keys do not match Morph v1 schema.' }
    if (@($p.payload.theme.Keys | Where-Object { $_ -cnotin $allowedTheme }).Count -or @($allowedTheme | Where-Object { $_ -cnotin $p.payload.theme.Keys }).Count) { throw 'Theme keys do not match Morph v1 schema.' }
    if (@($p.payload.theme.semanticColors.Keys | Where-Object { $_ -cnotin $allowedSemantic }).Count -or @($allowedSemantic | Where-Object { $_ -cnotin $p.payload.theme.semanticColors.Keys }).Count) { throw 'Semantic color keys do not match Morph v1 schema.' }
    if ($p.payload.codeThemeId -cnotin @('one','one-dark','nord','dracula','catppuccin','gruvbox','solarized','github-light','tokyo-night','matrix')) { throw 'Unsupported built-in codeThemeId.' }
    if ($p.payload.variant -cnotin @('dark','light')) { throw 'Unsupported variant.' }
    foreach ($color in @($p.payload.theme.accent,$p.payload.theme.ink,$p.payload.theme.surface,$p.payload.theme.semanticColors.diffAdded,$p.payload.theme.semanticColors.diffRemoved,$p.payload.theme.semanticColors.skill)) {
        if ($color -cnotmatch '^#[0-9A-Fa-f]{6}$') { throw "Invalid color: $color" }
    }
    if ($p.payload.theme.contrast -isnot [ValueType] -or $p.payload.theme.contrast -lt 0 -or $p.payload.theme.contrast -gt 100) { throw 'Contrast must be a number from 0 to 100.' }
    return $p
}

function Get-ThemeFiles { Get-ChildItem -LiteralPath $script:ThemesDir -Filter '*.json' -File | Where-Object Name -ne 'profile.schema.json' }

switch ($Command) {
    'help' { @'
Morph — Shape your Codex.
Commands: list | show <id> | check | export <id> [-Path file] | backup -Path <source> [-BackupPath <destination>] | restore -Path <backup> -BackupPath <destination> | diagnostics
Export writes a native theme share string. Import it through Codex Desktop Settings > Appearance.
'@ }
    'list' { foreach ($f in Get-ThemeFiles) { $p = Read-Profile $f.BaseName; [pscustomobject]@{ Id=$p.id; Name=$p.name; Variant=$p.payload.variant } } }
    'show' { if (-not $Theme) { throw 'Specify a theme id.' }; Read-Profile $Theme | ConvertTo-Json -Depth 20 }
    'check' { foreach ($f in Get-ThemeFiles) { $null = Read-Profile $f.BaseName }; "Validated $(@(Get-ThemeFiles).Count) profiles against Morph v1 constraints." }
    'export' {
        if (-not $Theme) { throw 'Specify a theme id.' }
        $p = Read-Profile $Theme
        $serialized = 'codex-theme-v1:' + ($p.payload | ConvertTo-Json -Depth 20 -Compress)
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
