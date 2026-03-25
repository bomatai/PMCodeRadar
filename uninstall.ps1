# PMCodeRadar Uninstaller for Windows
# Removes all 23 PMCodeRadar skill folders from ~/.claude/skills/
# Does NOT remove any other skills the user may have installed.

$skillsDir = Join-Path $env:USERPROFILE ".claude" "skills"

$pmSkills = @(
    "setup",
    "constraint-analysis",
    "debt-cost-estimate",
    "pre-ship-scan",
    "dead-code-audit",
    "event-inventory",
    "duplicate-check",
    "schema-explain",
    "error-audit",
    "api-surface-map",
    "onboarding-audit",
    "validation-audit",
    "route-audit",
    "notification-audit",
    "search-audit",
    "architecture-map",
    "removal-impact",
    "privacy-audit",
    "flag-audit",
    "dependency-map",
    "migration-risk",
    "catalog"
    "feedback"
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PMCodeRadar Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-Not (Test-Path $skillsDir)) {
    Write-Host "Skills directory not found: $skillsDir" -ForegroundColor Yellow
    Write-Host "Nothing to uninstall."
    exit 0
}

# Find which PMCodeRadar skills are currently installed
$found = @()
$notFound = @()

foreach ($skill in $pmSkills) {
    $path = Join-Path $skillsDir $skill
    if (Test-Path $path) {
        $found += $skill
    } else {
        $notFound += $skill
    }
}

if ($found.Count -eq 0) {
    Write-Host "No PMCodeRadar skills found in $skillsDir" -ForegroundColor Yellow
    Write-Host "Nothing to uninstall."
    exit 0
}

Write-Host "The following $($found.Count) PMCodeRadar skill folders will be REMOVED:" -ForegroundColor Yellow
Write-Host ""
foreach ($skill in $found) {
    Write-Host "  - $skill" -ForegroundColor Red
}
Write-Host ""

if ($notFound.Count -gt 0) {
    Write-Host "Not found (already removed or never installed):" -ForegroundColor DarkGray
    foreach ($skill in $notFound) {
        Write-Host "  - $skill" -ForegroundColor DarkGray
    }
    Write-Host ""
}

$confirm = Read-Host "Are you sure you want to remove these skills? (y/n)"

if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host ""
    Write-Host "Uninstall cancelled. No files were removed." -ForegroundColor Green
    exit 0
}

Write-Host ""
$removed = 0
$errors = 0

foreach ($skill in $found) {
    $path = Join-Path $skillsDir $skill
    try {
        Remove-Item -Recurse -Force $path
        Write-Host "  Removed: $skill" -ForegroundColor Green
        $removed++
    } catch {
        Write-Host "  FAILED:  $skill - $_" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Uninstall complete" -ForegroundColor Cyan
Write-Host "  Removed: $removed / $($found.Count) skills" -ForegroundColor Cyan
if ($errors -gt 0) {
    Write-Host "  Errors:  $errors" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your other Claude Code skills were not touched." -ForegroundColor Green
Write-Host "To reinstall PMCodeRadar, run install.ps1" -ForegroundColor DarkGray
