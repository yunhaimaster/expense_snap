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

## When to Use What

### Skills vs Agents vs Commands

| Type | Trigger | Context | Use When |
|------|---------|---------|----------|
| **Skills** | Auto by Claude | Main thread | General guidance needed |
| **Agents** | Explicit dispatch | Isolated | Deep analysis, multi-file |
| **Commands** | User types `/cmd` | Main thread | Specific task, structured output |

### Review Tools (Consolidated Guide)

| Scenario | Tool | Why |
|----------|------|-----|
| "Review this file" | `/review path` | User-invoked, structured output |
| "Review these changes before commit" | `/review --staged` | User-invoked, pre-commit check |
| Deep architecture review | `code-reviewer` agent | Isolated context, uses Opus |
| Auto-guidance while coding | `flutter-review` skill | Auto-triggered, inline tips |

**Rule of thumb:** User says "review" → `/review`. Claude autonomously reviewing → skill. Need isolation → agent.

### Test Tools (Consolidated Guide)

| Scenario | Tool | Why |
|----------|------|-----|
| "Run tests" | `/test` or `test-runner` agent | User-invoked |
| "Generate tests for X" | `test-gen` skill | Auto-triggered when writing code |
| "Fix failing tests" | `test-runner` agent | Iterative fix loop |

### Performance Tools (Consolidated Guide)

| Scenario | Tool | Why |
|----------|------|-----|
| Quick perf check | `/perf` command | User-invoked, fast |
| Deep analysis | `perf-analyzer` agent | Isolated, thorough |

### Code Simplification (Consolidated Guide)

**Workflow:** Review → Identify Complexity → Simplify

| Scenario | Tool | Why |
|----------|------|-----|
| After `/review` flags complexity | `/code-simplifier` on flagged areas | Targeted cleanup |
| After `code-reviewer` agent runs | Auto-suggest simplification | Chain with deep review |
| Major refactoring complete | `/code-simplifier` pass | Catch accidental complexity |
| Explicit cleanup of old code | `/code-simplifier path/to/file` | Override default scope |

**Rule of thumb:** Review first, simplify flagged areas. Default targets recently modified code only.

**Integration Pattern:**
```
/review path/to/file
  ↓ (if complexity flagged)
/code-simplifier path/to/file
  ↓
Verify → Commit
```

**When NOT to simplify:**
- Quick hotfixes (ship first, simplify later)
- Code you didn't modify (unless explicitly requested)

### Other Tools

| Task | Tool |
|------|------|
| Fix analyze warnings | `flutter-fixer` agent |
| i18n validation | `i18n-checker` agent |
| Debug issues | `debug-flutter` skill (auto) |
| Pattern guidance | `flutter-patterns` skill (auto) |
| Simplify code | `/code-simplifier` (post-review) |

## Memory Sources

| Source | Purpose | Update Frequency |
|--------|---------|------------------|
| `PROJECT_INDEX.md` | Codebase structure (canonical) | When architecture changes |
| `.serena/memories/project-context.md` | Current project status | Each session |
| `.serena/memories/session-*.md` | Historical session notes | Auto-created |

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
