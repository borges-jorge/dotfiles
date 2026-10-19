---
name: Chore
about: Maintenance work with no defect behind it
title: "{area}: {what has to be done, present tense, max 72 chars}"
labels: [chore]
---

<!--
  BEFORE YOU OPEN THIS
  ────────────────────
  A chore changes no behaviour: upgrades, cleanups, tooling, renames, moving files.
  If something is broken, open a Bug. If it was analysed and postponed, open Tech-debt.

  Language: en-US, matching the code. Delete every comment block before submitting.
-->

## Context

<!-- What area this touches and why it comes up now. Two or three lines. -->

{Area and trigger.}

## Work

<!-- What has to be done. A short list beats a paragraph. Name the real files. -->

- [ ] {action on `{path}`}
- [ ] {action on `{path}`}

## Expected

<!-- The state that shows, once the work is done, that it was reached. One or two lines. -->

{Observable state after the work.}

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

## Why now

<!-- One line: what it unblocks, or what it costs to keep postponing.
     A chore with no answer here is not ready to be opened. -->

{Reason it is worth doing now.}

## Not included

<!-- One line. The nearest thing this deliberately does NOT do, so the scope
     does not grow while the issue sits open. -->

{Adjacent work left out.}

## References

<!-- Optional. Delete if empty. -->

- Related: #{NN}
- File: `{path}`
