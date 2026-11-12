#Requires -Version 7.4
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cli = Join-Path $root 'scripts/Morph.ps1'
$builder = Join-Path $root 'tools/Build-Themes.ps1'
$themes = Join-Path $root 'themes'
$schemaPath = Join-Path $root 'schemas/theme.schema.json'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("morph-tests-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    & $builder -Check | Out-Null
    $check = @(& $cli check)
    if (($check -join "`n") -notmatch 'compatibility: unknown') { throw 'Compatibility status was not reported accurately.' }
    $catalog = @(Get-Content -LiteralPath (Join-Path $themes 'index.json') -Raw | ConvertFrom-Json)
    $listed = @(& $cli list)
    if ($catalog.Count -lt 3 -or $listed.Count -ne $catalog.Count) { throw 'CLI list and catalog counts differ.' }
    $schema = Get-Content -LiteralPath $schemaPath -Raw
    foreach ($entry in $catalog) {
        $folder = Join-Path $themes $entry.slug
        $sourcePath = Join-Path $folder 'theme.json'
        $source = Get-Content -LiteralPath $sourcePath -Raw
        if (-not (Test-Json -Json $source -Schema $schema)) { throw "Schema rejected $($entry.slug)." }
        $importPath = Join-Path $folder 'import.txt'
        $import = (Get-Content -LiteralPath $importPath -Raw).Trim()
        if (-not $import.StartsWith('codex-theme-v1:')) { throw "Import prefix missing for $($entry.slug)." }
        if ($import -cne ((& $cli export $entry.slug | Out-String).Trim())) { throw "CLI/export artifact mismatch: $($entry.slug)." }
        $payload = $import.Substring('codex-theme-v1:'.Length) | ConvertFrom-Json
        if ($payload.variant -ne $entry.mode) { throw "Import mode mismatch: $($entry.slug)." }
        if (-not (Test-Path -LiteralPath (Join-Path $folder 'preview.svg'))) { throw "Preview missing for $($entry.slug)." }
        if ($entry.import -ne "themes/$($entry.slug)/import.txt") { throw "Catalog import path invalid for $($entry.slug)." }
        $readmeLink = "themes/$($entry.slug)/import.txt"
        if (-not (Select-String -LiteralPath (Join-Path $root 'README.md') -SimpleMatch -Quiet $readmeLink)) { throw "README does not link directly to $readmeLink." }
    }
    if (Test-Path -LiteralPath (Join-Path $themes 'profile.schema.json')) { throw 'Obsolete profile schema remains in the theme gallery.' }
    $readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
    $readmeLines = $readme -split "`r?`n"
    if ($readmeLines -notcontains '| --- | --- | --- | --- | --- |') { throw 'README gallery table separator is malformed.' }
    if (-not ($readmeLines | Where-Object { $_ -match '^\| Absolutely Light \|' })) { throw 'First gallery theme is not on a separate table row.' }
    foreach ($match in [regex]::Matches($readme, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target.StartsWith('http') -or $target.StartsWith('#')) { continue }
        $localTarget = ($target -split '#',2)[0]
        if (-not (Test-Path -LiteralPath (Join-Path $root $localTarget))) { throw "README link does not resolve: $target" }
    }

    $beforeHashes = @{}
    foreach ($entry in $catalog) {
        foreach ($artifactName in @('preview.svg','import.txt')) {
            $path = Join-Path (Join-Path $themes $entry.slug) $artifactName
            $beforeHashes["$($entry.slug)/$artifactName"] = (Get-Content -LiteralPath $path -Raw).Replace("`r`n", "`n")
        }
    }
    $fixture = Join-Path $tmp 'fixture'
    New-Item -ItemType Directory -Path $fixture | Out-Null
    foreach ($name in @('tools','scripts','themes','schemas')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $fixture -Recurse }
    & (Join-Path $fixture 'tools/Build-Themes.ps1') | Out-Null
    & (Join-Path $fixture 'tools/Build-Themes.ps1') -Check | Out-Null
    foreach ($entry in $catalog) {
        foreach ($artifactName in @('preview.svg','import.txt')) {
            $relative = "$($entry.slug)/$artifactName"
            $path = Join-Path (Join-Path $fixture 'themes' $entry.slug) $artifactName
            $fixtureOutput = (Get-Content -LiteralPath $path -Raw).Replace("`r`n", "`n")
            if ($beforeHashes[$relative] -cne $fixtureOutput) { throw "Theme build output is not deterministic: $relative" }
        }
    }
    $fixtureIndexPath = Join-Path $fixture 'themes/index.json'
    $fixtureIndex = Get-Content -LiteralPath $fixtureIndexPath -Raw
    Set-Content -LiteralPath $fixtureIndexPath -Value ($fixtureIndex.Replace("`n", "`r`n")) -Encoding utf8NoBOM -NoNewline
    & (Join-Path $fixture 'tools/Build-Themes.ps1') -Check | Out-Null

    $badFixture = Join-Path $tmp 'invalid-cli'
    New-Item -ItemType Directory -Path $badFixture | Out-Null
    foreach ($name in @('scripts','themes','schemas')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $badFixture -Recurse }
    $invalid = Get-Content -LiteralPath (Join-Path $themes 'void/theme.json') -Raw | ConvertFrom-Json -AsHashtable
    $invalid.theme.unknownKey = 'reject this'
    $invalid | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $badFixture 'themes/void/theme.json')
    $failed = $false
    try { & (Join-Path $badFixture 'scripts/Morph.ps1') check | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'CLI accepted a source with an unknown schema key.' }
    $optionalFixture = Join-Path $tmp 'optional-source-cli'
    New-Item -ItemType Directory -Path $optionalFixture | Out-Null
    foreach ($name in @('scripts','themes','schemas')) { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $optionalFixture -Recurse }
    $optional = Get-Content -LiteralPath (Join-Path $themes 'void/theme.json') -Raw | ConvertFrom-Json -AsHashtable
    $optional.theme.Remove('opaqueWindows'); $optional.theme.Remove('semanticColors'); $optional.theme.Remove('surface')
    $optional | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $optionalFixture 'themes/void/theme.json')
    $optionalImport = (& (Join-Path $optionalFixture 'scripts/Morph.ps1') export void | Out-String).Trim()
    $optionalPayload = $optionalImport.Substring('codex-theme-v1:'.Length) | ConvertFrom-Json
    if ($optionalPayload.theme.opaqueWindows -ne $false -or $optionalPayload.theme.surface -ne $optional.theme.background) { throw 'Optional theme source defaults were not applied.' }
    if ($optionalPayload.theme.semanticColors.diffAdded -ne '#4ade80' -or $optionalPayload.theme.semanticColors.diffRemoved -ne '#f87171') { throw 'Optional semantic color defaults were not applied.' }
    $failed = $false
    try { & $cli export does-not-exist | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'CLI accepted an unknown theme.' }
    $failed = $false
    try { & $cli preview '../README' | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Preview accepted a path traversal identifier.' }

    $sourceFile = Join-Path $tmp 'source.txt'; $backup = Join-Path $tmp 'source.backup'; $restored = Join-Path $tmp 'restored.txt'
    Set-Content -LiteralPath $sourceFile -Value 'fixture'
    & $cli backup -Path $sourceFile -BackupPath $backup | Out-Null
    & $cli restore -Path $backup -BackupPath $restored | Out-Null
    if ((Get-Content -LiteralPath $restored -Raw).Trim() -ne 'fixture') { throw 'Backup/restore round trip failed.' }
    $failed = $false
    try { & $cli restore -Path $backup -BackupPath $restored | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Restore unexpectedly overwrote an existing destination.' }
    $backupWhatIf = Join-Path $tmp 'backup-whatif'
    & $cli backup -Path $sourceFile -BackupPath $backupWhatIf -WhatIf | Out-Null
    if (Test-Path -LiteralPath $backupWhatIf) { throw 'Backup -WhatIf wrote a file.' }
    'All Morph tests passed.'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
