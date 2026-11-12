#Requires -Version 7.4
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$themesDir = Join-Path $root 'themes'
$schema = Join-Path $root 'schemas/theme.schema.json'
$items = @()

function Escape-Xml([string]$Text) {
    if ($null -eq $Text) { return '' }
    return [System.Security.SecurityElement]::Escape($Text)
}

foreach ($folder in Get-ChildItem -LiteralPath $themesDir -Directory | Sort-Object Name) {
    $sourcePath = Join-Path $folder.FullName 'theme.json'
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { continue }
    $raw = Get-Content -LiteralPath $sourcePath -Raw
    if (-not (Test-Json -Json $raw -SchemaFile $schema)) { throw "Invalid theme source: $sourcePath" }
    $source = $raw | ConvertFrom-Json -AsHashtable
    if ($source.slug -cne $folder.Name) { throw "Theme slug '$($source.slug)' does not match folder '$($folder.Name)'." }
    $id = $source.slug
    $cli = Join-Path $root 'scripts/Morph.ps1'
    $import = (& $cli export $id | Out-String).Trim()
    if (-not $import.StartsWith('codex-theme-v1:')) { throw "Generated import has invalid prefix: $id" }
    $importText = $import + "`n"

    $theme = $source.theme
    $name = Escape-Xml $source.name
    $description = Escape-Xml $source.description
    $mode = Escape-Xml $source.mode.ToUpperInvariant()
    $tags = Escape-Xml ($source.tags -join ' · ')
    $accent = $theme.accent
    $background = $theme.background
    $surface = if ($theme.surface) { $theme.surface } else { $background }
    $foreground = $theme.foreground
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="960" height="560" viewBox="0 0 960 560" role="img" aria-labelledby="title desc">
  <title id="title">$name theme preview</title>
  <desc id="desc">Illustrative preview generated from this theme's source colors. Not a Codex screenshot. $description</desc>
  <rect width="960" height="560" rx="24" fill="$background"/>
  <rect x="22" y="22" width="916" height="516" rx="20" fill="$surface" stroke="$foreground" stroke-opacity=".12"/>
  <rect x="22" y="22" width="916" height="68" rx="20" fill="$foreground" opacity=".06"/>
  <circle cx="55" cy="56" r="8" fill="$accent"/>
  <circle cx="82" cy="56" r="8" fill="$foreground" opacity=".25"/>
  <circle cx="109" cy="56" r="8" fill="$foreground" opacity=".14"/>
  <text x="145" y="63" font-family="Segoe UI, sans-serif" font-size="18" fill="$foreground">MORPH / $mode</text>
  <rect x="50" y="118" width="235" height="380" rx="14" fill="$background" opacity=".62"/>
  <rect x="72" y="145" width="145" height="10" rx="5" fill="$accent"/>
  <rect x="72" y="184" width="174" height="10" rx="5" fill="$foreground" opacity=".38"/>
  <rect x="72" y="218" width="140" height="10" rx="5" fill="$foreground" opacity=".25"/>
  <rect x="72" y="252" width="160" height="10" rx="5" fill="$foreground" opacity=".25"/>
  <text x="326" y="160" font-family="Segoe UI, sans-serif" font-size="34" font-weight="600" fill="$foreground">$name</text>
  <text x="326" y="197" font-family="Segoe UI, sans-serif" font-size="16" fill="$foreground" opacity=".72">$description</text>
  <text x="326" y="228" font-family="Segoe UI, sans-serif" font-size="14" fill="$foreground" opacity=".62">$tags</text>
  <rect x="326" y="258" width="556" height="168" rx="16" fill="$background" stroke="$foreground" stroke-opacity=".14"/>
  <text x="352" y="298" font-family="Segoe UI, sans-serif" font-size="16" fill="$foreground" opacity=".75">A calm workspace for your next idea.</text>
  <rect x="352" y="326" width="154" height="42" rx="10" fill="$accent"/>
  <text x="374" y="353" font-family="Segoe UI, sans-serif" font-size="15" font-weight="600" fill="$background">Continue</text>
  <rect x="522" y="326" width="172" height="42" rx="10" fill="none" stroke="$foreground" stroke-opacity=".34"/>
  <text x="544" y="353" font-family="Segoe UI, sans-serif" font-size="15" fill="$foreground">Secondary action</text>
  <text x="352" y="399" font-family="Consolas, monospace" font-size="14" fill="$foreground" opacity=".72">$($source.codeThemeId) · contrast $($theme.contrast)</text>
  <text x="326" y="470" font-family="Segoe UI, sans-serif" font-size="13" fill="$foreground" opacity=".7">Illustrative preview — not a Codex screenshot</text>
</svg>
"@
    $svg = ($svg.Trim() + "`n").Replace("`r`n", "`n")
    $previewPath = Join-Path $folder.FullName 'preview.svg'
    $importPath = Join-Path $folder.FullName 'import.txt'
    if ($Check) {
        foreach ($artifactCheck in @(@{Path=$previewPath;Expected=$svg;Label='preview'},@{Path=$importPath;Expected=$importText;Label='import'})) {
            if (-not (Test-Path -LiteralPath $artifactCheck.Path)) { throw "Missing $($artifactCheck.Label): $($artifactCheck.Path)" }
            $actual = (Get-Content -LiteralPath $artifactCheck.Path -Raw).Replace("`r`n", "`n")
            if ($actual -cne $artifactCheck.Expected) { throw "Stale $($artifactCheck.Label): $($artifactCheck.Path)" }
        }
    } else {
        Set-Content -LiteralPath $previewPath -Value $svg -Encoding utf8NoBOM -NoNewline
        Set-Content -LiteralPath $importPath -Value $importText -Encoding utf8NoBOM -NoNewline
    }
    $items += [pscustomobject]@{ name=$source.name; slug=$id; author=$source.author; mode=$source.mode; tags=$source.tags; description=$source.description; preview="themes/$id/preview.svg"; import="themes/$id/import.txt" }
}

$index = (($items | ConvertTo-Json -Depth 20).Replace("`r`n", "`n"))
$indexPath = Join-Path $themesDir 'index.json'
if ($Check) {
    if (-not (Test-Path -LiteralPath $indexPath)) { throw 'Missing themes/index.json.' }
    $actualIndex = (Get-Content -LiteralPath $indexPath -Raw).Replace("`r`n", "`n")
    if ($actualIndex -cne ($index + "`n")) { throw 'Stale themes/index.json.' }
    'All source schemas, import artifacts, previews, and catalog data are current.'
} else {
    Set-Content -LiteralPath $indexPath -Value ($index + "`n") -Encoding utf8NoBOM -NoNewline
    "Generated $($items.Count) import artifacts, previews, and catalog records."
}
