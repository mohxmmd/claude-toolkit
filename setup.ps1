#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Forge installer for Windows PowerShell.

.DESCRIPTION
    Adds the marketplace, installs the bundle (which pulls in Charter, Craft and
    TARS), and turns on auto-update so you receive fixes without doing this again.

    This is the exact equivalent of setup.sh, for machines without a POSIX shell.
    Never deletes anything. Your settings file is backed up before it is touched.

.PARAMETER NoAutoUpdate
    Install, but do not enable automatic updates.

.PARAMETER AutoUpdateOnly
    Only turn on auto-update; install nothing.

.EXAMPLE
    .\setup.ps1
.EXAMPLE
    .\setup.ps1 -NoAutoUpdate
#>
[CmdletBinding()]
param(
    [switch]$NoAutoUpdate,
    [switch]$AutoUpdateOnly,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$Repo    = if ($env:FORGE_REPO) { $env:FORGE_REPO } else { 'mohxmmd/claude-toolkit' }
$Market  = 'claude-forge'
$CfgDir  = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$Settings = Join-Path $CfgDir 'settings.json'

if ($Help) {
    @'
Install the Claude Forge: Charter, Craft and TARS.

Usage:
  .\setup.ps1 [-NoAutoUpdate] [-AutoUpdateOnly] [-Help]

Options:
  -NoAutoUpdate     Install, but do not enable automatic updates
  -AutoUpdateOnly   Only turn on auto-update; install nothing
  -Help             Show this message

Auto-update, when enabled, writes two things into your Claude Code settings:

  extraKnownMarketplaces.claude-forge.autoUpdate = true
      Refresh this marketplace and its installed plugins at session start.

  env.FORCE_AUTOUPDATE_PLUGINS = "1"
      Let plugins update even when Claude Code's own auto-updater is off, which
      is the default for native and VS Code installs. This affects PLUGINS ONLY
      and never updates Claude Code itself.

This means you will run new versions of these plugins without reviewing them
first. That is the point, and it is also a real trade-off. Use
-NoAutoUpdate if you would rather update by hand.
'@ | Write-Host
    exit 0
}

if ($NoAutoUpdate -and $AutoUpdateOnly) {
    [Console]::Error.WriteLine("error: -NoAutoUpdate and -AutoUpdateOnly contradict each other.")
    exit 1
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine("error: 'claude' is not on your PATH.")
    [Console]::Error.WriteLine("       Install Claude Code first: https://claude.com/claude-code")
    exit 1
}

# ------------------------------------------------------------------ install
if (-not $AutoUpdateOnly) {
    Write-Host "Adding marketplace $Repo ..."
    & claude plugin marketplace add $Repo
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("error: marketplace add failed (exit $LASTEXITCODE)")
        exit 1
    }

    Write-Host "Installing forge (with Charter, Craft and TARS) ..."
    & claude plugin install "forge@$Market"
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("error: plugin install failed (exit $LASTEXITCODE)")
        exit 1
    }
}

# ------------------------------------------------------------ auto-update
if ($NoAutoUpdate) {
    @"

Installed. Auto-update was NOT enabled.

To update later:
  claude plugin marketplace update $Market
  claude plugin update forge@$Market

Next:
  1. Restart Claude Code   (plugins load at session start)
  2. Run /charter:init in a project
"@ | Write-Host
    exit 0
}

# ConvertFrom-Json returns PSCustomObject on Windows PowerShell 5.1, which is
# awkward to add keys to. Ordered hashtables round-trip cleanly and keep the
# original key order, so a settings file stays readable after we touch it.
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

$manualBlock = @"
  "env": { "FORCE_AUTOUPDATE_PLUGINS": "1" },
  "extraKnownMarketplaces": {
    "$Market": {
      "source": { "source": "github", "repo": "$Repo" },
      "autoUpdate": true
    }
  }
"@

if (-not (Test-Path -LiteralPath $CfgDir)) {
    New-Item -ItemType Directory -Path $CfgDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $Settings)) {
    [System.IO.File]::WriteAllText($Settings, "{}`n", (New-Object System.Text.UTF8Encoding($false)))
}

try {
    $raw = Get-Content -LiteralPath $Settings -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { $raw = '{}' }
    $data = ConvertTo-OrderedHashtable ($raw | ConvertFrom-Json)
} catch {
    Write-Warning "$Settings is not valid JSON, so auto-update was not enabled."
    Write-Host "         Add this to it by hand once it parses:`n"
    Write-Host $manualBlock
    exit 0
}
if ($null -eq $data) { $data = [ordered]@{} }

$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$Settings.backup-$stamp"
Copy-Item -LiteralPath $Settings -Destination $backup

if (-not $data.Contains('env')) { $data['env'] = [ordered]@{} }
$data['env']['FORCE_AUTOUPDATE_PLUGINS'] = '1'

if (-not $data.Contains('extraKnownMarketplaces')) { $data['extraKnownMarketplaces'] = [ordered]@{} }
$markets = $data['extraKnownMarketplaces']
if (-not $markets.Contains($Market)) { $markets[$Market] = [ordered]@{} }
$entry = $markets[$Market]
# Preserve an existing source: the user may have added this from a fork.
if (-not $entry.Contains('source')) {
    $entry['source'] = [ordered]@{ source = 'github'; repo = $Repo }
}
$entry['autoUpdate'] = $true

$json = ConvertTo-Json -InputObject $data -Depth 100
[System.IO.File]::WriteAllText($Settings, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))

@"

Auto-update enabled for $Market.
Settings backed up to $backup

You will now receive new versions of these plugins automatically, without
reviewing them first. Undo any time by deleting "autoUpdate" from
extraKnownMarketplaces in $Settings.

Next:
  1. Restart Claude Code   (plugins load at session start)
  2. Run /charter:init in a project
"@ | Write-Host
