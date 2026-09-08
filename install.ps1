#Requires -Version 5.1
<#
.SYNOPSIS
    TARS installer for Claude Code, for Windows PowerShell.

.DESCRIPTION
    Copies output-styles/TARS.md into your Claude Code output styles directory.
    The exact equivalent of install.sh, for machines without a POSIX shell.
    Never deletes anything. An existing TARS.md is backed up first.

.PARAMETER Dir
    Install into this path instead of ~\.claude\output-styles

.EXAMPLE
    .\install.ps1
.EXAMPLE
    .\install.ps1 -Dir C:\path\to\project\.claude\output-styles
#>
[CmdletBinding()]
param(
    [string]$Dir,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$RawUrl = 'https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/output-styles/TARS.md'

if ($Help) {
    @'
Install the TARS output style for Claude Code.

Usage:
  .\install.ps1 [-Dir <path>] [-Help]

Options:
  -Dir <path>   Install into <path> instead of ~\.claude\output-styles
  -Help         Show this message

An existing TARS.md is copied to TARS.md.backup-<timestamp> before the new
one is written. Nothing is ever deleted.
'@ | Write-Host
    exit 0
}

if (-not $Dir) {
    $cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
    $Dir = Join-Path $cfg 'output-styles'
}

# Prefer the copy sitting next to this script; fall back to downloading.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localSrc  = Join-Path (Join-Path $scriptDir 'output-styles') 'TARS.md'
$tmpSrc    = $null

try {
    if (Test-Path -LiteralPath $localSrc) {
        $src = $localSrc
    } else {
        $tmpSrc = Join-Path ([System.IO.Path]::GetTempPath()) ("tars-" + [guid]::NewGuid().ToString('N') + '.md')
        # Windows PowerShell 5.1 defaults to TLS 1.0, which GitHub refuses.
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $RawUrl -OutFile $tmpSrc -UseBasicParsing
        if ((Get-Item -LiteralPath $tmpSrc).Length -eq 0) {
            [Console]::Error.WriteLine('error: downloaded TARS.md is empty')
            exit 1
        }
        $src = $tmpSrc
    }

    $dest = Join-Path $Dir 'TARS.md'
    if (-not (Test-Path -LiteralPath $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
    }

    if (Test-Path -LiteralPath $dest) {
        $a = (Get-FileHash -LiteralPath $src  -Algorithm SHA256).Hash
        $b = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
        if ($a -eq $b) {
            Write-Host "TARS is already installed and up to date at $dest"
            exit 0
        }
        $backup = "$dest.backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
        Copy-Item -LiteralPath $dest -Destination $backup
        Write-Host "Existing TARS.md backed up to $backup"
    }

    Copy-Item -LiteralPath $src -Destination $dest -Force
}
finally {
    if ($tmpSrc -and (Test-Path -LiteralPath $tmpSrc)) {
        Remove-Item -LiteralPath $tmpSrc -Force -ErrorAction SilentlyContinue
    }
}

@"

TARS installed to $dest

Next:
  1. Open Claude Code
  2. Run /config and pick TARS under "Output style"
  3. Run /clear (output styles load at session start)

To uninstall, delete $dest and switch back to Default in /config.
"@ | Write-Host
