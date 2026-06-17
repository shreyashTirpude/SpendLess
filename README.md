# SpendLens — Auto Expense Tracker

**Privacy-first, SMS-powered expense tracker for Android.**  
Every UPI, debit card, and credit card transaction is automatically parsed from bank SMS notifications — on-device, AES-256 encrypted, zero cloud upload.

---

## What It Does

SpendLens reads your bank SMS alerts, extracts transaction details, categorizes them automatically, and gives you a complete picture of your finances — without ever sending your data to a server.

- **Zero manual entry** — 10+ Indian bank formats parsed automatically
- **100% on-device** — Raw SMS never leaves your phone
- **AES-256 encrypted storage** — Hive local database with encryption keys in Android Keystore
- **Production-ready** — 55 Dart files, 8,000+ lines, 9 screens, 18 providers, 5 services

---

## Screens

| Screen | What It Does |
|--------|-------------|
| **Splash** | Biometric gate on every launch; checks auth + onboarding state |
| **Auth** | Firebase Auth with PIN fallback; biometric enroll on first login |
| **Lock** | App-lock screen (auto-triggers after 2 min background); PIN + biometric |
| **Onboarding** | 4-slide permission flow (SMS, notifications, biometric) |
| **Terms** | Scroll-to-accept legal screen; guards onboarding entry |
| **Home** | Dashboard with balance card, weekly bar chart, achievement banners, top categories, recent 5 transactions |
| **Transactions** | Full searchable & filterable list; month picker; swipe-to-delete; FAB manual entry |
| **Budget** | Monthly limits per category with live progress bars; add/edit/delete budgets |
| **Insights** | Spend analytics — daily chart, month comparison, top merchants, top payees, weekly pattern heatmap, day-of-week ranking, no-spend streak, projected spend |
| **Subscriptions** | Auto-detected recurring charges grouped by merchant |
| **Category Detail** | Drill into any category; timeline chart + full transaction list |
| **Settings** | Profile, dark/light toggle, SMS rescan, biometric toggle, export CSV, data wipe, help |
| **Help** | In-app FAQ and support links |

---

## Core Features

### SMS Auto-Parsing
- Handles SBI, HDFC, ICICI, Axis, Kotak, PNB, BOB, Canara, Union Bank, Yes Bank, IDFC, IndusInd
- Extracts: amount, merchant name, account last-4, transaction type (credit/debit), date & time
- SHA-256 deduplication — never double-counts the same SMS
- Merchant normalizer maps raw strings to clean names (e.g., "SWIGGY ORDER 1234" → "Swiggy")

### Auto-Categorization Engine
25+ categories with keyword matching — Food, Transport, Shopping, Health, Entertainment, Utilities, Rent, EMI, Salary, Investments, Fuel, Education, Travel, and more. Learns from manual overrides stored locally.

### Analytics (Insights Screen)
- **Daily spend chart** — 30-day bar chart with tappable days
- **Month comparison** — this month vs last month per category
- **Top merchants** — by frequency
- **Top payees** — by amount
- **Weekly pattern** — Mon–Sun spend distribution (heatmap-style)
- **Day-of-week ranking** — spendiest day to most frugal
- **No-spend streak** — consecutive days with zero debit transactions
- **Projected month-end spend** — linear extrapolation from current pace
- **Smart insight cards** — contextual alerts (over-budget, unusual spike, savings milestone)

### Budget System
- Monthly limits per category
- Real-time progress bars with color-coded status (green → amber → red)
- Budget breach alerts via local notification
- Cache invalidation on every transaction mutation (Riverpod `transactionCacheProvider`)

### Recurring Detector
Identifies subscriptions and recurring charges from 2+ same-amount transactions with the same merchant within 25–35 day windows. Powers the Subscriptions screen.

### Streak Service
Tracks no-spend and under-budget streaks; stores streaks in Hive; surfaces them on the Home achievement banner.

### Financial Health Score
Composite 0–100 score computed from savings rate, budget adherence, emergency fund adequacy, and recurring spend ratio. Updates on every transaction change.

---

## UI Design System

### Apple HIG Inspired Dark Theme
- **Background** `#06060A` — deep space black
- **Surface** `#111118`, **Card** `#18181F`, **Elevated card** `#1E1E2A`
- **Gradient** — 3-stop: Violet `#7C3AED` → Indigo `#6366F1` → Blue `#3B82F6`
- **Success** `#34D399`, **Error** `#FF6B6B`

### Balance Card
3-stop gradient (`#7C3AED → #6366F1 → #3B82F6`), 28px border radius, dual layered box shadow (45% + 15% alpha at different blur radii).

### Frosted Glass Pill Navigation Bar
`BackdropFilter` with `sigmaX/Y = 20` blur. Animated `AnimatedContainer` pill slides behind the active tab icon. `AnimatedDefaultTextStyle` transitions label font weight on selection. No `BottomNavigationBar` — fully custom `_PillNavBar` widget.

### Ambient Glow (Dark Mode)
Two `RadialGradient` circles positioned at top-left and bottom-right of the Home scaffold body. `IgnorePointer` wrapped so they never intercept touch. Only renders in dark mode.

### Typography
`Google Fonts — DM Sans` at all weights. Display/Heading/Body/Label/Caption type scale in `AppTextStyles`.

---

## Architecture

```
lib/
├── core/
│   ├── config/          # GoRouter, Supabase config
│   ├── constants/       # App constants
│   ├── engine/          # ContextualAdEngine (affiliate suggestions)
│   ├── privacy/         # DataManifest (on-device data flow docs)
│   ├── security/        # SecurityService
│   ├── theme/           # AppColors, AppTextStyles, AppTheme
│   └── utils/           # CategoryEngine, MerchantNormalizer, RecurringDetector, SmsParser, Formatters
├── data/
│   ├── local/           # HiveService (AES-256), TransactionLocalDatasource
│   └── repositories/    # TransactionRepositoryImpl
├── domain/
│   ├── models/          # Transaction, Budget, Category, UserProfile (Hive-serialized)
│   └── repositories/    # Abstract repo interfaces
├── presentation/
│   ├── providers/       # 12 Riverpod providers (see below)
│   └── screens/         # 9 screen folders, 13 screen files
└── services/            # BiometricService, NotificationService, PasswordService, SmsScannerService, StreakService
```

### Riverpod Providers

| Provider | Type | Purpose |
|---------|------|---------|
| `transactionCacheProvider` | `NotifierProvider<int>` | Counter — bump to invalidate all derived providers |
| `transactionsProvider` | `FutureProvider` | All transactions for current month |
| `selectedMonthTransactionsProvider` | `FutureProvider` | Transactions for selected month/year |
| `homeStatsProvider` | `FutureProvider` | Income, spent, balance, recent 5, daily chart data |
| `cashFlowForecastProvider` | `FutureProvider` | Projected end-of-month spend |
| `savingsGoalProvider` | `StateProvider` | User's monthly savings target |
| `budgetProvider` | `FutureProvider` | All budgets with live spend |
| `healthScoreProvider` | `FutureProvider` | Financial health 0–100 |
| `insightCardsProvider` | `FutureProvider` | Smart insight cards list |
| `topMerchantsProvider` | `FutureProvider` | Top 5 merchants by frequency |
| `monthComparisonProvider` | `FutureProvider` | This month vs last by category |
| `noSpendStreakProvider` | `FutureProvider` | Consecutive no-spend days |
| `dailySpendProvider` | `FutureProvider` | 30-day daily spend array |
| `projectedSpendProvider` | `FutureProvider` | Linear spend projection |
| `weeklyPatternProvider` | `FutureProvider` | Mon–Sun distribution |
| `dayOfWeekRankingProvider` | `FutureProvider` | Days ranked by average spend |
| `topPayeesByAmountProvider` | `FutureProvider` | Top payees by total amount |
| `userProfileProvider` | `FutureProvider` | Name, avatar, onboarding state |
| `appSettingsProvider` | `FutureProvider` | Notification prefs, currency, lock config |
| `themeModeProvider` | `NotifierProvider` | Dark/light mode with persistence |
| `recurringTransactionsProvider` | `FutureProvider` | Subscription detection results |

---

## Security

| Layer | Implementation |
|-------|---------------|
| Local storage | Hive + AES-256; key stored in Android Keystore via `flutter_secure_storage` |
| SMS handling | Raw SMS text never stored; only extracted fields written to Hive |
| Deduplication | SHA-256 hash of raw SMS stored — collision-safe; SMS body not recoverable from hash |
| App lock | Biometric (fingerprint/face) via `local_auth`; PIN fallback via `PasswordService` |
| Session timeout | Auto-lock after 2 min background via `AppLifecycleListener` |
| Network | Zero outbound network calls for transaction data (Firebase Auth only) |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.32.2 / Dart SDK ≥ 3.3.0 |
| State management | Riverpod 2.x — FutureProvider + NotifierProvider |
| Local database | Hive 2.x + AES-256 encryption |
| Navigation | GoRouter 14.x with named routes |
| Charts | fl_chart 0.68 |
| Authentication | Firebase Auth 5.x |
| Notifications | flutter_local_notifications 17.x |
| Biometrics | local_auth 2.x |
| SMS reading | telephony 0.2 (Android BroadcastReceiver) |
| Secure storage | flutter_secure_storage 9.x (Android Keystore) |
| Fonts | Google Fonts — DM Sans |
| Sharing | share_plus 9.x |
| Permissions | permission_handler 11.x |

---

## Bug Fixes Applied (BUG-20 → BUG-30)

All 11 production bugs identified in the deep audit are fixed:

| ID | Screen / Provider | Fix |
|----|-----------------|-----|
| BUG-20 | `terms_screen.dart` | `_agree()` try/catch — resets spinner on error |
| BUG-21 | `terms_screen.dart` | `mounted` guard before `context.go()` |
| BUG-22 | `insights_provider.dart` | `noSpendStreakProvider` watches `transactionCacheProvider` |
| BUG-23 | `insights_provider.dart` | `monthComparisonProvider` watches `transactionCacheProvider` |
| BUG-24 | `transaction_provider.dart` | `daysUntilEmpty` guards zero-income and zero-surplus cases |
| BUG-25 | `transaction_provider.dart` | Copy-before-sort in `selectedMonthTransactionsProvider` |
| BUG-26 | `home_screen.dart` | `_AchievementBanner` — exclusive zero-spend badge; no badge stack |
| BUG-27 | `home_screen.dart` | `withValues(alpha:)` replacing deprecated `withOpacity()` |
| BUG-28 | `terms_screen.dart` | Scroll listener handles case where content fits without scrolling |
| BUG-29 | `GeneratedPluginRegistrant.java` | Removed `IntegrationTestPlugin` (breaks release build) |
| BUG-30 | `transaction_provider.dart` | Sort before `.take(5)` in `homeStatsProvider` recent transactions |

---

## Premium Feature Roadmap

SpendLens is designed with a freemium tier system to convert free users to paid subscribers. Full strategy report: [`docs/SpendLens_Premium_Strategy.pdf`](docs/SpendLens_Premium_Strategy.pdf)

### Tier Architecture

| Tier | Price | Annual |
|------|-------|--------|
| Free | ₹0 | — |
| Plus | ₹99/mo | ₹799/yr |
| Pro | ₹299/mo | ₹1,999/yr |
| Family | ₹449/mo | ₹2,999/yr |

### Top 10 Premium Features (by conversion impact)

| Rank | Feature | Tier | Why Users Pay |
|------|---------|------|--------------|
| 1 | AI Money Coach (on-device LLM chatbot) | Pro | Replaces ₹2,000/hr financial advisor |
| 2 | Subscription Waste Auditor | Plus | "₹1,840/mo wasted" — loss aversion trigger |
| 3 | Tax-Ready ITR Export (80C/80D/HRA) | Plus | 40–60% conversion spike every Feb–April |
| 4 | Spending Prediction Engine (ML forecast) | Pro | Prevents overspend before it happens |
| 5 | Debt Payoff Optimizer (Avalanche + Snowball) | Plus | PocketGuard charges $149 lifetime for this alone |
| 6 | Annual Bill Spike Predictor | Plus | 30-day early warning on insurance, renewals |
| 7 | Salary Day Cash Flow Predictor | Pro | Day-by-day rupee buffer until next payday |
| 8 | Smart Budget Auto-Generator | Plus | AI sets budgets from your own history |
| 9 | Savings Rate Trajectory | Plus | Shows exact date each goal will be funded |
| 10 | Investment Readiness Score | Pro | 0–100 score — "ready to invest?" with roadmap |

50 features fully ranked with descriptions, tier placement, implementation complexity, and revenue projections are in [`docs/SpendLens_Premium_Strategy.pdf`](docs/SpendLens_Premium_Strategy.pdf).

**Key retention insight:** Annual subscriptions retain at **44.1%** after 12 months vs **17.5%** monthly. Lead with annual pricing; offer 7-day no-card trial.

---

## Build & Run

```bash
# Prerequisites: Flutter 3.32.2, Android SDK, Java 17
flutter pub get
flutter run                          # debug on connected device
flutter build apk --release          # release APK (~57MB)
flutter build appbundle --release    # AAB for Play Store
```

Required Android permissions (auto-requested on first launch):
- `READ_SMS` — transaction parsing
- `RECEIVE_SMS` — real-time transaction detection
- `USE_BIOMETRIC` — app lock
- `POST_NOTIFICATIONS` — budget alerts

---

## Project Structure Stats

| Metric | Count |
|--------|-------|
| Dart source files | 55 |
| Lines of code | ~8,500 |
| Screens | 13 |
| Riverpod providers | 21 |
| Services | 5 |
| Domain models | 5 |
| Hive boxes | 5 |
| Supported bank SMS formats | 12+ |
| Auto-detected categories | 25+ |

---

## Changelog

### v1.3.0 — June 2026 (current)
- Apple HIG inspired UI overhaul (deep space theme, 3-stop gradient balance card)
- Frosted glass pill navigation bar (custom `BackdropFilter` + animated pill)
- Ambient radial glow effect on Home screen (dark mode)
- Day-of-week spend ranking in Insights
- Page transition animations throughout
- 11 production bug fixes (BUG-20 through BUG-30)
- Premium feature strategy + 50-feature roadmap document

### v1.2.0 — June 2026
- Circular ring charts for category breakdown
- Category accent color system
- Lock screen keyboard UX fix
- Privacy manifest for Play Store compliance

### v1.1.0 — June 2026
- Subscriptions screen with recurring charge detection
- App lifecycle lock (background → foreground triggers biometric)
- SMS rescan functionality
- Merchant name normalization engine
- Hive auto-sync on all mutations

### v1.0.0 — June 2026
- Initial production release
- All 9 core screens complete
- AES-256 local storage
- Firebase Auth
- SMS auto-parsing for 12 Indian banks
- Budget system with breach alerts
- Insights analytics engine

---

**Package:** `com.spendlens.spendlens`  
**Min SDK:** Android 6.0 (API 23)  
**Target SDK:** Android 14 (API 34)  
**Last updated:** June 2026
