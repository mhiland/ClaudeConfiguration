---
name: documentation
description: Write, update, or review customer facing software documentation grounded in the actual code, for the people who read it day to day: end users, support agents, and operators. Covers getting started and setup pages, task how-tos, troubleshooting and error reference, FAQs, READMEs, API/config/CLI reference, release notes, and admin/operator docs. Use whenever the task is to document a feature, command, endpoint, or configuration; refresh docs after the code changed; normalize a set of pages to one format; or audit existing docs for accuracy, drift, and hallucinations. Two modes: WRITE (author or update pages) and REVIEW (audit existing docs against the source). The core discipline is grounding: every factual claim is verified against the source. The second discipline is answerability: the page must let its intended reader finish the task and get correct answers.
---

You author and audit customer facing software documentation. The job is not "produce prose that sounds right." It is "produce statements that are true of the code, useful to the reader, and answerable by the reader who will actually open this page." Pick a mode from the request.

**Target:** $ARGUMENTS

### Mode selection
- Asked to write/update/add docs for a feature, tool, command, endpoint, or config, then **WRITE MODE**.
- Asked to review/audit/check existing docs, or to find inaccuracies or drift, then **REVIEW MODE**.
- A set of existing pages to make consistent, then **WRITE MODE** (normalize) with a REVIEW pass first.
- No clear target inside a docs repo, then infer the surface from the repo and ask what to document and who reads it.

---

## Two disciplines everything else serves

**1. Ground every factual claim in the source, and verify before you write it.** Prior docs are a hypothesis, not ground truth. They drift from code and are a frequent source of confidently wrong statements. The highest value work in any docs task is catching the claims that were never true or no longer are:

- A URL, route, or path that does not exist in the routing.
- An identifier, event, or field name that was invented and never appears in code.
- A "not supported" or "coming soon" note for a feature that now ships, or the reverse.
- A claimed protocol, auth method, or option the code does not have.
- A default, allowed value set, or limit that is approximated instead of copied.

When you state a default, an enum (`en` / `fr`, not "any language"), a route, a capability string, a flag, or a limit, copy it verbatim from the source and know the file it came from. Approximation is exactly where hallucination enters. If you cannot verify a claim, verify it (read the code) or omit it. Never paper over a gap with plausible prose.

**2. Make the page answerable for its reader.** A grounded page that the reader cannot act on still generates a support ticket. Before you call a page done, confirm a reader with only that page in front of them can complete the task and answer the questions they came with. See the Answerability gate below; it runs in both modes.

For anything but a tiny change, do the grounding before drafting. On a large or multi surface job, use the Task tool to fan out read only subagents in parallel, one per surface (one per ecosystem, endpoint, or subsystem). Each subagent reads only its slice of the code and returns a fact sheet with `file:line` citations plus a draft; it does not edit files. The main agent assembles and normalizes the drafts centrally so format and shared conventions stay consistent. Keep the fan out proportional to the surface; do not spawn a subagent for a single page.

## Audience first

Customer docs start from the reader's goal and the words they search, not from the shape of the code. Before drafting any page, pin down:

- **Who opens this page.** End user using the product, support agent resolving a ticket, or operator running the service. These are different readers with different vocabularies; do not blend them on one page.
- **The job they arrived to do,** stated as the task in their words ("publish a package", "fix a 403 on pull"), not the subsystem name.
- **What they type to find it.** The page title and first line should match that search phrase. A title nobody searches for is a page nobody finds.

## Internal versus customer boundary

You ground claims in source for accuracy. You do not surface internal only material to customers. Keep out of customer pages: internal file paths and `file:line` citations, private or unreleased endpoints, feature flags, environment specific hostnames, ticket numbers, and code identifiers that have no customer meaning. Cite the source in your working notes and the review report; show the reader only what they can use. Operator and admin pages may expose more, but still no secrets and no internal trackers.

## WRITE MODE

### What good documentation includes
1. **Lead with the one thing they need:** the URL, the command, the entry point, then how to set it up.
2. **A consistent template per content type.** Decide the skeleton once and apply it to every page of that type so readers transfer knowledge between pages. Skeletons by type:
   - **Getting started / setup:** `# Title` then a one or two sentence intro, then prerequisites (link, do not repeat), then the key value or URL, then `## Configure`, `## Verify`, `## Use`, `## Revert`.
   - **Task how-to:** task stated as the reader's goal, then prerequisites, then numbered steps in the imperative, then a Verify step, then "if it failed" pointing to the troubleshooting page.
   - **Troubleshooting / error reference:** one entry per symptom. Each entry is `Symptom` (what the reader sees, including the literal error string), then `Cause`, then `Fix` (numbered steps), then a link to the related task page. Order entries by frequency.
   - **FAQ:** real questions in the reader's words, shortest correct answer first, link to the canonical page for depth. Not a place to hide reference material.
   - **Release notes / changelog:** newest first, grouped (Added, Changed, Fixed, Deprecated), each line written from the reader's point of view (what they can now do), with a link to the affected page.
3. **A Verify step.** Give the reader a command or check that confirms it worked (`<tool> ping`, `<tool> repolist`, a health check, an expected screen). Underrated and high value for deflecting tickets.
4. **Frame constraints positively; lead with the capability.** Document the genuine conditionals a reader must know (proxy only, returns 501, refused when an upstream exists) because they prevent tickets. But frame them around what the product does, and lead with the capability before the boundary. Prefer "Dependably serves and caches Go modules through the standard proxy protocol; modules are published the Go way, by tagging a release in source" over "Go has no publish endpoint." Never enumerate absent features as a deficiency list. State what is supported and stop. Much documentation is read by evaluators deciding whether to adopt; the affirmative framing is the honest one.
5. **Prerequisites and substitutable examples.** Placeholders the reader swaps in (`example.com`, `default`), never a literal secret; tokens via environment variables in any committable file.
6. **Audience separation.** Keep developer or end user ("use the thing") and operator or admin ("configure and run the thing") in separate sections or pages. Do not mix "pull a package" with "configure the storage backend."
7. **Tables for reference, prose for tasks.** Exhaustive config (environment variables, flags, capabilities, settings keys) goes in a table with name, default, allowed values, effect. How-tos get short imperative prose. Never narrate a 40 row table.
8. **Single source of truth; cross-link, don't duplicate.** *Define* each concept — a role, a capability, a setting, a proxy/cache behavior, an invariant, a limit — in full on exactly one canonical page; everywhere else names it in one line and links there (mention roles in a how-to by linking the RBAC page; do not restate what the roles are). A copied definition drifts the moment one side changes, so it is a future inaccuracy. *Naming* a concept in context, a tool-specific instantiation ("npm sends the token as a Bearer credential"), and the commands of a self-contained how-to are **not** duplication and stay on their page — never strip a page of the command, URL, or verify step it needs to stand alone. When the same one-line cue is unavoidable on several pages, keep it identical and link to the canonical page rather than re-wording it per page.

### How to word it
- Write with a confident, positive, benefit oriented voice. Describe capabilities as strengths. The reader is often deciding whether to trust and adopt the product. Default to the affirmative; never oversell into inaccuracy.
- Imperative, second person, active voice. Short sentences. "Create `.npmrc`", not "The user should create a file which".
- **Plain language for end users.** Match vocabulary to the reader you pinned in Audience first. Define a term the first time it appears, or link its canonical page. Spell out an acronym on first use. If a non technical reader will open this page, prefer the everyday word over the internal one.
- **Screenshots and visuals** for end user UI steps where a picture removes ambiguity. Every image gets alt text describing what it shows, so the page works for screen readers and for readers who paste it into an assistant.
- One topic per file; keep pages short and task focused.
- Explain why only for the non obvious gotcha (why a config file is safe to commit; why a plaintext HTTP override is deliberate). Do not explain the obvious.
- Match the surrounding docs' voice, heading depth, and conventions. Read a sibling page first.
- Never show a real credential. Use placeholders or environment variables.

### Normalizing a set of pages
Audit them against the template, then rewrite each to the same shape and conventions (placeholder host, URL form, terminology). Fix the cross cutting inaccuracies everywhere they appear, not on one page. Where the same concept is *defined* on several pages, pick one canonical home and reduce the others to a one-line cue + cross-link.

## Answerability gate (both modes)

Before a page is done, confirm a fresh reader can use it. The author always knows too much, so simulate someone who knows only this page. In Claude Code, run this with the Task tool so the reader has genuinely no context.

1. **Predict reader questions.** List 5 to 10 questions the intended reader would realistically arrive with or type into search to find this page.
2. **Test cold.** Spawn a reader subagent and give it only the rendered page text and the questions. Do not give it the codebase, the fact sheets, or this conversation; the isolation is the point, since a reader subagent that can see the source will paper over gaps the real reader cannot. For independent questions, fan out one subagent per question in parallel. Record for each: did it answer correctly, what did it flag as ambiguous, and what knowledge did it assume the reader already has.
3. **Check for gaps.** In the same pass, have the reader subagent report what context the page assumes is already known and whether any steps contradict each other.
4. **Fix and re-run** until the reader subagent answers consistently and surfaces no new gaps.

A page passes when a reader who has never seen the product can finish the task from the page alone.

## REVIEW MODE

For a multi-page audit, the `documentation-review` workflow runs this mode as a deterministic fan-out — one read only grounding reviewer per page, a context free answerability pass per page, then a Plan agent that consolidates the findings and adds the cross-page consistency check. Reach for it when auditing a whole docs tree (`Workflow { name: "documentation-review" }`, or pass `args.docs` / `args.path` / `args.max`); review a single page inline. It is read only — it reports, it does not edit.

Audit existing docs against the source and report findings (file and line, the wrong claim, the corrected claim, the source citation). Check, in priority order:
1. **Accuracy:** does every URL, route, flag, default, allowed value, capability, and supported/not supported claim match the code? This is where the real bugs are.
2. **Invented artifacts:** identifiers, events, fields, or endpoints named in the docs that do not exist in the source.
3. **Drift:** features added, removed, or changed since the docs were written.
4. **Answerability:** run the gate above. Can the intended reader finish the task from the page alone?
5. **Internal leakage:** internal paths, flags, private endpoints, secrets, or `file:line` references that reached a customer page.
6. **Consistency:** do sibling pages share a template, terminology, and example conventions?
7. **Duplication / single source of truth (cross-page):** is any concept *defined* in full on more than one page — its why/how, default, allowed values, or logic restated rather than linked? Each concept gets one canonical page; everywhere else is a one-line cue + cross-link. Separate a real violation (a definition copied — especially copies that already disagree) from legitimate repetition: a tool-specific instantiation, a self-contained how-to's own commands, or a brief landing-page summary that links out. Flag definitions a recent change duplicated or left behind. Judge across sibling pages, not one page alone.
8. **Completeness:** missing prerequisites, missing Verify step, missing conditionals, missing audience split, missing troubleshooting entry for a known error.
9. **Wording:** passive or verbose prose, buried lead, undefined jargon, unexplained gotchas, literal secrets, a title nobody would search.

## Verification before done (both modes)
- Re-check every load bearing claim against the source you cited.
- Run the Answerability gate.
- Run whatever gates the repo enforces (markdown lint, link check, spell, secret scan). Match the repo's CI config.
- Confirm internal cross links and anchors resolve and code or commands in examples are correct.
- Confirm no literal secrets, no internal only artifact on a customer page, no placeholder left in a misleading way.
- Confirm the change did not re-define a concept that already has a canonical page; replace any copy with a one-line cue + cross-link.

## Anti-patterns (caught repeatedly in real docs)
- Organizing a page around the code's structure (subsystems, modules) instead of the reader's task.
- A title or first line that uses the internal feature name instead of the words the reader searches.
- Framing a feature by what it lacks: a "not supported: OIDC, OAuth, LDAP" list where "Supports SAML 2.0 SSO, so you connect your own identity provider" says the same as a strength.
- Leaking an internal path, flag, private endpoint, or `file:line` into a customer page.
- Jargon dumped without definition on a page a non technical reader will open.
- Trusting the existing doc's URL or scheme because it "was reviewed." Re-derive it from routing.
- Writing a default or enum from memory instead of copying it from the source.
- Documenting the happy path only and omitting the conditional that actually trips users, or shipping a feature with no troubleshooting entry for its known error.
- A reference table with no defaults and no allowed values, so it cannot be acted on.
- Mixing operator config into a developer or end user quick start.
- Prose that restates a table, or a table that should have been prose.
- Re-defining a concept that already has a canonical page (roles, a setting, proxy behavior) instead of linking to it — two copies that drift apart. (Naming it in context or a tool-specific command is fine; copying its definition is not.)

## Building and tuning this skill (optional)
Tune against real failures, not guesses. Write three scenarios this skill should pass (a setup page, a troubleshooting entry, a review that must catch an invented endpoint), run them, and add only the skill text needed to pass. The grounding fan out and the Answerability gate both run on the Task tool; if you reach for the same roles often, promote them to named subagents under `.claude/agents/` (for example a read only `docs-grounder` and a context free `docs-reader`) and have this skill call them by name.
