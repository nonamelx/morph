$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cli = Join-Path $root 'scripts/Morph.ps1'
$previewGenerator = Join-Path $root 'tools/Generate-Previews.ps1'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("morph-tests-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $profiles = & $cli check
    if ($LASTEXITCODE -gt 0) { throw 'Profile check failed.' }
    if (-not (($profiles -join "`n") -match 'compatibility: unknown')) { throw 'Compatibility status was not reported.' }
    $items = @(& $cli list)
    if ($items.Count -ne 2) { throw "Expected 2 themes, got $($items.Count)." }
    $export = (& $cli export claude-warm | Out-String).Trim()
    if (-not $export.StartsWith('codex-theme-v1:')) { throw 'Export prefix missing.' }
    foreach ($id in @('claude-warm','void')) {
        $artifactPath = Join-Path $root "themes/$id.codex-theme-v1"
        $artifact = (Get-Content -LiteralPath $artifactPath -Raw).Trim()
        if (-not $artifact.StartsWith('codex-theme-v1:')) { throw "Import artifact missing prefix: $id" }
        $cliOutput = (& $cli export $id | Out-String).Trim()
        if ($artifact -cne $cliOutput) { throw "Versioned artifact differs from CLI export: $id" }
        $svg = Get-Content -LiteralPath (Join-Path $root "themes/$id.svg") -Raw
        if ($svg -notmatch 'Illustrative preview — not a Codex screenshot') { throw "Preview disclaimer missing: $id" }
    }
    & $previewGenerator -Check | Out-Null
    $before = Get-FileHash -LiteralPath (Join-Path $root 'themes/void.svg') -Algorithm SHA256
    $previewFixture = Join-Path $tmp 'preview-fixture'
    New-Item -ItemType Directory -Path $previewFixture | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'tools') -Destination $previewFixture -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'scripts') -Destination $previewFixture -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'themes') -Destination $previewFixture -Recurse
    $fixtureGenerator = Join-Path $previewFixture 'tools/Generate-Previews.ps1'
    & $fixtureGenerator | Out-Null
    $fixtureHash = Get-FileHash -LiteralPath (Join-Path $previewFixture 'themes/void.svg') -Algorithm SHA256
    $after = Get-FileHash -LiteralPath (Join-Path $root 'themes/void.svg') -Algorithm SHA256
    if ($before.Hash -cne $after.Hash) { throw 'Test workflow modified checked-in previews.' }
    if ($before.Hash -cne $fixtureHash.Hash) { throw 'Preview generation is not deterministic.' }
    & $fixtureGenerator -Check | Out-Null
    $bad = Join-Path $tmp 'test-invalid.json'
    $originalProfile = Get-Content -LiteralPath (Join-Path $root 'themes/void.json') -Raw
    $invalidProfile = $originalProfile | ConvertFrom-Json -AsHashtable
    $invalidProfile.id = 'test-invalid'
    $invalidProfile.payload.theme.unknownKey = 'should fail'
    $invalidProfile | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $bad
    $badCliProfile = Join-Path $tmp 'invalid-cli-fixture'
    New-Item -ItemType Directory -Path $badCliProfile | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'scripts') -Destination $badCliProfile -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'themes') -Destination $badCliProfile -Recurse
    Copy-Item -LiteralPath $bad -Destination (Join-Path $badCliProfile 'themes/test-invalid.json')
    $invalidCli = Join-Path $badCliProfile 'scripts/Morph.ps1'
    $failed = $false
    try { & $invalidCli check | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'CLI unexpectedly accepted invalid profile.' }
    $failed = $false
    try { & $cli export bogus | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Unknown theme unexpectedly succeeded.' }
    $source = Join-Path $tmp 'source.txt'; $backup = Join-Path $tmp 'source.backup'; $restore = Join-Path $tmp 'restored.txt'
    Set-Content -LiteralPath $source -Value 'fixture'
    & $cli backup -Path $source -BackupPath $backup | Out-Null
    & $cli restore -Path $backup -BackupPath $restore | Out-Null
    if ((Get-Content -LiteralPath $restore -Raw).Trim() -ne 'fixture') { throw 'Backup/restore round trip failed.' }
    $failed = $false
    try { & $cli restore -Path $backup -BackupPath $restore | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Restore unexpectedly overwrote a file.' }
    $failed = $false
    try { & $cli restore -Path $tmp -BackupPath (Join-Path $tmp 'directory-copy') | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Restore unexpectedly accepted a directory source.' }
    $backupWhatIf = Join-Path $tmp 'whatif-backup'
    & $cli backup -Path $source -BackupPath $backupWhatIf -WhatIf | Out-Null
    if (Test-Path -LiteralPath $backupWhatIf) { throw 'Backup -WhatIf wrote a file.' }
    & $cli export void -Path (Join-Path $tmp 'whatif.txt') -WhatIf | Out-Null
    if (Test-Path (Join-Path $tmp 'whatif.txt')) { throw '-WhatIf wrote a file.' }
    'All Morph tests passed.'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
