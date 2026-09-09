#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Forge uninstaller for Windows PowerShell.

.DESCRIPTION
    The exact equivalent of uninstall.sh, for machines without a POSIX shell.

    Removes everything Forge put on this machine and, when run from a project,
    everything Charter and Craft wrote into it. Two sources of truth:

      1. .forge\manifest.tsv, the receipt Charter and Craft append to as they
         write. Removal is exact rather than inferred.
      2. Known markers and paths, for projects set up before the receipt
         existed. It finds the fence and the state files; it cannot tell which
         permission rules were Charter's and which were yours, so it reports
         those instead of guessing.

    Nothing is deleted without a copy. Project artifacts are moved into
    .forge-backup-<timestamp>\ and settings files are backed up in place.

.PARAMETER Plan
    Show what would be removed and change nothing.

.PARAMETER Yes
    Do not ask for confirmation.

.EXAMPLE
    .\uninstall.ps1 -Plan
.EXAMPLE
    .\uninstall.ps1
#>
[CmdletBinding()]
param(
    [switch]$Plan,
    [switch]$Yes,
    [switch]$KeepProject,
    [switch]$KeepSettings,
    [switch]$KeepStyle,
    [switch]$KeepPlugins,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$Market    = if ($env:FORGE_MARKET) { $env:FORGE_MARKET } else { 'claude-forge' }
$CfgDir    = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$Settings  = Join-Path $CfgDir 'settings.json'
$StyleFile = Join-Path (Join-Path $CfgDir 'output-styles') 'TARS.md'
$Project   = (Get-Location).Path
$Manifest  = Join-Path $Project '.forge\manifest.tsv'
$Styles    = @('TARS', 'tars:TARS')

if ($Help) {
    @'
Uninstall the Claude Forge: forge, Charter, Craft and TARS.

Usage:
  .\uninstall.ps1 [-Plan] [-Yes] [-KeepProject] [-KeepSettings]
                  [-KeepStyle] [-KeepPlugins] [-Help]

Options:
  -Plan           Show what would be removed and change nothing
  -Yes            Do not ask for confirmation
  -KeepProject    Leave this repository's files alone
  -KeepSettings   Leave the user settings.json alone
  -KeepStyle      Leave ~\.claude\output-styles\TARS.md in place
  -KeepPlugins    Leave the plugins and marketplace installed
  -Help           Show this message

Machine:
  plugins        forge, charter, craft and tars
  marketplace    the claude-forge marketplace entry
  settings       extraKnownMarketplaces.claude-forge
                 env.FORCE_AUTOUPDATE_PLUGINS
                 enabledPlugins entries ending in @claude-forge
                 outputStyle, only when it is set to TARS
  style file     ~\.claude\output-styles\TARS.md, if install.ps1 put it there

This repository (from .forge\manifest.tsv, or from known markers):
  files          .forge\, .craft\, .claude\charter.json, Charter's rules files
  CLAUDE.md      the block between the charter:start and charter:end markers
  settings       the permission rules Charter added, and outputStyle
  .gitignore     the lines Charter and Craft added

Everything removed from the project is copied into .forge-backup-<timestamp>\
first. Other repositories are not touched: run this from each of them.
'@ | Write-Host
    exit 0
}

# ConvertFrom-Json returns PSCustomObject on Windows PowerShell 5.1, which is
# awkward to remove keys from. Ordered hashtables round-trip cleanly and keep
# the original key order, so a settings file stays readable after we touch it.
function ConvertTo-OrderedHashtable {
    param($InputObject)
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $out = [ordered]@{}
        foreach ($p in $InputObject.PSObject.Properties) {
            $out[$p.Name] = ConvertTo-OrderedHashtable $p.Value
        }
        return $out
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return ,@($InputObject | ForEach-Object { ConvertTo-OrderedHashtable $_ })
    }
    return $InputObject
}

function Read-Settings {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { $raw = '{}' }
        return ConvertTo-OrderedHashtable ($raw | ConvertFrom-Json)
    } catch {
        Write-Warning "$Path is not valid JSON, so it was left alone."
        return $null
    }
}

function Get-OutputStyle {
    param([string]$Path)
    $data = Read-Settings $Path
    if ($null -eq $data) { return $null }
    if ($data.Contains('outputStyle')) { return $data['outputStyle'] }
    return $null
}

$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = Join-Path $Project ".forge-backup-$stamp"

function Save-Copy {
    param([string]$Relative)
    $full = Join-Path $Project $Relative
    if (-not (Test-Path -LiteralPath $full)) { return }
    $dest = Join-Path $backupDir $Relative
    $parent = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $full -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------------- survey
$installed = @()
$marketPresent = $false
$haveClaude = [bool](Get-Command claude -ErrorAction SilentlyContinue)

if ($haveClaude -and -not $KeepPlugins) {
    $list = (& claude plugin list 2>$null | Out-String)
    $installed = [regex]::Matches($list, "[A-Za-z0-9_.-]+@$([regex]::Escape($Market))") |
        ForEach-Object { $_.Value } | Sort-Object -Unique
    # The bundle goes first: charter, craft and tars are its dependencies, and
    # removing a dependency out from under it is the one order that can fail.
    $installed = @($installed | Where-Object { $_ -eq "forge@$Market" }) +
                 @($installed | Where-Object { $_ -ne "forge@$Market" })
    $markets = (& claude plugin marketplace list 2>$null | Out-String)
    $marketPresent = $markets -match [regex]::Escape($Market)
}

$userHits = @()
$userData = Read-Settings $Settings
if ($null -ne $userData) {
    if ($userData.Contains('extraKnownMarketplaces') -and $userData['extraKnownMarketplaces'].Contains($Market)) {
        $userHits += "extraKnownMarketplaces.$Market"
    }
    if ($userData.Contains('env') -and $userData['env'].Contains('FORCE_AUTOUPDATE_PLUGINS')) {
        $userHits += 'env.FORCE_AUTOUPDATE_PLUGINS'
    }
    if ($userData.Contains('enabledPlugins')) {
        $gone = @($userData['enabledPlugins'].Keys | Where-Object { $_ -like "*@$Market" })
        if ($gone.Count) { $userHits += "enabledPlugins: $($gone -join ', ')" }
    }
    if ($Styles -contains $userData['outputStyle']) { $userHits += 'outputStyle' }
}

# Every project fact lands in these lists, from the receipt when there is one
# and from markers when there is not. The removal pass reads only these.
$pPaths    = New-Object System.Collections.ArrayList
$pFences   = New-Object System.Collections.ArrayList
$pSettings = New-Object System.Collections.ArrayList
$pIgnores  = New-Object System.Collections.ArrayList
$pUnknown  = New-Object System.Collections.ArrayList
$haveManifest = $false

function Test-Rel { param([string]$p) Test-Path -LiteralPath (Join-Path $Project $p) }

if (-not $KeepProject) {
    if (Test-Path -LiteralPath $Manifest) {
        $haveManifest = $true
        foreach ($line in (Get-Content -LiteralPath $Manifest)) {
            if ($line -match '^\s*(#|$)') { continue }
            $f = $line -split "`t"
            if ($f.Count -lt 3) { continue }
            $kind = $f[1]; $path = $f[2]
            $a = if ($f.Count -gt 3) { $f[3] } else { '' }
            $b = if ($f.Count -gt 4) { $f[4] } else { '' }
            switch ($kind) {
                'path'      { if (Test-Rel $path) { [void]$pPaths.Add($path) } }
                'fence'     {
                    if ((Test-Rel $path) -and ((Get-Content -LiteralPath (Join-Path $Project $path) -Raw) -like "*$a*")) {
                        [void]$pFences.Add([pscustomobject]@{ Path = $path; Start = $a; End = $b })
                    }
                }
                'settings'  { if (Test-Rel $path) { [void]$pSettings.Add([pscustomobject]@{ Path = $path; Bucket = $a; Value = $b }) } }
                'gitignore' {
                    if ((Test-Rel $path) -and ((Get-Content -LiteralPath (Join-Path $Project $path)) -contains $a)) {
                        [void]$pIgnores.Add([pscustomobject]@{ Path = $path; Line = $a })
                    }
                }
            }
        }
        if (Test-Rel '.forge') { [void]$pPaths.Add('.forge') }
    } else {
        foreach ($p in @('.craft', '.claude\charter.json', '.forge')) {
            if (Test-Rel $p) { [void]$pPaths.Add($p) }
        }
        foreach ($f in @('CLAUDE.md', '.claude\CLAUDE.md')) {
            if ((Test-Rel $f) -and ((Get-Content -LiteralPath (Join-Path $Project $f) -Raw) -like '*charter:start*')) {
                [void]$pFences.Add([pscustomobject]@{ Path = $f; Start = 'charter:start'; End = 'charter:end' })
            }
        }
        foreach ($f in @('.claude\settings.local.json', '.claude\settings.json')) {
            if ($Styles -contains (Get-OutputStyle (Join-Path $Project $f))) {
                [void]$pSettings.Add([pscustomobject]@{ Path = $f; Bucket = 'key'; Value = 'outputStyle' })
            }
        }
        # Permission rules cannot be attributed without a receipt. Charter's
        # rules and yours live in the same array and look identical.
        foreach ($f in @('.claude\settings.json', '.claude\settings.local.json')) {
            if ((Test-Rel $f) -and ((Get-Content -LiteralPath (Join-Path $Project $f) -Raw) -like '*"deny"*')) {
                [void]$pUnknown.Add("${f}: permission rules, source unknown without a receipt")
            }
        }
    }
}

# -------------------------------------------------------------------- plan
Write-Host ""
Write-Host "FORGE UNINSTALL"
Write-Host ""
Write-Host "Machine"
if ($KeepPlugins)        { Write-Host "  plugins       kept (-KeepPlugins)" }
elseif (-not $haveClaude){ Write-Host "  plugins       'claude' is not on your PATH, so plugins cannot be removed here" }
elseif ($installed.Count){ Write-Host "  plugins       $($installed -join ' ')" }
else                     { Write-Host "  plugins       none installed from $Market" }
if ($KeepPlugins)        { Write-Host "  marketplace   kept (-KeepPlugins)" }
elseif ($marketPresent)  { Write-Host "  marketplace   $Market" }
else                     { Write-Host "  marketplace   not configured" }
if ($KeepSettings)       { Write-Host "  settings      kept (-KeepSettings)" }
elseif ($userHits.Count) {
    Write-Host "  settings      $Settings"
    foreach ($k in $userHits) { Write-Host "                  $k" }
} else                   { Write-Host "  settings      nothing of ours in $Settings" }
if ($KeepStyle)          { Write-Host "  style file    kept (-KeepStyle)" }
elseif (Test-Path -LiteralPath $StyleFile) { Write-Host "  style file    $StyleFile" }
else                     { Write-Host "  style file    not present" }

Write-Host ""
Write-Host "This repository   $Project"
if ($KeepProject) {
    Write-Host "  kept (-KeepProject)"
} else {
    if ($haveManifest) {
        Write-Host "  receipt       .forge\manifest.tsv  ($($pPaths.Count) paths, $($pFences.Count) fences, $($pSettings.Count) settings, $($pIgnores.Count) gitignore)"
    } else {
        Write-Host "  receipt       none - falling back to known markers and paths"
    }
    foreach ($p in $pPaths)    { Write-Host "  remove        $p" }
    foreach ($f in $pFences)   { Write-Host "  fence         $($f.Path)  ($($f.Start) .. $($f.End))" }
    foreach ($s in $pSettings) {
        if ($s.Bucket -eq 'key') { Write-Host "  settings      $($s.Path): drop $($s.Value)" }
        else                     { Write-Host "  settings      $($s.Path): $($s.Bucket) rule $($s.Value)" }
    }
    foreach ($g in $pIgnores)  { Write-Host "  .gitignore    $($g.Path): $($g.Line)" }
    foreach ($u in $pUnknown)  { Write-Host "  left alone    $u" }
    if (-not ($pPaths.Count + $pFences.Count + $pSettings.Count + $pIgnores.Count + $pUnknown.Count)) {
        Write-Host "  nothing of ours here"
    }
}
Write-Host ""

if ($Plan) {
    Write-Host "Plan only. Nothing was changed. Re-run without -Plan to remove."
    exit 0
}

if (-not $Yes) {
    $answer = Read-Host "Remove all of the above? [y/N]"
    if ($answer -notmatch '^(y|Y|yes|YES)$') {
        Write-Host "Nothing was changed."
        exit 0
    }
    Write-Host ""
}

function Save-Json {
    param([string]$Path, $Data, [string[]]$Changed)
    $backup = "$Path.backup-$stamp"
    Copy-Item -LiteralPath $Path -Destination $backup
    $json = ConvertTo-Json -InputObject $Data -Depth 100
    [System.IO.File]::WriteAllText($Path, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  edited $Path"
    foreach ($c in $Changed) { Write-Host "    removed $c" }
    Write-Host "    backup $backup"
}

# ---------------------------------------------------------- user settings
if (-not $KeepSettings -and $userHits.Count) {
    Write-Host "User settings:"
    $data = Read-Settings $Settings
    if ($null -ne $data) {
        $changed = @()
        if ($Styles -contains $data['outputStyle']) { $data.Remove('outputStyle'); $changed += 'outputStyle' }
        if ($data.Contains('env') -and $data['env'].Contains('FORCE_AUTOUPDATE_PLUGINS')) {
            $data['env'].Remove('FORCE_AUTOUPDATE_PLUGINS')
            $changed += 'env.FORCE_AUTOUPDATE_PLUGINS'
            if ($data['env'].Count -eq 0) { $data.Remove('env') }
        }
        if ($data.Contains('extraKnownMarketplaces') -and $data['extraKnownMarketplaces'].Contains($Market)) {
            $data['extraKnownMarketplaces'].Remove($Market)
            $changed += "extraKnownMarketplaces.$Market"
            if ($data['extraKnownMarketplaces'].Count -eq 0) { $data.Remove('extraKnownMarketplaces') }
        }
        if ($data.Contains('enabledPlugins')) {
            $gone = @($data['enabledPlugins'].Keys | Where-Object { $_ -like "*@$Market" })
            foreach ($k in $gone) { $data['enabledPlugins'].Remove($k) }
            if ($gone.Count) { $changed += "enabledPlugins: $($gone -join ', ')" }
            if ($data['enabledPlugins'].Count -eq 0 -and $gone.Count) { $data.Remove('enabledPlugins') }
        }
        if ($changed.Count) { Save-Json $Settings $data $changed } else { Write-Host "  unchanged $Settings" }
    }
    Write-Host ""
}

# -------------------------------------------------------------- style file
if (-not $KeepStyle -and (Test-Path -LiteralPath $StyleFile)) {
    Remove-Item -LiteralPath $StyleFile -Force
    Write-Host "Style file:"
    Write-Host "  removed $StyleFile"
    Write-Host ""
}

# ----------------------------------------------------------------- project
if (-not $KeepProject -and ($pPaths.Count + $pFences.Count + $pSettings.Count + $pIgnores.Count)) {
    Write-Host "This repository:"

    # Fences first, while the receipt that describes them still exists.
    foreach ($f in $pFences) {
        $full = Join-Path $Project $f.Path
        if (-not (Test-Path -LiteralPath $full)) { continue }
        Save-Copy $f.Path
        $keep = New-Object System.Collections.ArrayList
        $skip = $false
        foreach ($line in (Get-Content -LiteralPath $full)) {
            if ($line -like "*$($f.Start)*") { $skip = $true }
            if (-not $skip) { [void]$keep.Add($line) }
            if ($line -like "*$($f.End)*")   { $skip = $false }
        }
        [System.IO.File]::WriteAllLines($full, $keep, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  cleared fence in $($f.Path)"
    }

    foreach ($g in $pIgnores) {
        $full = Join-Path $Project $g.Path
        if (-not (Test-Path -LiteralPath $full)) { continue }
        Save-Copy $g.Path
        $keep = @(Get-Content -LiteralPath $full | Where-Object { $_ -ne $g.Line })
        [System.IO.File]::WriteAllLines($full, $keep, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "  removed '$($g.Line)' from $($g.Path)"
    }

    # One pass per file, so a file with several rules is edited and backed up
    # once rather than once per rule.
    foreach ($group in ($pSettings | Group-Object Path)) {
        $rel = $group.Name
        $full = Join-Path $Project $rel
        if (-not (Test-Path -LiteralPath $full)) { continue }
        Save-Copy $rel
        $data = Read-Settings $full
        if ($null -eq $data) { continue }
        $changed = @()
        foreach ($s in $group.Group) {
            if ($s.Bucket -eq 'key') {
                if ($s.Value -eq 'outputStyle' -and ($Styles -notcontains $data['outputStyle'])) { continue }
                if ($data.Contains($s.Value)) { $data.Remove($s.Value); $changed += $s.Value }
                continue
            }
            if ($data.Contains('permissions') -and $data['permissions'].Contains($s.Bucket)) {
                $rules = @($data['permissions'][$s.Bucket] | Where-Object { $_ -ne $s.Value })
                if ($rules.Count -ne @($data['permissions'][$s.Bucket]).Count) {
                    $changed += "permissions.$($s.Bucket) $($s.Value)"
                }
                if ($rules.Count) { $data['permissions'][$s.Bucket] = $rules }
                else { $data['permissions'].Remove($s.Bucket) }
                if ($data['permissions'].Count -eq 0) { $data.Remove('permissions') }
            }
        }
        if ($changed.Count) { Save-Json $full $data $changed } else { Write-Host "  unchanged $rel" }
    }

    foreach ($p in $pPaths) {
        $full = Join-Path $Project $p
        if (-not (Test-Path -LiteralPath $full)) { continue }
        Save-Copy $p
        Remove-Item -LiteralPath $full -Recurse -Force
        Write-Host "  removed $p"
        # A directory that is now empty, such as .claude\rules, goes too.
        $parent = Split-Path -Parent $full
        if ((Test-Path -LiteralPath $parent) -and -not (Get-ChildItem -LiteralPath $parent -Force)) {
            Remove-Item -LiteralPath $parent -Force
        }
    }

    if (Test-Path -LiteralPath $backupDir) { Write-Host "  copies kept in .forge-backup-$stamp" }
    Write-Host ""
}

if (-not $KeepProject -and $pUnknown.Count) {
    Write-Host "Left for you to decide:"
    foreach ($u in $pUnknown) { Write-Host "  $u" }
    Write-Host "  No receipt existed, so these cannot be told apart from your own rules."
    Write-Host ""
}

# ----------------------------------------------------------------- plugins
if (-not $KeepPlugins -and $haveClaude -and ($installed.Count -or $marketPresent)) {
    Write-Host "Plugins:"
    foreach ($p in $installed) {
        & claude plugin uninstall $p --yes 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "  removed $p" }
        else { Write-Host "  failed  $p  (run: claude plugin uninstall $p --yes)" }
    }
    if ($marketPresent) {
        & claude plugin marketplace remove $Market 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "  removed marketplace $Market" }
        else { Write-Host "  failed  marketplace $Market  (run: claude plugin marketplace remove $Market)" }
    }
    Write-Host ""
}

Write-Host "Done. Restart Claude Code so the removals take effect."
Write-Host ""
Write-Host "Backups: settings files as *.backup-$stamp beside the original."
if (Test-Path -LiteralPath $backupDir) { Write-Host "         project files in .forge-backup-$stamp" }
Write-Host ""
Write-Host "Other repositories are not touched. Run this from each one."
