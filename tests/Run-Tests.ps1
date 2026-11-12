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
    $bad = Join-Path (Join-Path $root 'themes') 'test-invalid.json'
    $originalProfile = Get-Content -LiteralPath (Join-Path $root 'themes/void.json') -Raw
    try {
        $invalidProfile = $originalProfile | ConvertFrom-Json -AsHashtable
        $invalidProfile.payload.theme.unknownKey = 'should fail'
        $invalidProfile | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $bad
        $failed = $false
        try { & $cli check | Out-Null } catch { $failed = $true }
        if (-not $failed) { throw 'Unknown profile key unexpectedly passed validation.' }
    } finally {
        Remove-Item -LiteralPath $bad -Force -ErrorAction SilentlyContinue
    }
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
