# ✨ Feature Documentation

This document provides an in-depth explanation of the primary features, analytics engines, and user experience modules in **ConvoLens**.

---

## 📜 1. Call History & Precision Timeline

The Call History module provides an intuitive timeline interface for browsing, filtering, and jumping across thousands of call records with zero latency.

### Key Capabilities
- **Multi-Tier Wave Scrubbing**:
  - Pulling inward from the right bezel activates the liquid wave navigator.
  - **Tier 1 (Year)**: Dragging near the edge selects the year.
  - **Tier 2 (Month)**: Dragging further inward expands month selection (`Jan`, `Feb`, etc.).
  - **Tier 3 (Date)**: Pulling deep into the screen isolates individual dates (`1`, `15`, `28`).
- **Dynamic Wave Canvas (`_LiquidWavePainter`)**: Real-time canvas painter renders fluid wave crests with animated text markers and physical spring damping.
- **Pop-Out Preview Badge**: A floating glass badge projects to the left of your thumb, giving real-time feedback on the currently selected year, month, or date before releasing to jump.
- **Floating Date Jumper Sheet**:
  - Tapping the floating date indicator opens an interactive glass bottom sheet displaying available years and months populated directly from actual call history.
  - Includes a quick **"Today"** shortcut to instantly jump to the newest records without scroll lag or animation stutter.
- **In-Memory History Filter Chips**:
  - Pill filter bar anchored below the large title for instantaneous switching between **All**, **Missed**, **Incoming**, **Outgoing**, and **Unknown** calls.
  - Live count badges update reactively without issuing additional database round-trips.
- **Rich Call Cards**:
  - Displays contact name/number, avatar thumbnail, call type badge, timestamp, and duration.
  - Shows custom notes, color tags, audio attachments, and scheduled follow-up reminders.

---

## 📊 2. Relationship Analytics & Responsiveness Engine

The Analytics dashboard transforms raw call logs into actionable relationship metrics and interactive visualizations.

### Key Visualizations & Engines
- **Callback Latency & Responsiveness Engine**:
  - Evaluates missed call follow-ups within 24 hours using phone number normalization (E.164 and national formats).
  - Computes **Average Callback Latency** (how quickly missed calls are returned).
  - Tracks **Missed Call Return Rate %** (percentage of missed calls successfully called back).
  - Displays **Call Initiation Balance** (visual split bar comparing calls initiated by you vs. the contact).
- **Optimal Contact Calling Times ("Best Time to Call")**:
  - Analyzes historical call log answer patterns by weekday and 2-hour time intervals.
  - Displays an automated recommendation banner on the Contact Detail screen (e.g., *"Wednesdays, 4 PM – 6 PM"*).
- **Relationship Web Painter (`RelationshipWebPainter`)**:
  - Interactive node-graph visualizing your top contacts as interconnected nodes.
  - Node sizes reflect total interaction volume, while connecting lines represent interaction frequency and strength.
- **Contribution Heatmaps & Calendar Grids**:
  - GitHub-style color heatmaps displaying daily call volume across months and weeks.
  - Supports filtering by incoming, outgoing, or missed calls.
- **Hourly Distribution Clock (`HourClockFacePainter`)**:
  - A 24-hour radial clock face highlighting peak calling hours during the day.
- **Communication Streaks & Insights**:
  - Tracks consecutive daily call activity and sends streak milestone notifications.
  - Automated weekly summary statistics with percentage scaling for answer rates and weekend volume.

---

## 👤 3. Contact Intelligence & Personal CRM

Manage contacts beyond phonebook defaults with custom relationship metadata and effortless gesture controls.

### Capabilities
- **Interactive Contact Swipe Actions**:
  - Direct quick actions from the contacts list using `Dismissible` with non-destructive spring-back physics and haptic feedback.
  - **Swipe Right (Emerald Green)**: Instantly initiate a phone call.
  - **Swipe Left (Accent Blue)**: Open SMS/messaging.
- **Permanent Glass Alphabet Scrubber**:
  - Semi-transparent, tactile alphabet scrubber resting along the right screen bezel (blooms to full opacity on touch).
  - Precomputes relative section offsets to jump smoothly to any letter header without blocking scrolling or frame drops.
- **Real-Time Duplicate Detection & Autocomplete Dropdown**:
  - Live query evaluation across First Name, Last Name, Phone Number, Email, Company, and Job Title fields as you type.
  - Floating liquid glass dropdown showing matching contacts with high-res avatars/colored initials, matched attributes, and quick action chips.
  - Tap-to-edit workflow: Tapping any suggestion redirects directly to `EditContactScreen` pre-populated with that contact's existing details.
  - One-tap dismissible header to let users continue creating a separate contact if desired.
- **Synchronized Photo Banner Hero Morphs**:
  - Coordinated Hero tags (`contact_banner_${normalizedNumber}`) and matching clamp dimensions (`(height * 0.32).clamp(220, 280)`) between Call Details and Contact Details for seamless screen transitions.
- **Device Contact Synchronization**: Automatically merges local phone contacts with SQLite interaction history via `flutter_contacts`.
- **Contact Details & Notes**: Add rich notes, meeting context, and internal background information to any contact.
- **Custom Color Tags**: Assign custom color-coded labels (e.g. `Client`, `VIP`, `Family`, `Work`).
- **Communication Preferences**:
  - Set preferred contact method (Call, WhatsApp, Email, SMS).
  - Specify best time of day to reach the contact.
- **Social & Web Links**: Attach social links (LinkedIn, X, GitHub, Website) to contact cards.
- **Archived & Favorite Lists**: Keep active contact lists focused by archiving inactive entries (accessible directly in Settings).

---

## 💳 4. Personal Digital Profile & QR Sharing

Create a digital business card and share details effortlessly.

### Capabilities
- **Editable Profile**: Manage your display name, primary phone number, email, company, title, and bio.
- **Custom Field Entries**: Add arbitrary custom key-value metadata fields to your profile.
- **Dynamic QR Code Generator**:
  - Generates QR codes encoded with standard vCard payload format.
  - Customize QR code colors, background glass styling, and center logo icons.
- **vCard Export & Import**: Save or share digital contact cards directly with external applications.

---

## 🔔 5. Notifications & Deep Linking

- **Actionable Notifications**:
  - System notifications for missed calls include interactive action buttons for **Call Back** and **Message**.
- **Deep Linking Navigation**:
  - Tapping a notification or its action buttons launches directly into the relevant `CallDetailScreen` or `ContactDetailScreen` via compound payload resolution.
- **Streaks & Reminders**:
  - Daily communication streak tracking and follow-up reminders.
- **Diagnostics**:
  - Built-in `NotificationTroubleshootingScreen` under Settings for testing permissions and validating channel dispatch.

---

## 🚀 6. Multi-Step Onboarding & Permissions Hub

- **Guided 3-Step Walkthrough**:
  - Automatically launches on first app open, walking new users through timeline navigation, callback latency analytics, and privacy commitments.
- **Interactive Permissions Checklist**:
  - Live permission cards with emerald green check badges for:
    - **Call Logs & Phone Access**: Enables chronological call syncing and callback latency computations.
    - **Device Contacts**: Matches callers with device contacts and provides duplicate detection.
    - **Notifications**: Enables missed call return alerts, streak milestones, and scheduled reminders.
    - **Microphone & Voice Notes**: Enables recording inline voice notes and scanning call recordings.
    - **Exact Alarms**: Ensures scheduled follow-up notifications arrive at the exact minute.
  - **"Grant All Required" Action**: Sequentially requests essential permissions in one tap.
- **Revisit Anytime**:
  - Accessible directly in **Settings ➔ Permissions & Security ➔ Welcome Guide & Setup**.

---

## 💎 7. Liquid Glass UI & Fluid Navigation

Powered by `liquid_glass_widgets`:
- **Directional Slide Tab Transitions (`_SmoothSlideIndexedStack`)**:
  - Tab navigation features a 250ms directional slide-and-fade transition with `Curves.easeOutCubic` matching native forward/backward navigation physics while maintaining underlying list scroll positions.
- **Universal Cupertino Page Transitions**:
  - All routes across the application utilize `CupertinoPageTransitionsBuilder`, providing consistent, native-smooth horizontal slide gestures matching the top-left back button.
- **Sub-Pixel Coordinate-Aligned Hero Banners**:
  - `ContactDetailScreen` and `CallDetailScreen` share identical physical screen coordinates (`top: padding.top + kToolbarHeight + 16.0`, `horizontal: 16.0`, `height: (screenHeight * 0.32).clamp(220, 280)`), enabling seamless Hero image morphs without jumping or distortion.
- **Glass App Bar & Tab Bar**: Floating glass title headers and bottom navigation bars with contextual action buttons.
- **Morphing Modal Sheets**: Smooth morphing animations for modal sheets originating from tap anchors.
- **Shader & Repaint Optimizations**:
  - Blurred photo banner backdrops wrapped in `RepaintBoundary` to eliminate GPU canvas redraws during scroll.
  - Solid background colors applied to root scaffolds to prevent window transparency rendering failures.

