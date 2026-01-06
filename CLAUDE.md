# Project Context

**First step for new sessions:** Read `PROJECT_INDEX.md` for codebase overview (94% token reduction vs full exploration).

## Quick Reference

| Item | Location |
|------|----------|
| **Architecture** | Clean Architecture + Provider |
| **Entry point** | `lib/main.dart` |
| **DI** | `lib/core/di/service_locator.dart` (`sl` global) |
| **Routes** | `lib/core/router/app_router.dart` |
| **Tests** | `flutter test` |
| **Analyze** | `flutter analyze` |

## Code Conventions

### 金額處理
- **金額以「分」儲存** - `amountCents = (dollars * 100).round()`
- **匯率以 ×10⁶ 精度** - `storedRate = (rate * 1000000).round()`
- 避免浮點誤差，所有計算使用整數

### Error Handling
- 使用 `Result<T>` pattern，不在 business logic 拋異常
- `Result.success(value)` / `Result.failure(AppException(...))`
- 用 `fold()` 處理結果

### Provider Patterns
- 用 `Selector` 替代 `Consumer` 減少 rebuild
- `context.read<T>()` 用於事件處理
- `context.watch<T>()` 用於 build

### Widget Patterns
- 使用 `const` constructors
- 長列表用 `ListView.builder`
- 效能敏感區域加 `RepaintBoundary`

## Pre-commit Checklist
```bash
flutter analyze && flutter test
```

## Cross-session Context
- `.serena/memories/` - 歷史 session 記錄
- `.serena/memories/project-context.md` - 專案背景

---

<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->