# receipt-ocr Specification

## Purpose
TBD - created by archiving change add-receipt-ocr. Update Purpose after archive.
## Requirements
### Requirement: Text Recognition from Receipt Image
The system SHALL recognize text from receipt images using on-device ML Kit.

#### Scenario: Successful text recognition
- **WHEN** a receipt image is captured
- **THEN** text content is extracted from the image
- **AND** processing completes within 2 seconds

#### Scenario: OCR failure handling
- **WHEN** OCR processing fails on a receipt image
- **THEN** the error is logged silently
- **AND** the user can manually enter expense details

### Requirement: Currency Detection
The system SHALL detect currency from receipt text using pattern matching with user default fallback.

#### Scenario: Explicit currency code detected
- **GIVEN** receipt text contains "HKD 100.00"
- **WHEN** currency detection is performed
- **THEN** currency is identified as "HKD"

#### Scenario: Currency symbol detected
- **GIVEN** receipt text contains "¥88.00"
- **WHEN** currency detection is performed
- **THEN** currency is identified as "CNY"

#### Scenario: No currency detected uses fallback
- **GIVEN** receipt text contains only "$50.00" without clear currency indicator
- **AND** user's default currency is "HKD"
- **WHEN** currency detection is performed
- **THEN** currency falls back to "HKD"

### Requirement: Amount Extraction
The system SHALL extract the total amount using keyword matching with position-based fallback.

#### Scenario: Amount found near keyword
- **GIVEN** receipt text contains "總計: $123.45"
- **WHEN** amount extraction is performed
- **THEN** amount is extracted as 12345 cents

#### Scenario: Amount found by position fallback
- **GIVEN** receipt text has no keywords but "$88.00" appears at the bottom
- **WHEN** amount extraction is performed
- **THEN** amount is extracted as 8800 cents

#### Scenario: Phone number filtering
- **GIVEN** receipt text contains phone number "12345678" and amount "$50.00"
- **WHEN** amount extraction is performed
- **THEN** amount is extracted as 5000 cents
- **AND** phone number is ignored

### Requirement: Description Extraction
The system SHALL extract store name as expense description.

#### Scenario: Store name at top of receipt
- **GIVEN** receipt text has "大家樂餐廳" at the top
- **WHEN** description extraction is performed
- **THEN** description is set to "大家樂餐廳"

#### Scenario: Store name with business keyword
- **GIVEN** receipt text contains "XX商店有限公司"
- **WHEN** description extraction is performed
- **THEN** description includes "XX商店有限公司"

### Requirement: Auto-fill Form on Image Capture
The system SHALL automatically fill expense form fields after image capture.

#### Scenario: Successful auto-fill
- **WHEN** user captures a receipt image
- **AND** OCR processing completes successfully
- **THEN** currency field is populated with detected currency
- **AND** amount field is populated with detected amount
- **AND** description field is populated with detected store name
- **AND** user can modify any auto-filled values

#### Scenario: Partial detection auto-fill
- **GIVEN** OCR only detects amount but not currency or description
- **WHEN** auto-fill is performed
- **THEN** amount field is populated
- **AND** currency field uses user's default currency
- **AND** description field remains empty for user input

### Requirement: Processing Indicator
The system SHALL show loading state during OCR processing.

#### Scenario: Loading indicator displayed
- **WHEN** user captures a receipt image
- **AND** OCR processing starts
- **THEN** loading indicator is shown on form fields
- **AND** form fields are disabled during processing
- **AND** indicator is hidden when processing completes

