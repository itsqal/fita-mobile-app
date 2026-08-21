# FITA — FWA Interface Transaction Apps

The Account Executive mobile app for HiFi AIR, part of the FWA Sales
Digitalization programme at Indosat Ooredoo Hutchison.

Flutter, Android only. See `CLAUDE.md` for the product rules — it is the
authority on layout, copy and backend behaviour, and this file does not repeat
it.

---

## Running it

The backend host is chosen at build time, so a shipped build cannot be pointed
at a development server by accident.

```bash
# Android emulator against a local backend.
# 10.0.2.2 is the emulator's alias for the host machine — 127.0.0.1 would be
# the emulator itself.
flutter run

# Physical handset against a local backend: pass your machine's LAN address.
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/v1

# Production.
flutter build apk --release --dart-define=ENV=prod
```

Production is `https://api.fwa-business.site/v1`. It is not reachable from the
Indosat corporate network — DNS suffix search rewrites the host and a proxy
answers with an untrusted certificate, so a failed probe there proves nothing.

For local development the backend must be running on `127.0.0.1:8000`. Seed
credential: `AE-BENGKULU1` / `Password123!`. That account does **not** exist in
production.

```bash
flutter analyze
flutter test
```

---

## Layout

```
lib/
  core/
    api/          ApiClient (auth, refresh, idempotency), TokenStore, ApiException
    config/       Env — base URL, GPS accuracy gate, incentive divisor
    format/       Indonesian dates, MSISDN normalisation, money, status labels
    location/     LocationService — accuracy gate and mock-location reporting
    theme/        Brand tokens and ThemeData
    period.dart   The API's period enum, which the "7 Hari Terakhir" chip reflects
  data/
    models/       One class per openapi.yaml schema
    ae_repository.dart   One method per screen-to-endpoint row in CLAUDE.md §7
  features/
    auth/         Log-In, SessionController
    home/         Halo {nama}!, the bar chart
    customers/    Input New Customer, Daftar New Customer / Daftar Hot Leads
    activation/   Aktivasi Pelanggan, the scanner, Daftar Aktivasi
    report/       Report
  widgets/        Shared header, filter row, tiles, cards, async states
```

Screens talk to `AeRepository`, never to `ApiClient` directly. No screen carries
a raw hex colour — everything comes from `Brand`.

---

## Build pins, and why

Three settings look arbitrary and are not. Removing any one breaks the build.

**`compileSdk` / `targetSdk` = 36**, not Flutter's default 37
(`android/app/build.gradle.kts`). The Android SDK publishes that platform only
as `platforms;android-37.0`, whose `AndroidVersion.ApiLevel` is the non-integer
`37.0`. The Flutter Gradle plugin resolves the hash string `android-37`, which
does not exist and cannot be installed.

**`flutter_secure_storage` = `^10.3.1`.** 11.0.0 declares `minCompileSdk 37` and
therefore cannot build at all given the above. In 10.3.1 the
`encryptedSharedPreferences` flag is deprecated *and ignored* — the library
already encrypts with its own ciphers — so it must not be passed.

**`kotlin.incremental=false`** (`android/gradle.properties`). Kotlin incremental
compilation fails on Windows with "Could not close incremental caches" while
compiling `mobile_scanner`. Full recompiles are slower but reliable.

---

## Known gaps

- **`mustChangePassword`** is returned by `/auth/login` on every AE's first
  login and is currently ignored. No change-password screen has been approved.
- **Gallery picker** in the scanner is present but inert — choosing an image
  needs a file-picker package that has not been approved. Layout is locked, so
  the control stays and says so rather than failing silently.
- **The `Filter` control** opens a period chooser matching the API's own
  `period` enum. What it is *meant* to open is unresolved (CLAUDE.md §11.1).
- **Offline outbox.** `sqflite` and `connectivity_plus` are in place but the
  queue itself is not built yet; submissions currently fail with a message when
  the connection is down.
- **Typeface.** The mockups are set in a geometric sans (Poppins family). The
  app currently uses the platform default, which is the one visible difference
  from the mockups.
