# ✨ Feature Documentation

This document provides an in-depth explanation of the primary features and user experience modules in **Convolens**.

---

## 📜 1. Call History & Multi-Tier Timeline Wave Navigator

The Call History module provides an intuitive timeline interface for browsing call records.

### Key Capabilities
- **Multi-Tier Scrubbing**:
  - Pulling inward from the right bezel activates the liquid wave navigator.
  - **Tier 1 (Year)**: Dragging near the edge selects the year.
  - **Tier 2 (Month)**: Dragging further inward expands month selection (`Jan`, `Feb`, etc.).
  - **Tier 3 (Date)**: Pulling deep into the screen isolates individual dates (`1`, `15`, `28`).
- **Dynamic Wave Canvas**: Real-time canvas painter (`_LiquidWavePainter`) renders fluid wave crests with animated text markers.
- **Pop-Out Preview Badge**: A floating badge projects to the left of your thumb, giving real-time feedback on the currently selected year, month, or date before releasing to jump.
- **Call Cards**:
  - Displays contact name/number, avatar thumbnail, call type badge (incoming, outgoing, missed), timestamp, and duration.
  - Shows custom notes, tags, audio recording attachments, and scheduled follow-up reminders.

---

## 📊 2. Relationship Analytics & Visualizations

The Analytics dashboard transforms call history into interactive visual data.

### Key Visualizations
- **Relationship Web Painter (`RelationshipWebPainter`)**:
  - Node-graph visualization displaying your top contacts as interconnected nodes.
  - Node sizes reflect total interaction volume, while connecting lines represent interaction frequency and strength.
- **Contribution Heatmaps & Calendar Grids**:
  - GitHub-style color heatmaps displaying daily call volume across months and weeks.
  - Supports filtering by incoming, outgoing, or missed calls.
- **Hourly Distribution Clock (`HourClockFacePainter`)**:
  - A 24-hour radial clock face highlighting peak calling hours during the day.
- **Communication Streaks & Insights**:
  - Tracks consecutive daily call activity and sends streak milestone notifications.
  - Automated weekly summary statistics.

---

## 👤 3. Contact Intelligence & Personal CRM

Manage contacts beyond phonebook defaults with custom relationship metadata.

### Capabilities
- **Device Contact Synchronization**: Automatically merges local phone contacts with SQLite interaction history via `flutter_contacts`.
- **Contact Details & Notes**: Add rich notes, meeting context, and internal background information to any contact.
- **Custom Color Tags**: Assign custom color-coded labels (e.g. `Client`, `VIP`, `Family`, `Work`).
- **Communication Preferences**:
  - Set preferred contact method (Call, WhatsApp, Email, SMS).
  - Specify best time of day to reach the contact.
- **Social & Web Links**: Attach social links (LinkedIn, X, GitHub, Website) to contact cards.
- **Archived & Favorite Lists**: Keep active contact lists focused by archiving inactive entries.

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

## 💎 5. Liquid Glass UI System

Powered by `liquid_glass_widgets`:
- **Glass App Bar**: Floating glass title header with smooth collapse/expand animations.
- **Glass Tab Bar**: Floating bottom navigation bar with contextual action buttons.
- **Morphing Modal Sheets**: Smooth morphing animations for modal sheets originating from tap anchors.
