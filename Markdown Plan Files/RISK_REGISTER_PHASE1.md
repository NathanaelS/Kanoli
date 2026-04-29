# Kanoli Flutter Port - Risk Register (Phase 1)

## Rating Scale

- Probability: Low / Medium / High
- Impact: Low / Medium / High

## Risks

1. Security-scoped bookmark behavior mismatch (Apple platforms)
- Probability: Medium
- Impact: High
- Why: Swift app relies on macOS bookmark-based permission restore; Flutter plugins differ by platform.
- Mitigation: Abstract file-access layer early; prototype permission persistence on macOS+iOS before deeper UI work.

2. Markdown parser/serializer parity drift
- Probability: Medium
- Impact: High
- Why: Existing Swift parser handles legacy checklist formats and strict metadata semantics.
- Mitigation: Port parser first with fixture-based tests mirroring current Swift tests and edge cases.

3. Todo sidecar merge behavior regression
- Probability: Medium
- Impact: High
- Why: Existing logic preserves unrelated lines/spacing while editing card-scoped tasks.
- Mitigation: Add golden tests for spacing, blank lines, and unrelated card lines before UI integration.

4. Cross-board filtering parity gaps
- Probability: Medium
- Impact: Medium
- Why: Current app evaluates filters across open-tab snapshots including inactive boards loaded from disk.
- Mitigation: Keep filtering in domain layer and add deterministic tests across multi-board fixtures.

5. Drag/drop UX and reorder correctness
- Probability: Medium
- Impact: Medium
- Why: SwiftUI drag/drop with live `dropEntered` reordering has nuanced behavior.
- Mitigation: Implement deterministic reorder algorithm first, then add platform-specific DnD adapters and widget tests.

6. Large single-file UI decomposition introduces behavior changes
- Probability: Medium
- Impact: Medium
- Why: `ContentView.swift` includes tightly coupled states (focus/popover/scroll/open panel interactions).
- Mitigation: Port by behavior slices with parity checkpoints; preserve event order in integration tests.

7. Date/time and timezone parity issues
- Probability: Low
- Impact: Medium
- Why: Swift uses POSIX formatter conventions for markdown and todo fields.
- Mitigation: Use explicit formatter utilities in Dart and lock tests to expected string formats.

8. Crash diagnostics parity not equivalent on all platforms
- Probability: Medium
- Impact: Medium
- Why: Swift uses signal handlers and NSException hooks; Flutter error capture model differs.
- Mitigation: Implement platform-appropriate crash/event logging with consistent user-facing crash notice behavior.

9. Platform file dialog and path UX differences
- Probability: Medium
- Impact: Medium
- Why: Startup flows rely on desktop save/open panels and default document paths.
- Mitigation: Normalize picker flows with platform-aware adapters and UX acceptance checks.

10. Hidden dependency on macOS-only behavior in current code
- Probability: Medium
- Impact: Medium
- Why: several flows are wrapped in `#if os(macOS)` and may not have direct equivalents on mobile.
- Mitigation: Define explicit mobile/desktop behavior spec before implementation and track intentional deviations.

## Immediate Mitigation Tasks Before Phase 2

- Build parser parity test fixtures from current Swift tests.
- Prototype file permission persistence on macOS and iOS.
- Define a strict compatibility contract for markdown/todo output.
- Document any accepted behavior differences per platform before coding UI.

