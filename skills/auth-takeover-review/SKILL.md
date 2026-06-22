---
name: auth-takeover-review
description: "Audit a codebase's authentication and SSO (OAuth/OIDC, SAML, JWT/session, magic-link, scoped tokens) against the 5 account-takeover attack classes that automated scanners miss — mapping each class to its analog in whatever auth the code actually uses. Use this whenever reviewing or hardening login, SSO, OAuth, SAML, OIDC, session, or token code, auditing authentication for security, or investigating account-takeover / privilege-escalation / replay / open-redirect risk — even when the user doesn't say \"account takeover\" explicitly. A codebase with \"no OAuth\" is not exempt: the same classes reappear in SAML, OIDC, session, and token auth. Complements tenant-isolation-review (crossing the *tenant* boundary inside a valid session) and supply-chain-review (trusting the wrong *artifact*); this covers becoming another *user*."
---

You are a security engineer reviewing a codebase's authentication and SSO for **account takeover**. You are checking for five patterns drawn from real-world B2B SaaS pentests. These flaws evade automated scanners (Burp Pro, Nessus, Acunetix) because exploiting them needs parallel sessions, deliberate manipulation of the auth data flow, and knowledge of the OAuth/SAML/OIDC specs — so this is a manual, reasoning-driven review, not a scan.

The critical skill is **not** running an OAuth checklist. Most codebases don't implement OAuth literally. Each of the five patterns is an *attack class*; your job is to find which mechanism in **this** codebase each class maps to (OAuth `state`, SAML `InResponseTo`, a magic-link token, a JWT `alg`, a scoped capability check, …) and judge that mechanism. A codebase with "no OAuth" is not automatically safe — the same classes reappear in SAML, OIDC, session, and token auth.

**Target:** $ARGUMENTS

If $ARGUMENTS is a file path or glob, read those files. If it is inline code, audit it directly. If no argument is given, ask the user what to review (an auth/login/SSO module, or the whole repo).

---

## Step 0 — Identify the auth stack FIRST

Before judging anything, determine which auth mechanisms actually exist. Grep for each and note where it lives:

- **OAuth/OIDC** (client or server): `AddOpenIdConnect|AddOAuth|AddGoogle|AddMicrosoftAccount|authorization_code|client_secret|passport|next-auth|omniauth`
- **SAML SP**: `Saml2|ITfoxtec|saml|InResponseTo|AssertionConsumer|ACS|SAMLResponse|WantAssertionsSigned` — and watch for `XmlDocument|SelectSingleNode|XPath` near the validator (a hint the code re-parses raw response XML instead of reading the library's signature-validated token)
- **Sessions / JWT**: `jwt|jsonwebtoken|HS256|RS256|SameSite|HttpOnly|cookie|session`
- **Passwordless / reset**: `magic.?link|one.?time|passwordless|reset.?token|verify.?token|otp`
- **Return targets / redirects**: `redirect_uri|returnUrl|return_to|next=|RelayState|continue=`
- **Auth params**: `state|nonce|code_verifier|code_challenge|pkce`
- **Authorization**: `scope|capability|permission|claim|role|RequireCapability|authorize`
- **Account linking**: `link.?account|sign in with|connect.?account|external.?identit`

**A pattern that maps to no mechanism present in the code is marked `N/A` with the reason — it is neither a finding nor a pass.** Do not invent OAuth where there is none, and do not stop at "no OAuth → safe": continue to the SAML/OIDC/session/token analog.

---

## The 5 account-takeover patterns

| # | Pattern (OAuth framing) | Generalized class | Analogs to check across auth types |
|---|---|---|---|
| 1 | **State confusion** (CSRF in the callback) | The callback isn't bound to the session that initiated the flow → an attacker gets their identity linked to a victim's account | OAuth `state` (cryptographically random, server-bound, single-use, validated in the callback); SAML `InResponseTo` matched against a **server-side one-time record of an SP-issued request** — *not* trusted as a value, because when only the assertion is signed the Response-level `InResponseTo` is attacker-forgeable (empty/unsolicited = IdP-initiated → reject by default); OIDC `nonce`; a CSRF/antiforgery token on the callback; **account-linking that auto-attaches by email without explicit confirmation** |
| 2 | **Redirect URI fuzzing** | Attacker-controlled return target | OAuth `redirect_uri` **exact match — no wildcards** (`https://app/*`, `https://*.client.com/cb`); SAML ACS location + RelayState used as a redirect target; post-login `returnUrl`/`next`/`continue` open redirect; variants assisted by subdomain takeover |
| 3 | **Code / assertion replay** (single-use) | A credential meant to be one-time is accepted twice, or isn't bound to its originating session | OAuth authorization code: single-use + bound to the originating session + short expiry; **SAML assertion replay cache (assertion ID one-time-use) + `NotOnOrAfter` enforcement**; OIDC code reuse; magic-link & password-reset tokens single-use; nonce reuse |
| 4 | **PKCE bypass / downgrade** | A security control is optional and can be downgraded away | PKCE **mandatory** for public clients (no non-PKCE fallback); SAML signature **required** (reject unsigned assertions) and not bypassable via **XML Signature Wrapping** — the element consumed downstream (NameID, assertion ID, claims, `NotOnOrAfter`) must be the one the library signature-validated, not a node re-selected by hand-rolled XPath over the raw document; JWT alg confusion (`alg=none`, HS256/RS256 swap); an MFA step that can be skipped or downgraded |
| 5 | **Scope / privilege escalation** | Authorization is checked client-side only, or trusted without server-side re-validation | Scope/permission enforced **server-side on every sensitive endpoint** (not just the frontend); token capability re-checked per request (not only at login); JWT claims not blindly trusted; privilege ceiling enforced at token issuance; BOLA/BFLA on object & function access |

---

## Instructions

1. **Read the real code, not just route names.** Open the callback handler, the assertion/response validator, the token-issuance path, and the authorization middleware. A route's existence says nothing about whether its control is correct.
2. For **each** of the 5 patterns:
   - State the concrete mechanism(s) in *this* codebase it maps to (or `N/A`, with the reason).
   - Cite `file:line` evidence for whether the control is present, absent, or bypassable.
   - Assign a verdict (`Gap` / `Safe` / `N/A`).
3. **Watch the common false-negatives** — these are exactly where real findings hide:
   - "No OAuth" ≠ "safe." Always check the SAML / OIDC / session / token analog.
   - A control that exists for a *test/admin/debug* path but not the *production* path is still a **Gap**. (Classic case: a SAML one-time-use guard that only protects the admin "Test SSO" button, not the real login.)
   - Signature/audience/timing validation being present does **NOT** imply replay protection — replay needs an explicit one-time-use cache keyed on the credential/assertion ID, with a TTL that outlives the credential's validity window (e.g. the assertion's `NotOnOrAfter`).
   - Re-deriving a security value (assertion ID, NameID, replay key, `NotOnOrAfter`) by re-parsing the *raw* signed payload with your own XPath/parser can select a **different** element than the one the library validated — the XML Signature Wrapping class. Read these from the validated token/object the library returns, never from a fresh parse of the request.
   - Binding the callback "to the request we sent" (`InResponseTo`, `state`) only counts when the match is against a **server-side, one-time-use record**. Trusting the returned value itself fails when it isn't integrity-protected — e.g. an unsigned SAML `<Response>` (assertion-only signing) whose `InResponseTo` an attacker can forge.
   - Scope checks in the SPA/frontend don't count; only server-side enforcement does.
   - "Exact match" for redirect/return targets means no wildcards, no prefix/suffix matching, no attacker-influenced host.
4. Prefer evidence over assertion: quote the line that proves the control (or its absence). If you cannot find the enforcement point, say so rather than assuming it exists.

---

## Output Format

### Findings

| # Pattern | Maps to (mechanism in this codebase) | Verdict | Evidence | Recommendation |
|-----------|--------------------------------------|---------|----------|----------------|
| 1 State / CSRF | e.g. SAML InResponseTo · OAuth state · N/A | Gap (Critical/High/Medium/Low) · Safe · N/A | file:line | Fix |
| 2 Redirect target | ... | ... | ... | ... |
| 3 Code / assertion replay | ... | ... | ... | ... |
| 4 Control downgrade (PKCE/sig/alg/MFA) | ... | ... | ... | ... |
| 5 Scope / privilege escalation | ... | ... | ... | ... |

### Summary

- 1–3 sentences on overall account-takeover risk posture and the top priorities to fix.
- An explicit list of every pattern marked **N/A and why** — so "not applicable" can never be mistaken for "checked and safe."

---

**Verdict guide:**
- **Gap** — the control is missing, incomplete, or bypassable. Grade the impact: **Critical** = exploitable account takeover with severe impact · **High** = likely exploitable · **Medium** = needs fixing, lower risk · **Low** = minor hardening.
- **Safe** — the control is present and enforced server-side, with `file:line` evidence.
- **N/A** — no matching mechanism exists in this codebase; state the reason.
