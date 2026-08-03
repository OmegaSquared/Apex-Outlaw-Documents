# Regenerates Design_Documents/_MASTER_COMBINED.md by concatenating every .md
# file under Design_Documents/ into a single aggregated file for external AI review.
#
# Usage (from any cwd):
#   pwsh Design_Documents/regen_master_combined.ps1
#
# Skips: _MASTER_COMBINED.md itself, *_OLD.md archives, and any *.draft.md files.
# Sort: 00_Master_Design_Overview.md first, then everything else by relative path.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$output = Join-Path $root '_MASTER_COMBINED.md'

function ShouldSkip($relPath) {
    if ($relPath -eq '_MASTER_COMBINED.md') { return $true }
    if ($relPath -like '*_OLD.md') { return $true }
    if ($relPath -like '*.draft.md') { return $true }
    return $false
}

$allMd = Get-ChildItem -Path $root -Recurse -Filter '*.md' | Where-Object {
    $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
    -not (ShouldSkip $rel)
}

# 00_Master_Design_Overview.md sorts first; everything else by relative path.
$sorted = $allMd | Sort-Object @{ Expression = {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
        if ($rel -eq '00_Master_Design_Overview.md') { return '0_' + $rel }
        return '1_' + $rel
    }
}

$today = Get-Date -Format 'yyyy-MM-dd'
$header = @"
# Apex Outlaw — Combined Design Documents

_Regenerated $today by ``regen_master_combined.ps1`` — concatenates every ``.md`` file under ``Design_Documents/`` (excluding ``*_OLD.md`` archives) for external AI review. Run the script again any time the source docs change._

## Table of Contents

"@

$toc = New-Object System.Text.StringBuilder
$body = New-Object System.Text.StringBuilder
$i = 1
foreach ($file in $sorted) {
    $rel = $file.FullName.Substring($root.Length).TrimStart('\', '/').Replace('\', '/')
    [void]$toc.AppendLine("$i. $rel")
    [void]$body.AppendLine()
    [void]$body.AppendLine('---')
    [void]$body.AppendLine()
    [void]$body.AppendLine("# === FILE: $rel ===")
    [void]$body.AppendLine()
    [void]$body.AppendLine((Get-Content -Path $file.FullName -Raw))
    $i++
}

$combined = $header + $toc.ToString() + $body.ToString()
Set-Content -Path $output -Value $combined -Encoding utf8NoBOM
Write-Host "Regenerated $output ($($sorted.Count) files combined)."
