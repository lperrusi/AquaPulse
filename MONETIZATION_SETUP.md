# Monetization Setup Guide

This guide will help you set up monetization for your hydration tracker app with Google Mobile Ads and in-app purchases.

## 🎯 Monetization Strategy

Your app uses a **freemium model** with:
- **Banner ads** - Non-intrusive, always visible at bottom
- **Interstitial ads** - Shown after water intake (natural break point)
- **Premium subscription** - Ad-free experience + extra features

## 📱 Google Mobile Ads Setup

### 1. Create AdMob Account
1. Go to [AdMob Console](https://admob.google.com/)
2. Create a new account or sign in
3. Add your app to AdMob

### 2. Create Ad Units
Create these ad units in AdMob:

#### Banner Ad Unit
- **Type**: Banner
- **Size**: 320x50 (Standard Banner)
- **Name**: `Banner Ad - Hydration Tracker`

#### Interstitial Ad Unit
- **Type**: Interstitial
- **Name**: `Interstitial Ad - Hydration Tracker`

### 3. Update Ad Unit IDs
Replace the test IDs in `lib/services/ad_service.dart`:

```dart
// Replace these with your real ad unit IDs
static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXXXX/YYYYYYYYYY';
static const String _interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXX/ZZZZZZZZZZ';
```

## 💰 In-App Purchase Setup

### 1. App Store Connect (iOS)
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app
3. Go to **Features** → **In-App Purchases**
4. Create subscription products:

#### Monthly Subscription
- **Product ID**: `premium_monthly`
- **Type**: Auto-Renewable Subscription
- **Price**: $2.99/month (or your preferred price)

#### Yearly Subscription
- **Product ID**: `premium_yearly`
- **Type**: Auto-Renewable Subscription
- **Price**: $19.99/year (or your preferred price)

### 2. Google Play Console (Android)
1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to **Monetize** → **Products** → **Subscriptions**
4. Create the same subscription products with matching IDs

### 3. Update Product IDs (if needed)
If you use different product IDs, update them in `lib/services/premium_service.dart`:

```dart
static const String _monthlySubscriptionId = 'your_monthly_product_id';
static const String _yearlySubscriptionId = 'your_yearly_product_id';
```

## 🚀 Testing

### Test Ads
- The app currently uses **test ad unit IDs**
- Test ads will show during development
- Replace with real IDs before production

### Test Purchases
- Use **sandbox accounts** for testing
- iOS: Create test user in App Store Connect
- Android: Use test accounts in Google Play Console

## 📊 Revenue Optimization Tips

### 1. Ad Placement
- ✅ **Banner ads** at bottom - Non-intrusive
- ✅ **Interstitial ads** after water intake - Natural break
- ❌ Avoid showing ads too frequently
- ❌ Don't show ads during critical user flows

### 2. Premium Features
- ✅ **Ad-free experience** - Main value proposition
- ✅ **Advanced analytics** - Detailed insights
- ✅ **Unlimited reminders** - Remove limits
- ✅ **Premium themes** - Visual customization
- ✅ **Cloud backup** - Data sync across devices

### 3. Pricing Strategy
- **Monthly**: $2.99 - Lower barrier to entry
- **Yearly**: $19.99 - 44% savings, better retention
- **Free trial**: Consider 7-day free trial
- **Promotional pricing**: Launch discounts

## 🔧 Configuration Files

### iOS Configuration
- `ios/Runner/Info.plist` - Add AdMob app ID
- `ios/Runner/GoogleService-Info.plist` - Firebase config

### Android Configuration
- `android/app/src/main/AndroidManifest.xml` - Add AdMob app ID
- `android/app/google-services.json` - Firebase config

## 📈 Analytics & Tracking

### Firebase Analytics
Track these events for optimization:
- `ad_impression` - When ads are shown
- `ad_click` - When ads are clicked
- `premium_upgrade` - When user upgrades
- `premium_cancel` - When user cancels

### Revenue Metrics
Monitor these KPIs:
- **ARPU** (Average Revenue Per User)
- **Conversion rate** (Free to Premium)
- **Churn rate** (Premium cancellations)
- **Ad revenue** vs **Subscription revenue**

## 🛡️ Privacy & Compliance

### GDPR Compliance
- Add privacy policy
- Implement consent management
- Allow users to opt out of ads

### App Store Guidelines
- Follow [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Follow [Google Play Policy](https://play.google.com/about/developer-content-policy/)

## 🚀 Launch Checklist

### Before Launch
- [ ] Replace test ad unit IDs with real ones
- [ ] Set up subscription products in stores
- [ ] Test purchases with sandbox accounts
- [ ] Add privacy policy and terms of service
- [ ] Configure analytics tracking
- [ ] Test ad frequency and placement

### Post-Launch
- [ ] Monitor ad performance
- [ ] Track subscription conversions
- [ ] Optimize pricing based on data
- [ ] A/B test ad placements
- [ ] Gather user feedback

## 💡 Pro Tips

1. **Start with test ads** - Don't rush to production ads
2. **Focus on user experience** - Don't over-monetize
3. **Test different price points** - Find the sweet spot
4. **Offer value** - Premium features should be worth the price
5. **Listen to users** - Adjust based on feedback

## 📞 Support

- [Google Mobile Ads Documentation](https://developers.google.com/admob)
- [In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Google Play Billing](https://developer.android.com/google/play/billing)

---

**Remember**: The goal is to provide value to users while generating revenue. Focus on creating a great user experience first, then optimize monetization based on user behavior and feedback.
