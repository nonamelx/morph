#Requires -Version 7.4
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$themes = Join-Path $root 'themes'
$schemaFile = Join-Path $themes 'profile.schema.json'

function Escape-Xml([string]$Text) {
    if ($null -eq $Text) { return '' }
    return [System.Security.SecurityElement]::Escape($Text)
}

foreach ($file in Get-ChildItem -LiteralPath $themes -Filter '*.json' -File | Where-Object Name -ne 'profile.schema.json' | Sort-Object Name) {
    $raw = Get-Content -LiteralPath $file.FullName -Raw
    if (-not (Test-Json -Json $raw -SchemaFile $schemaFile)) { throw "Invalid theme profile: $($file.Name)" }
    $profile = $raw | ConvertFrom-Json -AsHashtable
    $p = $profile.payload
    $out = Join-Path $themes "$($profile.id).svg"
    $label = Escape-Xml $profile.name
    $description = Escape-Xml $profile.description
    $surface = $p.theme.surface; $ink = $p.theme.ink; $accent = $p.theme.accent
    $add = $p.theme.semanticColors.diffAdded; $remove = $p.theme.semanticColors.diffRemoved
    $svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="960" height="560" viewBox="0 0 960 560" role="img" aria-labelledby="title desc">
  <title id="title">$label theme preview</title>
  <desc id="desc">Illustrative palette preview, not a Codex screenshot. $description</desc>
  <rect width="960" height="560" rx="24" fill="$surface"/>
  <rect x="0" y="0" width="190" height="560" rx="24" fill="$($p.theme.surface)"/>
  <rect x="24" y="28" width="142" height="10" rx="5" fill="$accent"/>
  <rect x="24" y="68" width="130" height="12" rx="6" fill="$ink" opacity=".7"/>
  <rect x="24" y="104" width="108" height="12" rx="6" fill="$ink" opacity=".3"/>
  <rect x="24" y="144" width="122" height="12" rx="6" fill="$ink" opacity=".3"/>
  <rect x="24" y="184" width="94" height="12" rx="6" fill="$ink" opacity=".3"/>
  <text x="230" y="76" font-family="Segoe UI, sans-serif" font-size="20" fill="$ink">MORPH / ILLUSTRATION</text>
  <text x="230" y="132" font-family="Segoe UI, sans-serif" font-size="36" font-weight="600" fill="$ink">$label</text>
  <text x="230" y="168" font-family="Segoe UI, sans-serif" font-size="17" fill="$ink" opacity=".72">$description</text>
  <rect x="230" y="210" width="670" height="200" rx="18" fill="$ink" opacity=".06" stroke="$ink" stroke-opacity=".14"/>
  <text x="260" y="252" font-family="Segoe UI, sans-serif" font-size="16" fill="$ink" opacity=".76">Appearance preview</text>
  <text x="260" y="302" font-family="Segoe UI, sans-serif" font-size="22" fill="$ink">A calm workspace for your next idea.</text>
  <rect x="260" y="338" width="158" height="42" rx="10" fill="$accent"/>
  <text x="283" y="365" font-family="Segoe UI, sans-serif" font-size="15" font-weight="600" fill="$surface">Continue</text>
  <rect x="440" y="338" width="180" height="42" rx="10" fill="none" stroke="$ink" stroke-opacity=".32"/>
  <text x="464" y="365" font-family="Segoe UI, sans-serif" font-size="15" fill="$ink">Secondary action</text>
  <text x="230" y="454" font-family="Consolas, monospace" font-size="16" fill="$add">+ added line</text>
  <text x="230" y="484" font-family="Consolas, monospace" font-size="16" fill="$remove">− removed line</text>
  <rect x="230" y="518" width="12" height="12" rx="6" fill="$surface" stroke="$ink"/>
  <text x="252" y="529" font-family="Segoe UI, sans-serif" font-size="13" fill="$ink" opacity=".7">Illustrative preview — not a Codex screenshot</text>
</svg>
"@
    $svg = ($svg.Trim() + "`n").Replace("`r`n", "`n")
    $artifact = Join-Path $themes "$($profile.id).codex-theme-v1"
    $cli = Join-Path $root 'scripts/Morph.ps1'
    $share = (& $cli export $profile.id | Out-String).Trim()
    $artifactText = $share + "`n"
    if ($Check) {
        if (-not (Test-Path -LiteralPath $out)) { throw "Preview is stale: $out. Run tools/Generate-Previews.ps1." }; $existing = (Get-Content -LiteralPath $out -Raw).Replace("`r`n", "`n"); if ($existing -cne $svg) { throw "Preview is stale: $out. Run tools/Generate-Previews.ps1." }
        if (-not (Test-Path -LiteralPath $artifact)) { throw "Import artifact missing: $artifact" }; $existingArtifact = (Get-Content -LiteralPath $artifact -Raw).Replace("`r`n", "`n"); if ($existingArtifact -cne $artifactText) { throw "Import artifact is stale: $artifact" }
    } else {
        Set-Content -LiteralPath $out -Value $svg -Encoding utf8NoBOM -NoNewline
        Set-Content -LiteralPath $artifact -Value $artifactText -Encoding utf8NoBOM -NoNewline
    }
}

if ($Check) { 'All theme previews and artifacts are current.' } else { 'Generated deterministic theme previews and import artifacts.' }
