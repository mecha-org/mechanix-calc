# Mechanix Calculator

A modern, functional calculator app built with Flutter Elinux for Mechanix OS. It features a clean UI, basic arithmetic operations, and calculation history.

## ✨ Features

- **Basic Arithmetic**: Addition, subtraction, multiplication, and division.
- **Calculation History**: Keep track of your previous calculations.
- **Real-time Formatting**: Large numbers are automatically formatted with commas for better readability.

## 🚀 Getting Started

### Prerequisites

- [Flutter-Elinux SDK](https://github.com/flutter-elinux/flutter-elinux)
- [Dart SDK](https://dart.dev/get-dart)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/mecha-org/mechanix-calc
   ```

2. Navigate to the project directory:
   ```bash
   cd mechanix-calc
   ```
3. Get dependencies:
   ```bash
   flutter-elinux pub get
   ```

### Running the App

To run the app on your connected device or emulator:

```bash
flutter-elinux run
```

## 🧪 Testing

### Unit Tests

To run unit tests:

```bash
flutter-elinux test
```

### Integration Tests

To run integration tests:

```bash
flutter-elinux test integration_test/app_test.dart -d linux
```

## 🛠 Tech Stack

- **Framework**: [flutter-elinux](https://github.com/flutter-elinux/flutter-elinux)
- **State Management**: [Bloc (flutter_bloc)](https://pub.dev/packages/flutter_bloc)
- **Math Engine**: [math_expressions](https://pub.dev/packages/math_expressions)
