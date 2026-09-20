# 🏗️ Technical Architecture

This document provides a detailed overview of the technical architecture, design patterns, data flow, and directory layout of **Convolens**.

---

## 🏛️ Architectural Overview

Convolens follows a layered, feature-first architecture that separates concerns into clean, maintainable layers:

```
┌──────────────────────────────────────────────────────────┐
│                    UI & Presentation Layer               │
│   (Screens, Custom Painters, Glass Containers, Widgets)  │
└────────────────────────────┬─────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│                     Repository Layer                     │
│  (CallsRepository, AnalyticsRepository, ContactsRepo)    │
└────────────────────────────┬─────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────┐
│                    Database & Local Data                 │
│    (AppDatabase / Drift SQLite, Reactive Streams)        │
└──────────────────────────────────────────────────────────┘
```

---

## 📁 Layer Breakdown

### 1. Presentation Layer (`lib/features/*` & `lib/shared/*`)
- **State Management**: Uses native `StatefulWidget`s, `ValueNotifier`s, and `StreamBuilder`s to reactively re-render UI elements upon database updates.
- **Glassmorphism UI**: UI components consume `liquid_glass_widgets` for glass surfaces, backdrop blurs, floating navigation bars, and morphing sheet overlays.
- **Custom Painting**: High-performance canvas painters (`_LiquidWavePainter`, `RelationshipWebPainter`, `ContributionHeatmapPainter`, `HourClockFacePainter`) render interactive visualizations with low raster budget overhead.

### 2. Domain & Repository Layer (`lib/features/*/repository`)
- Decouples UI widgets from direct database queries.
- Aggregates call records, device contact details, and metadata into unified view models (e.g. `Call`, `ContactSummary`, `AnalyticsFilters`).
- Computes memoized data structures for list indexing and heatmaps (`buildHistoryItems`, `buildYearIndex`, `buildMonthIndex`).

### 3. Data Layer (`lib/core/database`)
- Powered by **Drift** (SQLite wrapper for Dart).
- Emits real-time reactive streams (`watchAllCalls()`, `watchAllCallDetailsMap()`, `watchSettings()`) allowing UI components to instantly reflect changes.
- Uses versioned schema migration strategies (Schema Version 15) and custom index structures (`idx_calls_date`, `idx_call_details_call_id`).

---

## 📂 Detailed Directory Layout

```
lib/
├── app/
│   ├── main_shell.dart             # Scaffold hosting main bottom tab navigation
│   └── routes.dart                 # Navigation route definitions
├── core/
│   ├── database/
│   │   ├── models/                 # Query result data transfer objects
│   │   ├── tables/                 # Drift table definitions (Calls, Details, Tags, etc.)
│   │   └── app_database.dart       # Main Drift database class & schema migrations
│   ├── logger/                     # Dev mode loggers and debug utilities
│   ├── native/                     # Native channel bindings (phone calls, permissions)
│   ├── notifications/              # Local notification dispatcher (streaks, reminders)
│   ├── theme/                      # HSL themes & glass styling configurations
│   ├── toast/                      # Custom glass toast notifications
│   ├── utils/                      # Phone number normalization, date helpers
│   └── widgets/                    # Core reusable UI widgets
└── features/
    ├── analytics/                  # Communication analytics, heatmaps, web graph
    ├── contacts/                   # Contact list, detail screen, tags, social links
    ├── history/                    # Call history, timeline wave navigator, search
    ├── profile/                    # Personal vCard profile & QR code generator
    └── settings/                   # App preferences, theme picker, developer tools
```

---

## ⚡ Performance Optimization Principles

1. **Stream Scope Minimization**: `StreamBuilder`s are placed at the lowest possible sub-tree level (e.g. wrapping only specific slivers rather than entire screens) to prevent unnecessary full-screen re-renders.
2. **Gesture Arena Isolation**: Edge gestures (such as the timeline wave) utilize `onHorizontalDrag*` recognizers combined with `IgnorePointer` layers so vertical list scrolling is never blocked.
3. **Raster Cache Hints**: Custom painters leverage `isComplex: true` and `willChange: true` on `CustomPaint` widgets for efficient rasterization.
4. **Disposed Listeners & Timers**: All `StreamSubscription`s, `AnimationController`s, and `ValueNotifier`s are safely disposed in widget lifecycles.
