# SpendLens Interactive Walkthrough

Visual guide to every screen and feature you'll interact with.

---

## 🎬 INTERACTIVE WALKTHROUGH

### SCREEN 1: Splash Screen (2 seconds)
```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│            💸 SpendLens             │
│                                     │
│         [⟳ Loading Spinner]         │
│                                     │
│                                     │
└─────────────────────────────────────┘

What happens: Auto-advances to onboarding after 2 seconds
```

---

### SCREEN 2: Onboarding (4 Slides)

#### Slide 1: Zero Manual Entry
```
┌─────────────────────────────────────┐
│                                     │
│       📱 ZERO MANUAL ENTRY          │
│                                     │
│  Your bank sends SMS.               │
│  We read it. You get insights.      │
│  That's it.                         │
│                                     │
│          ● ○ ○ ○                   │
│                                     │
│        [Next]                       │
└─────────────────────────────────────┘

Try: Swipe right or tap Next
```

#### Slide 2: Your Data, Your Phone
```
┌─────────────────────────────────────┐
│                                     │
│      🔒 YOUR DATA, YOUR PHONE      │
│                                     │
│  SMS never leaves your device.      │
│  Parsed data syncs encrypted.       │
│  You stay in control.               │
│                                     │
│          ○ ● ○ ○                   │
│                                     │
│        [Next]                       │
└─────────────────────────────────────┘

Try: Swipe or tap Next
```

#### Slide 3: Smart Categories
```
┌─────────────────────────────────────┐
│                                     │
│      📊 AUTO-CATEGORIZATION         │
│                                     │
│  Zomato → Food                      │
│  Uber → Transport                   │
│  Netflix → Entertainment            │
│  25+ categories, auto-tagged        │
│                                     │
│          ○ ○ ● ○                   │
│                                     │
│        [Next]                       │
└─────────────────────────────────────┘

Try: Swipe or tap Next
```

#### Slide 4: Your Budget, Visualized
```
┌─────────────────────────────────────┐
│                                     │
│    💰 BUDGETS & INSIGHTS            │
│                                     │
│  Set monthly limits.                │
│  Get alerts at 80%, 100%.           │
│  See spending patterns.             │
│                                     │
│          ○ ○ ○ ●                   │
│                                     │
│    [Get Started]                    │
└─────────────────────────────────────┘

Try: Tap Get Started → moves to Auth
```

---

### SCREEN 3: Authentication

#### Phone OTP Tab (Default)
```
┌─────────────────────────────────────┐
│  [Phone]  [Email]                   │
├─────────────────────────────────────┤
│                                     │
│  Phone Authentication               │
│                                     │
│  Country Code                       │
│  [+91▼]                             │
│                                     │
│  Phone Number                       │
│  [_____________________]            │
│   (Enter 10 digits)                 │
│                                     │
│        [Send OTP]                   │
│                                     │
│                                     │
└─────────────────────────────────────┘

Try: Enter phone (9876543210)
     Tap "Send OTP"
     Enter mock OTP (any 6 digits)
```

#### Email Tab (Click "Email")
```
┌─────────────────────────────────────┐
│  [Phone]  [Email]                   │
├─────────────────────────────────────┤
│                                     │
│  Email Authentication               │
│                                     │
│  Email Address                      │
│  [_____________________]            │
│                                     │
│  Password                           │
│  [_____________________]            │
│                                     │
│  [Login]    [Create Account ↓]      │
│                                     │
│  Forgot Password?                   │
│                                     │
└─────────────────────────────────────┘

Try: Click "Create Account" → Signup Dialog
```

#### Signup Dialog (Click "Create Account")
```
┌─────────────────────────────────────┐
│  Create Account                     │
├─────────────────────────────────────┤
│                                     │
│  Name                               │
│  [_____________________]            │
│                                     │
│  Email                              │
│  [_____________________]            │
│                                     │
│  Password                           │
│  [_____________________]            │
│                                     │
│  Confirm Password                   │
│  [_____________________]            │
│                                     │
│     [Cancel]    [Sign Up]           │
│                                     │
└─────────────────────────────────────┘

Try: Fill details → Tap "Sign Up"
```

---

### SCREEN 4: Home Dashboard

```
┌─────────────────────────────────────┐
│  SpendLens                          │
│  Thu, 6 Jun                         │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────┬──────────────┐    │
│  │              │              │    │
│  │    SPENT     │    INCOME    │    │
│  │   ₹15,430    │   ₹50,000    │    │
│  │              │              │    │
│  └──────────────┴──────────────┘    │
│                                     │
│  RECENT TRANSACTIONS                │
│  ─────────────────────────────────  │
│                                     │
│  🍽️  Zomato                        │
│      Food & Dining    ₹450         │
│      Today at 12:30 PM              │
│                                     │
│  🚗  Uber                          │
│      Transport        ₹280         │
│      Yesterday at 6:45 PM           │
│                                     │
│  💳  Amazon                        │
│      Shopping         ₹1,299       │
│      Mon 4 Jun at 5:20 PM          │
│                                     │
│  📺  Netflix                       │
│      Entertainment    ₹199         │
│      Mon 4 Jun at 2:10 PM          │
│                                     │
│  ⚡  BSNL                          │
│      Bills & Utilities ₹899        │
│      Sun 3 Jun at 8:00 AM          │
│                                     │
│  ┌─────────────────────────────────┐│
│  │🏠    📋    💰    📈    ⚙️        ││ Bottom Navigation
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘

Try: Tap any transaction → Transaction detail (future)
     Tap 📋 → Transactions screen
     Tap 💰 → Budget screen
     Tap 📈 → Insights screen
     Tap ⚙️ → Settings screen
```

**Color Coding:**
- 🟢 **Green text** = Credit (income, refund, cashback)
- 🔴 **Red text** = Debit (spending, payments)
- **Category emoji** = Visual category identifier

---

### SCREEN 5: Transactions

```
┌─────────────────────────────────────┐
│  Transactions                       │
├─────────────────────────────────────┤
│                                     │
│  TODAY (₹1,410)                     │
│  ─────────────────────────────────  │
│                                     │
│  🍽️  Zomato                        │
│      Food & Dining    ₹450         │
│      12:30 PM                       │
│                                     │
│  🚗  Uber                          │
│      Transport        ₹280         │
│      6:45 PM                        │
│                                     │
│                                     │
│  YESTERDAY (₹1,498)                 │
│  ─────────────────────────────────  │
│                                     │
│  💳  Amazon                        │
│      Shopping         ₹1,299       │
│      5:20 PM                        │
│                                     │
│  📺  Netflix                       │
│      Entertainment    ₹199         │
│      2:10 PM                        │
│                                     │
│                                     │
│  MON 4 JUN (₹899)                   │
│  ─────────────────────────────────  │
│                                     │
│  ⚡  BSNL                          │
│      Bills & Utilities ₹899        │
│      8:00 AM                        │
│                                     │
│  ┌─────────────────────────────────┐│
│  │🏠    📋    💰    📈    ⚙️        ││ [+] FAB to add transaction
│  │ ↑ HOME  TRANSACTIONS ...         ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘

Try: Tap [+] FAB → Add Manual Transaction form
     Scroll up/down → See older transactions
```

---

### SCREEN 6: Budget

```
┌─────────────────────────────────────┐
│  Budget - June 2026                 │
├─────────────────────────────────────┤
│                                     │
│  ⚠️  OVER BUDGET IN 2 CATEGORIES    │
│     Food, Shopping                  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  🍽️  FOOD & DINING                 │
│      ████████████░░░ 89%            │
│      ₹4,450 / ₹5,000                │
│      ₹550 over budget               │
│                                     │
│  🛍️  SHOPPING                       │
│      ██████████████░ 95%            │
│      ₹9,500 / ₹10,000               │
│      ₹500 over budget               │
│                                     │
│  🚗  TRANSPORT                      │
│      ███░░░░░░░░░░ 28%              │
│      ₹840 / ₹3,000                  │
│      ₹2,160 remaining               │
│                                     │
│  🎬  ENTERTAINMENT                  │
│      ██░░░░░░░░░░░ 15%              │
│      ₹750 / ₹5,000                  │
│      ₹4,250 remaining               │
│                                     │
│  📚  EDUCATION                      │
│      █░░░░░░░░░░░░ 5%               │
│      ₹250 / ₹5,000                  │
│      ₹4,750 remaining               │
│                                     │
│  ┌─────────────────────────────────┐│
│  │🏠    📋    💰    📈    ⚙️        ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘

Color Indicators:
- 🔴 Red progress bar = Over budget (>100%)
- 🟡 Yellow progress bar = Near limit (80-100%)
- 🟢 Green progress bar = Within limit (<80%)

Try: Scroll down → See all budget categories
     Tap a budget → Edit limit (future feature)
```

---

### SCREEN 7: Insights

```
┌─────────────────────────────────────┐
│  Insights                           │
├─────────────────────────────────────┤
│                                     │
│  SMART INSIGHTS (Swipe →)           │
│  ╔══════════════════════════════╗   │
│  ║ 📊 Daily Average             ║   │
│  ║ You spent ₹514 per day       ║   │
│  ║ This month so far            ║   │
│  ╚══════════════════════════════╝   │
│                                     │
│  ╔══════════════════════════════╗   │
│  ║ 🔴 Food Spending Up          ║   │
│  ║ ₹4,450 (↑40% vs May)         ║   │
│  ║ Consider using Swiggy One    ║   │
│  ╚══════════════════════════════╝   │
│                                     │
│  ╔══════════════════════════════╗   │
│  ║ 💡 Savings Rate              ║   │
│  ║ 69% of income saved          ║   │
│  ║ Great job!                   ║   │
│  ╚══════════════════════════════╝   │
│                                     │
│  TOP MERCHANTS (by frequency)       │
│  ─────────────────────────────────  │
│                                     │
│  🏆 1. Zomato        18 transactions│
│     ₹4,450 total                    │
│                                     │
│  🥈 2. Amazon        12 transactions│
│     ₹15,850 total                   │
│                                     │
│  🥉 3. Uber          9 transactions │
│     ₹2,520 total                    │
│                                     │
│  4. Netflix          4 transactions │
│     ₹796 total                      │
│                                     │
│  MONTHLY COMPARISON                 │
│  ─────────────────────────────────  │
│                                     │
│  Food & Dining:  Jun ₹4,450         │
│                  May ₹3,180 (-27%)  │
│                                     │
│  Transport:      Jun ₹840           │
│                  May ₹1,230 (+39%)  │
│                                     │
│  ┌─────────────────────────────────┐│
│  │🏠    📋    💰    📈    ⚙️        ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘

Try: Swipe left/right in insight cards → See all insights
     Scroll down → See top merchants & comparisons
```

---

### SCREEN 8: Settings

```
┌─────────────────────────────────────┐
│  Settings                           │
├─────────────────────────────────────┤
│                                     │
│  PROFILE                            │
│  ─────────────────────────────────  │
│  👤 Name                            │
│     Shreyash Tirpude                │
│                                     │
│  📱 Phone                           │
│     +91 9876543210 (Read-only)      │
│                                     │
│  SECURITY                           │
│  ─────────────────────────────────  │
│  🔒 Biometric Lock                  │
│     [Toggle OFF] ← Tap to enable    │
│                                     │
│  🔑 Change PIN                      │
│     Set up optional PIN lock        │
│                                     │
│  NOTIFICATIONS                      │
│  ─────────────────────────────────  │
│  🔔 Transaction Alerts              │
│     [Toggle ON]                     │
│                                     │
│  📊 Budget Alerts                   │
│     [Toggle ON]                     │
│     Alert at 80% and 100% spent     │
│                                     │
│  📈 Weekly Report                   │
│     [Toggle ON]                     │
│     Every Monday at 9:00 AM         │
│                                     │
│  DATA & PRIVACY                     │
│  ─────────────────────────────────  │
│  💾 Export My Data                  │
│     Download as CSV                 │
│     Tap → Generates & downloads     │
│                                     │
│  🗑️  Clear All Data                │
│     Deletes all transactions        │
│     (Requires confirmation)         │
│                                     │
│  APP                                │
│  ─────────────────────────────────  │
│  📋 Privacy Policy                  │
│     Opens external link             │
│                                     │
│  ℹ️  About SpendLens                │
│     Version 1.0.0                   │
│                                     │
│  ⭐ Rate on Play Store              │
│     Opens Play Store                │
│                                     │
│  💬 Contact Support                 │
│     Opens email composer            │
│                                     │
│  🚪 Sign Out                        │
│     [Red Button] Logout             │
│                                     │
│  ┌─────────────────────────────────┐│
│  │🏠    📋    💰    📈    ⚙️        ││
│  │                    SETTINGS      ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘

Try: Toggle switches → Turn features on/off
     Tap "Export My Data" → Download CSV
     Tap "Biometric Lock" → Enable fingerprint
     Scroll down → Sign out
```

---

## 🎮 INTERACTIVE FEATURES TO TRY

### 1. Navigation (Bottom Tabs)
```
[🏠 Home] → [📋 Transactions] → [💰 Budget] → [📈 Insights] → [⚙️ Settings]

Try: Tap each tab → App smoothly transitions
     Tap same tab twice → May scroll to top
```

### 2. Add Manual Transaction
```
From Transactions or Home screen:
  Tap [+] FAB
  ↓
  Fill form:
    - Amount: ₹450
    - Merchant: Zomato
    - Category: Food & Dining
    - Date: Today
    - Note: (optional)
  ↓
  [Save] → Transaction appears in list
```

### 3. Biometric Lock
```
From Settings → Security:
  Tap "Biometric Lock" toggle
  ↓
  System prompts fingerprint/face setup
  ↓
  Close app
  ↓
  Reopen app
  ↓
  Biometric prompt appears
  ↓
  Authenticate → App unlocks
```

### 4. Export Data
```
From Settings → Data & Privacy:
  Tap "Export My Data"
  ↓
  CSV file generated
  ↓
  Opens download location
  ↓
  File contains: transactions, categories, amounts (NO raw SMS)
```

### 5. Budget Alerts
```
Set budget: Settings → Budget → Add limit (₹500 for Food)
Spend ₹400 → At 80% → Notification: "You're at 80% of Food budget"
Spend ₹600 → At 100%+ → Alert: "🔴 Over budget in Food"
```

---

## 🎨 VISUAL INDICATORS

### Colors
```
🔴 Red    = Debit/Spending/Over budget
🟢 Green  = Credit/Income/Within budget
🟡 Yellow = Warning/Near limit
⚫ Black  = Neutral/Default
```

### Category Emojis
```
🍽️  Food & Dining
🚗  Transport
🛍️  Shopping
🎬  Entertainment
📚  Education
🏥  Health
💳  Bills & Utilities
💰  Investments
🏧  ATM & Cash
📱  Subscriptions
🎉  Events & Activities
```

---

## 📱 WHAT WORKS NOW

✅ **Fully functional:**
- ✓ All navigation between screens
- ✓ Onboarding carousel
- ✓ Auth screens (UI only, needs backend)
- ✓ Dashboard with sample transactions
- ✓ Transaction list with date grouping
- ✓ Budget progress bars
- ✓ Insights cards
- ✓ Settings toggles
- ✓ Dark theme throughout
- ✓ Responsive layout (all screen sizes)

⚠️ **Requires backend/API:**
- Phone OTP verification (needs Supabase)
- Email signup/login (needs Firebase/Supabase)
- Real SMS parsing (needs Android SMS receiver)
- Cloud sync (needs Supabase database)
- Biometric setup (needs platform config)

---

## 🚀 START EXPLORING!

```powershell
# Run the app
cd C:\Users\shrey\Desktop\SpendLensProject
.\scripts\setup_and_run.ps1

# Then interact with all 8 screens
```

**Happy exploring!** 🎮✨
