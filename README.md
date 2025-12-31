# Login App - MVVM + BLoC Pattern

A complete Flutter authentication app with Firebase Auth, OTP verification via email, and session management.

## Features

- ✅ **MVVM + BLoC Pattern** - Clean architecture with proper separation of concerns
- ✅ **Firebase Authentication** - Secure user authentication
- ✅ **Email OTP Verification** - OTP sent via Gmail SMTP for both signup and login
- ✅ **Session Management** - Persistent login sessions using SharedPreferences
- ✅ **Profile Management** - Upload profile image (stored locally), URL in Firestore
- ✅ **Full User Flow**:
  - Signup → OTP Verification → Profile Page
  - Login → OTP Verification → Profile Page
  - Profile: View/Edit profile, Logout, Delete Account

## Architecture

```
lib/
├── core/
│   └── constants/
│       └── app_constants.dart          # App-wide constants
├── data/
│   ├── models/
│   │   ├── user_model.dart             # User data model
│   │   └── otp_model.dart              # OTP data model
│   └── repositories/
│       ├── auth_repository.dart        # Firebase Auth operations
│       ├── storage_repository.dart     # Local storage (SharedPreferences)
│       └── otp_repository.dart         # OTP generation & verification
├── presentation/
│   ├── bloc/
│   │   ├── auth_bloc.dart              # Business logic
│   │   ├── auth_event.dart             # Auth events
│   │   └── auth_state.dart             # Auth states
│   └── screens/
│       ├── splash_screen.dart          # Initial loading screen
│       ├── login_screen.dart           # Login UI
│       ├── signup_screen.dart          # Signup UI
│       ├── otp_verification_screen.dart # OTP verification UI
│       └── profile_screen.dart         # Profile UI
├── firebase_options.dart               # Firebase configuration
└── main.dart                           # App entry point
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd login1app
flutter pub get
```

### 2. Configure Firebase

#### Option A: Using FlutterFire CLI (Recommended)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```

This will automatically:
- Create a Firebase project (or use existing)
- Register your iOS and Android apps
- Download configuration files
- Generate `firebase_options.dart`

#### Option B: Manual Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable **Authentication** → **Email/Password** sign-in method
4. Enable **Cloud Firestore** database
5. Download configuration files:
   - **Android**: `google-services.json` → `android/app/`
   - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`
7. Update `lib/firebase_options.dart` with your Firebase credentials

### 3. Configure Email OTP

Open `lib/core/constants/app_constants.dart` and update:

```dart
static const String senderEmail = 'your-email@gmail.com';
static const String appPassword = 'your-app-password';
```

#### How to Get Gmail App Password:

1. Go to Google Account → Security
2. Enable 2-Step Verification
3. Go to App Passwords
4. Select "Mail" and your device
5. Copy the 16-character password
6. Paste it in `appPassword` (without spaces)

### 4. Firebase Firestore Rules

Set these rules in Firebase Console → Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
  }
}
```

### 5. Run the App

```bash
flutter run
```

## User Flow

### Signup Flow
1. User enters: Name, Email, Password, Confirm Password
2. Optional: Upload profile picture
3. Click "Sign Up"
4. OTP sent to email
5. User enters 6-digit OTP
6. Account created → Navigate to Profile Page

### Login Flow
1. User enters: Email, Password
2. Credentials verified
3. OTP sent to email
4. User enters 6-digit OTP
5. Logged in → Navigate to Profile Page

### Profile Page
- View profile image, name, email
- Edit profile image (tap camera icon)
- Logout (with confirmation)
- Delete account (with confirmation)

## State Management

This app uses **BLoC (Business Logic Component)** pattern:

- **Events**: User actions (login, signup, logout, etc.)
- **States**: UI states (loading, authenticated, error, etc.)
- **BLoC**: Handles business logic and state transitions

## Dependencies

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.2
  
  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  
  # Local Storage
  shared_preferences: ^2.3.3
  
  # Image Picker
  image_picker: ^1.1.2
  
  # Email OTP
  mailer: ^6.1.2
  
  # UI
  flutter_spinkit: ^5.2.1
  cached_network_image: ^3.4.1
```

## Key Features Implementation

### Session Management
- Uses `SharedPreferences` to store login state
- Persists across app restarts
- Automatic session check on app launch

### Profile Image Storage
- Image stored locally using `image_picker`
- Local path saved in `SharedPreferences`
- Local path also stored in Firestore (not Firebase Storage URL)
- No cloud storage used - all images are local

### Security
- Passwords hashed by Firebase Auth
- OTP expires after 10 minutes
- Firestore rules restrict access to user's own data
- Images stored locally on device

## Troubleshooting

### Firebase Initialization Error
- Make sure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in correct locations
- Run `flutterfire configure` again

### OTP Not Sending
- Verify Gmail credentials in `app_constants.dart`
- Check if 2-Step Verification is enabled
- Ensure App Password is correct (16 characters, no spaces)

### Profile Image Not Showing
- Check if image path is saved in SharedPreferences
- Verify image file exists at the local path
- Check Firestore to see if path is stored correctly

## License

MIT License - feel free to use this project for learning or production.
