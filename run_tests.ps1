# SpendLens Integration Test Runner
# Run this script from the project root with a physical Android device or emulator connected.
#
# Usage:
#   .\run_tests.ps1                   # auto-detect connected device
#   .\run_tests.ps1 -DeviceId R5CT90  # specific device by ID
#   .\run_tests.ps1 -Suite app        # only app_test.dart
#   .\run_tests.ps1 -Suite features   # only features_test.dart
#
# Prerequisites:
#   1. Android device connected via USB with USB debugging enabled
#      OR Android emulator running (needs VT-x / WHPX / sufficient disk space)
#   2. Run: flutter doctor   — must show Connected device
#   3. Trust the PC on the device (tap "Allow USB debugging" on phone)

param(
    [string]$DeviceId = "",
    [ValidateSet("all", "app", "features")]
    [string]$Suite = "all"
)

Set-Location $PSScriptRoot

$deviceFlag = if ($DeviceId) { "-d $DeviceId" } else { "" }

Write-Host ""
Write-Host "=== SpendLens E2E Integration Tests ===" -ForegroundColor Cyan
Write-Host ""

# Show connected devices
Write-Host "Connected devices:" -ForegroundColor Yellow
flutter devices
Write-Host ""

function Run-Suite($file, $label) {
    Write-Host "--- Running: $label ---" -ForegroundColor Green
    $cmd = "flutter test $file $deviceFlag --no-pub"
    Write-Host "Command: $cmd" -ForegroundColor Gray
    Invoke-Expression $cmd
    Write-Host ""
}

switch ($Suite) {
    "app"      { Run-Suite "integration_test/app_test.dart"      "Core App Flow (TC-01 to TC-28)" }
    "features" { Run-Suite "integration_test/features_test.dart" "Feature Tests (TC-F01 to TC-F17)" }
    "all" {
        Run-Suite "integration_test/app_test.dart"      "Core App Flow (TC-01 to TC-28)"
        Run-Suite "integration_test/features_test.dart" "Feature Tests (TC-F01 to TC-F17)"
    }
}

Write-Host "=== Done ===" -ForegroundColor Cyan
