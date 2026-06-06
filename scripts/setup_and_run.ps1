# SpendLens Setup & Run Script
# Automates Flutter setup, dependencies, and app launch

param(
    [switch]$SkipSetup = $false,
    [string]$DeviceType = "emulator",  # emulator or device
    [switch]$Release = $false,
    [string]$CustomEmulator = ""
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  SpendLens - Setup & Run                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Status {
    param([string]$Message, [string]$Status = "INFO")
    $colors = @{
        "✓" = "Green"
        "✗" = "Red"
        "⚠" = "Yellow"
        "→" = "Cyan"
        "INFO" = "Gray"
    }
    $color = $colors[$Status] ?? "Gray"
    Write-Host "  $Status  $Message" -ForegroundColor $color
}

function Test-Command {
    param([string]$Command)
    try {
        $null = & $Command --version 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Add-ToPath {
    param([string]$Path)
    if ($env:PATH -notlike "*$Path*") {
        $env:PATH += ";$Path"
        Write-Status "Added to PATH: $Path" "✓"
    }
}

# ============================================================================
# STEP 1: ENVIRONMENT CHECK
# ============================================================================

Write-Host "`n[1/5] Checking Environment..." -ForegroundColor Yellow

# Check Flutter
if (Test-Command "flutter") {
    $flutterVersion = flutter --version | Select-Object -First 1
    Write-Status "Flutter found: $flutterVersion" "✓"
}
else {
    Write-Status "Flutter not found in PATH" "✗"
    Write-Host "`n  Installing Flutter..." -ForegroundColor Gray

    # Try Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install flutter -y
        Add-ToPath "C:\tools\flutter\bin"
    }
    else {
        Write-Status "Chocolatey not found. Manual installation required." "⚠"
        Write-Host "`n  Download from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
        Write-Host "  Extract to: C:\Users\$env:USERNAME\flutter" -ForegroundColor Yellow
        Write-Host "  Then add to PATH: `$env:PATH += `";C:\Users\$env:USERNAME\flutter\bin`"" -ForegroundColor Yellow

        Read-Host "`n  Press Enter after installing Flutter"

        if (-not (Test-Command "flutter")) {
            Write-Status "Flutter still not found. Exiting." "✗"
            exit 1
        }
    }
}

# Check Android SDK
if ([string]::IsNullOrEmpty($env:ANDROID_HOME)) {
    $androidPath = "C:\Users\$env:USERNAME\AppData\Local\Android\sdk"
    if (Test-Path $androidPath) {
        $env:ANDROID_HOME = $androidPath
        [Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidPath, [EnvironmentVariableTarget]::User)
        Write-Status "Set ANDROID_HOME: $androidPath" "✓"
    }
    else {
        Write-Status "ANDROID_HOME not set. Please install Android Studio or set manually." "⚠"
    }
}
else {
    Write-Status "ANDROID_HOME: $env:ANDROID_HOME" "✓"
}

# Check Java
if (Test-Command "java") {
    Write-Status "Java found" "✓"
}
else {
    Write-Status "Java not found. Please install JDK 11+." "⚠"
}

# ============================================================================
# STEP 2: FLUTTER DOCTOR CHECK
# ============================================================================

Write-Host "`n[2/5] Running Flutter Doctor..." -ForegroundColor Yellow

$doctorOutput = flutter doctor 2>&1
Write-Host $doctorOutput

$hasDevice = $doctorOutput | Select-String "connected device" -Quiet
if (-not $hasDevice) {
    Write-Status "No device/emulator found" "⚠"
    Write-Host "`n  Available emulators:" -ForegroundColor Gray
    flutter emulators

    Write-Host "`n  To launch an emulator:" -ForegroundColor Gray
    Write-Host "    flutter emulators --launch <emulator_id>" -ForegroundColor Gray

    if ($DeviceType -eq "emulator") {
        $emulatorChoice = Read-Host "`n  Enter emulator name to launch (or press Enter to skip)"
        if (-not [string]::IsNullOrEmpty($emulatorChoice)) {
            Write-Host "  Launching emulator: $emulatorChoice..." -ForegroundColor Gray
            flutter emulators --launch $emulatorChoice | Out-Null
            Start-Sleep -Seconds 3
        }
    }
}

# ============================================================================
# STEP 3: GET DEPENDENCIES
# ============================================================================

Write-Host "`n[3/5] Installing Dependencies..." -ForegroundColor Yellow

Push-Location $projectRoot

Write-Status "Running: flutter pub get" "→"
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Status "Failed to get dependencies" "✗"
    exit 1
}
Write-Status "Dependencies installed" "✓"

# ============================================================================
# STEP 4: ENVIRONMENT SETUP
# ============================================================================

Write-Host "`n[4/5] Setting Up Environment..." -ForegroundColor Yellow

# Check .env file
if (-not (Test-Path ".env")) {
    Write-Status ".env not found, creating from template..." "⚠"
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Status ".env created (needs Firebase/Supabase keys)" "→"
    }
    else {
        Write-Status "No .env template found" "⚠"
    }
}
else {
    Write-Status ".env found" "✓"
}

# ============================================================================
# STEP 5: LAUNCH APP
# ============================================================================

Write-Host "`n[5/5] Launching App..." -ForegroundColor Yellow

Write-Host "`n  Verifying device is ready..." -ForegroundColor Gray
$devices = flutter devices 2>&1

if ($devices | Select-String "no devices found") {
    Write-Status "No device available. Please:" "✗"
    Write-Host "`n  1. Connect an Android device via USB, OR" -ForegroundColor Yellow
    Write-Host "  2. Start an emulator: flutter emulators --launch <name>" -ForegroundColor Yellow
    Write-Host "  3. Run: flutter run" -ForegroundColor Yellow
    exit 1
}

# Show device info
Write-Host "`n  Available devices:" -ForegroundColor Gray
flutter devices

# Build command
$buildMode = if ($Release) { "--release" } else { "" }
$runCommand = "flutter run $buildMode"

Write-Host "`n  Launching app..." -ForegroundColor Gray
Write-Host "  Command: $runCommand" -ForegroundColor Gray
Write-Host "`n  ▸ Press 'r' to hot reload" -ForegroundColor Cyan
Write-Host "  ▸ Press 'R' to full restart" -ForegroundColor Cyan
Write-Host "  ▸ Press 'q' to quit" -ForegroundColor Cyan
Write-Host ""

Pop-Location

# Launch the app
Invoke-Expression $runCommand

# ============================================================================
# POST-RUN
# ============================================================================

Write-Host "`n╔════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  App Session Ended                         ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  • Run again: .\scripts\setup_and_run.ps1" -ForegroundColor Gray
Write-Host "  • Run tests: flutter test --coverage" -ForegroundColor Gray
Write-Host "  • Build release: flutter build appbundle --release" -ForegroundColor Gray
Write-Host ""
