# Convolens

An intelligent, glassmorphism-styled Call History, Relationship Analytics, and Personal Contact Intelligence app built with **Flutter**, **Drift (SQLite)**, and **Liquid Glass Widgets**.

---

## 🌟 Features Overview

### 📜 1. Call History & Multi-Tier Timeline Wave
- **Interactive Timeline Wave Navigator**: Scrub seamlessly through thousands of call logs by **Year**, **Month**, and **Date**.
- **Dynamic Wave Labels**: Displays real-time year, month, and day markers along the liquid wave crest with pop-out badge previews.
- **Rich Call Cards**: Displays call type (incoming, outgoing, missed), duration, timestamp, notes preview, tags, reminder badges, and attachment counters.
- **Instant Search & Jump**: Fast query searching and estimated scrolling jumps.

### 📊 2. Relationship Analytics & Visualizations
- **Relationship Web Painter**: Interactive node-graph visualizing communication strength, call density, and contact connections.
- **Contribution Heatmaps & Calendar Grids**: GitHub-style activity heatmaps showing call distribution across weeks and months.
- **Hourly Distribution Clock**: 24-hour clock face visualization indicating peak calling hours.
- **Streak Tracking & Weekly Insights**: Automated notifications celebrating communication streaks and weekly summaries.

### 👤 3. Contact Intelligence & Personal CRM
- **Detailed Contact Profiles**: Custom notes, tags, color coding, preferred communication methods, and best time to call.
- **Social & Web Links**: Custom link attachments for contacts (LinkedIn, X, WhatsApp, etc.).
- **Archived & Favorite Contacts**: Organize contacts into favorites or archive inactive records.
- **Contact QR Generator**: Generate custom QR codes for individual contacts.

### 💳 4. Digital Profile & QR Sharing
- **Customizable Profile**: Personal business card with dynamic custom fields (Job Title, Company, Bio, Email, Socials).
- **vCard & Custom QR Codes**: Export personal details as vCard or dynamic QR code with customizable background color and icon.

### 💎 5. Liquid Glass Design System
- Built on `liquid_glass_widgets` featuring standard glassmorphic containers, morphing modal sheets, floating glass app bars, and responsive bottom tab bars.

---

## 🏗️ Technical Architecture

- **UI Framework**: Flutter (Dart ^3.12)
- **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) with reactive streams and migration versioning.
- **Design System**: Liquid Glass Widgets (`liquid_glass_widgets`) with HSL-tailored dark/light mode themes.
- **State Management**: Reactive StreamBuilders & ValueNotifiers with memoized cache layers.
- **Native Integration**: `permission_handler`, `flutter_contacts`, `url_launcher`, `just_audio`, `record`.

---

## 📁 Repository Structure

```
lib/
├── app/                  # Application shell and tab navigation
├── core/
│   ├── database/         # Drift database, tables, migrations & models
│   ├── logger/           # Dev mode logging utilities
│   ├── native/           # Platform & native interop bindings
│   ├── notifications/    # Local notification service (streaks, reminders)
│   ├── theme/            # Theme constants & glass styling configurations
│   ├── toast/            # Toast notification service
│   └── widgets/          # Shared core UI widgets
├── features/
│   ├── analytics/        # Relationship web, heatmaps, clock face, filters
│   ├── contacts/         # Contact details, tags, links, archived list
│   ├── history/          # Call history, timeline wave navigator, search
│   ├── profile/          # Digital business card, profile editor, QR sharing
│   └── settings/         # App settings, theme selector, dev tools
└── main.dart             # App entry point
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24.0 or newer)
- Dart SDK 3.12+
- Android Studio / VS Code with Flutter extension

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yashwanth-creator02/convolens.git
   cd convolens
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Database Code (Drift)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Analysis

- **Run Static Analysis**:
  ```bash
  dart analyze lib
  ```

- **Run Unit & Widget Tests**:
  ```bash
  flutter test
  ```

- **Format Code**:
  ```bash
  dart format lib test
  ```

---

## 📚 Documentation

For in-depth technical documentation, refer to the [`docs/`](./docs) directory:
- 🏗️ [Architecture Overview](./docs/ARCHITECTURE.md)
- ✨ [Feature Documentation](./docs/FEATURES.md)
- 🗄️ [Database Schema & Migrations](./docs/DATABASE_SCHEMA.md)
- 🛠️ [Development & Performance Guide](./docs/DEVELOPMENT_GUIDE.md)

---

## 📄 License

Copyright © 2026 Convolens Team. All rights reserved.
