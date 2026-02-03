# Authentication Test Checklist

## ✅ Build Status
- [x] App builds successfully
- [x] No compilation errors
- [x] Firebase initialized correctly
- [x] App running on iPhone 17 Pro simulator

## 🔐 Sign Up (Registration) Tests

### Test 1: Basic Registration
- [ ] Navigate to Sign Up screen
- [ ] Enter valid email (e.g., `test@example.com`)
- [ ] Enter valid password (at least 6 characters)
- [ ] Enter full name
- [ ] Tap "Create Account"
- [ ] **Expected**: Account created successfully, user redirected to onboarding/dashboard
- [ ] **Verify**: User profile saved to Firestore
- [ ] **Verify**: User profile saved to local database

### Test 2: Registration Validation
- [ ] Try to register with invalid email (e.g., `invalid-email`)
- [ ] **Expected**: Error message "Please enter a valid email address"
- [ ] Try to register with short password (less than 6 characters)
- [ ] **Expected**: Error message "Password must be at least 6 characters long"
- [ ] Try to register with empty name
- [ ] **Expected**: Error message "Please enter your name"

### Test 3: Duplicate Email
- [ ] Register with email `test@example.com`
- [ ] Log out
- [ ] Try to register again with same email
- [ ] **Expected**: Error message "An account already exists with this email address. Please sign in instead."

## 🔑 Sign In (Login) Tests

### Test 4: Successful Login
- [ ] Navigate to Login screen
- [ ] Enter registered email
- [ ] Enter correct password
- [ ] Tap "Login"
- [ ] **Expected**: Login successful, redirected to dashboard
- [ ] **Verify**: User profile loaded from Firestore/local database

### Test 5: Login Validation
- [ ] Try to login with invalid email format
- [ ] **Expected**: Error message "Please enter a valid email address"
- [ ] Try to login with empty password
- [ ] **Expected**: Error message "Please enter your password"

### Test 6: Wrong Credentials
- [ ] Try to login with non-existent email
- [ ] **Expected**: Error message "No account found with this email address. Please sign up first."
- [ ] Try to login with correct email but wrong password
- [ ] **Expected**: Error message "Incorrect password. Please try again."

## 🔄 Session Management Tests

### Test 7: Persistent Session
- [ ] Login successfully
- [ ] Close the app completely
- [ ] Reopen the app
- [ ] **Expected**: User remains logged in, goes directly to dashboard
- [ ] **Verify**: No need to login again

### Test 8: Logout
- [ ] While logged in, navigate to Profile tab
- [ ] Tap logout button
- [ ] **Expected**: User logged out, redirected to login screen
- [ ] **Verify**: Cannot access dashboard without logging in again

## 🔒 Password Reset Tests

### Test 9: Forgot Password - Valid Email
- [ ] From login screen, tap "Forgot Password?"
- [ ] Enter registered email address
- [ ] Tap "Send Reset Email"
- [ ] **Expected**: Success message "Password reset email sent! Please check your inbox..."
- [ ] **Verify**: Email sent (check Firebase console or email inbox)

### Test 10: Forgot Password - Invalid Email
- [ ] From forgot password screen, enter invalid email
- [ ] **Expected**: Error message "Please enter a valid email address"
- [ ] Enter non-existent email
- [ ] **Expected**: Appropriate error message from Firebase

## 📱 Navigation Flow Tests

### Test 11: First Time User Flow
- [ ] Fresh install (or clear app data)
- [ ] **Expected**: Introduction screen → Login screen
- [ ] Register new account
- [ ] **Expected**: Onboarding screen → Dashboard

### Test 12: Returning User Flow
- [ ] User already registered and logged in
- [ ] Close and reopen app
- [ ] **Expected**: Direct to dashboard (no login required)

### Test 13: Sign Up from Login
- [ ] From login screen, tap "Sign Up"
- [ ] **Expected**: Navigate to registration screen
- [ ] Complete registration
- [ ] **Expected**: Redirected to onboarding/dashboard

### Test 14: Back Navigation
- [ ] From registration screen, tap back button
- [ ] **Expected**: Return to login screen
- [ ] From forgot password screen, tap "Back to Login"
- [ ] **Expected**: Return to login screen

## 🛡️ Security Tests

### Test 15: Password Visibility Toggle
- [ ] On login screen, enter password
- [ ] Tap eye icon
- [ ] **Expected**: Password becomes visible
- [ ] Tap again
- [ ] **Expected**: Password becomes hidden
- [ ] Repeat on registration screen

### Test 16: Error Handling
- [ ] Test with network disconnected
- [ ] Try to login
- [ ] **Expected**: Appropriate network error message
- [ ] Reconnect network
- [ ] **Expected**: Login works normally

## 🔍 Data Persistence Tests

### Test 17: User Profile Sync
- [ ] Register new user
- [ ] Complete onboarding
- [ ] Update profile (name, weight, activity level)
- [ ] Log out and log back in
- [ ] **Expected**: Profile changes persist
- [ ] **Verify**: Data in Firestore matches local database

### Test 18: Multiple Device Support
- [ ] Register on device 1
- [ ] Login on device 2 with same credentials
- [ ] **Expected**: Same user profile loaded
- [ ] **Verify**: Data syncs from Firestore

## 📊 Firebase Integration Verification

### Test 19: Firebase Console Check
- [ ] After registration, check Firebase Console
- [ ] **Verify**: User appears in Authentication > Users
- [ ] **Verify**: User document created in Firestore > users collection
- [ ] **Verify**: User ID matches Firebase UID

### Test 20: Analytics Events
- [ ] Check Firebase Analytics
- [ ] **Verify**: Login events logged
- [ ] **Verify**: Sign up events logged
- [ ] **Verify**: Password reset events logged

## 🎯 Edge Cases

### Test 21: Rapid Taps
- [ ] Rapidly tap login button multiple times
- [ ] **Expected**: Only one login attempt processes
- [ ] **Verify**: No duplicate requests

### Test 22: Special Characters
- [ ] Register with email containing special characters
- [ ] **Expected**: Handled correctly
- [ ] Register with password containing special characters
- [ ] **Expected**: Accepted if valid

### Test 23: Long Inputs
- [ ] Try very long email address
- [ ] **Expected**: Validation works correctly
- [ ] Try very long password
- [ ] **Expected**: Accepted (within reasonable limits)

---

## 🐛 Known Issues to Watch For

1. **Session Persistence**: Ensure user stays logged in after app restart
2. **Error Messages**: All error messages should be user-friendly
3. **Loading States**: Loading indicators should show during auth operations
4. **Network Errors**: Graceful handling of network failures
5. **Firebase Errors**: Proper translation of Firebase error codes to user messages

---

## 📝 Notes

- All authentication now uses Firebase Auth (production-ready)
- User profiles are synced between Firestore and local SQLite database
- Session management is automatic via Firebase Auth state listener
- Password reset emails are sent via Firebase

---

## ✅ Quick Test Commands

To test on simulator:
```bash
flutter run -d 318AABB4-CC3E-47CB-A8E2-091957B00DC3
```

To check Firebase Console:
- Go to https://console.firebase.google.com
- Select your project
- Check Authentication > Users
- Check Firestore Database > users collection
