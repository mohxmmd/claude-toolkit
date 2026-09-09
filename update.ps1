#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Forge updater for Windows PowerShell.

.DESCRIPTION
    The equivalent of update.sh, for machines without a POSIX shell.

      .\update.ps1            refresh the marketplace, show what changed, update
      .\update.ps1 -Check     report installed vs available, change nothing
      .\update.ps1 -Weekly    check once a week, in the background, from now on

    Read this before turning on -Weekly:

    Claude Code has its own plugin auto-update and it runs at EVERY session
    start, which is more often than weekly. If you want to stay current, that is
    the better mechanism and it is one command:

        .\setup.ps1 -AutoUpdateOnly

    -Weekly is for the other case: auto-update off on purpose, but not wanting
    to fall six versions behind without noticing.

.PARAMETER Check
    Report installed vs available versions. Changes nothing.

.PARAMETER Weekly
    Check for updates once a week, in the background.

.PARAMETER NoWeekly
    Stop the weekly check.

.EXAMPLE
    .\update.ps1 -Check
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Weekly,
    [switch]$NoWeekly,
    [switch]$Yes,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$Market      = if ($env:FORGE_MARKET) { $env:FORGE_MARKET } else { 'claude-forge' }
$CfgDir      = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$Settings    = Join-Path $CfgDir 'settings.json'
$StateDir    = Join-Path $CfgDir 'forge'
$HookFile    = Join-Path $StateDir 'weekly-update.ps1'
$StampFile   = Join-Path $StateDir 'last-update-check'
$LogFile     = Join-Path $StateDir 'update.log'
$InstalledDb = Join-Path $CfgDir 'plugins\installed_plugins.json'
$MarketJson  = Join-Path $CfgDir "plugins\marketplaces\$Market\.claude-plugin\marketplace.json"

if ($Help) {
    @'
Update the Claude Forge plugins: forge, Charter, Craft and TARS.

Usage:
  .\update.ps1 [-Check] [-Weekly] [-NoWeekly] [-Yes] [-Help]

Options:
  -Check       Report installed vs available versions. Changes nothing.
  -Weekly      Check for updates once a week, in the background
  -NoWeekly    Stop the weekly check
  -Yes         Do not ask for confirmation
  -Help        Show this message

Before -Weekly, know this:

  Claude Code's own plugin auto-update runs at EVERY session start, which is
  more often than weekly and needs no script. If you want to stay current:

      .\setup.ps1 -AutoUpdateOnly

  -Weekly is for the other case: auto-update deliberately off, but you would
  still rather not fall six versions behind. Running both is redundant.

What -Weekly installs:

  ~\.claude\forge\weekly-update.ps1   a small script, nothing else calls it
  a SessionStart hook in settings.json, marked async so it never delays a
  session, which runs that script

  The script exits immediately on six days out of seven. On the seventh it
  refreshes the marketplace, updates the four plugins, and appends the result
  to ~\.claude\forge\update.log. Remove it with -NoWeekly, or by uninstalling.
'@ | Write-Host
    exit 0
}

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

function Read-Json {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { $raw = '{}' }
        return ConvertTo-OrderedHashtable ($raw | ConvertFrom-Json)
    } catch { return $null }
}

function Get-Versions {
    $db = Read-Json $InstalledDb
    $mk = Read-Json $MarketJson
    if ($null -eq $db -or $null -eq $mk) { return @() }
    $avail = @{}
    foreach ($p in $mk['plugins']) { $avail[$p['name']] = $p['version'] }
    $rows = @()
    foreach ($key in ($db['plugins'].Keys | Sort-Object)) {
        if ($key -notlike "*@$Market") { continue }
        $entries = $db['plugins'][$key]
        if (-not $entries -or -not $entries.Count) { continue }
        $name = $key.Split('@')[0]
        $rows += [pscustomobject]@{
            Name      = $name
            Installed = $entries[0]['version']
            Available = if ($avail.ContainsKey($name)) { $avail[$name] } else { '?' }
        }
    }
    return $rows
}

# Returns $true when everything is current.
function Show-Report {
    $rows = Get-Versions
    if (-not $rows.Count) {
        Write-Host "  (cannot read versions here; 'claude plugin list' shows what is installed)"
        return $true
    }
    $current = $true
    foreach ($r in $rows) {
        if ($r.Installed -eq $r.Available) {
            Write-Host ("  {0,-10} {1,-8} up to date" -f $r.Name, $r.Installed)
        } else {
            Write-Host ("  {0,-10} {1,-8} -> {2}" -f $r.Name, $r.Installed, $r.Available)
            $current = $false
        }
    }
    return $current
}

function Test-AutoUpdate {
    $data = Read-Json $Settings
    if ($null -eq $data -or -not $data.Contains('extraKnownMarketplaces')) { return $false }
    $m = $data['extraKnownMarketplaces']
    if (-not $m.Contains($Market)) { return $false }
    return [bool]$m[$Market]['autoUpdate']
}

function Confirm-Action {
    param([string]$Question)
    if ($Yes) { return $true }
    $answer = Read-Host "$Question [y/N]"
    return ($answer -match '^(y|Y|yes|YES)$')
}

function Assert-Claude {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("error: 'claude' is not on your PATH.")
        [Console]::Error.WriteLine("       Install Claude Code first: https://claude.com/claude-code")
        exit 1
    }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Save-Settings {
    param($Data, [string[]]$Changed)
    $backup = "$Settings.backup-$stamp"
    Copy-Item -LiteralPath $Settings -Destination $backup
    $json = ConvertTo-Json -InputObject $Data -Depth 100
    [System.IO.File]::WriteAllText($Settings, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  edited $Settings (backup $backup)"
}

# ------------------------------------------------------------------- check
if ($Check) {
    Assert-Claude
    Write-Host ""
    Write-Host "Refreshing $Market ..."
    & claude plugin marketplace update $Market 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  warning: could not refresh the marketplace; versions may be stale"
    }
    Write-Host ""
    Write-Host "Versions"
    $current = Show-Report
    Write-Host ""
    if ($current) { Write-Host "Everything is current." }
    else { Write-Host "Run .\update.ps1 to install the newer versions." }
    if (Test-AutoUpdate) {
        Write-Host "Auto-update is on: this happens by itself at every session start."
    }
    Write-Host ""
    exit 0
}

# ------------------------------------------------------------------ weekly
$hookBody = @'
# Forge weekly update check. Installed by update.ps1 -Weekly, removed by
# -NoWeekly or by uninstalling. Runs from a SessionStart hook, marked async, so
# it never delays the session it starts in.
#
# Six days out of seven this exits immediately without doing anything.

$ErrorActionPreference = 'SilentlyContinue'

$market = if ($env:FORGE_MARKET) { $env:FORGE_MARKET } else { 'claude-forge' }
$cfg    = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$dir    = Join-Path $cfg 'forge'
$stamp  = Join-Path $dir 'last-update-check'
$log    = Join-Path $dir 'update.log'
$lock   = Join-Path $dir 'update.lock'
$days   = 7

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) { exit 0 }
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

if (Test-Path -LiteralPath $stamp) {
    $age = (Get-Date) - (Get-Item -LiteralPath $stamp).LastWriteTime
    if ($age.TotalDays -lt $days) { exit 0 }
}

# One check at a time. A lock older than a day is assumed dead.
if (Test-Path -LiteralPath $lock) {
    $lockAge = (Get-Date) - (Get-Item -LiteralPath $lock).LastWriteTime
    if ($lockAge.TotalDays -lt 1) { exit 0 }
    Remove-Item -LiteralPath $lock -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $lock -Force | Out-Null

try {
    # Stamped before the work, not after: a failing check must not retry on
    # every session start for the rest of the week.
    Set-Content -LiteralPath $stamp -Value '' -Force

    $out = @("--- " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    $out += (& claude plugin marketplace update $market 2>&1 | Out-String).TrimEnd()
    $listed = (& claude plugin list 2>&1 | Out-String)
    foreach ($p in @('forge', 'charter', 'craft', 'tars')) {
        if ($listed -notmatch "$p@$market") { continue }
        $out += (& claude plugin update "$p@$market" 2>&1 | Out-String).TrimEnd()
    }
    Add-Content -LiteralPath $log -Value $out

    # Keep the log small enough that nobody has to think about it.
    $lines = @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue)
    if ($lines.Count -gt 500) {
        Set-Content -LiteralPath $log -Value ($lines[-200..-1])
    }
} finally {
    Remove-Item -LiteralPath $lock -Recurse -Force -ErrorAction SilentlyContinue
}
exit 0
'@

function Edit-HookSetting {
    param([string]$Action)
    if (-not (Test-Path -LiteralPath $CfgDir)) {
        New-Item -ItemType Directory -Path $CfgDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $Settings)) {
        [System.IO.File]::WriteAllText($Settings, "{}`n", (New-Object System.Text.UTF8Encoding($false)))
    }
    $data = Read-Json $Settings
    if ($null -eq $data) {
        [Console]::Error.WriteLine("error: $Settings is not valid JSON. Fix it and re-run.")
        exit 1
    }
    if (-not $data.Contains('hooks')) { $data['hooks'] = [ordered]@{} }
    if (-not $data['hooks'].Contains('SessionStart')) { $data['hooks']['SessionStart'] = @() }
    $groups = @($data['hooks']['SessionStart'])

    $isOurs = {
        param($g)
        if ($null -eq $g -or -not $g.Contains('hooks')) { return $false }
        foreach ($h in @($g['hooks'])) {
            if ($h -and $h.Contains('command') -and $h['command'] -eq $HookFile) { return $true }
        }
        return $false
    }

    if ($Action -eq 'add') {
        if (@($groups | Where-Object { & $isOurs $_ }).Count) {
            Write-Host "  unchanged $Settings"
            return
        }
        $entry = [ordered]@{
            hooks = @(
                [ordered]@{
                    type    = 'command'
                    command = $HookFile
                    shell   = 'powershell'
                    async   = $true
                    timeout = 300
                }
            )
        }
        $data['hooks']['SessionStart'] = @($groups + $entry)
        Save-Settings $data @("hooks.SessionStart")
        return
    }

    # Drop only our hook. Anyone else's SessionStart hook is left as it was.
    $kept = @()
    $dropped = 0
    foreach ($g in $groups) {
        if ($null -eq $g -or -not $g.Contains('hooks')) { $kept += $g; continue }
        $inner = @()
        foreach ($h in @($g['hooks'])) {
            if ($h -and $h.Contains('command') -and $h['command'] -eq $HookFile) { $dropped++ }
            else { $inner += $h }
        }
        if ($inner.Count) { $g['hooks'] = $inner; $kept += $g }
    }
    if (-not $dropped) { Write-Host "  unchanged $Settings"; return }
    if ($kept.Count) { $data['hooks']['SessionStart'] = $kept }
    else { $data['hooks'].Remove('SessionStart') }
    if ($data['hooks'].Count -eq 0) { $data.Remove('hooks') }
    Save-Settings $data @("hooks.SessionStart")
}

if ($Weekly) {
    if (Test-AutoUpdate) {
        Write-Host ""
        Write-Host "Auto-update is already on for $Market."
        Write-Host ""
        Write-Host "It refreshes the marketplace and updates these plugins at EVERY session"
        Write-Host "start, which is more often than weekly and needs no hook. Adding the"
        Write-Host "weekly check on top of it gains nothing and gives two mechanisms the"
        Write-Host "same job."
        Write-Host ""
        if (-not (Confirm-Action "Install the weekly check anyway?")) {
            Write-Host "Nothing was changed."
            exit 0
        }
        Write-Host ""
    }
    if (-not (Test-Path -LiteralPath $StateDir)) {
        New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($HookFile, $hookBody, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Weekly check:"
    Write-Host "  wrote $HookFile"
    Edit-HookSetting 'add'
    Write-Host ""
    Write-Host "  It runs at session start, marked async so it never delays a session, and"
    Write-Host "  does nothing at all until seven days have passed. Results are appended to"
    Write-Host "  $LogFile"
    Write-Host ""
    Write-Host "Restart Claude Code for the hook to take effect."
    exit 0
}

if ($NoWeekly) {
    Write-Host "Weekly check:"
    Edit-HookSetting 'remove'
    foreach ($f in @($HookFile, $StampFile)) {
        if (Test-Path -LiteralPath $f) {
            Remove-Item -LiteralPath $f -Force
            Write-Host "  removed $f"
        }
    }
    if (Test-Path -LiteralPath $LogFile) { Write-Host "  kept $LogFile" }
    if ((Test-Path -LiteralPath $StateDir) -and -not (Get-ChildItem -LiteralPath $StateDir -Force)) {
        Remove-Item -LiteralPath $StateDir -Force
        Write-Host "  removed $StateDir"
    }
    Write-Host ""
    Write-Host "Restart Claude Code for the change to take effect."
    exit 0
}

# ------------------------------------------------------------------ update
Assert-Claude

Write-Host ""
Write-Host "Refreshing $Market ..."
& claude plugin marketplace update $Market 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("error: could not refresh the marketplace.")
    [Console]::Error.WriteLine("       Is it installed? claude plugin marketplace list")
    exit 1
}

Write-Host ""
Write-Host "Before"
$current = Show-Report

if ($current) {
    Write-Host ""
    Write-Host "Everything is already current. Nothing to do."
    exit 0
}

Write-Host ""
Write-Host "Updating"
$behind = @(Get-Versions | Where-Object { $_.Installed -ne $_.Available } | ForEach-Object { $_.Name })
if (-not $behind.Count) { $behind = @('forge', 'charter', 'craft', 'tars') }
foreach ($p in $behind) {
    & claude plugin update "$p@$Market" 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host "  updated $p" }
    else { Write-Host "  failed  $p  (run: claude plugin update $p@$Market)" }
}

Write-Host ""
Write-Host "After"
Show-Report | Out-Null

Write-Host ""
Write-Host "Restart Claude Code. Plugins load at session start, so the new versions apply"
Write-Host "to your next session, not this one."
