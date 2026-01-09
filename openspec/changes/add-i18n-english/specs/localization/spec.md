## ADDED Requirements

### Requirement: Supported Languages
The system SHALL support English (EN) and Traditional Chinese (ZH-HK) as UI languages.

#### Scenario: English UI display
- **GIVEN** user has set language preference to English
- **WHEN** user navigates to any screen
- **THEN** all UI text, labels, and messages display in English
- **AND** date formats use English conventions (e.g., "January 2025")

#### Scenario: Chinese UI display
- **GIVEN** user has set language preference to Traditional Chinese
- **WHEN** user navigates to any screen
- **THEN** all UI text, labels, and messages display in Traditional Chinese
- **AND** date formats use Chinese conventions (e.g., "2025年1月")

### Requirement: Language Auto-Detection
The system SHALL automatically detect the user's preferred language from system settings, with user preference taking highest priority.

#### Scenario: Auto-detect system locale
- **GIVEN** a new user opens the app for the first time
- **AND** system locale is set to English
- **AND** no language preference has been saved
- **WHEN** the app initializes
- **THEN** English is selected as the UI language

#### Scenario: Fallback for unsupported locale
- **GIVEN** a new user opens the app for the first time
- **AND** system locale is set to an unsupported language (e.g., Japanese)
- **AND** no language preference has been saved
- **WHEN** the app initializes
- **THEN** Traditional Chinese is used as the fallback language

#### Scenario: User preference takes precedence over system locale
- **GIVEN** user has previously set language preference to English
- **AND** system locale is set to Chinese
- **WHEN** user reopens the app
- **THEN** app displays in English (user preference wins)
- **AND** system locale is ignored

### Requirement: Manual Language Selection
The system SHALL allow users to manually override the UI language.

#### Scenario: Change language in settings
- **GIVEN** user is on the Settings screen
- **WHEN** user taps "Language" option
- **THEN** system displays available languages (English, 繁體中文)
- **AND** current language is indicated

#### Scenario: Apply language change
- **GIVEN** user selects a different language
- **WHEN** selection is confirmed
- **THEN** entire app UI updates to the selected language immediately
- **AND** preference is persisted for future sessions

### Requirement: Locale-Aware Date Formatting
The system SHALL format dates according to the selected locale.

#### Scenario: English date format
- **GIVEN** app language is set to English
- **WHEN** system displays a date (January 15, 2025)
- **THEN** month summary shows "January 2025"
- **AND** expense card shows "Jan 15"
- **AND** relative time shows "5 minutes ago"

#### Scenario: Chinese date format
- **GIVEN** app language is set to Traditional Chinese
- **WHEN** system displays a date (January 15, 2025)
- **THEN** month summary shows "2025年1月"
- **AND** expense card shows "1月15日"
- **AND** relative time shows "5分鐘前"

### Requirement: Locale-Aware Number Formatting
The system SHALL format numbers according to the selected locale. Note: English and Hong Kong Chinese share the same number format convention (comma as thousands separator, period as decimal).

#### Scenario: English number format
- **GIVEN** app language is set to English
- **WHEN** system displays amount 12345.67
- **THEN** number is formatted as "12,345.67"
- **AND** currency symbols remain unchanged (HK$, ¥, $)

#### Scenario: Chinese number format
- **GIVEN** app language is set to Traditional Chinese
- **WHEN** system displays amount 12345.67
- **THEN** number is formatted as "12,345.67" (HK convention matches English)
- **AND** currency symbols remain unchanged (HK$, ¥, $)

### Requirement: Localized Export Filenames
The system SHALL generate export filenames in the selected language.

#### Scenario: English export filename
- **GIVEN** app language is set to English
- **AND** exporting January 2025 data for user "John"
- **WHEN** system generates export file
- **THEN** Excel filename is "Expense_Report_2025-01_John.xlsx"
- **AND** ZIP filename is "Expense_Report_2025-01_John.zip"

#### Scenario: Chinese export filename
- **GIVEN** app language is set to Traditional Chinese
- **AND** exporting January 2025 data for user "小明"
- **WHEN** system generates export file
- **THEN** Excel filename is "報銷單_2025年01月_小明.xlsx"
- **AND** ZIP filename is "報銷單_2025年01月_小明.zip"

### Requirement: Localized Excel Content
The system SHALL generate Excel content with localized headers.

#### Scenario: English Excel headers
- **GIVEN** app language is set to English
- **WHEN** system generates Excel file
- **THEN** column headers are: "No.", "Date", "Description", "Currency", "Amount", "Rate", "HKD Amount", "Notes"
- **AND** total row label is "Total"

#### Scenario: Chinese Excel headers
- **GIVEN** app language is set to Traditional Chinese
- **WHEN** system generates Excel file
- **THEN** column headers are: "編號", "日期", "描述", "原幣", "金額", "匯率", "港幣金額", "備註"
- **AND** total row label is "總計"

### Requirement: Localized Error Messages
The system SHALL display error messages in the selected language.

#### Scenario: English error message
- **GIVEN** app language is set to English
- **AND** network connection is unavailable
- **WHEN** user attempts to fetch exchange rates
- **THEN** error message displays "Please check your network connection"

#### Scenario: Chinese error message
- **GIVEN** app language is set to Traditional Chinese
- **AND** network connection is unavailable
- **WHEN** user attempts to fetch exchange rates
- **THEN** error message displays "請檢查網絡連線後再試"

### Requirement: Localized Currency Names
The system SHALL display currency names in the selected language.

#### Scenario: English currency names
- **GIVEN** app language is set to English
- **WHEN** user views currency dropdown
- **THEN** currencies display as "HKD - Hong Kong Dollar", "CNY - Chinese Yuan", "USD - US Dollar"

#### Scenario: Chinese currency names
- **GIVEN** app language is set to Traditional Chinese
- **WHEN** user views currency dropdown
- **THEN** currencies display as "HKD - 港幣", "CNY - 人民幣", "USD - 美元"

### Requirement: Language Persistence
The system SHALL persist language preference across app restarts.

#### Scenario: Remember language choice
- **GIVEN** user has selected English as their language
- **WHEN** user closes and reopens the app
- **THEN** app loads with English UI
- **AND** does not revert to system locale

### Requirement: Offline Language Support
The system SHALL support all languages without network connectivity.

#### Scenario: Language works offline
- **GIVEN** device has no network connection
- **WHEN** user changes language setting
- **THEN** language change applies successfully
- **AND** all translations display correctly

### Requirement: OCR Language Independence
The system SHALL perform OCR based on receipt content language, independent of UI language setting.

#### Scenario: OCR detects receipt language regardless of UI
- **GIVEN** app language is set to English
- **AND** user captures a receipt with Chinese text
- **WHEN** OCR processes the image
- **THEN** OCR correctly recognizes Chinese characters
- **AND** extracted amount and description reflect the receipt content
- **AND** UI continues to display in English

#### Scenario: Mixed language receipt
- **GIVEN** user captures a receipt with both English and Chinese text
- **WHEN** OCR processes the image
- **THEN** OCR correctly recognizes text in both languages
- **AND** extraction is based on receipt content, not UI locale
