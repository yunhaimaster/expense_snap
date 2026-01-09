# Change: Add Internationalization (English)

## Why

The app is currently Chinese-only (繁體中文), limiting potential user base to ~1.5B speakers. Adding English support removes the language barrier for 60%+ of global app store users and establishes the localization infrastructure for future language expansion.

## What Changes

- **NEW**: Flutter l10n infrastructure using `flutter_localizations` + `intl` + ARB files
- **NEW**: `localization` capability with language switching
- Extract ~300 hardcoded strings to ARB translation files
- Make date/time formatting locale-aware
- Make currency name display locale-aware
- Localize export filenames (`Expense_Report_2025-01.xlsx` vs `報銷單_2025年01月.xlsx`)
- Localize error messages with fallback chain

## Impact

- **New spec**: `specs/localization/spec.md`
- **Affected specs** (behavior unchanged, output localized):
  - `data-export` - filename format, Excel headers
  - `expense-management` - UI strings
  - `receipt-capture` - UI strings
  - `receipt-ocr` - OCR remains language-agnostic (detects receipt language, not UI language)
  - `currency-conversion` - currency names
- **Affected code**:
  - `lib/main.dart` - MaterialApp localization delegates
  - `lib/core/utils/formatters.dart` - locale-aware formatting
  - `lib/core/utils/error_messages.dart` - localized messages
  - `lib/core/constants/currency_constants.dart` - localized names
  - All 31 files with UI strings in `lib/presentation/`
  - `lib/services/export_service.dart` - localized filenames

## Non-Goals

- RTL (right-to-left) language support - deferred to future expansion
- Additional languages beyond EN/ZH-HK - deferred
- Currency symbol localization (keeps HK$, ¥, $) - symbols are universal
- Play Store listing localization - separate marketing effort
