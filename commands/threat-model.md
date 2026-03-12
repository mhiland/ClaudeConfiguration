---
name: threat-model
description: STRIDE-based threat modeling and security architecture analysis
author: Claude Code Enhanced Setup
version: 2.0
category: security
---

# Threat Model -- STRIDE-Based Code Analysis

Perform a code-based threat model of this project using the STRIDE methodology. This analysis is scoped to what can be determined from source code, configuration, and infrastructure-as-code. It is not a substitute for a full threat model involving stakeholder interviews, network diagrams, and runtime analysis.

## Step 1: Identify Components

Search the codebase to build an inventory of security-relevant components:

- **API endpoints**: Read route definitions (FastAPI, Flask, Express, etc.) and list all exposed endpoints with their HTTP methods and authentication requirements.
- **Authentication and authorization**: Find auth mechanisms (tokens, sessions, API keys, OAuth, RBAC). Note where auth is enforced and where it is absent.
- **Database connections**: Identify database drivers, connection strings, ORM models, and raw query usage. Check for parameterized queries vs string interpolation.
- **External integrations**: Find outbound HTTP calls, message queues, third-party SDKs, and webhook handlers.
- **Configuration and secrets**: Check environment variable usage, config files, .env files, and whether secrets are hardcoded or properly externalized.
- **Docker and infrastructure**: Read Dockerfiles, compose files, and deployment configs for capability grants, exposed ports, volume mounts, and network modes.
- **Input entry points**: Identify all places user-supplied data enters the system (HTTP bodies, query params, file uploads, CLI args, system command inputs).

## Step 2: Map Data Flows

Trace how data moves through the system by reading the actual code:

- User input to validation to processing to storage
- Authentication credential flow (login to token issuance to verification)
- Sensitive data paths (where sensitive data is read, transformed, stored, and displayed)
- Inter-service communication (protocols, encryption, trust assumptions)
- Logging paths (what is logged, where logs are stored, whether sensitive data is logged)

## Step 3: Apply STRIDE to Each Component

For each component and data flow identified, systematically evaluate:

- **Spoofing**: Can an attacker impersonate a user, service, or component? Are authentication checks present and correct?
- **Tampering**: Can data be modified in transit or at rest without detection? Is input validated? Are integrity checks in place?
- **Repudiation**: Can actions be performed without accountability? Is audit logging sufficient? Can logs be tampered with?
- **Information Disclosure**: Can sensitive data leak through error messages, logs, API responses, or side channels? Is encryption used where needed?
- **Denial of Service**: Are there rate limits? Can resources be exhausted? Are there unbounded queries or file operations?
- **Elevation of Privilege**: Can a low-privilege user access admin functionality? Are authorization checks enforced at every layer?

## Step 4: Produce Threat Assessment Report

Output the findings using this structure:

### 4a. Component Inventory

List each component found in Step 1 with a one-line description and its trust boundary (e.g., external-facing, internal-only, database tier).

### 4b. Data Flow Summary

Describe each significant data flow found in Step 2 in one to two sentences.

### 4c. Threat Matrix

Present findings as a markdown table:

| # | Component | STRIDE | Threat Description | Risk | Status | Recommendation |
|---|-----------|--------|--------------------|------|--------|----------------|
| 1 | Example endpoint | T | No input validation on user-supplied JSON body | High | Unmitigated | Add Pydantic model validation |

Column definitions:
- **#**: Sequential identifier
- **Component**: The specific component, endpoint, or data flow
- **STRIDE**: One of S, T, R, I, D, E
- **Threat Description**: Concrete description of the threat based on code evidence
- **Risk**: Critical, High, Medium, or Low (based on exploitability and impact)
- **Status**: Mitigated, Partially Mitigated, or Unmitigated
- **Recommendation**: Specific, actionable fix referencing code patterns or libraries

### 4d. Summary

- Total threats found, grouped by risk level
- Top 3 priorities requiring immediate attention
- Overall security posture assessment (one paragraph)

## Constraints

- Only report threats you can substantiate with code evidence. Do not speculate about runtime behavior you cannot verify from source.
- Reference specific file paths and line numbers when possible.
- If a threat category has no findings for a component, skip it rather than padding with generic advice.
- Keep the report actionable. Every recommendation should be something a developer can implement.
