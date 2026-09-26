# Changelog

All notable changes to the ConvoLens project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.1] - 2026-09-26

### Changed
- **Branding & Display Name Consistency**:
  - Updated all onboarding screens and system descriptions to the official app display name **"Point"**.
  - Synchronized `MaterialApp.title` and permission troubleshooting guides to reflect "Point" branding.
- **App Capabilities & Features Catalog Expanded**:
  - Completely updated `AppFeaturesScreen` (unlocked via the 8-tap logo easter egg in Settings) with in-depth cards for:
    - Contact Quick Swipe Actions (Call & SMS)
    - Callback Latency & Responsiveness Engine (24h follow-ups, return rate %, initiation balance split, and Best Time to Call)
    - Precision Date Jumper & In-Memory Filter Chips (Today shortcut, live counters)
    - Permanent Glass Alphabet Scrubber & Real-Time Duplicate Detection
    - Actionable Notifications & Deep Linking
    - Multi-Step Onboarding & Permissions Hub
    - Sub-Pixel Hero Alignment & Fluid Transitions

---

## [1.3.0] - 2026-09-26

### Added
- **Multi-Step Onboarding & Permissions Walkthrough**:
  - 3-step onboarding flow for first-time launch explaining app capabilities, timeline scrubbing, callback analytics, and privacy guarantees.
  - Interactive permissions checklist requesting **Call Logs & Phone State**, **Device Contacts**, **Notifications & Alerts**, **Microphone / Voice Notes**, and **Exact Alarms**.
  - One-tap "Grant All Required" action with real-time permission status updates and emerald green badges.
  - Persistent state in Drift database (`hasCompletedOnboarding`) and "Welcome Guide & Setup" tile under Settings ➔ Permissions & Security to revisit anytime.

### Changed
- **Sub-Pixel Coordinate Alignment for Hero Photo Banners**:
  - Aligned global screen coordinates (top offset `padding.top + kToolbarHeight + 16.0`, horizontal margin `16.0`, width `width - 32`, and height `(screenHeight * 0.32).clamp(220, 280)`) between `ContactDetailScreen` and `CallDetailScreen` so Hero photo banners transition with zero jump or distortion.
- **Fluid Screen Shifting & Directional Tab Transitions**:
  - Added `CupertinoPageTransitionsBuilder` across all platforms in `AppTheme` ensuring that pushing screens, popping back, and navigation flows have consistent, native-smooth horizontal slide physics.
  - Upgraded `MainShell` tab switcher to `_SmoothSlideIndexedStack` that slides horizontally with `Curves.easeOutCubic` according to tab direction while preserving scroll offsets.
  - Replaced `StretchRevealRoute` on contact search with smooth `CupertinoPageRoute`.

### Fixed
- **Resolved Blank Screen on Android Devices**:
  - Removed unstable `io.flutter.embedding.android.EnableImpeller = true` meta-data flag from `AndroidManifest.xml` that caused black/blank screens on devices with incompatible Vulkan drivers.
  - Replaced `backgroundColor: Colors.transparent` on root `Scaffold` with solid `activeTheme.scaffoldBackgroundColor` across all themes to eliminate window transparency fallback failures.
  - Added defensive `try-catch` blocks around `LiquidGlassWidgets` and `NotificationService` initializers in `main.dart` with global `FlutterError.onError` handler to prevent cold-start freezes.

---

## [1.2.0] - 2026-09-26

### Added
- **Interactive Contact Swipe Actions**:
  - Direct quick actions from the contacts list: Swipe Right to Call (emerald green) and Swipe Left to Message/SMS (accent blue) using `Dismissible` with non-destructive spring-back physics and haptic feedback.
- **Callback Latency & Responsiveness Engine**:
  - SQLite query engine `getCallbackLatencyStats(...)` evaluating missed call follow-ups within 24 hours with E.164/national phone number normalization.
  - Global Analytics: Added **Responsiveness & Callbacks** card with Average Callback Latency, Missed Call Return Rate %, Call Initiation balance split bar, and Peak Calling Rhythm.
  - Contact Detail Analytics: Added **Initiated by You %**, **Callback Latency**, **Return Rate %**, and an automated **BEST TIME TO CALL** recommendation banner (e.g., *"Wednesdays, 4 PM – 6 PM"*).
- **History Floating Date Jumper Sheet**:
  - Interactive floating date indicator with calendar icon and chevron.
  - Glass Date Jumper Modal Sheet that displays available years and months from actual call history, plus a quick "Today" shortcut to jump directly to any time period without stutter.
- **In-Memory History Filter Chips**:
  - Fast pill filter bar below the large title for instant switching between **All**, **Missed**, **Incoming**, **Outgoing**, and **Unknown** calls with live count badges.
- **Notification Action Buttons & Deep Linking**:
  - Added interactive "Call Back" and "Message" notification action buttons to missed call alerts.
  - Deep linking navigation directly to `CallDetailScreen` or `ContactDetailScreen` via compound payloads.
- **Rescued Orphaned Linkages**:
  - Linked `ArchivedContactsScreen` under **Settings ➔ Sync & Storage ➔ Archived Contacts**.
  - Linked `AppFeaturesScreen` under **Settings ➔ Support & Feedback ➔ App Features & Capabilities** while preserving the secret 7-tap easter egg.
  - Linked `NotificationTroubleshootingScreen` under **Settings ➔ Notifications ➔ Notification Diagnostics & Test**.

### Changed
- **Fluid Shell & Hero Transitions**:
  - Upgraded `MainShell` tab switching to `_FadeIndexedStack` (220ms ease-out crossfade) while preserving underlying list scroll offsets.
  - Synchronized contact photo banner dimensions (`(height * 0.32).clamp(220, 280)`), border radius (`20.0`), and hero tags (`contact_banner_${normalizePhoneNumber(number)}`) between Call Details and Contact Details.
- **Permanent Glass Alphabet Scrubber**:
  - Scrubber resting opacity set to `0.55` (blooms to `1.0` on touch); eliminated the 12px drag-in restriction for continuous multi-letter dragging.
  - Precomputed relative letter offsets in `ContactsScreen` to jump cleanly without queuing conflicting post-frame animations.
- **Performance & Shader Optimizations**:
  - Wrapped blurred photo banner backdrops inside `RepaintBoundary` to prevent GPU canvas redraws during scroll.
  - Enabled `addRepaintBoundaries: true` across `SliverHistoryCallList` items.
  - Memoized database watch streams in `initState()` to prevent unsubscribe/resubscribe cycles on build.
  - Corrected percentage scaling display bug in `Quick Insights` (`answerRate` and `weekendCallPercentage`).

---

## [1.1.0] - 2026-09-25

### Added
- **Real-Time Duplicate Contact Detection & Autocomplete Dropdown**:
  - Live query checking while typing into new contact fields (First Name, Last Name, Phone Number(s), Email, Company, and Job Title).
  - Floating `ContactSuggestionsDropdown` styled with liquid glass aesthetic, displaying contact avatars, formatted names, matched metadata, and quick edit triggers.
  - Seamless redirection: Tapping any matched contact immediately redirects to `EditContactScreen` pre-populated with that contact's existing details.
  - One-tap dismissible header to let users continue creating a separate contact if desired.
- **Enhanced Edit Contact Pre-Filling**:
  - Resilient name parsing fallback from `displayName` if structured name properties are not directly split by device contact providers.
  - Automatic asynchronous controller population when full contact accounts and properties resolve.
- **Automated Tests**:
  - Comprehensive unit and widget tests in `test/features/contacts/add_contact_dropdown_test.dart` validating suggestion rendering, tap redirection callbacks, and dismissal actions.

### Changed
- Standardized toasts across all screens to liquid `GlassToast` via `ToastService`.
- Reverted analytics info sheets back to floating `GlassSheet`.
- Refactored `AddContactScreen` to synchronize device contact cache and dynamically manage focus nodes across multiple phone number fields.

---

## [1.0.0] - Initial Release

- Multi-Tier Timeline Wave Navigator (Year, Month, Date scrubbing).
- Relationship Web Graph, GitHub-style Activity Heatmaps, and 24-hour Radial Clock.
- Full Personal CRM with notes, custom color tags, communication preferences, and web links.
- Digital Business Card & dynamic vCard QR code generator.
- Liquid Glass UI System powered by `liquid_glass_widgets`.
