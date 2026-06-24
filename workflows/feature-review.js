export const meta = {
  name: 'feature-review',
  description: 'Scoped feature/frontend review: parallel frontend + backend scouts → a Plan agent that synthesizes the gaps into MR-sized tickets and an implementation plan.',
  whenToUse: 'The backend grew capabilities the frontend/dashboard has not caught up to (or any scoped "inventory the gaps then plan it" review). Pass the focus area via args.',
  phases: [
    { title: 'Scout', detail: 'frontend + backend inventory scouts, in parallel (read-only)' },
    { title: 'Synthesize', detail: 'one Plan agent merges both inventories into tickets + a plan' },
  ],
}

// Optional focus passed as the Workflow `args` value, e.g.
//   { focus: 'new Go/Cargo ecosystems missing from dashboard, search dropdowns, settings' }
const focus = (args && args.focus) ||
  'frontend/dashboard surfaces that are stale relative to recently-added backend capabilities'

const frontendScout = () => agent(
  `Explore the frontend of this repository (operate in the current working directory; typical roots: ` +
  `web/src, src, app). Search breadth: very thorough. Read-only.\n\n` +
  `Focus: ${focus}\n\n` +
  `Produce a precise inventory with file paths and line numbers:\n` +
  `1. Every place the frontend hardcodes or enumerates a domain set (e.g. ecosystems, categories) — ` +
  `dropdowns, filters, search, dashboard — give the exact list at each site.\n` +
  `2. The dashboard/overview page: what metrics/cards it shows, the chart color source, the per-item color ` +
  `mapping used elsewhere (badges), whether tables render zero-count rows, and what any time-windowed ` +
  `label actually measures + which API feeds it.\n` +
  `3. The settings page(s): what is configurable today, especially per-item proxy/upstream, limits, toggles.\n` +
  `4. Any shared constants module vs. per-page duplication.\n\n` +
  `Be concrete: file paths, line numbers, exact arrays/maps. Your final text is data for the orchestrator.`,
  { label: 'scout:frontend', phase: 'Scout', agentType: 'Explore' }
)

const backendScout = () => agent(
  `Explore the backend of this repository (operate in the current working directory; typical roots: src, ` +
  `server, api). Search breadth: very thorough. Read-only.\n\n` +
  `Context: the frontend is stale — capabilities were added backend-only. Focus: ${focus}\n\n` +
  `Produce an inventory of backend capabilities that likely have NO UI, with file paths and key names:\n` +
  `1. The full domain set the backend now supports (controllers, normalizers, source mappings) and routes.\n` +
  `2. Operator endpoints whose behavior isn't surfaced in the UI — quote the controlling setting/env var.\n` +
  `3. Settings columns/keys (schema) and which the management API exposes; flag recent ones with no UI.\n` +
  `4. The management API surface for dashboard-type stats — what the stats endpoint returns, and any ` +
  `counters not yet shown.\n` +
  `5. Distinguish env-var-only deploy-time config (not UI material) from DB-backed settings (UI material).\n\n` +
  `Be concrete: file paths, line numbers, setting key names. Your final text is data for the orchestrator.`,
  { label: 'scout:backend', phase: 'Scout', agentType: 'Explore' }
)

// ---- Phase: Scout (parallel barrier — the planner needs BOTH inventories at once) ----
phase('Scout')
const [frontend, backend] = await parallel([frontendScout, backendScout])

// ---- Phase: Synthesize (single Plan agent over the verified facts) ----
phase('Synthesize')
const plan = await agent(
  `Design an implementation plan for closing frontend/backend gaps in this repository (operate in the ` +
  `current working directory). Read CLAUDE.md (if present) for the conventions/compliance gates you must ` +
  `respect.\n\n` +
  `Use these VERIFIED inventories — do NOT re-explore broadly, only design:\n\n` +
  `### Frontend inventory\n${frontend}\n\n### Backend inventory\n${backend}\n\n` +
  `Deliver:\n` +
  `1. A short list of MR-sized tranches (as few as possible) — for each: title, the gap it closes, the ` +
  `exact files to touch, and whether it needs schema/contract-gate steps.\n` +
  `2. A concrete step-by-step plan for the highest-value tranche (exact files, any color/label/i18n values, ` +
  `the stats-shape change with snapshot/serialization details, test impact).\n` +
  `Keep it tight — substance, not re-justification. Your final text is data for the orchestrator.`,
  { label: 'synthesize:plan', phase: 'Synthesize', agentType: 'Plan' }
)

return { focus, frontendInventory: frontend, backendInventory: backend, plan }
