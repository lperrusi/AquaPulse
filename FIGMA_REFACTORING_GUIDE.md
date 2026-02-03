# Figma Design Refactoring Guide

This document tracks the refactoring of the Flutter app to match the Figma designs from the GitHub repository: https://github.com/lperrusi/Aquapulsewatertrackerapp.git

## Design System Updates

### Colors (Already Match)
- Primary Blue: `#2196F3` ✅
- Secondary Blue: `#4FC3F7` ✅
- Background: `#FAFCFF` ✅
- All other colors match ✅

### Key Design Patterns from Figma

1. **Gradients**: Always use `linear-gradient(135deg, #4FC3F7 0%, #2196F3 100%)`
2. **Border Radius**: 
   - Small: 12px (rounded-xl)
   - Medium: 16px (rounded-2xl)
   - Large: 20px (rounded-[20px])
   - XLarge: 24px (rounded-3xl)
   - XXLarge: 28px (rounded-[28px])
   - XXXLarge: 30px (rounded-[30px])
3. **Shadows**:
   - Dialog: `0 10px 30px rgba(0, 0, 0, 0.1)`
   - Button: `0 4px 12px rgba(33, 150, 243, 0.3)`
   - Card: `0 2px 8px rgba(33, 150, 243, 0.08)`
   - Progress Circle: `0 20px 40px rgba(33, 150, 243, 0.15)`
   - Bottom Nav: `0 -5px 10px rgba(0, 0, 0, 0.05)`
4. **Spacing**: Use 4px, 8px, 12px, 16px, 20px, 24px, 32px grid
5. **Typography**: Inter font, specific sizes match Figma

## Screens to Refactor

### ✅ Completed
1. **SplashScreen** - Updated to match Figma exactly
   - Animated logo with scale and opacity
   - Gradient background
   - Centered layout
   - Loading indicator at bottom

### 🔄 In Progress
2. **IntroductionScreen** - Needs refactoring
3. **OnboardingScreen** - Needs refactoring
4. **LoginScreen** - Needs refactoring
5. **DashboardScreen** - Needs refactoring
6. **BottomNav** - Needs refactoring
7. **AddWaterDialog** - Needs refactoring
8. **ProgressCircle** - Needs refactoring

## Component-Specific Changes

### ProgressCircle
- Size: 200x200px
- Stroke width: 12px
- Background circle: `#E8F4FD`
- Progress gradient: `#4FC3F7` to `#2196F3`
- Excess progress: `#FFD700` (golden)
- Shadow: `0 20px 40px rgba(33, 150, 243, 0.15)`
- Center text: 32px bold for amount, 14px for goal

### BottomNav
- White background
- Rounded top corners: 20px
- Shadow: `0 -5px 10px rgba(0, 0, 0, 0.05)`
- Center FAB: 60x60px, gradient, shadow `0 6px 12px rgba(33, 150, 243, 0.3)`
- Active tab: Gradient background, white icon
- Inactive tab: Transparent, gray icon (#7F8C8D)

### AddWaterDialog
- Border radius: 28px
- Background: `#FAFCFF`
- Header: Gradient circle icon (48x48px)
- Quick add grid: 3 columns
- Quick add buttons: Light blue background (#E8F4FD), blue border (#B8D4F0)
- Custom amount input: Light blue background (#F5F9FF)

### WeatherCard
- Gradient background: `#4FC3F7` to `#2196F3`
- Border radius: 16px
- Shadow: `0 4px 16px rgba(33, 150, 243, 0.3)`
- White text
- Icons: MapPin, Thermometer, Droplets

### TodayIntakeList
- White background
- Border radius: 16px
- Shadow: `0 2px 8px rgba(33, 150, 243, 0.08)`
- Each entry: Left border 4px blue, light blue circle icon
- Edit button: Small, blue icon

## Implementation Notes

1. All screens should use the updated `NeumorphicStyle` utility
2. Use `primaryGradient()` for all gradient buttons and elements
3. Use standard border radius values from `NeumorphicStyle`
4. Use standard shadow helpers from `NeumorphicStyle`
5. Match spacing exactly (4px grid system)
6. Use Inter font consistently (already configured in main.dart)

## Next Steps

1. Continue refactoring IntroductionScreen
2. Update OnboardingScreen
3. Update LoginScreen
4. Update DashboardScreen components
5. Update BottomNav
6. Update AddWaterDialog
7. Create/update ProgressCircle widget
8. Test all screens for visual consistency
