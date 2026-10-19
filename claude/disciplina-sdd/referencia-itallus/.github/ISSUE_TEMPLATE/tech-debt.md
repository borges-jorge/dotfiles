---
name: Tech-debt / deferred
about: A defect or improvement found and deliberately postponed
title: "{area}: {what was postponed, present tense, max 72 chars}"
labels: [tech-debt, deferred]
---

<!--
  BEFORE YOU OPEN THIS
  ────────────────────
  Tech-debt is a decision, not a leftover. It records something that WAS found,
  WAS understood, and WAS postponed on purpose — with the reason and the cost of
  waiting. If it was never analysed, it is a bug or a chore, not debt.

  One issue per finding. Each issue is a unit that closes on its own: one
  expected state, one delivery path. A review pass or a gate run that yields
  five findings opens five issues, never one list. If "Expected" needs more
  than one independent check to be confirmed, split the issue.

  Language: en-US, matching the code. Delete every comment block before submitting.
-->

## Context

<!-- Where it came from: which feature, which pass, what surfaced it. Two or three lines. -->

{Feature or area, and how this came up.}

## Problem

<!-- What is wrong today, with the evidence that revealed it. If the cost is
     measurable — time, duplication, failure rate — put the number here. -->

{What happens today.}

```text
{Evidence: output, measurement or file excerpt. Trim to the relevant lines.}
```

## Expected

<!-- What the correct state looks like. Concrete enough that someone can tell,
     later, whether it was reached. -->

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

## Why it was postponed

<!-- The decision, in one or two lines: what took priority, or what has to exist first. -->

{Reason.} Blocked by: {`{issue, feature or artefact}` or "nothing — priority only"}.

## Trigger

<!-- The condition that brings this back: usage evidence (an incident, a volume,
     user feedback), a new obligation, or an owner decision. Concrete enough that
     someone can tell, later, whether it happened. -->

{Condition that brings it back.}

## Cost of waiting

<!-- One line. What gets worse, or what breaks, if this stays open another cycle. -->

{Consequence of postponing.}

## Proposal

<!-- Optional. Delete if you have none — an empty proposal is worse than no proposal. -->

{Suggested approach, one paragraph or a short list.}

## References

<!-- Optional. Delete if empty. -->

- Origin: {PR #NN, commit SHA, or run link}
- Related: #{NN}
