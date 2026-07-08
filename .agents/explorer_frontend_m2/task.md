# Task: Frontend Code Quality Audit Exploration

## Objective
Analyze the Mynix Control Flutter frontend codebase to find state management leaks, stability issues, Null Safety violations, and micro-architecture compliance issues.

## Scope
- D:\Mynix_Control\frontend\lib\
- Compare code against the global rules in `D:\Mynix_Control\AGENTS.md` and user_global rules.

## Requirements
1. **BLoC State Management**: Check BLoC class definitions, stream subscriptions, and state emission logic. Look for memory leaks (missing close/dispose) or logic flaws.
2. **Crashes and Exceptions**: Scan for raw types, potential `NoSuchMethodError` on null objects, or missing try-catch around risky calls.
3. **Null Safety**: Check for Null Safety violations, risky forced unwraps (`!`), or unhandled nullable types.
4. **Micro-Architecture line limits**: Check file sizes in `lib/features/`. Any file exceeding 200-250 lines must be identified.
5. **UI Decomposition**: Identify complex UI build methods that should be decomposed into separate widgets.

## Outputs
Write `handoff.md` inside your working directory with a detailed findings list including file paths, line numbers, issue descriptions, and recommended fixes.
