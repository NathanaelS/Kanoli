# Reviewer Guidance

Use this file for GPT-5.5 or another strong review model.

## Purpose

Review a completed diff for correctness, scope control, compatibility, and maintainability.

## Load With

- `AGENTS.md`
- `docs/agents/reviewer.md`
- current diff
- relevant project-context file(s) only if the diff touches that subsystem

Do not load executor/planner guidance unless specifically requested.

## Review Focus

Check for:
- architecture drift
- unnecessary edits
- formatting churn
- Markdown compatibility regressions
- `todo.txt` compatibility regressions
- Trello import regressions
- parser/persistence edge cases
- Flutter state bugs
- UI behavior regressions
- missing tests
- silent fallbacks
- empty error handling
- dead code

## Output Format

Use this format:

```md
# Review

## Blockers
- ...

## Non-blocking Risks
- ...

## Missing Tests
- ...

## Unnecessary Changes
- ...

## Approval Recommendation
Approve / Request changes / Needs manual verification
```

## Review Rules

- Do not rewrite the implementation unless explicitly asked.
- Prefer findings over unsolicited patches.
- Be specific: cite file/function names when possible.
- Distinguish blockers from preferences.
- Do not nitpick style unless it affects maintainability or consistency.
