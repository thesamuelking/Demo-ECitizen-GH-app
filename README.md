# GhanaServe — Flutter Mobile App

A citizen-facing mobile app for accessing Ghana Government services.

## Services Covered
- 👶 Birth Certificate
- 🛂 Passport
- 🚗 Driver's License
- 🏥 Health Insurance (NHIS)
- 🪪 Ghana Card (National ID)

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.16.0 — [Install Flutter](https://docs.flutter.dev/get-started/install)
- Dart SDK ≥ 3.2.0 (bundled with Flutter)
- Android Studio or Xcode (for device/emulator)

### Run the app

```bash
# 1. Navigate into the project
cd flutter_app

# 2. Install dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run

# Run on a specific platform
flutter run -d android
flutter run -d ios
flutter run -d chrome   # web preview
```

### Run the real backend

The app uses the Django REST API in `backend/` for authentication and citizen applications. MySQL is the default database and Docker Compose provides a local instance.

```powershell
cd backend
py -m venv .venv

# If PowerShell blocks activation, allow this session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
\.\.venv\Scripts\Activate.ps1

# Or, if you prefer Command Prompt instead of PowerShell:
# .\.venv\Scripts\activate.bat

pip install -r requirements.txt
Copy-Item .env.example .env
docker compose up -d db
py manage.py makemigrations accounts applications
py manage.py migrate
py manage.py runserver 0.0.0.0:8000
```

The Android emulator uses `http://10.0.2.2:8000/api` by default. Set another server with `--dart-define=API_BASE_URL=http://<host>:8000/api`.

### Admin dashboard

Run the same Flutter project on the web with `flutter run -d chrome`. Citizen sign-in includes a Government Staff Portal link. Staff must first select their service role, then sign in with an authorized `@ecitizengh.com` account.

#### Create or reset service-admin accounts

The backend supports one dedicated staff login per service department. The `create_admin` command is idempotent: if the `--email` already exists, it updates that account's name, phone, service assignment, and password; otherwise, it creates the account. To rename an existing account, provide its current address with `--old-email` and its new address with `--email`. Every account must use an `@ecitizengh.com` email address, and each password should be unique and at least eight characters long.

From the `backend/` directory, activate the virtual environment and run the following commands. Replace every value in angle brackets before running it. Do not commit real passwords to source control or paste them into shared documentation.

1. Install the backend dependencies and apply the existing migrations:

```powershell
pip install -r requirements.txt
py manage.py migrate
```

2. Change the emails and reset the passwords for the two existing service logins. Replace both `<current-...-admin-email>` values with the exact current email addresses in the database, and replace both `<new-...-admin-email>` values with the new addresses you want to use:

```powershell
py manage.py create_admin --old-email "<current-identity-admin-email>@ecitizengh.com" --email "<new-identity-admin-email>@ecitizengh.com" --name "Identity and Personal Documents Administrator" --phone "<identity-admin-phone>" --password "<new-identity-password>" --service "Identity & Personal Documents"
py manage.py create_admin --old-email "<current-taxes-admin-email>@ecitizengh.com" --email "<new-taxes-admin-email>@ecitizengh.com" --name "Taxes and Payments Administrator" --phone "<taxes-admin-phone>" --password "<new-taxes-password>" --service "Taxes & Payments"
```

3. Create dedicated accounts for the remaining six service departments. The email addresses below are suggested names; change them only if those addresses are not available in your organization:

```powershell
py manage.py create_admin --email "transport.admin@ecitizengh.com" --name "Transport and Drivers Services Administrator" --phone "<transport-admin-phone>" --password "<new-transport-password>" --service "Transport & Driver's Services (DVLA)"
py manage.py create_admin --email "health.admin@ecitizengh.com" --name "Health and Insurance Administrator" --phone "<health-admin-phone>" --password "<new-health-password>" --service "Health & Insurance"
py manage.py create_admin --email "socialsecurity.admin@ecitizengh.com" --name "Social Security Administrator" --phone "<social-security-admin-phone>" --password "<new-social-security-password>" --service "Social Security"
py manage.py create_admin --email "business.admin@ecitizengh.com" --name "Business and Company Services Administrator" --phone "<business-admin-phone>" --password "<new-business-password>" --service "Business & Company Services"
py manage.py create_admin --email "safetyjustice.admin@ecitizengh.com" --name "Safety and Justice Administrator" --phone "<safety-justice-admin-phone>" --password "<new-safety-justice-password>" --service "Safety & Justice"
py manage.py create_admin --email "utilities.admin@ecitizengh.com" --name "Utilities and Assembly Administrator" --phone "<utilities-admin-phone>" --password "<new-utilities-password>" --service "Utilities & Assembly"
```

4. Start the backend and verify each account by selecting the matching service department on the Government Staff Portal:

```powershell
py manage.py runserver 0.0.0.0:8000
```

The dashboard uses the shared Django API at `/api/applications/admin/applications/`. Staff can inspect submitted form data, filter/search applications, and set processing, approved, or rejected. Each status decision creates a backend notification which is merged into the citizen's Notifications view.

#### Backend configuration notes

- No new migration is required for this change. The `accounts` migration already contains the `service_department` field.
- The command validates the service name against `CitizenUser.SERVICE_DEPARTMENTS`; copy the service values exactly as shown above.
- The command updates an existing account by `--email`, or renames an existing account in place when `--old-email` is supplied. It rejects the operation if the new email already belongs to another account.
- Keep `SECRET_KEY`, database credentials, and other values in `backend/.env`. Do not place real admin passwords in `.env.example`, README files, or Git.
- After changing credentials, sign out any old dashboard sessions and sign back in with the new email/password and matching service selection.

### Build for release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── router/
│   └── app_router.dart         # go_router navigation
├── theme/
│   └── app_theme.dart          # Colors, typography, Material theme
├── models/
│   └── service_model.dart      # Data types & enums
├── data/
│   └── services_data.dart      # Static service & application data
├── screens/
│   ├── splash_screen.dart
│   ├── shell_screen.dart       # Bottom nav shell
│   ├── home_screen.dart
│   ├── services_screen.dart
│   ├── service_detail_screen.dart
│   ├── apply_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── service_card.dart
    └── status_badge.dart
```

## Key Dependencies

| Package | Purpose |
|---|---|
| `go_router` | Declarative navigation |
| `flutter_riverpod` | State management |
| `google_fonts` | Plus Jakarta Sans + Inter + JetBrains Mono |
| `flutter_animate` | Smooth micro-animations |
| `shared_preferences` | Local storage |
| `flutter_secure_storage` | Secure token storage |
| `url_launcher` | Support call links |

## Color Palette (Ghana Flag)

| Token | Hex | Usage |
|---|---|---|
| Ghana Red | `#CE1126` | Primary, Home header |
| Ghana Gold | `#FCD116` | Accent, notices |
| Ghana Green | `#006B3F` | Secondary, Profile header, progress |
| Surface | `#F4F6F9` | Page background |
