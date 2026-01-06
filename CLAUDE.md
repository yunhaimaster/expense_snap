# Project Context

**First step for new sessions:** Read `PROJECT_INDEX.md` for codebase overview (94% token reduction vs full exploration).

## Quick Reference
- **Architecture**: Clean Architecture + Provider
- **Entry point**: `lib/main.dart`
- **DI**: `lib/core/di/service_locator.dart` (`sl` global)
- **Routes**: `lib/core/router/app_router.dart`
- **Tests**: `flutter test`
- **Type check**: `flutter analyze`

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