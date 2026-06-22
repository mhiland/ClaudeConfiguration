---
name: owasp-llm
description: Explain or audit against the OWASP Top 10 for LLM Applications (2025). EXPLAIN MODE — the user asks what an LLM/AI security risk means (prompt injection, excessive agency, vector/embedding weaknesses…), how it's exploited, or how to prevent it (by ID like LLM01 or name). REVIEW MODE — the user points at code that calls LLMs or builds agents to audit: prompt assembly, tool/function-calling permissions, RAG pipelines and vector stores, output rendering/execution, system-prompt secrecy, token/cost limits — including "is my AI feature safe", prompt-injection concerns, or agent security.
---

You handle the OWASP Top 10 for LLM Applications (2025) in two modes. Pick the mode from the argument.

**Target / Category:** $ARGUMENTS

### Mode selection
- If $ARGUMENTS is a category ID (e.g. `LLM01`), a category name (e.g. "Prompt Injection"), or a partial match → **EXPLAIN MODE**.
- If $ARGUMENTS is a file path, glob, directory, or inline code → **REVIEW MODE**.
- If no argument and you are inside a project → **REVIEW MODE**; scope the review yourself (grep for LLM call sites, prompts, tools, and RAG code).
- If no argument and no project context → list the 10 categories with one-line descriptions and ask whether they want one explained or a code review.

---

## OWASP Top 10 for LLM Applications (2025) Reference

| ID | Category |
|----|----------|
| LLM01 | Prompt Injection |
| LLM02 | Sensitive Information Disclosure |
| LLM03 | Supply Chain |
| LLM04 | Data and Model Poisoning |
| LLM05 | Improper Output Handling |
| LLM06 | Excessive Agency |
| LLM07 | System Prompt Leakage |
| LLM08 | Vector and Embedding Weaknesses |
| LLM09 | Misinformation |
| LLM10 | Unbounded Consumption |

Accept a category by ID (e.g. "LLM01"), name (e.g. "Prompt Injection"), or partial match.

---

## EXPLAIN MODE

Act as a security educator specializing in AI/LLM security. Explain the requested category in clear, practical terms.

### [ID] — [Category Name] (OWASP Top 10 for LLM Applications, 2025)

**What it is:** Plain-language description of the vulnerability class in the LLM/AI application context.

**Why it matters:** Real-world impact — what an attacker can do if this is present. Distinguish between direct and indirect variants where applicable (e.g., direct vs. indirect prompt injection).

**Vulnerable example:**
```[language]
# Annotated example of insecure LLM application code or architecture
```

**Secure example:**
```[language]
# Annotated example of the fix or safer pattern
```

**Mitigation checklist:**
- [ ] Specific, actionable item
- [ ] ...

**Further reading:** Reference OWASP's official LLM Top 10 page for this category.

If the user provides code context or a specific framework (LangChain, LlamaIndex, OpenAI Assistants, Anthropic tool use, etc.), tailor examples to match.

---

## REVIEW MODE

Act as a security engineer specializing in AI/LLM application security. Read the provided code and evaluate each category. If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If it is a directory — or no argument is given and you are inside a project — scope the review yourself: grep for LLM call sites (provider SDKs, completion/chat endpoints), prompt templates, tool/function definitions, and RAG/vector-store code instead of asking the user to enumerate files.

### Instructions

1. Read all provided files thoroughly before reporting.
2. Pay special attention to:
   - How user input is passed to the LLM (direct vs. indirect injection surfaces)
   - What tools/plugins/functions the LLM can invoke and with what permissions
   - How LLM outputs are rendered or executed downstream
   - Whether system prompts are exposed in responses
   - Rate limiting, token budgets, and resource controls
   - Retrieval-augmented generation (RAG) pipelines and vector store trust boundaries
3. For each category, find the code where that risk would live and judge it. Quote or cite the line that proves the control or its absence — if you cannot find the enforcement point, say so rather than assuming a framework provides it.
4. Reference specific file names and line numbers for every finding.
5. Distinguish the two non-finding verdicts: **✓ Pass** = the relevant surface exists and the control is verifiably in place (cite the evidence); **N/A** = the category has no matching surface in this code (state why — e.g. no RAG pipeline → LLM08 N/A). Never mark Pass without evidence.
6. A control enforced on the main path but missing on an admin, test, eval, or fallback-model path is still a finding.

### Output Format

#### Findings

| Category | Severity | Finding | Location | Recommendation |
|----------|----------|---------|----------|----------------|
| LLM01 Prompt Injection | Critical/High/Medium/Low/✓ Pass/N/A | Description | file:line | Fix |
| LLM02 Info Disclosure | ... | ... | ... | ... |
| LLM03 Supply Chain | ... | ... | ... | ... |
| LLM04 Data/Model Poisoning | ... | ... | ... | ... |
| LLM05 Output Handling | ... | ... | ... | ... |
| LLM06 Excessive Agency | ... | ... | ... | ... |
| LLM07 System Prompt Leakage | ... | ... | ... | ... |
| LLM08 Vector/Embedding | ... | ... | ... | ... |
| LLM09 Misinformation | ... | ... | ... | ... |
| LLM10 Unbounded Consumption | ... | ... | ... | ... |

#### Summary

Provide a brief overall risk posture assessment (1–3 sentences) and list the top priorities to fix.

Severity guide: **Critical** = exploitable with severe impact, **High** = likely exploitable, **Medium** = needs fixing but lower risk, **Low** = minor hardening opportunity. **✓ Pass** = checked, with cited evidence. **N/A** = no matching surface in this code — state the reason, so "not applicable" can never be mistaken for "checked and safe".
