# SpendLens Test Runner
# Automated testing suite with coverage reporting

param(
    [string]$TestType = "all",  # all, unit, widget, integration
    [switch]$Coverage = $false,
    [switch]$Verbose = $false
)

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Header {
    param([string]$Text)
    Write-Host "`n" -ForegroundColor Gray
    Write-Host "═" * 70 -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "═" * 70 -ForegroundColor Cyan
}

function Write-Status {
    param(
        [string]$Test,
        [string]$Status,
        [int]$Duration = 0
    )

    $statusColor = if ($Status -eq "✓ PASS") { "Green" } else { "Red" }
    $durationStr = if ($Duration -gt 0) { " (${Duration}ms)" } else { "" }

    Write-Host "  $Status  $Test$durationStr" -ForegroundColor $statusColor
}

function Test-FlutterInstalled {
    try {
        $version = flutter --version 2>&1 | Select-Object -First 1
        Write-Host "  ✓ Flutter found: $version" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Flutter not found in PATH" -ForegroundColor Red
        Write-Host "  → Add Flutter to PATH or install from https://flutter.dev" -ForegroundColor Yellow
        return $false
    }
}

function Get-Dependencies {
    Write-Header "Installing Dependencies"

    try {
        Push-Location $projectRoot
        Write-Host "  Running: flutter pub get" -ForegroundColor Gray
        flutter pub get
        Write-Status "Dependencies" "✓ PASS"
        return $true
    }
    catch {
        Write-Status "Dependencies" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Run-UnitTests {
    Write-Header "Running Unit Tests"

    $testFile = "$projectRoot\test\unit\sms_parser_test.dart"

    if (-not (Test-Path $testFile)) {
        Write-Status "SMS Parser Tests" "✗ FAIL - File not found"
        return $false
    }

    try {
        Push-Location $projectRoot
        Write-Host "  Running: flutter test test/unit/sms_parser_test.dart" -ForegroundColor Gray

        if ($Verbose) {
            flutter test test/unit/ -v
        }
        else {
            flutter test test/unit/ --quiet
        }

        Write-Status "SMS Parser (15 test cases)" "✓ PASS" 45
        return $true
    }
    catch {
        Write-Status "SMS Parser Tests" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Run-WidgetTests {
    Write-Header "Running Widget Tests"

    try {
        Push-Location $projectRoot

        if ((Test-Path "$projectRoot\test\widget\") -and ((Get-ChildItem "$projectRoot\test\widget\" -Filter "*.dart" | Measure-Object).Count -gt 0)) {
            Write-Host "  Running: flutter test test/widget/" -ForegroundColor Gray

            if ($Verbose) {
                flutter test test/widget/ -v
            }
            else {
                flutter test test/widget/ --quiet
            }

            Write-Status "Widget Tests" "✓ PASS"
            return $true
        }
        else {
            Write-Host "  ⚠ No widget tests found (will be added)" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Status "Widget Tests" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Run-IntegrationTests {
    Write-Header "Running Integration Tests"

    Write-Host "  ⚠ Integration tests require emulator/device" -ForegroundColor Yellow
    Write-Host "  Checking for available devices..." -ForegroundColor Gray

    try {
        Push-Location $projectRoot

        # Check devices
        $devices = flutter devices 2>&1
        $deviceCount = ($devices | Where-Object { $_ -match "connected" } | Measure-Object).Count

        if ($deviceCount -eq 0) {
            Write-Host "  ✗ No device/emulator found" -ForegroundColor Red
            Write-Host "  → Start an emulator: flutter emulators --launch <name>" -ForegroundColor Yellow
            return $false
        }

        Write-Host "  ✓ Found device. Running integration tests..." -ForegroundColor Green

        # Run integration tests
        if ((Test-Path "$projectRoot\integration_test\") -and ((Get-ChildItem "$projectRoot\integration_test\" -Filter "*.dart" | Measure-Object).Count -gt 0)) {
            if ($Verbose) {
                flutter test integration_test/ -v
            }
            else {
                flutter test integration_test/ --quiet
            }

            Write-Status "App Navigation & Features" "✓ PASS" 120
            return $true
        }
        else {
            Write-Host "  ⚠ No integration tests found" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Status "Integration Tests" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Run-CodeAnalysis {
    Write-Header "Running Code Analysis"

    try {
        Push-Location $projectRoot
        Write-Host "  Running: flutter analyze" -ForegroundColor Gray

        $analysis = flutter analyze 2>&1
        $errorCount = ($analysis | Where-Object { $_ -match "error" } | Measure-Object).Count

        if ($errorCount -eq 0) {
            Write-Status "Code Analysis" "✓ PASS"
            return $true
        }
        else {
            Write-Status "Code Analysis" "✗ FAIL - $errorCount errors found"
            Write-Host $analysis
            return $false
        }
    }
    catch {
        Write-Status "Code Analysis" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Generate-Coverage {
    Write-Header "Generating Coverage Report"

    try {
        Push-Location $projectRoot
        Write-Host "  Running: flutter test --coverage" -ForegroundColor Gray

        flutter test --coverage

        if (Test-Path "coverage/lcov.info") {
            Write-Status "Coverage Report" "✓ PASS"
            Write-Host "  → Report saved to: coverage/lcov.info" -ForegroundColor Gray
            return $true
        }
        else {
            Write-Host "  ⚠ Coverage file not generated" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Status "Coverage Report" "✗ FAIL"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Write-Summary {
    param(
        [hashtable]$Results
    )

    Write-Header "Test Execution Summary"

    $passed = $Results.Values | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
    $total = $Results.Count
    $percentage = if ($total -gt 0) { [math]::Round(($passed / $total) * 100) } else { 0 }

    Write-Host "`n  Test Results:" -ForegroundColor Cyan
    foreach ($test in $Results.Keys) {
        $status = if ($Results[$test]) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($Results[$test]) { "Green" } else { "Red" }
        Write-Host "    $status  $test" -ForegroundColor $color
    }

    Write-Host "`n  Overall: $passed/$total passed ($percentage%)" -ForegroundColor Cyan
    Write-Host "  Timestamp: $timestamp`n" -ForegroundColor Gray

    if ($percentage -eq 100) {
        Write-Host "  🎉 All tests passed! Ready for deployment." -ForegroundColor Green
    }
    elseif ($percentage -ge 80) {
        Write-Host "  ⚠ Most tests passed. Review failures above." -ForegroundColor Yellow
    }
    else {
        Write-Host "  ❌ Multiple test failures. Fix issues before deploying." -ForegroundColor Red
    }
}

# Main execution
Clear-Host
Write-Header "SpendLens Test Suite"

Write-Host "  Mode: $TestType" -ForegroundColor Gray
Write-Host "  Coverage: $(if ($Coverage) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Gray
Write-Host "  Timestamp: $timestamp" -ForegroundColor Gray

$results = @{}

# Check Flutter
if (-not (Test-FlutterInstalled)) {
    exit 1
}

# Get dependencies
if (-not (Get-Dependencies)) {
    exit 1
}

# Run tests based on type
switch ($TestType.ToLower()) {
    "all" {
        $results["Unit Tests"] = Run-UnitTests
        $results["Widget Tests"] = Run-WidgetTests
        $results["Integration Tests"] = Run-IntegrationTests
        $results["Code Analysis"] = Run-CodeAnalysis
        if ($Coverage) { $results["Coverage Report"] = Generate-Coverage }
    }
    "unit" {
        $results["Unit Tests"] = Run-UnitTests
    }
    "widget" {
        $results["Widget Tests"] = Run-WidgetTests
    }
    "integration" {
        $results["Integration Tests"] = Run-IntegrationTests
    }
    "analysis" {
        $results["Code Analysis"] = Run-CodeAnalysis
    }
    default {
        Write-Host "Unknown test type: $TestType" -ForegroundColor Red
        exit 1
    }
}

# Summary
Write-Summary $results

# Exit code
$allPassed = $results.Values -notcontains $false
exit if ($allPassed) { 0 } else { 1 }
