# PMCodeRadar Installer for Windows
# One command to install 23 Claude Code skills for Product Managers
# Built by Boma Tai-Osagbemi | pmplaybook.ai

$ErrorActionPreference = "Stop"

$ClaudeDir = "$env:USERPROFILE\.claude"
$SkillsDir = "$ClaudeDir\skills"

Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "  PMCodeRadar Installer" -ForegroundColor Cyan
Write-Host "  23 Claude Code Skills for Product Managers" -ForegroundColor Cyan
Write-Host "  pmplaybook.ai" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

# Find the script's directory (where PMCodeRadar lives)
if ($PSScriptRoot) {
    $ScriptDir = $PSScriptRoot
} elseif ($MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $ScriptDir = Get-Location
}

$SourceSkillsDir = Join-Path $ScriptDir "skills"

Write-Host "  Source:  $ScriptDir" -ForegroundColor DarkGray
Write-Host ""

# Verify we're running from a valid PMCodeRadar directory
if (-not (Test-Path $SourceSkillsDir)) {
    Write-Host "  [ERROR] This doesn't look like a PMCodeRadar directory." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Expected to find a skills/ folder in:" -ForegroundColor Red
    Write-Host "    $ScriptDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Make sure you're running the script from inside the PMCodeRadar folder:" -ForegroundColor Yellow
    Write-Host "    cd C:\path\to\PMCodeRadar" -ForegroundColor Yellow
    Write-Host "    .\install.ps1" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Check if Claude Code directory exists
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "  [ERROR] Claude Code directory not found." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Looked for: $ClaudeDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This means Claude Code isn't installed yet." -ForegroundColor Yellow
    Write-Host "  Install it first: https://docs.anthropic.com/en/docs/claude-code" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  After installing Claude Code, run this script again." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "  [1/3] Creating skills directory..." -ForegroundColor White
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    Write-Host "         Created $SkillsDir" -ForegroundColor DarkGray
} else {
    Write-Host "         Already exists" -ForegroundColor DarkGray
}

# Get list of skills to install
$SkillFolders = Get-ChildItem -Path $SourceSkillsDir -Directory

Write-Host "  [2/3] Copying $($SkillFolders.Count) skills..." -ForegroundColor White

$Installed = 0
$Skipped = 0
$Overwritten = 0

foreach ($Skill in $SkillFolders) {
    $DestPath = Join-Path $SkillsDir $Skill.Name

    if (Test-Path $DestPath) {
        # Overwrite existing skill silently (update scenario)
        Remove-Item -Recurse -Force $DestPath
        $Overwritten++
    }

    Copy-Item -Recurse -Path $Skill.FullName -Destination $DestPath -Force
    $Installed++
}

Write-Host "         $Installed skills installed" -ForegroundColor DarkGray
if ($Overwritten -gt 0) {
    Write-Host "         $Overwritten skills updated (already existed)" -ForegroundColor DarkGray
}

# Verify installation
Write-Host "  [3/3] Verifying installation..." -ForegroundColor White
$InstalledSkills = Get-ChildItem -Path "$SkillsDir\*\SKILL.md" -ErrorAction SilentlyContinue
$InstalledCount = if ($InstalledSkills) { $InstalledSkills.Count } else { 0 }

# Check a few key skills exist
$KeySkills = @("setup", "error-audit", "schema-explain", "constraint-analysis")
$MissingKeys = @()
foreach ($Key in $KeySkills) {
    if (-not (Test-Path "$SkillsDir\$Key\SKILL.md")) {
        $MissingKeys += $Key
    }
}

Write-Host ""

if ($MissingKeys.Count -eq 0 -and $InstalledCount -ge 23) {
    Write-Host "  ==========================================" -ForegroundColor Green
    Write-Host "  Installation complete!" -ForegroundColor Green
    Write-Host "  ==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Location: $SkillsDir" -ForegroundColor White
    Write-Host "  Skills:   $InstalledCount installed" -ForegroundColor White
    Write-Host ""
    Write-Host "  WHAT TO DO NEXT:" -ForegroundColor Cyan
    Write-Host "  1. Close Claude Code completely (if it's open)" -ForegroundColor White
    Write-Host "  2. Open your terminal and cd into any codebase" -ForegroundColor White
    Write-Host "  3. Start Claude Code" -ForegroundColor White
    Write-Host "  4. Type:  /setup" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  That's it. The setup skill will scan your repo" -ForegroundColor DarkGray
    Write-Host "  and tell you exactly what to run next." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Built by Boma Tai-Osagbemi | pmplaybook.ai" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor Cyan
} else {
    Write-Host "  ==========================================" -ForegroundColor Red
    Write-Host "  Installation had issues." -ForegroundColor Red
    Write-Host "  ==========================================" -ForegroundColor Red
    Write-Host ""
    if ($MissingKeys.Count -gt 0) {
        Write-Host "  Missing key skills: $($MissingKeys -join ', ')" -ForegroundColor Yellow
    }
    Write-Host "  Found $InstalledCount skills (expected 23)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Try again or install manually - see README.md" -ForegroundColor Yellow
}

Write-Host ""
