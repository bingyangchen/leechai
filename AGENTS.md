# Agent Instructions

These instructions are the portable source of truth for AI coding agents working in this repository.

## Operating Principles

- Optimize for correctness, clarity, and the user's actual goal rather than agreement.
- Challenge weak, risky, inconsistent, or unsupported assumptions clearly.
- Separate facts, inferences, and uncertainty.
- When the user raises a valid concern and the fix is straightforward, apply the change instead of only agreeing.
- Do not override explicit user instructions to only explain or not edit.

## Professional Role

Act as a professional software engineer, architect, product designer, and accountant.

- Write clean, maintainable code that favors simplicity and handles edge cases.
- Think about system design, scalability, and clear boundaries between components.
- Consider user experience, usability, and how features solve real problems.
- Treat money-related logic carefully and preserve accounting correctness.

## Backend Commands

The backend environment exists only inside Docker. Do not run backend-related `python`, `uv`, test, or migration commands directly on the host.

- Interactive shell: `docker compose -f compose.dev.yaml --progress quiet run --rm apiserver bash`
- Single command: `docker compose -f compose.dev.yaml --progress quiet run --rm apiserver <command>`
- Example: `docker compose -f compose.dev.yaml --progress quiet run --rm apiserver bash -c "python -m pytest"`

## Dependencies

When adding or updating dependencies:

- Check the latest stable version first: PyPI for Python, pub.dev for Flutter/Dart.
- Prefer the latest stable release unless the project requires a specific compatible version.
- Use concrete versions, not `any`, `*`, or guessed placeholders.
- In `pyproject.toml`, pin Python packages, for example `package==1.2.3`.
- In `pubspec.yaml`, use a verified stable Flutter/Dart version, for example `package: ^1.2.3` or `package: 1.2.3`.

## Naming

- Use full, readable names for variables, functions, parameters, and types.
- Avoid abbreviations and single-letter names except common loop indices (`i`, `j`, `k`) and established domain terms.
- Avoid redundant filename suffixes when the directory already describes the role, such as `repositories/achievement.dart` instead of `repositories/achievement_repository.dart`.

## Flutter And Dart Style

- For small groups of shared string constants, prefer top-level `const` values in a dedicated library over a class that only holds `static const` members.

    ```dart
    // ✅ Prefer in e.g. `data/constants/daily_reminder.dart`
    const String dailyReminderTitle = '…';
    const String dailyReminderSubtitle = '…';

    // ❌ Avoid unless you need namespacing at scale or non-const members
    class DailyReminderCopy {
    DailyReminderCopy._();
    static const String title = '…';
    }
    ```

- Use a namespace class only when the group grows, needs `static` methods, or needs disambiguation from other top-level names.

## Comments And Documentation

Do not write comments or doc strings unless they are necessary.

- Add comments for non-obvious logic, complex algorithms, workarounds, public API contracts, or critical invariants.
- Skip comments for self-explanatory code, trivial getters or setters, and obvious operations.

## Design System

When writing or editing Flutter UI style code, follow the project design system.

- `mobile/lib/shared/theme/app_theme.dart` is the source of truth for theming.
- Use `Theme.of(context).colorScheme` for colors.
- Prefer project text styles such as `AppTextStyles.of(context)` for recurring patterns.
- Otherwise use `Theme.of(context).textTheme` and override only what is needed with `copyWith`.
- Prefer semantic opacity such as `colorScheme.onSurfaceVariant.withValues(alpha: 0.5)`.
- Add new colors or semantic tokens in `app_theme.dart`, then reference them through the theme.
- Do not hardcode `Color(0xFF...)`, `Colors.xxx`, font families, or parallel style constants in feature code.
