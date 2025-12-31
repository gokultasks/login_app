# Flutter Clean Architecture Documentation

## Overview
This project implements **Clean Architecture** principles using **BLoC (Business Logic Component)** pattern combined with **Repository pattern** for state management and data abstraction.

---

## Architecture Patterns

### 1. MVVM (Model-View-ViewModel)
- **Model**: Data models (`UserModel`, `ItemModel`)
- **View**: UI screens (`LoginScreen`, `ProfileScreen`, etc.)
- **ViewModel**: BLoC handles business logic and state management

### 2. BLoC Pattern
- Separates business logic from UI
- Uses streams for reactive programming
- Events → BLoC → States flow
- Implements single responsibility principle

### 3. Repository Pattern
- Abstracts data sources (Firebase, API, local storage)
- Provides clean API for BLoC layer
- Handles data operations and transformations

---

## Project Folder Structure

```
lib/
├── core/
│   └── constants/
│       └── app_constants.dart          # App-wide constants
│
├── data/
│   ├── models/                         # Data models
│   │   ├── user_model.dart
│   │   └── item_model.dart
│   │
│   └── repositories/                   # Data layer
│       ├── auth_repository.dart        # Authentication operations
│       ├── storage_repository.dart     # Local storage operations
│       ├── otp_repository.dart         # OTP operations
│       └── item_repository.dart        # Item CRUD operations
│
├── presentation/
│   ├── bloc/                           # Business Logic Components
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── item_list/
│   │   │   ├── item_list_bloc.dart
│   │   │   ├── item_list_event.dart
│   │   │   └── item_list_state.dart
│   │   └── item_form/
│   │       ├── item_form_bloc.dart
│   │       ├── item_form_event.dart
│   │       └── item_form_state.dart
│   │
│   └── screens/                        # UI Layer
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── forgot_password_screen.dart
│       ├── otp_verification_screen.dart
│       ├── profile_screen_new.dart
│       ├── main_navigation_screen.dart
│       ├── home_screen.dart
│       └── item_form_screen.dart
│
├── firebase_options.dart               # Firebase configuration
└── main.dart                          # App entry point
```

---

## Layer Responsibilities

### 1. Presentation Layer (`presentation/`)

#### **Screens** (`screens/`)
**Responsibility:**
- Display UI components
- Handle user interactions
- Listen to BLoC states
- Dispatch events to BLoC
- Navigation between screens



#### **BLoC** (`bloc/`)
**Responsibility:**
- Manage application state
- Handle business logic
- Process events from UI
- Call repository methods
- Emit states to UI
- Validate data
- Error handling

**Components:**
- **Events**: User actions or system events
- **States**: Represent different UI states
- **BLoC**: Processes events and emits states



#### **Repositories** (`repositories/`)
**Responsibility:**
- Abstract data sources (Firebase, API, Local DB)
- Implement CRUD operations
- Handle data fetching and caching
- Error handling and exceptions
- Data transformation between sources and models



### 3. Core Layer (`core/`)

**Responsibility:**
- App-wide constants
- Utility functions
- Common widgets
- Theme configuration
- Custom extensions

**Example:**
```dart
class AppConstants {
  static const String usersCollection = 'users';
  static const String itemsCollection = 'items';
  static const int pageSize = 15;
}
```

---

## Data Flow Architecture

### Complete Flow: User Login Example

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERACTION                          │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER - UI (login_screen.dart)                │
│                                                                   │
│  - User enters email/password                                    │
│  - Clicks "Login" button                                         │
│  - Dispatches event: SignInRequestedEvent                        │
│                                                                   │
│  context.read<AuthBloc>().add(                                   │
│    SignInRequestedEvent(email: email, password: password)        │
│  );                                                              │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER - BLoC (auth_bloc.dart)                      │
│                                                                   │
│  1. Receives: SignInRequestedEvent                               │
│  2. Emits: AuthLoadingState (show loading indicator)             │
│  3. Validates credentials (optional)                             │
│  4. Calls repository method                                      │
│                                                                   │
│  Future<void> _onSignInRequested(event, emit) async {            │
│    emit(AuthLoadingState());                                     │
│    try {                                                         │
│      final user = await _authRepository.signIn(...);             │
│      emit(AuthenticatedState(user));                             │
│    } catch (e) {                                                 │
│      emit(AuthErrorState(e.toString()));                         │
│    }                                                             │
│  }                                                               │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  DATA LAYER - Repository (auth_repository.dart)                  │
│                                                                   │
│  1. Receives method call: signIn(email, password)                │
│  2. Validates input                                              │
│  3. Calls Firebase Auth API                                      │
│  4. Fetches user data from Firestore                             │
│  5. Transforms data to UserModel                                 │
│  6. Returns UserModel to BLoC                                    │
│                                                                   │
│  Future<UserModel?> signIn({email, password}) async {            │
│    final userCredential = await _firebaseAuth                    │
│        .signInWithEmailAndPassword(...);                         │
│    final doc = await _firestore                                  │
│        .collection('users')                                      │
│        .doc(userCredential.user!.uid)                            │
│        .get();                                                   │
│    return UserModel.fromFirestore(doc);                          │
│  }                                                               │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  DATA SOURCE - Firebase                                          │
│                                                                   │
│  - Firebase Authentication: Verifies credentials                 │
│  - Firestore Database: Fetches user profile data                │
│                                                                   │
│  Returns: User authentication data + profile data                │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  DATA LAYER - Repository (Response)                              │
│                                                                   │
│  - Receives Firebase response                                    │
│  - Transforms to UserModel                                       │
│  - Handles errors if any                                         │
│  - Returns UserModel to BLoC                                     │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER - BLoC (State Emission)                      │
│                                                                   │
│  - Receives UserModel from repository                            │
│  - Emits AuthenticatedState(user)                                │
│  - BLoC state updated                                            │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER - UI (State Reaction)                        │
│                                                                   │
│  BlocBuilder rebuilds with new state:                            │
│                                                                   │
│  BlocBuilder<AuthBloc, AuthState>(                               │
│    builder: (context, state) {                                   │
│      if (state is AuthLoadingState) {                            │
│        return CircularProgressIndicator();                       │
│      }                                                           │
│      if (state is AuthenticatedState) {                          │
│        // Navigate to home screen                                │
│        return ProfileScreen(user: state.user);                   │
│      }                                                           │
│      if (state is AuthErrorState) {                              │
│        return ErrorMessage(state.message);                       │
│      }                                                           │
│    }                                                             │
│  );                                                              │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                        UI UPDATED                                 │
│                   User sees home screen                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Simplified Flow Diagram

```
UI Layer (Screens)
    │
    │ 1. User Action (tap button)
    │ 2. Dispatch Event
    ▼
BLoC Layer
    │
    │ 3. Process Event
    │ 4. Call Repository
    ▼
Repository Layer
    │
    │ 5. Fetch/Save Data
    │ 6. Transform Data
    ▼
Data Source (Firebase/API)
    │
    │ 7. Return Data
    ▼
Repository Layer
    │
    │ 8. Convert to Model
    │ 9. Return to BLoC
    ▼
BLoC Layer
    │
    │ 10. Emit State
    ▼
UI Layer (Screens)
    │
    │ 11. React to State
    │ 12. Update UI
    ▼
User sees updated screen
```

---


