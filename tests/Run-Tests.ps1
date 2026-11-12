$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cli = Join-Path $root 'scripts/Morph.ps1'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("morph-tests-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $profiles = & $cli check
    if ($LASTEXITCODE -gt 0) { throw 'Profile check failed.' }
    $items = @(& $cli list)
    if ($items.Count -ne 2) { throw "Expected 2 themes, got $($items.Count)." }
    $export = (& $cli export claude-warm | Out-String).Trim()
    if (-not $export.StartsWith('codex-theme-v1:')) { throw 'Export prefix missing.' }
    $bad = Join-Path $tmp 'bad.json'
    Set-Content -LiteralPath $bad -Value '{"id":"bad"}'
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
    & $cli export void -Path (Join-Path $tmp 'whatif.txt') -WhatIf | Out-Null
    if (Test-Path (Join-Path $tmp 'whatif.txt')) { throw '-WhatIf wrote a file.' }
    'All Morph tests passed.'
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
