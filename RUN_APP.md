# SpendLens — Run The App

Complete step-by-step guide to install Flutter and run the SpendLens app.

---

## 📋 Prerequisites Check

Run this to check what's already installed:

```powershell
# Check if Flutter is installed
flutter --version

# Check if Android SDK is available
$env:ANDROID_HOME
$env:ANDROID_SDK_ROOT

# Check Java
java -version
```

---

## 🚀 QUICK SETUP (10 minutes)

### Step 1: Install Flutter (if not already installed)

**Option A: Using Chocolatey (Windows)**
```powershell
# Install Chocolatey first (if needed)
Set-ExecutionPolicy AllSigned
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Flutter
choco install flutter -y
```

**Option B: Manual Download**
1. Download from: https://flutter.dev/docs/get-started/install/windows
2. Extract to: `C:\Users\shrey\flutter`
3. Add to PATH:
   ```powershell
   $env:PATH += ";C:\Users\shrey\flutter\bin"
   [Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariableTarget]::User)
   ```

### Step 2: Install Android SDK (if needed)

```powershell
# Check if Android Studio is installed
# If yes, set ANDROID_HOME
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\$env:USERNAME\AppData\Local\Android\sdk", [EnvironmentVariableTarget]::User)

# Verify
flutter doctor
```

### Step 3: Accept Licenses

```powershell
flutter doctor --android-licenses
# Type 'y' for each prompt
```

### Step 4: Get Dependencies

```powershell
cd C:\Users\shrey\Desktop\SpendLensProject
flutter pub get
```

### Step 5: Run the App

**Option A: On Emulator**
```powershell
# Open Android Studio or use:
flutter emulators --launch Pixel_4_API_30

# Wait for emulator to boot, then:
flutter run
```

**Option B: On Physical Device (via USB)**
```powershell
# Enable USB debugging on your phone
# Connect phone via USB

flutter devices
# Should show your device

flutter run
```

---

## ✅ Full Setup Verification

```powershell
# Run complete doctor check
flutter doctor

# Expected output should show:
# ✓ Flutter
# ✓ Android SDK
# ✓ Android Studio (or VS Code)
# ✓ Connected device(s)
```

---

## 🎯 Running the App

### Start the App

```powershell
cd C:\Users\shrey\Desktop\SpendLensProject

# Run in debug mode (fastest for development)
flutter run

# Or run in release mode (production-like, slower to build)
flutter run --release
```

### Hot Reload During Development

While the app is running:
- Press `r` → Hot reload (fast, keeps state)
- Press `R` → Full restart (slow, resets app)
- Press `q` → Quit

---

## 🧪 Interactive Testing Checklist

Once the app is running, test these flows:

### Onboarding
- [ ] See splash screen for 2 seconds
- [ ] Swipe through 4 onboarding slides
- [ ] "Get Started" button advances to auth

### Authentication (Phone OTP)
- [ ] Enter phone number +91 XXXXXXXXXX
- [ ] Click "Send OTP"
- [ ] (Mock) Enter OTP code
- [ ] Successfully logged in

### Authentication (Email)
- [ ] Switch to "Email" tab
- [ ] Try "Create Account" with email
- [ ] Fill signup form (name, email, password)
- [ ] Successfully registered

### Home Dashboard
- [ ] See "Spent" and "Income" cards
- [ ] See recent transactions list
- [ ] Transactions show merchant, amount, time
- [ ] Debit amounts are red, credit amounts are green

### Transactions Screen
- [ ] Tap bottom nav "Transactions" tab
- [ ] See all transactions grouped by date
- [ ] Headers show "Today", "Yesterday", "Mon 3 Jun" format
- [ ] Each transaction shows category emoji + color
- [ ] Tap FAB to add manual transaction

### Budget Screen
- [ ] Tap "Budget" in bottom nav
- [ ] See budget list with progress bars
- [ ] Progress bars are color-coded by category
- [ ] Shows spent vs limit amounts

### Insights Screen
- [ ] Tap "Insights" in bottom nav
- [ ] See insight cards (horizontal scroll)
- [ ] See top merchants ranked by frequency
- [ ] See spending comparison vs last month

### Settings Screen
- [ ] Tap "Settings" in bottom nav
- [ ] Scroll through sections:
  - Profile (name, phone read-only)
  - Security (Biometric toggle)
  - Notifications (toggle switches)
  - Data (Export CSV, Clear data)
  - App (Privacy policy, About, Rate app)

### Navigation
- [ ] Bottom nav has 5 tabs (Home, Transactions, Budget, Insights, Settings)
- [ ] Tapping each tab navigates smoothly
- [ ] State is preserved when switching tabs

---

## 🐛 Troubleshooting

### Issue: "Flutter not found"
```powershell
# Add to PATH manually
$flutterPath = "C:\Users\shrey\flutter\bin"
if ($flutterPath -notin $env:PATH.Split(";")) {
    $env:PATH += ";$flutterPath"
}

# Verify
flutter --version
```

### Issue: "Android SDK not found"
```powershell
# Set ANDROID_HOME
[Environment]::SetEnvironmentVariable(
    "ANDROID_HOME",
    "C:\Users\$env:USERNAME\AppData\Local\Android\sdk",
    [EnvironmentVariableTarget]::User
)

# Restart PowerShell
```

### Issue: "No device connected"
```powershell
# List available emulators
flutter emulators

# Launch one
flutter emulators --launch Pixel_4_API_30

# Wait 30-60 seconds for boot
flutter devices
```

### Issue: "App won't start on emulator"
```powershell
# Kill and restart
flutter clean
flutter pub get
flutter run
```

### Issue: "Gradle build error"
```powershell
# Clean gradle cache
Remove-Item -Recurse -Force "android/.gradle"
flutter pub get
flutter run
```

---

## 📱 What You'll See

### Splash Screen
```
═══════════════════════════════════
        💸 SpendLens
        [Loading spinner]
═══════════════════════════════════
```

### Onboarding
```
╔═══════════════════════════════════╗
║    Zero Manual Entry             ║
║    Auto-tracks from bank SMS      ║
║                                   ║
║    [   Next  ]                    ║
│ ●○○○ (slide 1 of 4)              │
╚═══════════════════════════════════╝
```

### Dashboard Home
```
╔═══════════════════════════════════╗
║  THIS MONTH                       ║
║  ┌──────────────┬──────────────┐  ║
║  │ Spent        │ Income       │  ║
║  │ ₹15,430      │ ₹50,000      │  ║
║  └──────────────┴──────────────┘  ║
║                                   ║
║  RECENT TRANSACTIONS              ║
║  🍽️ Zomato - Food & Dining       ║
║     ₹450 · Today at 12:30 PM     ║
║                                   ║
║  🚗 Uber - Transport              ║
║     ₹280 · Yesterday at 6:45 PM   ║
╚═══════════════════════════════════╝
```

### Transactions Screen
```
╔═══════════════════════════════════╗
║  TODAY                            ║
║  🍽️ Zomato      ₹450  12:30 PM   ║
║  🚗 Uber        ₹280   6:45 PM   ║
║                                   ║
║  YESTERDAY                        ║
║  💳 Amazon      ₹1,299  5:20 PM   ║
║  📺 Netflix     ₹199    2:10 PM   ║
║                                   ║
║           [+] Add Transaction     ║
╚═══════════════════════════════════╝
```

---

## 🎮 Interactive Commands (While App Running)

| Key | Action |
|-----|--------|
| `r` | Hot reload (fast refresh, keeps state) |
| `R` | Full restart (slow rebuild) |
| `q` | Quit app |
| `d` | Detach from device |
| `l` | Show logs |

---

## 📊 Expected App Features

✅ **Working:**
- Splash → Onboarding → Auth flow
- 8 screens fully navigable
- SMS parser (backend ready, needs device SMS)
- Budget tracking with visual progress
- Insights with top merchants
- Settings with all toggles
- Dark theme throughout

⚠️ **Requires Backend:**
- Supabase auth (needs credentials in .env)
- Cloud sync (needs internet + Supabase)
- Real SMS parsing (needs actual SMS from bank)

---

## 🚀 Next Steps

Once app is running:
1. **Interact** → Navigate through all screens
2. **Test** → Try adding manual transactions
3. **Verify** → Check budget alerts, insights
4. **Customize** → Modify colors/text in `lib/core/theme/`
5. **Deploy** → Build APK when ready

---

## 📞 Need Help?

- **Flutter docs:** https://flutter.dev/docs
- **Android Studio:** https://developer.android.com/studio
- **Project issues:** Check `TEST.md` for debugging

---

**Ready to interact with SpendLens!** 🎮✨
