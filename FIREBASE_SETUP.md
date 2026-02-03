# Firebase Setup Guide for Hydration Tracker

This guide will help you set up Firebase for the Hydration Tracker app.

## Prerequisites

1. **Firebase CLI** - Install if you haven't already:
   ```bash
   npm install -g firebase-tools
   ```

2. **FlutterFire CLI** - Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `hydration-tracker-app`
4. Enable Google Analytics (optional but recommended)
5. Click "Create project"

## Step 2: Configure Firebase for Flutter

1. **Login to Firebase CLI**:
   ```bash
   firebase login
   ```

2. **Configure FlutterFire**:
   ```bash
   flutterfire configure --project=hydration-tracker-app
   ```

   This will:
   - Create Firebase apps for each platform (iOS, Android, Web)
   - Generate `firebase_options.dart` with real configuration
   - Update your `pubspec.yaml` with Firebase dependencies

## Step 3: Enable Firebase Services

### Authentication
1. In Firebase Console, go to **Authentication**
2. Click **Get started**
3. Enable **Email/Password** sign-in method
4. (Optional) Enable **Google** sign-in for social login

### Firestore Database
1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location close to your users
5. Click **Done**

### Storage (Optional)
1. In Firebase Console, go to **Storage**
2. Click **Get started**
3. Choose **Start in test mode**
4. Select a location

## Step 4: Security Rules

### Firestore Security Rules
Go to **Firestore Database** > **Rules** and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Friends - users can read/write their own friend relationships
    match /friends/{friendId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         resource.data.friendId == request.auth.uid);
    }
    
    // Friend requests - users can read requests sent to them and create new ones
    match /friend_requests/{requestId} {
      allow read: if request.auth != null && 
        (resource.data.fromUserId == request.auth.uid || 
         resource.data.toUserId == request.auth.uid);
      allow create: if request.auth != null && 
        request.resource.data.fromUserId == request.auth.uid;
      allow update: if request.auth != null && 
        resource.data.toUserId == request.auth.uid;
    }
    
    // Challenges - users can read challenges they participate in
    match /challenges/{challengeId} {
      allow read, write: if request.auth != null;
    }
    
    // Challenge participants - users can read/write their own participation
    match /challenge_participants/{participantId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Leaderboard entries - anyone can read, users can write their own
    match /leaderboard_entries/{entryId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.resource.data.userId == request.auth.uid;
    }
  }
}
```

### Storage Security Rules (if using Storage)
Go to **Storage** > **Rules** and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 5: Update App Configuration

1. **Update firebase_options.dart**:
   The `flutterfire configure` command should have generated the correct configuration. If not, copy the values from Firebase Console.

2. **Update iOS Bundle ID** (if needed):
   - Open `ios/Runner.xcodeproj` in Xcode
   - Change Bundle Identifier to match your Firebase iOS app

3. **Update Android Package Name** (if needed):
   - Open `android/app/build.gradle`
   - Change `applicationId` to match your Firebase Android app

## Step 6: Test Firebase Connection

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

3. **Check Firebase Console**:
   - Go to **Authentication** to see if users can sign up
   - Go to **Firestore Database** to see if data is being created

## Step 7: Production Setup

### Update Security Rules
Before going to production, update Firestore rules to be more restrictive:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Add more specific rules based on your app's needs
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // ... other rules
  }
}
```

### Enable App Check (Recommended)
1. In Firebase Console, go to **App Check**
2. Enable for your platforms
3. Add App Check to your Flutter app

### Set up Monitoring
1. Enable **Crashlytics** for crash reporting
2. Set up **Performance Monitoring**
3. Configure **Analytics** events

## Troubleshooting

### Common Issues

1. **"Firebase not initialized"**:
   - Make sure `firebase_options.dart` is properly generated
   - Check that `Firebase.initializeApp()` is called in `main()`

2. **"Permission denied"**:
   - Check Firestore security rules
   - Verify user is authenticated

3. **"Network error"**:
   - Check internet connection
   - Verify Firebase project is in the correct region

4. **iOS build errors**:
   - Run `cd ios && pod install`
   - Clean and rebuild: `flutter clean && flutter pub get`

### Debug Mode
Enable debug logging:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

## Next Steps

1. **Customize Authentication**: Add social login providers
2. **Set up Cloud Functions**: For complex business logic
3. **Configure Analytics**: Track user behavior
4. **Set up Push Notifications**: For reminders
5. **Add Crashlytics**: For crash reporting

## Support

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/) 