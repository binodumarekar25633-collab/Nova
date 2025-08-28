# Nova — AI Code Assistant (Flutter, Android)

Jarvis-style AI coder that understands **Hindi + English** speech, generates **code**, reads it out loud, and lets you **save** files.

## Features
- 🎤 Voice input (Hindi/English) via `speech_to_text`
- 🔊 Voice reply via `flutter_tts`
- 🤖 AI code generation (OpenAI) with language selector
- 🧾 Syntax-highlighted code view
- 💾 Save generated code to device storage
- 📂 Simple project manager (list/open/delete)

## How to build an APK for free (Codemagic)
1. Push this repo to **GitHub**.
2. Go to **codemagic.io** → Add Application → connect your GitHub repo.
3. In Codemagic **Environment variables**, create a group named `openai` and add:
   - `OPENAI_API_KEY` = your OpenAI key (secure)
   - `CM_EMAIL` = your email (optional for notifications)
4. Start the **flutter-android** workflow. Codemagic will:
   - Create a full Flutter skeleton,
   - Copy this project's `lib/` and `pubspec.yaml`,
   - Add required Android permissions,
   - Build a **release APK**.
5. Download `app-release.apk` from the Artifacts section and install it on your phone.

## Local testing
If you want to test locally, you can hardcode your API key in `lib/codegen_screen.dart`
by replacing:
```dart
const String openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
```
with:
```dart
const String openAIApiKey = "sk-...";
```

> Note: Internet + Microphone permissions are added automatically in Codemagic. If you run locally, ensure they exist in `AndroidManifest.xml`.