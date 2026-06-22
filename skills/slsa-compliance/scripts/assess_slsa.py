#!/usr/bin/env python3
"""Heuristic SLSA Build-level scanner for GitHub Actions workflows.

Usage:
    python3 assess_slsa.py <repo-root-or-workflows-dir> [--json]

Reports, per workflow under .github/workflows/, the deterministic signals that
bear on the SLSA Build track: provenance/signing actions, OIDC + attestation
permissions, npm --provenance, hosted vs self-hosted runners, and whether added
third-party actions are pinned to a commit SHA vs a mutable tag. Prints a
heuristic suggested Build level per workflow and overall.

This is INPUT TO JUDGMENT, not a verdict. A matched action name does not prove
every released artifact is attested in the job that ships it — the skill must
read the workflow and confirm that. Use this to find leads fast.

Exit code 0 = no gaps in the heuristic, 1 = gaps found, 2 = usage/parse error.
No third-party dependencies; lightweight line scan (no YAML parser needed).
"""
import json
import os
import re
import sys

# --- signal patterns (line-level; case-insensitive where sensible) -----------

RE_ATTEST_PROV = re.compile(r"uses:\s*actions/attest-build-provenance@", re.I)
RE_ATTEST_GENERIC = re.compile(r"uses:\s*actions/attest@", re.I)
RE_SLSA_GENERATOR = re.compile(r"uses:\s*slsa-framework/slsa-github-generator", re.I)
RE_IDTOKEN = re.compile(r"\bid-token:\s*write\b", re.I)
RE_ATTESTATIONS = re.compile(r"\battestations:\s*write\b", re.I)
RE_NPM_PROVENANCE = re.compile(r"npm\s+publish[^\n]*--provenance|--provenance\b", re.I)
RE_RUNS_ON = re.compile(r"runs-on:\s*(.+)", re.I)
RE_USES = re.compile(r"uses:\s*([^\s#]+)")
RE_PUBLISH = re.compile(
    r"\b(npm\s+publish|docker/build-push-action|push-to-registry|"
    r"gh-action-pypi-publish|action-gh-release|gh release upload|"
    r"upload-assets|push:\s*true)\b", re.I)

SHA_RE = re.compile(r"^[0-9a-f]{40}$")
SELF_HOSTED_RE = re.compile(r"self-hosted", re.I)
HOSTED_RE = re.compile(r"\b(ubuntu|windows|macos)-", re.I)


def find_workflows(target):
    """Return a list of workflow file paths from a repo root or workflows dir."""
    if os.path.isfile(target):
        return [target]
    candidates = []
    wf_dir = target
    if not target.rstrip("/").endswith(os.path.join(".github", "workflows")):
        maybe = os.path.join(target, ".github", "workflows")
        if os.path.isdir(maybe):
            wf_dir = maybe
    if not os.path.isdir(wf_dir):
        return []
    for name in sorted(os.listdir(wf_dir)):
        if name.endswith((".yml", ".yaml")):
            candidates.append(os.path.join(wf_dir, name))
    return candidates


def scan_uses(line):
    """Return (action_ref, is_third_party, is_pinned_to_sha) for a `uses:` line."""
    m = RE_USES.search(line)
    if not m:
        return None
    ref = m.group(1)
    if ref.startswith(("./", "docker://")):
        return None  # local / docker action — pinning N/A
    owner = ref.split("/", 1)[0]
    is_third_party = owner not in ("actions", "github")
    pin = ref.split("@", 1)[1] if "@" in ref else ""
    return (ref, is_third_party, bool(SHA_RE.match(pin)))


def analyze_file(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()

    sig = {
        "attest_build_provenance": [],
        "attest_generic": [],
        "slsa_generator": [],
        "id_token_write": [],
        "attestations_write": [],
        "npm_provenance": [],
        "self_hosted_runner": [],
        "hosted_runner": [],
        "publishes_artifact": [],
        "unpinned_third_party_actions": [],
    }
    for i, line in enumerate(lines, 1):
        if RE_ATTEST_PROV.search(line):
            sig["attest_build_provenance"].append(i)
        if RE_ATTEST_GENERIC.search(line):
            sig["attest_generic"].append(i)
        if RE_SLSA_GENERATOR.search(line):
            sig["slsa_generator"].append(i)
        if RE_IDTOKEN.search(line):
            sig["id_token_write"].append(i)
        if RE_ATTESTATIONS.search(line):
            sig["attestations_write"].append(i)
        if RE_NPM_PROVENANCE.search(line):
            sig["npm_provenance"].append(i)
        if RE_PUBLISH.search(line):
            sig["publishes_artifact"].append(i)
        m = RE_RUNS_ON.search(line)
        if m:
            val = m.group(1)
            if SELF_HOSTED_RE.search(val):
                sig["self_hosted_runner"].append(i)
            elif HOSTED_RE.search(val):
                sig["hosted_runner"].append(i)
        u = scan_uses(line)
        if u and u[1] and not u[2]:
            sig["unpinned_third_party_actions"].append((i, u[0]))

    level, reason = heuristic_level(sig)
    return {"file": path, "signals": sig, "suggested_level": level, "reason": reason}


def heuristic_level(sig):
    """Best-effort Build level from signals. Conservative; the skill refines it."""
    has_provenance = bool(
        sig["attest_build_provenance"] or sig["attest_generic"] or sig["npm_provenance"])
    has_oidc = bool(sig["id_token_write"])
    if sig["slsa_generator"]:
        return 3, "uses slsa-github-generator reusable workflow (isolated builder)"
    if has_provenance and has_oidc:
        if sig["self_hosted_runner"] and not sig["hosted_runner"]:
            return 1, "provenance + OIDC but on a self-hosted runner — L2 not automatic"
        return 2, "signed provenance via OIDC on a hosted runner"
    if has_provenance and not has_oidc:
        return 1, "provenance action present but no id-token: write — signing likely incomplete"
    if sig["publishes_artifact"]:
        return 0, "publishes an artifact with no provenance signal"
    return 0, "no provenance signals found"


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("-")]
    as_json = "--json" in argv
    if len(args) != 1:
        print(__doc__)
        return 2

    target = args[0]
    if not os.path.exists(target):
        print(f"ERROR: path not found: {target}")
        return 2

    workflows = find_workflows(target)
    results = [analyze_file(p) for p in workflows]

    # Overall = lowest level among workflows that look like they publish; if none
    # clearly publish, the lowest among all (a build with no publish step is L0-ish).
    publishing = [r for r in results
                  if r["signals"]["publishes_artifact"] or r["signals"]["slsa_generator"]
                  or r["signals"]["attest_build_provenance"] or r["signals"]["npm_provenance"]]
    pool = publishing or results
    overall = min((r["suggested_level"] for r in pool), default=None)
    gaps = overall is not None and overall < 2

    summary = {
        "target": target,
        "workflows_scanned": len(results),
        "overall_suggested_level": overall,
        "has_gaps_to_L2": gaps,
        "workflows": results,
    }

    if as_json:
        print(json.dumps(summary, indent=2))
        return 1 if gaps else 0

    print(f"SLSA Build-level scan: {target}")
    print("=" * 64)
    if not results:
        print("No workflow files found under .github/workflows/.")
        return 1
    for r in results:
        s = r["signals"]
        rel = os.path.relpath(r["file"], target if os.path.isdir(target) else os.path.dirname(target))
        print(f"\n{rel}  →  heuristic Build L{r['suggested_level']}")
        print(f"    {r['reason']}")

        def show(label, key):
            v = s[key]
            if v:
                print(f"    {label}: lines {', '.join(str(x) for x in v)}")
        show("attest-build-provenance", "attest_build_provenance")
        show("actions/attest (generic)", "attest_generic")
        show("slsa-github-generator", "slsa_generator")
        show("id-token: write", "id_token_write")
        show("attestations: write", "attestations_write")
        show("npm --provenance", "npm_provenance")
        show("self-hosted runner", "self_hosted_runner")
        show("publishes artifact", "publishes_artifact")
        if s["unpinned_third_party_actions"]:
            print("    unpinned third-party actions (pin to SHA):")
            for ln, ref in s["unpinned_third_party_actions"]:
                print(f"        {rel}:{ln}  {ref}")

    print("\n" + "-" * 64)
    if overall is None:
        print("Overall: no workflows to score.")
    else:
        print(f"Overall heuristic Build level (weakest publishing workflow): L{overall}")
        if gaps:
            print("Gaps to L2 present — see per-workflow notes above. "
                  "Confirm by reading the workflows: provenance must cover the "
                  "released artifact in the job that ships it.")
    return 1 if gaps else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
