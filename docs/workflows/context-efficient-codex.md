# Context-Efficient Codex Workflow

## Goal

Use the strongest model for reasoning and smaller models for scoped implementation without wasting context.

## Recommended Loop

1. Plan with GPT-5.5.
2. Execute with GPT-5.4 or GPT-5.4-mini.
3. Review with GPT-5.5.
4. Update `.agent/CONTINUITY.md` only for meaningful deltas.

## Planning Prompt

Reference only:
- `AGENTS.md`
- `docs/agents/planner.md`
- one relevant project-context file

Output a plan. Do not edit files.

## Execution Prompt

Reference only:
- `AGENTS.md`
- `docs/agents/executor.md`
- `PLANS.md` or the approved phase

Implement only the requested phase.

## Review Prompt

Reference only:
- `AGENTS.md`
- `docs/agents/reviewer.md`
- current diff

Review first. Do not patch unless asked.

## Thread Hygiene

Use fresh threads for:
- new features
- new bugs
- final reviews
- unrelated refactors

Avoid immortal project threads. They turn simple prompts into context freight trains.
