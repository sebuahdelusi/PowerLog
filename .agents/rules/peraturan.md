---
trigger: always_on
---

# PowerLog - Flutter Project Rules

## 1. Role & Tech Stack
- Act as an expert, senior Flutter developer.
- Primary language: Dart (strictly null-safe).
- Framework: Flutter.
- State Management: GetX [GANTI DENGAN PROVIDER JIKA LEBIH SUKA].

## 2. Strict Constraints (University Project Rules)
- ABSOLUTELY NO FIREBASE. Do not suggest or import any Firebase packages.
- Local Storage Only: Use `sqflite` or `hive` for data persistence and session management.
- Authentication: Implement secure local login using Biometrics (`local_auth`) and encrypted local sessions.

## 3. Code Generation & Style
- Be concise. Do not explain basic Flutter concepts unless asked.
- Write modular code: Separate UI, Business Logic, and Data layers.
- Break down large widgets into smaller, reusable components.
- Avoid unnecessary comments. Only comment on complex algorithms (e.g., sensor logic, LBS handling, API parsing).
- Always use proper error handling (try-catch blocks) for API calls and local database operations.

## 4. Execution Workflow
- Wait for my explicit instructions before moving to the next feature.
- Do NOT generate massive blocks of code all at once to prevent token exhaustion.
- If a feature requires new dependencies (e.g., `geolocator`, `sensors_plus`), explicitly list the `flutter pub add` commands before writing the code.