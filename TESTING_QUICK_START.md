# SpendLens Testing — Quick Start

**TL;DR:** Run tests with one command after setup.

## ⚡ 60-Second Setup

```bash
# 1. Navigate to project
cd C:\Users\shrey\Desktop\SpendLensProject

# 2. Install dependencies
flutter pub get

# 3. Run all tests
flutter test --coverage
```

## 🚀 Common Test Commands

| Command | What it does | Time |
|---------|-------------|------|
| `flutter test` | Run all unit + widget tests | 2 min |
| `flutter test test/unit/sms_parser_test.dart` | Run SMS parser tests only | 30 sec |
| `flutter test integration_test/` | Run full app E2E (needs emulator) | 15 min |
| `flutter test --coverage` | Generate code coverage report | 3 min |
| `flutter analyze` | Check for code quality issues | 1 min |
| `.\scripts\run_tests.ps1` | Automated test runner (PowerShell) | 5+ min |

## 🎯 Pre-Launch Tests

Run this before submitting to Play Store:

```bash
# 1. Unit tests
flutter test test/unit/sms_parser_test.dart -v

# 2. Code analysis
flutter analyze

# 3. Build APK
flutter build apk --release

# 4. Build App Bundle
flutter build appbundle --release
```

## 🧪 What Tests Exist

### ✅ Unit Tests (15 cases)
- SMS parsing for 10+ Indian bank formats
- Amount extraction (with/without commas)
- Credit vs debit detection
- Merchant name extraction
- OTP/promo rejection
- Duplicate detection

**File:** `test/unit/sms_parser_test.dart`  
**Run:** `flutter test test/unit/`

### ✅ Integration Tests (12+ flows)
- App launch → splash → onboarding
- Phone OTP authentication
- Email login/signup
- Navigation between all 5 main screens
- Transaction listing & filtering
- Budget tracking & alerts
- Insights analytics
- Settings & biometric

**Files:** `integration_test/app_test.dart`, `integration_test/features_test.dart`  
**Run:** `flutter test integration_test/` (requires emulator)

## 🔧 Emulator Setup (for Integration Tests)

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch Pixel_4_API_30

# Verify device ready
flutter devices

# Run integration tests
flutter test integration_test/ -v
```

## 📊 Coverage Report

```bash
# Generate coverage
flutter test --coverage

# View coverage (requires genhtml installed)
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

**Target:** 85%+ coverage of critical paths

## ❌ Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter: command not found` | Add Flutter to PATH: `$env:PATH += ";C:\Users\shrey\flutter\bin"` |
| `No device connected` | Start emulator: `flutter emulators --launch <name>` |
| `Test timeout` | Increase timeout: `flutter test --timeout=60s` |
| `Hive box error` | Clear app data and restart emulator |

## 📈 CI/CD Pipeline

Tests run automatically on every push:

- **Trigger:** Push to `main` or `develop`, PR to `main`
- **Jobs:** test → build
- **Status:** Check `.github/workflows/ci.yml`
- **Artifacts:** Release APK uploaded on success

## ✨ Manual Testing Checklist

After automated tests pass, verify manually:

- [ ] SMS from bank appears as transaction
- [ ] Budget alert shows at 80%
- [ ] Biometric lock works
- [ ] Export CSV doesn't include raw SMS
- [ ] App works offline
- [ ] Sync completes when online

## 📚 Full Documentation

See [TEST.md](TEST.md) for detailed test documentation.

---

**Ready to test!** 🚀
