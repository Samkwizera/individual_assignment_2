# Kigali City Directory

A Flutter mobile application that helps Kigali residents locate and navigate to essential public services and lifestyle locations — hospitals, police stations, libraries, restaurants, cafes, parks, and tourist attractions.

---

## Features

| Feature | Description |
|---|---|
| **Authentication** | Firebase Auth with email/password, email verification enforced |
| **CRUD Listings** | Create, read, update, delete service listings in Cloud Firestore |
| **Real-time Updates** | Listings update instantly across all screens via Firestore streams |
| **Search & Filter** | Search by name/description; filter by category (dynamic, real-time) |
| **Map Integration** | Embedded Google Maps with custom markers on detail and map view screens |
| **Navigation** | One-tap Google Maps turn-by-turn directions launch |
| **User Reviews** | Authenticated users can rate and review listings |
| **Location Aware** | "Near You" section shows closest services using device GPS |
| **Settings** | User profile display, notification preference toggles (local) |

---

## Architecture

This app uses **Provider** for state management with a clean layered architecture:

```
lib/
├── main.dart                      # App entry + AppRouter (auth state handler)
├── firebase_options.dart          # Firebase configuration (replace with yours)
│
├── models/
│   ├── user_model.dart            # UserModel (uid, email, displayName, createdAt)
│   ├── listing_model.dart         # ListingModel (all listing fields)
│   └── review_model.dart          # ReviewModel (rating, comment, userId)
│
├── services/                      # Pure Firebase API layer -- NO UI logic here
│   ├── auth_service.dart          # Firebase Auth operations
│   ├── listing_service.dart       # Firestore CRUD for listings
│   └── review_service.dart        # Firestore operations for reviews
│
├── providers/                     # State management (Provider)
│   ├── auth_provider.dart         # Auth state + operations exposed to UI
│   └── listing_provider.dart      # Listing streams, CRUD, search, filter
│
├── screens/
│   ├── auth/                      # Login, Signup, EmailVerification
│   ├── home/                      # HomeScreen with BottomNavigationBar
│   ├── directory/                 # Directory (browse all listings)
│   ├── my_listings/               # User's own listings (edit/delete)
│   ├── map_view/                  # Google Maps with all listing markers
│   ├── settings/                  # User profile + notification preferences
│   ├── listing_detail/            # Full listing details, map, reviews
│   └── listing_form/              # Create / Edit listing form with map picker
│
├── widgets/
│   ├── listing_card.dart          # Reusable listing card (full + compact)
│   ├── category_filter_bar.dart   # Horizontal scrolling category chips
│   ├── star_rating.dart           # Display + interactive star rating
│   └── loading_overlay.dart       # Loading, empty state, error widgets
│
└── utils/
    └── constants.dart             # Colors, text styles, theme, categories
```

### Data Flow
```
Firestore --> Service Layer --> Provider (ChangeNotifier) --> UI (Consumer/watch)
```
UI widgets **never** call Firebase directly. All Firestore operations go through a service, and the provider exposes the resulting state.

---

## Firestore Database Structure

```
users/
  {uid}/
    email:          string
    displayName:    string
    createdAt:      timestamp

listings/
  {listingId}/
    name:           string
    category:       string         // Hospital | Police Station | Library | ...
    address:        string
    contactNumber:  string
    description:    string
    latitude:       number
    longitude:      number
    createdBy:      string         // user UID
    createdByName:  string
    createdAt:      timestamp
    rating:         number         // computed average
    reviewCount:    number

reviews/
  {reviewId}/
    listingId:      string
    userId:         string
    userName:       string
    rating:         number
    comment:        string
    createdAt:      timestamp
```

---

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0+)
- Android Studio / VS Code
- Firebase account
- Google Cloud account (for Maps API)

### 2. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com) and create a new project
2. Enable **Authentication** > Sign-in method > **Email/Password**
3. Enable **Cloud Firestore** > Start in test mode
4. Register your Android app with package name: `com.kigali.kigali_city_directory`
5. Download `google-services.json` and place it in `android/app/`
6. Run FlutterFire CLI to generate `firebase_options.dart`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 3. Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** and **Directions API**
3. Create an API key and restrict it to your app package
4. Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/build.gradle.kts`

### 4. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /listings/{listingId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.createdBy;
    }
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }
  }
}
```

### 5. Run the App
```bash
flutter pub get
flutter run
```

---

## State Management: Provider

- `AuthProvider` wraps `AuthService`, exposes `AuthStatus` enum, `UserModel`, and loading/error states. Listens to `FirebaseAuth.authStateChanges` stream to react to login/logout automatically.
- `ListingProvider` wraps `ListingService` and `ReviewService`, exposes real-time Firestore listing streams, computed filtered listings based on search + category, CRUD operations, and loading/error states.

No Firestore calls exist inside any widget. All database interactions are in `services/` and exposed through `providers/`.

---

## Navigation

Bottom Navigation Bar with 4 tabs:
1. **Directory** - Browse/search all listings with category filters and near-you section
2. **My Listings** - Manage your own listings with inline edit/delete actions
3. **Map View** - All listings on an interactive dark-styled Google Map
4. **Settings** - Profile info + notification preference toggles

---

## UI Theme

Dark navy theme (`#0A1628`) with gold/amber accent (`#F5A623`) matching the Kigali City Directory design specification.
