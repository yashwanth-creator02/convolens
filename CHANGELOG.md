# Changelog

All notable changes to the ConvoLens project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
