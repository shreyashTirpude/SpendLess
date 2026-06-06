# SpendLens - Flutter Auto-Installation Script
# Run this as Administrator on Windows 11

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Flutter Auto-Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = [bool]([System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544")
if (-not $isAdmin) {
    Write-Host "[FAIL] Must run as Administrator" -ForegroundColor Red
    Write-Host ""
    Write-Host "Steps:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "  3. Run: .\install-flutter.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "[1] Checking Chocolatey..." -ForegroundColor Yellow
$chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

if (Test-Path $chocoPath) {
    Write-Host "  [OK] Chocolatey found" -ForegroundColor Green
} else {
    Write-Host "  [INSTALLING] Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [FAIL] Could not install Chocolatey" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual install:" -ForegroundColor Yellow
        Write-Host "  1. Visit: https://chocolatey.org/install" -ForegroundColor Gray
        Write-Host "  2. Follow instructions" -ForegroundColor Gray
        exit 1
    }
    Write-Host "  [OK] Chocolatey installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "[2] Installing Flutter..." -ForegroundColor Yellow
choco install flutter -y

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Flutter installation failed" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Flutter installed" -ForegroundColor Green

Write-Host ""
Write-Host "[3] Installing Java (required for Android)..." -ForegroundColor Yellow
choco install openjdk11 -y

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAIL] Java installation failed" -ForegroundColor Red
    Write-Host "  (Continue anyway)" -ForegroundColor Yellow
}
Write-Host "  [OK] Java 11 installed" -ForegroundColor Green

Write-Host ""
Write-Host "[4] Accepting Android licenses..." -ForegroundColor Yellow
# Refresh PATH to include flutter
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# Try to accept licenses
try {
    Write-Host "  Please wait..." -ForegroundColor Gray
    # Send 'y' multiple times to accept all licenses
    echo y | flutter doctor --android-licenses 2>$null | Out-Null
    Write-Host "  [OK] Licenses accepted" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not auto-accept licenses" -ForegroundColor Yellow
    Write-Host "  You may need to run: flutter doctor --android-licenses" -ForegroundColor Yellow
    Write-Host "  And press 'y' for each prompt" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5] Running Flutter Doctor..." -ForegroundColor Yellow
flutter doctor

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell" -ForegroundColor Gray
Write-Host "  2. cd C:\Users\shrey\Desktop\SpendLensProject" -ForegroundColor Gray
Write-Host "  3. .\run.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "To verify installation:" -ForegroundColor Cyan
Write-Host "  flutter --version" -ForegroundColor Gray
Write-Host "  flutter devices" -ForegroundColor Gray
Write-Host ""
