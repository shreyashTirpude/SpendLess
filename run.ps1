# SpendLens - Simple Run Script for PowerShell 5.1
# Just run: .\run.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   SpendLens - Setup & Launch" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectRoot = Get-Location

# Step 1: Check Flutter
Write-Host "[1] Checking Flutter..." -ForegroundColor Yellow
try {
    $version = flutter --version
    Write-Host "  [OK] Flutter installed" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Flutter not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Install from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# Step 2: Get dependencies
Write-Host ""
Write-Host "[2] Installing dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Could not install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Dependencies installed" -ForegroundColor Green

# Step 3: Check device
Write-Host ""
Write-Host "[3] Checking for device/emulator..." -ForegroundColor Yellow
$devices = flutter devices
Write-Host $devices

if ($devices -match "no device") {
    Write-Host "  [FAIL] No device found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start emulator:" -ForegroundColor Yellow
    Write-Host "  flutter emulators --launch emulator_name" -ForegroundColor Gray
    exit 1
}

# Step 4: Launch
Write-Host ""
Write-Host "[4] Launching SpendLens..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Shortcuts:" -ForegroundColor Cyan
Write-Host "  r  = Hot reload" -ForegroundColor Cyan
Write-Host "  R  = Full restart" -ForegroundColor Cyan
Write-Host "  q  = Quit" -ForegroundColor Cyan
Write-Host ""

flutter run

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Session Ended" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
