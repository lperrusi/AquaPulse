# Firebase Services Setup Instructions

Follow these steps to enable Firebase services for your hydration tracker app.

## **Step 1: Enable Authentication**

1. **Go to Firebase Console**: https://console.firebase.google.com/project/hydration-tracker-app-2024/authentication
2. **Click "Get started"** if not already enabled
3. **Enable Email/Password**:
   - Click on "Email/Password" in the Sign-in providers list
   - Toggle the "Enable" switch to ON
   - Click "Save"
4. **Optional: Enable Google Sign-in**:
   - Click on "Google" in the Sign-in providers list
   - Toggle the "Enable" switch to ON
   - Add your support email
   - Click "Save"

## **Step 2: Enable Firestore Database**

1. **Go to Firestore**: https://console.firebase.google.com/project/hydration-tracker-app-2024/firestore
2. **Click "Create database"** if not already created
3. **Choose security mode**:
   - Select **"Start in test mode"** (for development)
   - Click "Next"
4. **Choose location**:
   - Select a location close to your users (e.g., "us-central1")
   - Click "Done"

## **Step 3: Set Firestore Security Rules**

1. **Go to Firestore Rules**: https://console.firebase.google.com/project/hydration-tracker-app-2024/firestore/rules
2. **Replace the rules** with the content from `firestore.rules` file
3. **Click "Publish"**

## **Step 4: Enable Analytics (Optional)**

1. **Go to Analytics**: https://console.firebase.google.com/project/hydration-tracker-app-2024/analytics
2. **Click "Get started"** if not already enabled
3. **Follow the setup wizard** to configure analytics

## **Step 5: Test the App**

1. **Run the app**:
   ```bash
   flutter run --debug
   ```

2. **Check the logs** - you should see:
   - No more "Failed host lookup" errors
   - Firebase connection successful
   - Real-time data updates

## **Step 6: Add Sample Data (Optional)**

To test the social features with sample data:

1. **Get Service Account Key**:
   - Go to Project Settings: https://console.firebase.google.com/project/hydration-tracker-app-2024/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Save the JSON file as `serviceAccountKey.json` in the project root

2. **Install Node.js dependencies**:
   ```bash
   cd scripts
   npm install firebase-admin
   ```

3. **Run the sample data script**:
   ```bash
   node add_sample_data.js
   ```

## **Expected Results**

After setup, your app should:

✅ **Connect to Firebase** instead of HTTP API
✅ **Show real-time data** in social features
✅ **Allow user authentication** (login/signup)
✅ **Display leaderboards** with sample data
✅ **Show friend relationships** and challenges

## **Troubleshooting**

### **Common Issues:**

1. **"Permission denied" errors**:
   - Check Firestore security rules
   - Ensure rules are published

2. **"Firebase not initialized"**:
   - Verify `firebase_options.dart` is correct
   - Check that `Firebase.initializeApp()` is called

3. **"Network error"**:
   - Check internet connection
   - Verify Firebase project region

4. **"Authentication failed"**:
   - Ensure Authentication is enabled in Firebase Console
   - Check that Email/Password provider is enabled

### **Debug Mode:**

Enable debug logging in `main.dart`:
```dart
if (kDebugMode) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
```

## **Next Steps**

1. **Test Authentication**: Try creating a user account
2. **Test Social Features**: Add friends, create challenges
3. **Test Real-time Updates**: See data update instantly
4. **Add More Features**: Implement additional Firebase features

## **Production Setup**

Before going to production:

1. **Update Security Rules**: Make them more restrictive
2. **Enable App Check**: For additional security
3. **Set up Monitoring**: Crashlytics and Performance
4. **Configure Analytics**: Track user behavior
5. **Set up Push Notifications**: For reminders

## **Support**

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/) 