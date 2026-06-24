export const meta = {
  name: 'documentation-review',
  description: 'Audit existing documentation against the source code (the `documentation` skill, REVIEW mode) as a fan-out: one read-only grounding reviewer per page checks every factual claim against the code, a fresh cold-reader runs the answerability gate on each page, then a Plan agent consolidates findings (incl. the cross-page consistency check) into a prioritized report. Read-only — reports, does not edit.',
  whenToUse: 'Audit a set of docs (or a whole docs tree) for accuracy, drift, invented artifacts, internal leakage, duplication / single source of truth, completeness, and answerability. Stack-agnostic: operates in the current working directory by default, or pass args.root to review an external docs tree and args.source to ground accuracy against a separate source repo. Pass pages via args.docs (array of paths), narrow discovery with args.path, or let it discover them; cap with args.max (default 40). Billed multi-agent fan-out.',
  phases: [
    { title: 'Discover', detail: 'enumerate the documentation pages to review (skipped if args.docs given)' },
    { title: 'Audit', detail: 'one read-only grounding reviewer per page (claims vs source)' },
    { title: 'Answerability', detail: 'a fresh cold-reader runs the answerability gate per page' },
    { title: 'Synthesize', detail: 'one Plan agent consolidates findings + the cross-page consistency check' },
  ],
}

const MAX_PAGES = (args && Number.isInteger(args.max) && args.max > 0) ? args.max : 40

// Optional. By default the workflow operates in the current working directory. Set args.root to
// review a docs tree in a DIFFERENT repo (discovery enumerates it and returns absolute paths, so
// the audit/answerability/synthesis agents read it regardless of cwd). Set args.source to ground
// accuracy/drift findings against a separate source-code repo (e.g. docs and code live apart).
const ROOT = (args && typeof args.root === 'string' && args.root) ? args.root : null
const SOURCE = (args && typeof args.source === 'string' && args.source) ? args.source : null

const PAGES_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['pages'],
  properties: {
    pages: { type: 'array', items: { type: 'string' }, description: 'doc page file paths relative to repo root, most important first' },
    truncated: { type: 'boolean' },
    note: { type: 'string' },
  },
}

// Per-page grounding audit — the priority order is the documentation skill's REVIEW checklist.
const AUDIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['docFile', 'docLine', 'category', 'severity', 'claim', 'correction', 'source', 'confidence'],
        properties: {
          docFile: { type: 'string' },
          docLine: { type: 'integer' },
          category: { type: 'string', enum: ['accuracy', 'invented-artifact', 'drift', 'internal-leakage', 'duplication', 'completeness', 'wording'] },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          claim: { type: 'string', description: 'the doc text, quoted verbatim' },
          correction: { type: 'string', description: 'the true statement that matches the code' },
          source: { type: 'string', description: 'code file:line backing the correction (empty for pure wording findings)' },
          confidence: { type: 'string', enum: ['confirmed', 'suspected'] },
        },
      },
    },
    groundedSafe: { type: 'array', items: { type: 'string' }, description: 'one line each: claim checked and found correct, with source citation' },
  },
}

const ANSWERABILITY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['page', 'questions', 'gaps', 'verdict'],
  properties: {
    page: { type: 'string' },
    questions: { type: 'array', items: { type: 'string' }, description: '5-10 questions the intended reader arrives with' },
    gaps: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['question', 'answerable', 'problem'],
        properties: {
          question: { type: 'string' },
          answerable: { type: 'boolean' },
          problem: { type: 'string', description: 'what is missing/ambiguous when not answerable' },
        },
      },
    },
    assumedKnowledge: { type: 'array', items: { type: 'string' }, description: 'context the page assumes the reader already has' },
    verdict: { type: 'string', enum: ['answerable', 'gaps-found'] },
  },
}

function auditPrompt(page) {
  return `You are auditing ONE documentation page against the actual source code, in the discipline of the \`documentation\` skill's REVIEW mode. READ-ONLY — do not edit anything.

Page to audit: ${page}
${SOURCE ? `The product SOURCE CODE is at ${SOURCE} — read it there to ground accuracy / drift / invented-artifact claims (it is NOT the current working directory).` : `Find the source of truth in the current working directory's code (routing, config, handlers, schema).`}

1. Read the page in full.
2. For EVERY factual claim — a URL/route/path, a flag, a default, an allowed-value set / enum, a capability string, a limit, a "supported / not-supported" statement, or a named identifier/event/field/endpoint — find the source of truth in the code (routing, config, handlers, schema) and verify it. Quote the doc line and cite the code as file:line. Prior docs are a hypothesis, not ground truth.
3. Report findings in this priority order (highest first):
   - accuracy — the claim contradicts the code (wrong URL/route/flag/default/allowed value/capability/supported claim). This is where the real bugs are.
   - invented-artifact — an identifier/event/field/endpoint named in the doc that does not exist in the source.
   - drift — a feature added/removed/changed since the doc was written.
   - internal-leakage — an internal path, private/unreleased endpoint, feature flag, secret, ticket number, or raw file:line citation that reached a reader-facing page.
   - duplication (mark confidence=suspected) — this page DEFINES a portable concept in full (its why/how, default, allowed values, or logic) that likely has, or should have, a single canonical home on another page; raise it as a single-source-of-truth candidate for the synthesizer to confirm across pages. Do NOT flag a tool-specific instantiation ("npm sends a Bearer credential"), a self-contained how-to's own command/URL/verify step, or the mere naming of a concept — those legitimately repeat. You are blind to the other pages, so this is always suspected, never confirmed.
   - completeness — a missing prerequisite, missing Verify step, a conditional that actually trips users but is undocumented, or a missing audience split.
   - wording — buried lead, passive/verbose prose, undefined jargon, a literal secret in an example, a title nobody would search.

For each finding return: docFile, docLine, category, severity (critical/high/medium/low), claim (the doc text quoted verbatim), correction (the true statement that matches the code), source (code file:line backing the correction — leave empty only for pure wording findings), confidence (confirmed = you read the code and it contradicts the doc; suspected = needs runtime confirmation).

Ground every finding — discard anything you cannot tie to the code. Also return groundedSafe: claims you checked and found correct, one line each with the source citation (stated coverage is a valid result). Your final message is data for the orchestrator, not a user-facing message.`
}

function answerabilityPrompt(page) {
  return `You are running the Answerability gate from the \`documentation\` skill on ONE page. Simulate a FRESH reader who has only this page: read ONLY ${page} — do NOT read the source code or any other page (the author always knows too much; the point is to test what the page alone conveys). READ-ONLY.

1. Read the page.
2. Predict 5-10 questions the intended reader would realistically arrive with, or type into search to land on this page (their words and goals, not subsystem names).
3. For each question, judge whether the page ALONE answers it correctly and unambiguously.
4. List any knowledge the page assumes the reader already has, and any steps that contradict each other.

Return: page, questions, gaps [{question, answerable, problem}], assumedKnowledge, verdict (answerable if a reader who has never seen the product could finish the task from this page alone; otherwise gaps-found). Your final message is data for the orchestrator.`
}

// ---- Phase: Discover the pages to review (skipped when args.docs is provided) ----
phase('Discover')
let pages = (args && Array.isArray(args.docs) && args.docs.length) ? args.docs.slice() : null
let discoveryNote = null
if (!pages) {
  const path = args && args.path
  const focus = args && args.focus
  const discovery = await agent(
    `Read-only. Enumerate the human-facing documentation pages in ${ROOT ? ROOT : 'this repository (operate in the current working directory)'}.` +
    (path ? ` Restrict to: ${path}.` : '') +
    (focus ? ` Focus on pages about: ${focus}.` : '') +
    `\n\nTypical locations: docs/, doc/, a docs site under website/ or site/, README.md and other *.md at the root. INCLUDE reader-facing guides, setup/getting-started pages, how-tos, troubleshooting/error reference, FAQs, READMEs, and API/config/CLI reference. EXCLUDE source code, auto-generated changelogs, license files, node_modules, and vendored/third-party docs.\n\n` +
    `Return ${ROOT ? 'ABSOLUTE' : 'repo-root-relative'} page file paths, most important first. If there are more than ${MAX_PAGES}, return the ${MAX_PAGES} most important and set truncated=true with a one-line note on what was left out. Your final message is data for the orchestrator.`,
    { label: 'discover:pages', phase: 'Discover', agentType: 'Explore', schema: PAGES_SCHEMA }
  )
  pages = (discovery && discovery.pages) || []
  if (discovery && discovery.truncated) discoveryNote = discovery.note || `discovery truncated to the top ${MAX_PAGES} pages`
}

// Cap defensively even when pages came from args — and log what was dropped (no silent caps).
if (pages.length > MAX_PAGES) {
  discoveryNote = `capped ${pages.length} pages to the first ${MAX_PAGES} (raise args.max to cover more)`
  pages = pages.slice(0, MAX_PAGES)
}
log(`Reviewing ${pages.length} documentation page(s)${discoveryNote ? ` — ${discoveryNote}` : ''}.`)
if (pages.length === 0) {
  return { scanned: [], perPage: [], report: 'No documentation pages found to review. Pass them via args.docs or narrow with args.path.' }
}

// ---- Phase: Audit → Answerability (pipeline — each page grounds, then faces the cold-reader) ----
const perPage = (await pipeline(
  pages,
  (page) => agent(auditPrompt(page), { label: `audit:${page}`, phase: 'Audit', agentType: 'Explore', schema: AUDIT_SCHEMA })
    .then((audit) => ({ page, audit })),
  ({ page, audit }) => agent(answerabilityPrompt(page), { label: `answerable:${page}`, phase: 'Answerability', agentType: 'Explore', schema: ANSWERABILITY_SCHEMA })
    .then((gate) => ({ page, audit, gate }))
)).filter(Boolean)

const totalFindings = perPage.reduce((n, p) => n + ((p.audit && p.audit.findings) || []).length, 0)
const notAnswerable = perPage.filter((p) => p.gate && p.gate.verdict === 'gaps-found').map((p) => p.page)
log(`${perPage.length} pages audited: ${totalFindings} grounding findings; ${notAnswerable.length} page(s) failed the answerability gate.`)

// ---- Phase: Synthesize (single Plan agent — consolidates + runs the cross-page consistency check) ----
phase('Synthesize')
const sections = perPage.map((p) => {
  const findings = JSON.stringify((p.audit && p.audit.findings) || [], null, 2)
  const gate = JSON.stringify(p.gate || {}, null, 2)
  return `### ${p.page}\n\n**Grounding findings**\n${findings}\n\n**Answerability gate**\n${gate}`
}).join('\n\n')

const report = await agent(
  `You are synthesizing a documentation REVIEW (the \`documentation\` skill, REVIEW mode) for this repository (operate in the current working directory). ` +
  `${perPage.length} page(s) were each audited for grounding accuracy against the source and run through the Answerability gate. Their structured results follow. ` +
  `Do NOT re-audit the accuracy findings — consolidate them. You MAY read the pages themselves to perform the TWO cross-page checks the per-page agents could not: (a) consistency across sibling pages (a shared template/skeleton per content type, consistent terminology, and consistent example conventions such as the placeholder host and URL form); and (b) single source of truth — the same concept DEFINED in full (its why/how, default, allowed values, or logic) on more than one page, where everywhere but the canonical page should be a one-line cue + cross-link.\n\n` +
  `${sections}\n\n` +
  `Deliver:\n` +
  `1. A prioritized findings table across all pages, ordered by the skill's priority: accuracy → invented-artifact → drift → internal-leakage → consistency → duplication → completeness → wording. For each: page:line, category, severity, the wrong claim, the correction, the source citation.\n` +
  `2. Cross-page consistency findings (templates/terminology/example conventions that diverge between sibling pages), naming the pages involved.\n` +
  `3. A single source of truth section: concepts DEFINED on multiple pages — for each, the pages that define it, the one canonical page it should live on, and which copies to reduce to a cue + cross-link. Confirm or reject the per-page "suspected duplication" candidates by checking them against the other pages. EXPLICITLY separate real violations (a definition copied — especially copies that already disagree) from legitimate parallel-page repetition (a tool-specific instantiation, a self-contained how-to's own command/URL/verify step, or a brief landing-page summary that links out) — do not report the legitimate cases as findings.\n` +
  `4. An answerability summary: which pages a fresh reader cannot complete the task from, and the specific gaps to close.\n` +
  `5. A short "already accurate / well-structured" list so those don't regress.\n` +
  `Keep it tight — substance, not re-justification. Your final text is data for the orchestrator.`,
  { label: 'synthesize:report', phase: 'Synthesize', agentType: 'Plan' }
)

return {
  scanned: pages,
  perPage,
  totalFindings,
  notAnswerable,
  report,
}
