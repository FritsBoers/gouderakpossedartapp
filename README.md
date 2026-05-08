# Gouderak Posse Darts App

A competitive darts counter app with local/online multiplayer and leaderboards. Built with Flutter Web, Firebase (free tier), and Riverpod.

**Live:** https://FritsBoers.github.io/gouderakpossedartapp/

## Features

- Standard darts scoring (301/501/701) with double-out rules
- Local multiplayer (same device)
- Online multiplayer via game codes
- Checkout suggestions for finishes up to 170
- Player stats tracking (wins, average, highest finish, legs)
- Leaderboards (5 categories)
- Google + Email/Password authentication with email verification
- Red/yellow flag-inspired dark theme
- Works offline (local games) when Firebase is not configured

## Quick Start (Local Game Only)

No Firebase needed — the app runs in offline mode with local game support.

```bash
git clone https://github.com/FritsBoers/gouderakpossedartapp.git
cd gouderakpossedartapp
flutter pub get
flutter run -d chrome
```

## Full Setup (With Backend)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Node.js](https://nodejs.org/) (for Firebase CLI)
- A Google account

### 1. Accept Google Cloud Terms of Service

Visit https://console.cloud.google.com/ and sign in with your Google account. Accept the Terms of Service when prompted. This is required before creating Firebase projects via the CLI.

### 2. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com) and create a new project (or use an existing one)
2. Enable **Authentication** → Sign-in methods:
   - **Google** (set project support email)
   - **Email/Password**
3. Create a **Cloud Firestore** database (start in production mode)
4. Add a **Web app** in Project Settings → Your apps → Add app → Web

### 3. Configure Firebase in the App

**Option A: FlutterFire CLI (recommended)**

```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
flutterfire configure --project=YOUR_PROJECT_ID
```

This auto-generates `lib/firebase_options.dart` with your Firebase config.

**Option B: Manual configuration**

Copy the Firebase config from Firebase Console → Project Settings → Your apps → Web app → Config, and update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-api-key',
  appId: 'your-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  authDomain: 'your-project.firebaseapp.com',
  storageBucket: 'your-project.firebasestorage.app',
);
```

### 4. Deploy Firestore Security Rules

```bash
firebase login   # if not already logged in
firebase deploy --only firestore:rules
```

### 5. Run Locally

```bash
flutter run -d chrome
```

### 6. Build for Production

```bash
flutter build web --release --base-href "/gouderakpossedartapp/"
```

Output is in `build/web/`.

## GitHub Pages Deployment

The app auto-deploys to GitHub Pages on every push to `main` via GitHub Actions.

### Enable GitHub Pages

1. Go to your repo on GitHub → **Settings** → **Pages**
2. Under **Source**, select **GitHub Actions**
3. Push to `main` — the workflow at `.github/workflows/deploy.yml` will build and deploy

### Custom Domain (Optional)

1. Add a `CNAME` file in `web/` with your domain (e.g., `darts.yourdomain.com`)
2. Configure DNS: CNAME record pointing to `FritsBoers.github.io`
3. Enable HTTPS in GitHub Pages settings
4. Update `--base-href` in `.github/workflows/deploy.yml` to `"/"`

## Architecture

```
lib/
├── main.dart              # App entry, Firebase init
├── app.dart               # Root widget (theme + router)
├── firebase_options.dart  # Generated Firebase config
├── core/
│   ├── theme/             # Colors, Material theme
│   ├── router/            # go_router with auth guards
│   ├── constants/         # Game rules, checkout table
│   └── utils/             # Score validation, checkout suggestions
├── models/                # Data classes (User, Game, Leaderboard)
├── services/              # Firebase interaction layer
├── providers/             # Riverpod state management
└── ui/
    ├── screens/           # Full-page views
    └── widgets/           # Reusable components
```

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter Web |
| State Management | Riverpod |
| Routing | go_router |
| Backend | Firebase (Spark/free) |
| Auth | Firebase Auth (Google + Email) |
| Database | Cloud Firestore |
| Charts | fl_chart |
| Fonts | Google Fonts (Inter) |

## Free Tier Limits

| Service | Limit |
|---------|-------|
| Firestore reads | 50,000/day |
| Firestore writes | 20,000/day |
| Firebase Auth | Unlimited users |
| Firebase Storage | 5 GB |

