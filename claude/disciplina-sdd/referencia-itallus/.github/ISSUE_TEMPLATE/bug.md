---
name: Bug
about: A defect observed in execution, backed by evidence
title: "{component}: {what breaks, present tense, max 72 chars}"
labels: [bug]
---

<!--
  BEFORE YOU OPEN THIS
  ────────────────────
  A bug report needs OBSERVABLE evidence — output, log line, screenshot, measurement.
  Without it you are describing a suspicion, and a suspicion belongs in the discussion,
  not in the tracker. If you cannot show the failure, do not open the issue.

  Language: en-US, matching the code. Delete every comment block before submitting.
-->

## Context

<!-- One line each. Delete the rows that do not apply. -->

| | |
|---|---|
| Component | `{api \| web \| deploy \| infra \| pipeline}` |
| Environment | `{local \| CI \| production host}` |
| Revision | `{full 40-char SHA}` |
| First seen | `{YYYY-MM-DD}` |

## Problem

<!-- Two to four sentences. State the wrong behaviour, not the suspected cause.
     Naming a cause you have not proven turns the report into a hypothesis. -->

{What happens today.}

**Evidence**

```text
{Paste the output, log excerpt or command result that shows the failure.
 Trim to the relevant lines — 5 to 20 is usually enough. Redact secrets.}
```

## Expected

<!-- One or two sentences. What the same run should have produced. -->

{What should happen instead.}

## Delivery

<!-- Which path delivers this, decided before work starts (AGENTS.md, "Caminho de entrega").
     PRD when at least one holds:
       1. proven correct only by running it (test, stack or deploy) — reading the diff is not enough;
       2. changes runtime behaviour of the system or its operation (API, screen, stored data, deploy);
       3. changes a requirement, business rule or constraint (fixing a stale fact does not count);
       4. touches security, LGPD or the database schema.
     Simple task when none holds: a direct docs/chore/fix PR, no PRD.
     Name the path, the criterion that decides it and, on a borderline case, the risk,
     reversibility and reach. The owner validates by adding the label delivery:prd or
     delivery:simple; without it, work does not start. -->

{PRD | simple task} — {criterion that decides it, and the borderline assessment if any}.

## Reproduction

<!-- Numbered, minimal, runnable. Someone who never saw this must be able to follow it.
     If it only reproduces under a condition, say the condition. -->

1. `{command}`
2. `{command}`
3. {what you observe}

## Impact

<!-- One line: who or what is blocked, and whether there is a workaround. -->

{Consequence today.} Workaround: {`{command}` or "none"}.

## References

<!-- Optional. Delete if empty. -->

- Run: {link}
- Commit: {SHA}
- Related issue: #{NN}
