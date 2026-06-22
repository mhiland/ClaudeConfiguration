---
name: fleet-review
description: Launch a multi-agent review fleet — a security-review or performance-review Workflow (parallel scouts → triage → worktree fix + adversarial verify; or N perf scouts → ranked synthesis). Use when the user wants a deep, fanned-out security or performance/scale audit via a scout fleet ("fleet review", "run the security sweep", "scout-fleet audit", "multi-agent review"). Billed multi-agent fan-out. NOT for reviewing the current diff — for that use the built-in security-review or /code-review.
---

# Fleet review

A thin launcher for multi-agent review workflows. This is a **billed multi-agent fan-out** —
a security sweep can spawn a dozen-plus scouts plus a fix+verify pipeline per confirmed
high/critical finding — so confirm intent before launching.

## Step 0 — Pre-flight (do this before calling Workflow)

1. **Confirm the target repo.** The fleet reviews the current working directory's repo.
   Confirm you are in the repo the user wants audited before launching; if the working
   directory is not a git repository or not the intended project, STOP and ask. Note that a
   workflow's scout prompts may hardcode a specific path or architecture — if so, run it from
   that repo or adapt the script first (see Scope notes).
2. **Pick the workflow** from the user's request:
   - security audit / OWASP / BOLA / auth / SSRF / supply-chain → `security-review`
   - throughput / scale / hot-path / memory / database-under-load → `performance-review`
   - "both" / "everything" → run `security-review` first, then `performance-review`.
   If unstated, default to `security-review` and say so.
3. **Confirm git state** (matters for `security-review`, whose fixers branch off the default
   branch): the working tree is reasonably clean and the default branch is reachable. If it is
   behind or dirty, surface it — fixers cut `fix/<slug>` branches off local default.
4. **Set expectations.** One line on scale and that it's billed
   (e.g. "~a dozen scouts + up to a few agents per confirmed finding; deferred/suspected
   findings are reported, not auto-fixed"). Proceed unless the user objects.

## Step 1 — Launch

Call the **Workflow** tool with the chosen name:

- `{ name: "security-review" }` — no args.
- `{ name: "performance-review" }` — no args.

Watch progress with `/workflows`. Let it run; the harness re-invokes you when it completes.

## Step 2 — Report the result

- **security-review** returns `{ confirmed, refuted, deferred, uniqueFindings, scanned }`.
  Summarize: confirmed fixes that **survived the verification panel** (each is a committed,
  *unpushed* `fix/<slug>` branch), what was refuted, and the deferred (suspected / medium-low)
  findings that were reported but not auto-fixed. Then offer to take the green branches to
  merged PRs/MRs — the fixers stop at commit, they do not push.
- **performance-review** returns `{ reports, plan, scanned }`. Surface the synthesized,
  prioritized action list (the `plan`), highlighting the 3–5 highest-leverage changes.

## Scope notes

- This skill only **launches** the fleet; it does not define it. To change the scout set,
  severity-floor triage, or model tiers, edit the workflow scripts the fleet runs.
- The deep-dive skills the scouts invoke (`owasp-api`, `auth-takeover-review`,
  `tenant-isolation-review`, `supply-chain-review`, …) are global, so the fleet resolves them
  in any project — but a given workflow's fix/verify rules may be tuned to a specific project,
  hence the repo check in Step 0.
