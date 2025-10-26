```markdown
# Shiskar Studio Manager (offline-first)

A friendly, lightweight offline-first Android app built with Flutter to manage music production, video editing, photo editing, and DIY technical projects — entirely on-device.

Core features:
- Projects: create/manage projects (music/video/photo/tech) with notes, deadlines and status.
- Tasks: per-project to-dos with priority and progress.
- Media Organizer: local gallery, audio playback, tagging.
- Tech Logbook: log wiring diagrams, tests, attach photos and related video links.
- YouTube: optional channel subscriptions, long-form filtering (configurable), in-app embedded player.
- SunoAI: generate audio from prompts (requires Suno API key).
- Research skeleton: Google Custom Search / assistant skeleton for integration.
- Reminders and basic calendar helpers: local notifications & schedule reminders.
- Export/import JSON to/from removable storage.

How to run:
1. Install Flutter (stable).
2. flutter pub get
3. flutter run -d <android-device>

Build release APK:
- flutter build apk --release
- The APK will be at build/app/outputs/flutter-apk/app-release.apk

Notes:
- Replace YouTube placeholder channel handles if needed.
- SunoAI: enter API key in Settings before generating.
- Long-form threshold: configurable in Settings (seconds).
- For production, store API keys in secure storage and sign the app with your keystore.
```
