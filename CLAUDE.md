# Elira — Flutter AI Photo Editor

## Stack
- Flutter 3.x / Dart SDK ^3.13.3
- State: GetX (`get: ^4.6.6`) — controllers via `Get.put()`, observables `.obs`
- Nav: GetX named routes (`GetMaterialApp`, `RouteName`, `AppPages`)
- Firebase: Auth, Firestore, Analytics (`google-services.json` gitignored — never commit)
- HTTP: `http: ^1.6.0` (wired, no AI calls yet)
- Storage: sqflite + shared_preferences + path_provider

## Architecture
```
lib/
  main.dart                  # entry, portrait lock, GetMaterialApp
  values/
    app_colors.dart          # all colors + gradients (primary #2B7EFB, secondary #7B4FDB)
    app_theme.dart           # AppTheme.light
    app_pages.dart           # route→screen+binding map
    route_name.dart          # RouteName constants
  controller/                # GetxController per screen
  models/
    data_models/             # EditProject
    ui_models/               # EditorTool, AiToolItem, QuickActionItem
  presentation/
    common_components/       # AppBarTitle, PrimaryButton, SectionHeader, ToolSlider
    screen_*/                # one folder per screen
```

## Routes (RouteName)
| const | path |
|-------|------|
| splash | `/` |
| onboarding | `/onboarding` |
| main | `/main` |
| photoPicker | `/photo-picker` |
| editor | `/editor` |
| export | `/export` |

## Controllers & state
| Controller | Key observables |
|-----------|----------------|
| EditorController | imagePath, activeTool (EditorTool enum), brightness/contrast/saturation/sharpness, canUndo/Redo |
| AiStudioController | credits (120), isProcessing — `runTool(name)` is FAKE (3s delay, no real API) |
| PhotoPickerController | (skeleton) |
| HomeController | (skeleton) |
| CreateController | (skeleton) |
| ExportController | (skeleton) |
| OnboardingController | (skeleton) |
| ProfileController | (skeleton) |

## Editor tools panel tabs
adjust / filters / effects / retouch / crop / background / text / ai (remove / ai_panel)
All panels are UI-only stubs — no processing logic yet.

## AI status — NOT integrated
- No DeepSeek, no Replicate, no any LLM/vision API wired
- `AiStudioController.runTool()` = fake delay only
- `http` package present, ready to use
- AI tools in UI: AI Enhance, AI Retouch, Remove BG, Expand, Relight, Restore

## Submodule
`dsp_base` → `https://github.com/asctechsoft/dsp_base_app.git`

## Key conventions
- All colors from `AppColors` — never hardcode hex in widgets
- Navigation: `Get.toNamed(RouteName.x, arguments: y)`
- EditorScreen receives image path via `Get.arguments` (String)
- No comments in code unless WHY is non-obvious
- `google-services.json` / `GoogleService-Info.plist` always gitignored

## What needs building
1. Real AI API integration (Remove BG, Enhance, etc.)
2. EditorController: undo/redo stack, actual image processing
3. Controllers marked skeleton above
4. Firebase Auth flow (onboarding → main)
