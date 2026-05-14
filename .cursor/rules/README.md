# Cursor Rules for AquaPulse

This directory stores persistent Cursor guidance for consistent implementation across app screens and features.

## Current Rules

- `project-baseline.mdc`: global engineering expectations for architecture boundaries, async safety, and style reuse.
- `flutter-ui-screens-widgets.mdc`: UI standards for screen/widget composition, state handling, and user feedback patterns.
- `flutter-domain-services-models-providers.mdc`: scoped standards for `lib/services/**`, `lib/models/**`, and `lib/providers/**`.
- `flutter-tests.mdc`: scoped standards for `test/**` reliability and behavior-first coverage.
- `docs-release-workflow.mdc`: scoped standards for markdown docs/release workflow consistency.

## Extension Strategy

- Add focused rules per area (services/providers/models, tests, docs) only when repeated review feedback appears.
- Keep each rule concise, specific, and non-overlapping.
- Prefer examples for common mistakes that recur in this codebase.
