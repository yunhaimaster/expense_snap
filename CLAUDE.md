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
| **Skills** | Auto by Claude | Main thread | Guidance principles, patterns |
| **Agents** | Explicit dispatch | Isolated | Deep analysis, multi-file tasks |
| **Commands** | User types `/cmd` | Main thread | Structured output, specific action |

**Key Distinction:**
- **Skills** = *HOW* to do things (principles, patterns, guidelines)
- **Agents** = *DO* isolated work (returns summary to main thread)
- **Commands** = *RUN* specific task with structured output

### Proactive Skill Triggers (AUTO-INVOKE)

| User Intent | Skill to Invoke FIRST |
|-------------|----------------------|
| "Add/create/build X" | `brainstorming` |
| "Fix/debug/broken" | `systematic-debugging` |
| "Write tests" | `test-driven-development` |
| Multi-step task | `writing-plans` |
| 2+ independent tasks | `dispatching-parallel-agents` |
| About to say "done" | `verification-before-completion` |
| Flutter widget work | `flutter-patterns` |
| Flutter bug | `debug-flutter` |

### Proactive Agent Dispatch (AUTO-DISPATCH)

| After This | Dispatch Agent |
|------------|----------------|
| Major implementation complete | `code-reviewer` |
| Code changes with warnings | `flutter-fixer` |
| Before commit | `test-runner` |
| Performance concern | `perf-analyzer` |
| ARB file changes | `i18n-checker` |

### Code Intelligence Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **Serena MCP** | Symbol search, find refs, semantic edits | Exploring code relationships, refactoring |
| **Dart LSP** | Real-time diagnostics, go-to-def | After edits, type checking |
| **flutter analyze** | Static analysis | Pre-commit, CI |

**Best Practice:** Use Serena for exploration, LSP for live feedback, analyze for validation.

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

## Tooling Ecosystem

### MCP Servers (Active)
| Server | Purpose | Priority |
|--------|---------|----------|
| **serena** | 語義化程式碼分析 | 高 - 核心工具 |
| **context7** | Library docs lookup | 高 |
| **github** | GitHub 操作 | 中 |
| **sequential-thinking** | 複雜推理 | 低 - 按需 |

### Plugins (Enabled)
| Plugin | Purpose |
|--------|---------|
| **superpowers** | 工作流技能 |
| **commit-commands** | Git helpers |
| **code-simplifier** | 程式碼簡化 |
| **dart-lsp** | Dart 語言服務 |

### Hooks (Project-level)
| Hook | Trigger | Action |
|------|---------|--------|
| PreToolUse:Edit | Before edit | Check file was read |
| PostToolUse:Read | After read | Cache file path |
| PostToolUse:Edit | After edit | `dart format` + `flutter analyze` (once) |
| Stop | Session end | Remind to run analyze/test |

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
