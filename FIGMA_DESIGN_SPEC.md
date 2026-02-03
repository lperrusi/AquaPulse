# AquaPulse - Complete Design Specification for Figma

## App Overview
**AquaPulse** is a hydration tracking app with a modern, neumorphic design style. The app uses a blue color scheme with soft shadows and rounded corners throughout.

---

## Design System

### Color Palette
- **Primary Blue**: `#2196F3`
- **Secondary Blue**: `#4FC3F7`
- **Light Blue**: `#E8F4FD`
- **Very Light Blue**: `#F0F8FF`
- **Background Blue**: `#FAFCFF`
- **Surface Blue**: `#F5F9FF`
- **Dark Text**: `#2C3E50`
- **Light Text**: `#7F8C8D`
- **Soft Border**: `#E1EFF9`
- **Medium Border**: `#B8D4F0`
- **Golden (for exceeding goal)**: `#FFD700`

### Typography
- **Font Family**: Inter (Google Fonts)
- **Display Large**: 32px, Weight 600
- **Display Medium**: 28px, Weight 600
- **Display Small**: 24px, Weight 600
- **Headline Large**: 22px, Weight 600
- **Headline Medium**: 20px, Weight 600
- **Headline Small**: 18px, Weight 600
- **Title Large**: 16px, Weight 600
- **Title Medium**: 14px, Weight 500
- **Title Small**: 12px, Weight 500
- **Body Large**: 16px, Weight 400
- **Body Medium**: 14px, Weight 400
- **Body Small**: 12px, Weight 400

### Design Principles
- **Neumorphic Style**: Soft shadows, subtle depth, no harsh edges
- **Border Radius**: 12px (small), 16px (medium), 20px (large), 28px (dialogs)
- **Shadows**: Soft, subtle shadows with low opacity (0.05-0.2)
- **Gradients**: Linear gradients from `#4FC3F7` to `#2196F3`
- **Spacing**: 8px, 12px, 16px, 20px, 24px, 32px, 40px

---

## Screens

### 1. Splash Screen
**Purpose**: Initial loading screen with app branding

**Elements**:
- Full-screen background image: `AquaPulse_Splash_Screen_Background.png`
- Fallback gradient: White → `#E3F2FD` → `#BBDEFB`
- Bottom overlay with:
  - Tagline: "Stay Hydrated, Stay Healthy" (18px, Weight 500, Primary Blue)
  - Loading indicator (40x40px circular progress, Primary Blue with 0.7 opacity)
- Fade-in animation for text
- Auto-navigates after 3 seconds

**Layout**:
- Full screen, no safe area padding
- Content positioned at bottom with 60px bottom padding

---

### 2. Introduction Screen (Onboarding)
**Purpose**: 4-page introduction to app features

**Background**: Full-screen wave background image (`AquaPulse_Wave_Background_Low - Editado.png`)

**Page 1: Welcome**
- Large logo: `AquaPulse_Splash_Screen-4 - Editado.png` (200x200px)
- Title: "AquaPulse" (42px, Weight 900, Dark Text)
- Subtitle: "Stay Hydrated,\nStay Healthy" (24px, Weight 700, Dark Text)
- Description: "Track your daily water intake\nand develop healthy\nhydration habits" (18px, Weight 400, Dark Text)

**Page 2: Track Your Hydration**
- Demo interface card (120x120px, white background, rounded 30px):
  - Circular progress indicator (80x80px, 44% progress, blue)
  - Two buttons below: Glass icon (50x30px) and Add icon (50x30px)
- Title: "Track Your Hydration" (42px, Weight 900)
- Subtitle: "Monitor your daily water intake with our intuitive tracking system" (24px, Weight 700)

**Page 3: Never Forget to Hydrate**
- Notification demo card (200px width, white, rounded 20px):
  - Bell icon (30x30px, blue background)
  - Text: "Time to\ndrink water" (14px, Weight 600)
- Four reminder options in a row:
  - Morning (sun icon), Lunch (restaurant icon), Evening (moon icon), Hourly (clock icon)
  - Each: 35x35px circle with blue border, icon, label below
- Title: "Never Forget\nto Hydrate" (42px, Weight 900)
- Subtitle: "Set personalized reminders to stay hydrated throughout your day" (24px, Weight 700)

**Page 4: Track Your Progress**
- Stats preview card (120x120px, white, rounded 20px):
  - Header: "Weekly" (12px, bold, white text on blue background)
  - Progress text: "1400 / 2000 ml" (10px, Weight 600, blue)
  - Bar chart with 6 bars (M, T, W, T, F, S) with varying heights
- Title: "Track Your Progress" (42px, Weight 900)
- Subtitle: "View your hydration history and achievements to stay motivated" (24px, Weight 700)

**Navigation**:
- Skip button (top right, white background with 0.9 opacity, rounded 20px)
- Page indicators (10px circles, active: blue, inactive: white with 0.6 opacity)
- Bottom navigation:
  - Back button (when not on first page): White background, blue text
  - Next/Get Started button: Blue gradient, white text, rounded 30px

---

### 3. Onboarding Screen
**Purpose**: Collect user profile information

**Header**:
- Logo: 32x32px blue gradient square with water drop icon
- App name: "AquaPulse" (24px, bold)
- Progress indicator: 3 bars (32px, 16px, 16px) - first is gradient, others are gray
- Title: "TELL US ABOUT YOURSELF" (28px, bold, centered)

**Form Sections**:

**Age & Gender**:
- Label: "Age" (16px, Weight 600)
- Age input field (white background, rounded 12px)
- Two gender buttons side by side: "Male" and "Female"
  - Selected: Blue gradient background, white text, rounded 25px
  - Unselected: White background, blue text, blue border, rounded 25px

**Weight**:
- Label: "Weight" (16px, Weight 600)
- Weight input field (white background, rounded 12px)
- Unit selector button: "kg" or "lbs" (white background, blue text, rounded 12px)

**Activity Level**:
- Label: "Activity level" (16px, Weight 600)
- Dropdown button showing:
  - Icon (varies by level)
  - Title (16px, Weight 600)
  - Description (14px, Weight 400, light text)
  - Down arrow icon
- Modal bottom sheet with 5 options:
  - Sedentary (airline seat icon)
  - Lightly Active (walk icon)
  - Moderately Active (run icon)
  - Very Active (fitness center icon)
  - Extremely Active (gymnastics icon)
  - Each option: White background, blue border, rounded 12px
  - Selected: Blue gradient, white text, checkmark icon

**Continue Button**:
- Full width, blue gradient, white text, rounded 16px
- Shadow: Blue with 0.3 opacity, blur 12px, offset (0, 6)

**Background**: Light blue (`#FAFCFF`)

---

### 4. Login Screen
**Purpose**: User authentication

**Header**:
- App icon: 80x80px blue rounded square (20px radius) with water drop icon
- App title: "AquaPulse" (20px, bold, blue)
- Subtitle: "Stay hydrated, stay healthy" (16px, gray)

**Form**:
- Email field:
  - Label: "Email"
  - Hint: "Enter your email"
  - Prefix icon: Email icon
  - White/light gray background, rounded 12px
- Password field:
  - Label: "Password"
  - Hint: "Enter your password"
  - Prefix icon: Lock icon
  - Suffix icon: Eye icon (toggle visibility)
  - White/light gray background, rounded 12px
- Error message (if any):
  - Red background container
  - Error icon + message text

**Actions**:
- Login button: Primary blue, white text, rounded 12px, full width
- "Forgot Password?" link: Blue text, text button style
- Register link at bottom: "Don't have an account? Sign Up"

**Background**: White/light blue

---

### 5. Register Screen
**Purpose**: Create new user account

**Header**:
- App icon: 60x60px blue rounded square (15px radius)
- Title: "Join AquaPulse" (18px, bold)
- Subtitle: "Create your account to start tracking your hydration" (14px, gray, centered)

**Registration Form**:
- Name field: Full name input
- Email field: Email input
- Password field: Password input with visibility toggle
- Confirm Password field: Password confirmation with visibility toggle
- All fields: White/light gray background, rounded 12px, prefix icons

**Profile Setup (Optional)**:
- Section title: "Profile Setup (Optional)" (16px, bold)
- Age field: Number input
- Weight field: Number input (kg)
- Gender dropdown: Male/Female/Other
- Activity Level dropdown: 5 options

**Actions**:
- Create Account button: Primary blue, white text, rounded 12px
- Login link: "Already have an account? Sign In"

**Background**: White/light blue

---

### 6. Dashboard Screen (Main Home)
**Purpose**: Main screen showing hydration progress and quick actions

**Header**:
- Logo: 48x48px blue gradient square (12px radius) with water drop icon
- App name: "AquaPulse" (24px, Weight 700)

**Banner Ad**: Top banner ad space

**Main Progress Indicator**:
- Large circular progress (200x200px):
  - Background: Light blue circle
  - Progress ring: Blue (12px stroke width)
  - Excess progress (when over goal): Golden ring
  - Center content:
    - Current intake: "XXX ml" (32px, Weight 700)
    - Goal: "Goal: XXX ml" (14px, Weight 500, gray)
    - Excess (if any): "+XXX ml" (12px, Weight 600, golden)
- Shadow: Blue with 0.15 opacity, blur 20px
- Celebration overlay (when goal reached):
  - Confetti particles (12 particles in circle)
  - Celebration card: Blue gradient, white text
  - Text: "Goal Achieved! 🎉 Great job! 🎉"

**Recommendation Section**:
- Blue gradient card (rounded 16px):
  - Header: Location icon + "Weather Recommendation" + location name + refresh button
  - Content: Temperature, humidity, hydration tip, weather description
  - White text on blue gradient

**Today's Intake Section**:
- Section title: "Today's Intake" (18px, Weight 600)
- White card (rounded 16px) with list:
  - Each intake: Time (HH:MM) + Amount (ml) + Edit button
  - Edit button: Small blue icon button
  - Empty state: "No intakes recorded today" (centered, gray)

**Bottom Navigation Bar**:
- White background, rounded 20px, shadow
- 5 items:
  1. Home icon (selected: blue gradient, unselected: gray)
  2. Reminders icon
  3. Center FAB: Blue gradient circle (60x60px) with water drop icon
  4. Stats icon
  5. Profile icon
- Selected items have blue gradient background

**Add Water Dialog**:
- Modal dialog (rounded 28px, white/light blue background):
  - Header: Blue gradient circle icon (water drop) + "Add Water Intake" title + subtitle
  - Quick Add section: Horizontal scrollable row of cup size buttons
  - Custom Amount button: Blue gradient, white text
  - Cancel button: Outlined, gray text

**Custom Amount Dialog**:
- Modal dialog (rounded 28px):
  - Header: Blue gradient circle icon + "Custom Amount" title
  - Input field: Number input with "ml" suffix
  - Buttons: Cancel (outlined) + Add Water (blue gradient)

**Edit Intake Dialog**:
- Modal dialog (rounded 24px):
  - Title: "Edit Water Intake"
  - Time display
  - Amount input field
  - Buttons: Cancel + Update (blue)

**Background**: Light blue gradient

---

### 7. Reminders Screen
**Purpose**: Manage hydration reminders

**Header**:
- Title: "Reminders" (20px, Weight 600, centered)
- Transparent app bar

**Interval Reminders Section**:
- Card with:
  - Title: "Interval Reminders"
  - Toggle switch
  - Settings: Start time, End time, Interval (minutes)
  - Time pickers and interval selector

**Action Buttons Section**:
- Quick Add buttons:
  - Morning (8:00 AM, sun icon)
  - Lunch (12:00 PM, restaurant icon)
  - Evening (moon icon)
- Each button: White/light blue card with icon, label, and time

**Create Custom Reminder Button**:
- Blue gradient button, white text, rounded 16px

**Reminders List**:
- Each reminder card:
  - Title and message
  - Time and days
  - Toggle switch (enabled/disabled)
  - Edit and Delete buttons
- Empty state: "No reminders yet" with illustration

**Add/Edit Reminder Dialog**:
- Modal bottom sheet (rounded 24px):
  - Title input
  - Message input
  - Time picker
  - Day selector (7 days, checkboxes)
  - Interval settings (if interval reminder)
  - Save/Cancel buttons

**Background**: Light blue

---

### 8. Stats Screen
**Purpose**: View hydration statistics and achievements

**Tabs**: 
- Weekly Stats
- Achievements

**Weekly Stats Tab**:
- Week selector: Dropdown showing "This Week", "Last Week", "2 Weeks Ago"
- Summary cards:
  - Total intake (large number, blue)
  - Average daily (number, gray)
  - Goal completion % (circular progress)
- Bar chart: 7 bars (one per day) with labels (Mon-Sun)
- Line chart: Daily intake trend
- Daily breakdown list:
  - Each day: Date, intake amount, goal status, progress bar

**Achievements Tab**:
- Achievement summary card:
  - Total unlocked: "X / Y Achievements"
  - Progress bar
- Achievement cards (grid or list):
  - Icon (varies by achievement type)
  - Title and description
  - Progress indicator (if locked)
  - Unlocked badge (if unlocked)
  - Share button

**Achievement Types**:
- Streak achievements (fire icon)
- Goal achievements (target icon)
- Milestone achievements (trophy icon)
- Social achievements (people icon)
- Special achievements (star icon)

**Background**: Light blue

---

### 9. Profile Screen
**Purpose**: View and edit user profile

**Header**:
- Title: "Profile" (28px, bold)
- Logout button: Gray rounded button with logout icon

**Personal Information Section**:
- Name input field
- Email display (read-only)
- Age input field
- Weight input field with unit selector (kg/lbs)
- Gender selector: Male/Female buttons

**Activity Level Section**:
- Dropdown showing current activity level
- Same style as onboarding screen

**Hydration Goal Section**:
- Current goal display: "XXX ml/day"
- Adjust goal button or slider

**Statistics Cards**:
- Total water consumed (large number)
- Current streak (fire icon + days)
- Average daily intake
- Best day

**Update Button**:
- Blue gradient, white text, rounded 18px, full width
- Shadow: Blue with 0.3 opacity

**Background**: Light blue

---

### 10. Social Screen
**Purpose**: Friends, challenges, and leaderboards

**Tabs**:
- Friends
- Challenges
- Leaderboards

**Friends Tab**:
- Friend requests banner (if any): Blue tinted card with "X pending requests"
- Friends list:
  - Each friend card:
    - Avatar/icon
    - Name
    - Today's intake
    - Status indicator
    - Action buttons (message, remove)
- Empty state: "No friends yet" with illustration
- Add friend button: Blue gradient FAB

**Challenges Tab**:
- Active challenges list:
  - Challenge card:
    - Title and description
    - Participants (avatars)
    - Progress bars
    - Time remaining
    - Join/Accept button
- Past challenges section
- Create challenge button: Blue gradient FAB

**Leaderboards Tab**:
- Time period selector: Today, Week, Month, All Time
- Rankings list:
  - Position number
  - Avatar
  - Name
  - Score/intake
  - Badge/medal (top 3)
- Your position highlighted

**Background**: Light blue

---

### 11. Achievements Screen
**Purpose**: View all achievements

**Header**:
- Title: "Achievements"
- Share button (top right)

**Achievement Summary**:
- Large card showing:
  - "X / Y Achievements Unlocked"
  - Progress bar or circular progress
  - Percentage

**Unlocked Achievements Section**:
- Title: "Unlocked Achievements"
- Grid or list of achievement cards:
  - Large icon (colored)
  - Title and description
  - Unlocked date
  - Share button

**Locked Achievements Section**:
- Title: "Locked Achievements"
- Grid or list of achievement cards:
  - Grayed out icon
  - Title and description
  - Progress indicator (e.g., "5/7 days")
  - Requirement text

**Achievement Card Design**:
- White/light blue background
- Rounded 16px
- Icon (64x64px)
- Title (16px, bold)
- Description (14px, gray)
- Progress bar (if locked)
- Shadow: Subtle

**Background**: Light blue

---

### 12. Forgot Password Screen
**Purpose**: Request password reset

**Header**:
- Icon: 80x80px container with lock reset icon
- Title: "Reset Your Password" (18px, bold)
- Description: Instructions text (14px, gray, centered)

**Form**:
- Email input field (same style as login)
- Error message (if any): Red container with error icon

**Actions**:
- Send Reset Email button: Primary blue, white text
- Back to Login link: Blue text button

**Success State**:
- Success icon: Check circle (48px, blue)
- Title: "Email Sent!" (20px, bold, blue)
- Message: Confirmation text
- Back to Login button: Primary blue

**Background**: White/light blue

---

### 13. Weather Settings Screen
**Purpose**: Configure weather-related settings

**Header**:
- Title: "Weather Settings" (20px, Weight 600, centered)

**Current Weather Status Card**:
- Location name
- Temperature and humidity
- Last update time
- Status badge (Active/Inactive)

**Update Frequency Card**:
- Title: "Update Frequency"
- Options: 15 min, 30 min, 1 hour, 2 hours, Manual
- Radio buttons or segmented control

**Background Updates Card**:
- Toggle switch
- Description text

**Auto Refresh Card**:
- Toggle switch
- Description text

**Weather Information Card**:
- Help text about weather features
- Link to enable location permissions

**Background**: Light blue

---

## Reusable Components/Widgets

### 1. Water Intake Buttons
- Horizontal scrollable row of cup size buttons
- Each button (90x95px):
  - Blue gradient circle icon (water drop)
  - Amount in ml (large, bold)
  - "ml" label (small)
  - Cup name (if any, small)
  - Blue tinted background with border
- Edit button (top right): Blue icon button
- Empty state: Icon + "No quick add amounts" message

### 2. Hydration Progress Card
- Circular progress indicator
- Current intake display
- Goal display
- Percentage or remaining amount

### 3. Streak Card
- Fire icon
- Streak number (large, bold)
- "Day Streak" label
- Background: Orange/red gradient or blue

### 4. Recent Intakes List
- List of intake entries
- Each entry: Time + Amount + Edit button
- Empty state message

### 5. Weather Card
- Location icon and name
- Temperature and humidity
- Weather icon
- Hydration recommendation text
- Refresh button

### 6. Smart Notification Suggestions
- Card showing suggested reminder times
- Based on user patterns
- Quick add buttons for suggestions

### 7. Water Wave Progress
- Animated wave effect showing progress
- Used in some progress indicators

---

## Dialog/Modal Patterns

### Standard Dialog
- Background: White/light blue (`#FAFCFF`)
- Border radius: 24px or 28px
- Padding: 24px
- Shadow: Black with 0.1 opacity, blur 20px, offset (0, 10)
- Header: Icon + Title + Subtitle (optional)
- Content: Form fields or information
- Actions: Buttons at bottom (Cancel + Primary action)

### Bottom Sheet
- Background: White/light blue
- Border radius: 24px (top corners)
- Handle bar: 40px width, 4px height, gray, rounded 2px
- Padding: 20px
- Scrollable content
- Actions at bottom

### Input Fields
- Background: White or light blue (`#F5F9FF`)
- Border: Light blue (`#E1EFF9`)
- Border radius: 12px
- Focused border: Blue (`#2196F3`), 2px width
- Padding: 16px horizontal, 12px vertical
- Label: Above or floating
- Prefix/Suffix icons: 20-24px

### Buttons

**Primary Button**:
- Background: Blue gradient (`#4FC3F7` → `#2196F3`)
- Text: White, 16-18px, Weight 600-700
- Border radius: 16px
- Shadow: Blue with 0.3 opacity, blur 12px, offset (0, 4)
- Padding: 16-18px vertical

**Secondary Button**:
- Background: White or transparent
- Text: Blue, 16px, Weight 600
- Border: Blue, 1.5px
- Border radius: 16px

**Text Button**:
- Background: Transparent
- Text: Blue, 16px, Weight 600
- No border

**Icon Button**:
- Circular or rounded square
- Icon: 20-24px
- Background: Blue gradient or white with blue border

---

## Navigation Patterns

### Bottom Navigation
- White background
- Rounded 20px (top corners)
- Shadow: Black with 0.05 opacity, blur 10px, offset (0, -5)
- 5 items: Home, Reminders, Add (center FAB), Stats, Profile
- Selected: Blue gradient background, white icon
- Unselected: Transparent background, gray icon
- Center FAB: 60x60px blue gradient circle with water drop icon

### App Bar
- Transparent or white background
- Title: 20-28px, Weight 600, centered or left-aligned
- Actions: Icon buttons on right
- No elevation (elevation: 0)

---

## Animation & Interactions

### Progress Animation
- Smooth spring-like animation when progress updates
- Duration: 1200ms
- Curve: easeOutBack

### Celebration Animation
- Confetti particles (12 particles) expanding in circle
- Celebration card scales in with elastic curve
- Duration: 2000ms
- Auto-dismisses after 2 seconds

### Page Transitions
- Slide + Fade transition
- Duration: 800ms
- Curve: easeInOut

### Button Press
- Haptic feedback on water intake buttons
- Scale animation (optional)

---

## Empty States

All empty states follow this pattern:
- Large icon (48-64px, gray)
- Title text (16-18px, bold)
- Description text (14px, gray, centered)
- Optional action button

Examples:
- "No intakes recorded today"
- "No reminders yet"
- "No friends yet"
- "No achievements unlocked"

---

## Loading States

- Circular progress indicator
- Blue color (`#2196F3`)
- Size: 24-40px
- Optional: Loading text below

---

## Error States

- Error icon (64px, red or blue)
- Error title (18px, bold)
- Error message (14px, gray, centered)
- Optional: Retry button

---

## Assets Needed

### Images
- `AquaPulse_Splash_Screen_Background.png` (full screen)
- `AquaPulse_Wave_Background_Low - Editado.png` (full screen)
- `AquaPulse_Splash_Screen-4 - Editado.png` (200x200px logo)
- App icon variations (all sizes for iOS)

### Icons
- Water drop icon (primary)
- Notification/bell icon
- Calendar icon
- Chart/statistics icon
- Profile/person icon
- Settings icon
- Location icon
- Weather icons (sun, cloud, etc.)
- Activity level icons (walk, run, fitness, etc.)
- Achievement icons (fire, trophy, star, etc.)

---

## Notes for Designer

1. **Consistency**: All screens should maintain the neumorphic style with soft shadows and rounded corners
2. **Color Usage**: Blue gradients are used for primary actions and highlights. Use sparingly for emphasis
3. **Spacing**: Maintain consistent spacing using the 8px grid system
4. **Typography**: Inter font family throughout, maintain hierarchy with font weights
5. **Accessibility**: Ensure sufficient contrast ratios (WCAG AA minimum)
6. **Responsiveness**: Design for iPhone sizes (consider safe areas)
7. **Dark Mode**: Currently not implemented, but consider for future
8. **Animations**: Keep animations subtle and purposeful
9. **Empty States**: Always provide helpful guidance, not just "empty"
10. **Loading States**: Show progress indicators for any async operations

---

## Screen Flow

1. Splash → Introduction (if first time) → Onboarding → Dashboard
2. Splash → Login/Register → Dashboard
3. Dashboard ↔ Reminders ↔ Stats ↔ Profile ↔ Social
4. Dashboard → Add Water Dialog → Custom Amount Dialog
5. Profile → Edit Profile → Update
6. Reminders → Add/Edit Reminder Dialog
7. Social → Add Friend → Friend Requests
8. Stats → Achievement Details
9. Weather Settings → Enable Location

---

## Additional Features to Design

- **Banner Ads**: Standard mobile banner ad format (320x50 or similar)
- **Interstitial Ads**: Full-screen ad format (shown after water intake)
- **Notification Cards**: In-app notification preview cards
- **Achievement Unlock Animation**: Special animation when achievement is unlocked
- **Streak Celebration**: Special UI when streak milestones are reached
- **Challenge Invitation Cards**: Cards for accepting/declining challenges
- **Friend Request Cards**: Cards for accepting/declining friend requests

---

This specification covers all screens and design elements in the AquaPulse app. Use this as a reference when creating the Figma designs.
