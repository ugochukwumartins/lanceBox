# LanceBox — Project Documentation

**Application Overview**

LanceBox is a Flutter mobile application for invoice preparation and export. It supports profile configuration, itemized billing, tax and shipping calculations, invoice preview, PDF generation and sharing through installed applications.

**Functional Scope**

The application provides an onboarding interface with input validation, optional business logo upload and account type selection. The dashboard provides access to invoice creation and stored invoice records. The invoice editor captures customer information, line items, currency, issuance date, bank details and payment terms. Users can review and revise invoice details before exporting the document.

**Architecture and State Management**

The codebase is organized by feature. `lib/app/` contains application configuration, theming and shared state; `lib/features/` contains onboarding and invoicing; `lib/shared/` contains reusable interface components and validation rules.

Riverpod manages shared profile and invoice data. SharedPreferences provides local persistence, with state updates published after successful storage operations. Draft input and temporary interface state remain within their respective screens. Separate components handle form data, invoice calculations, document layout and PDF generation.

**Validation and Reliability**

Required fields are validated before progression. Bank numbers accept up to ten digits and preserve leading zeros; bank names reject numeric input. Quantities must be positive, charges non-negative and VAT within 0–100%. Monetary amounts use integer minor units. Invoice totals combine line-item amounts, VAT and shipping. Storage and export failures display actionable messages, while loading indicators communicate pending operations.

**Setup and Verification**

With Flutter installed and a mobile device or simulator configured, run `flutter pub get` followed by `flutter run -d <device-id>`. Quality checks use `dart format .`, `flutter analyze` and `flutter test`. Automated coverage includes calculations, validation, persistence, PDF generation, navigation and visual regression checks.

**Implementation Status**

Backend authentication and social sign-in are not connected. Sharing uses the operating system’s share interface. Invoice persistence is implemented; the preview currently has no visible Save action. Native file selection and sharing require device verification. Further setup and architectural details are available in `README.md` and `docs/CODE_GUIDE.md`.
