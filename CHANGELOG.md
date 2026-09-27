# Changelog

All notable changes to the **Mechanix Calculator** application will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-25

### Added

* **Core Arithmetic**: Support for addition, subtraction, multiplication, division, percentages, and sign toggling.
* **Calculation History**: Added a history panel to view previous calculations and reload expressions into the active editor.
* **Hardware Keyboard Support**: Added keyboard support for numbers, operators, `Enter` to calculate, `Backspace` to delete, and `Esc` to clear or dismiss history.
* **Expression Validation & Limits**: Added validation for division by zero, malformed expressions, numbers exceeding 15 digits, expressions exceeding 100 characters, and more than 20 operations.
* **Mechanix UI & Theming**: Integrated Mechanix design system components, Geist Mono typography, and responsive layouts.
* **Internationalization (i18n)**: Added multi-language support for error messages and UI text.
* **Error Feedback**: Added localized error feedback through UI snackbars.
* **Packaging & Build System**: Added Linux packaging support using `nfpm` and `mechanix-packager`.
