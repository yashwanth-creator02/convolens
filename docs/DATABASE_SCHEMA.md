# 🗄️ Database Schema & Migrations

Convolens uses **Drift** (SQLite wrapper for Dart) for local reactive database storage.

---

## 📊 Database Schema Overview

Current Schema Version: **`15`**

```
 ┌─────────────┐       ┌─────────────────┐       ┌─────────────────┐
 │    Calls    ├───────┤   CallDetails   ├───────┤ CallAttachments │
 └──────┬──────┘       └─────────────────┘       └─────────────────┘
        │                       │
        │                       │
 ┌──────┴──────┐       ┌────────┴────────┐
 │  CallTags   │       │      Tags       │
 └──────┬──────┘       └────────┬────────┘
        │                       │
 ┌──────┴──────┐       ┌────────┴────────┐
 │   Contact   ├───────┤   ContactTags   │
 │   Details   │       └─────────────────┘
 └──────┬──────┘
        │
 ┌──────┴──────┐
 │ContactLinks │
 └─────────────┘
```

---

## 📋 Entity Tables

### 1. `Calls` (`calls_table.dart`)
Stores raw call history records synced or recorded in the app.
- `id`: `Int` (Auto increment primary key)
- `number`: `Text` (Phone number)
- `timestamp`: `DateTime` (Call timestamp)
- `durationSeconds`: `Int` (Call duration)
- `callType`: `Text` (`incoming`, `outgoing`, `missed`)
- `formattedNumber`: `Text` (Normalized phone number format)

### 2. `CallDetails` (`call_details_table.dart`)
Metadata, notes, and follow-up reminders attached to a specific call.
- `id`: `Int` (Primary Key)
- `callId`: `Int` (Foreign key to `Calls.id`)
- `notes`: `Text` (Optional call notes)
- `reminderAt`: `DateTime` (Optional reminder alarm timestamp)
- `reminderLabel`: `Text` (Optional reminder title)

### 3. `Tags` & `CallTags` (`tags_table.dart`, `call_tags_table.dart`)
Custom tags assigned to call entries.
- **`Tags`**: `id`, `name`, `colorValue`
- **`CallTags`**: `callId`, `tagId` (Junction table)

### 4. `CallAttachments` (`call_attachments_table.dart`)
Files or audio recordings associated with calls.
- `id`: `Int` (Primary Key)
- `callId`: `Int` (Foreign key to `Calls.id`)
- `filePath`: `Text` (Local absolute storage path)
- `fileName`: `Text`
- `fileSizeBytes`: `Int`
- `mimeType`: `Text`

### 5. `ContactDetails`, `ContactTags`, `ContactLinks`
Extended relationship management data for contacts.
- **`ContactDetails`**: `normalizedNumber` (Primary Key), `customName`, `notes`, `colorValue`, `isArchived`, `ignoreFromAnalytics`, `preferredMethod`, `bestTimeToCall`.
- **`ContactTags`**: `contactNumber`, `tagId`.
- **`ContactLinks`**: `id`, `contactNumber`, `title`, `url`, `iconName`.

### 6. `ProfileFieldEntries` & `ProfileMeta` (`profile_fields_table.dart`, `profile_meta_table.dart`)
User profile business card details.
- **`ProfileMeta`**: `displayName`, `phoneNumber`, `email`, `company`, `title`, `bio`.
- **`ProfileFieldEntries`**: `id`, `key`, `value`, `sortOrder`.

### 7. `Settings` (`settings_table.dart`)
User application preferences.
- `id`: `Int`
- `devMode`: `Bool`
- `theme`: `Text` (`system`, `dark`, `light`)
- `showCallType`, `showDuration`, `showTime`, `showNotePreview`, `showTags`, `showReminderIndicator`, `showAttachmentCount`: `Bool`
- `lastNotifiedStreak`: `Int`
- `lastWeeklySummaryTimestamp`: `DateTime`

---

## ⚡ Performance Indexes

The database includes explicit indexes created during migration steps:
- `idx_calls_date`: Indexes `Calls(timestamp)` for fast chronological sorting and timeline indexing.
- `idx_calls_number`: Indexes `Calls(number)` for fast contact history lookups.
- `idx_call_details_call_id`: Indexes `CallDetails(callId)` for rapid detail lookup.
- `idx_call_tags_call_id`: Indexes `CallTags(callId)`.
- `idx_call_attachments_call_id`: Indexes `CallAttachments(callId)`.

---

## 🔄 Schema Migration History

- **v1 → v2**: Added `Settings` table.
- **v3 → v4**: Added `CallDetails`, `Tags`, and `CallTags` tables.
- **v5 → v7**: Added `reminderAt`, `reminderLabel` columns, and `CallAttachments` table.
- **v9 → v11**: Added `ContactDetails`, `ContactTags`, `ContactLinks`, and color/archive fields.
- **v12 → v13**: Added `ProfileFieldEntries`, `ProfileMeta`, and performance indexes (`idx_calls_date`, etc.).
- **v14 → v15**: Added `theme` selector column, streak tracking, and weekly summary timestamps.
