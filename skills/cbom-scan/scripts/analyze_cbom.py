#!/usr/bin/env python3
"""Validate and summarize a CycloneDX 1.6 CBOM.

Usage:
    python3 analyze_cbom.py path/to/cbom.json [--json]

Does two jobs the report depends on:
  1. Structural validation against the CycloneDX 1.6 CBOM essentials (no network,
     no external deps) so an invalid CBOM is caught before it ships.
  2. Deterministic tallies — counts by asset type and by risk class
     (quantum-vulnerable, deprecated/broken, acceptable, PQC-ready) — so the
     report's numbers aren't hand-counted.

Exit code 0 = valid, 1 = validation errors, 2 = usage/parse error.
Risk classification is heuristic, based on the asset name and algorithm
properties; treat it as a starting point, not gospel.
"""
import json
import re
import sys

# --- risk classification by algorithm name -----------------------------------

DEPRECATED = [
    r"\bmd5\b", r"\bmd4\b", r"\bmd2\b", r"\bsha-?1\b", r"\bdes\b(?!ede|-ede)",
    r"\b3des\b", r"\bdes-?ede\b", r"\btripledes\b", r"\brc4\b", r"\brc2\b",
    r"\bblowfish\b", r"\becb\b",
]
# Public-key crypto broken by Shor's algorithm (quantum-vulnerable).
QUANTUM_VULN = [
    r"\brsa\b", r"\bdsa\b", r"\becdsa\b", r"\becdh\b", r"\beddsa\b",
    r"\bed25519\b", r"\bx25519\b", r"\bcurve25519\b", r"\bsecp\d", r"\bprime256\b",
    r"\bdiffie", r"\bdh\b", r"\belgamal\b", r"\becc\b",
]
PQC_READY = [
    r"\bml-?kem\b", r"\bkyber\b", r"\bml-?dsa\b", r"\bdilithium\b",
    r"\bslh-?dsa\b", r"\bsphincs\b", r"\bfalcon\b", r"\bfn-?dsa\b",
    r"\bxmss\b", r"\blms\b",
]


def classify(name, algo_props):
    """Return one of: deprecated, quantum-vulnerable, pqc-ready, acceptable."""
    n = (name or "").lower()
    # nistQuantumSecurityLevel == 0 on a public-key primitive is the strongest signal.
    nq = algo_props.get("nistQuantumSecurityLevel") if algo_props else None
    if any(re.search(p, n) for p in PQC_READY):
        return "pqc-ready"
    if any(re.search(p, n) for p in DEPRECATED):
        return "deprecated"
    if any(re.search(p, n) for p in QUANTUM_VULN):
        return "quantum-vulnerable"
    if nq == 0:
        return "quantum-vulnerable"
    # ECB mode flagged via algorithmProperties.mode
    if algo_props and str(algo_props.get("mode", "")).lower() == "ecb":
        return "deprecated"
    return "acceptable"


# --- validation --------------------------------------------------------------

VALID_ASSET_TYPES = {"algorithm", "certificate", "related-crypto-material", "protocol"}


def validate(doc):
    errors, warnings = [], []
    if doc.get("bomFormat") != "CycloneDX":
        errors.append(f'bomFormat must be "CycloneDX" (got {doc.get("bomFormat")!r})')
    spec = str(doc.get("specVersion", ""))
    if spec != "1.6":
        (errors if spec and spec < "1.6" else warnings).append(
            f'specVersion should be "1.6" for standard CBOM (got {spec!r})')
    if "serialNumber" not in doc:
        warnings.append("missing serialNumber (urn:uuid:...)")
    if not isinstance(doc.get("components"), list) or not doc["components"]:
        errors.append("components[] is missing or empty — no crypto assets")
        return errors, warnings

    crypto = [c for c in doc["components"] if c.get("type") == "cryptographic-asset"]
    if not crypto:
        errors.append('no components with type "cryptographic-asset"')

    for i, c in enumerate(doc["components"]):
        tag = c.get("name") or c.get("bom-ref") or f"#{i}"
        if c.get("type") != "cryptographic-asset":
            continue
        if not c.get("bom-ref"):
            warnings.append(f"[{tag}] missing bom-ref")
        cp = c.get("cryptoProperties")
        if not isinstance(cp, dict):
            errors.append(f"[{tag}] missing cryptoProperties")
            continue
        at = cp.get("assetType")
        if at not in VALID_ASSET_TYPES:
            errors.append(f"[{tag}] invalid assetType {at!r} "
                          f"(expected one of {sorted(VALID_ASSET_TYPES)})")
        # assetType-specific property bag should be present
        expected_bag = {
            "algorithm": "algorithmProperties",
            "certificate": "certificateProperties",
            "related-crypto-material": "relatedCryptoMaterialProperties",
            "protocol": "protocolProperties",
        }.get(at)
        if expected_bag and expected_bag not in cp:
            warnings.append(f"[{tag}] assetType {at} but no {expected_bag}")
        if not c.get("evidence", {}).get("occurrences"):
            warnings.append(f"[{tag}] no evidence.occurrences (finding not traceable to code)")
    return errors, warnings


# --- main --------------------------------------------------------------------

def main(argv):
    args = [a for a in argv[1:] if not a.startswith("-")]
    as_json = "--json" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    try:
        with open(args[0], encoding="utf-8") as fh:
            doc = json.load(fh)
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR: could not read/parse {args[0]}: {e}")
        return 2

    errors, warnings = validate(doc)

    by_type, by_risk = {}, {}
    risky = []  # (name, risk, locations)
    for c in doc.get("components", []):
        if c.get("type") != "cryptographic-asset":
            continue
        cp = c.get("cryptoProperties", {})
        at = cp.get("assetType", "unknown")
        by_type[at] = by_type.get(at, 0) + 1
        locs = [o.get("location", "?") + (f":{o['line']}" if o.get("line") else "")
                for o in c.get("evidence", {}).get("occurrences", [])]
        if at == "algorithm":
            risk = classify(c.get("name"), cp.get("algorithmProperties", {}))
            by_risk[risk] = by_risk.get(risk, 0) + 1
            if risk in ("deprecated", "quantum-vulnerable"):
                risky.append((c.get("name", "?"), risk, locs))
        elif at == "related-crypto-material":
            # A committed private/secret key is frequently the single highest-severity
            # finding — surface it here, not only in the report prose.
            mat = cp.get("relatedCryptoMaterialProperties", {})
            if mat.get("type") in ("private-key", "secret-key"):
                by_risk["exposed-key-material"] = by_risk.get("exposed-key-material", 0) + 1
                risky.append((c.get("name", "?"), "exposed-key-material", locs))

    summary = {
        "file": args[0],
        "valid": not errors,
        "errors": errors,
        "warnings": warnings,
        "total_crypto_assets": sum(by_type.values()),
        "by_asset_type": by_type,
        "by_risk_class": by_risk,
        "priority_findings": [
            {"name": n, "risk": r, "locations": locs} for n, r, locs in risky
        ],
    }

    if as_json:
        print(json.dumps(summary, indent=2))
        return 0 if not errors else 1

    print(f"CBOM analysis: {args[0]}")
    print("=" * 60)
    print(f"Valid CycloneDX 1.6 CBOM: {'YES' if not errors else 'NO'}")
    if errors:
        print("\nERRORS (fix before shipping):")
        for e in errors:
            print(f"  ✗ {e}")
    if warnings:
        print("\nWarnings:")
        for w in warnings:
            print(f"  ! {w}")
    print(f"\nTotal cryptographic assets: {summary['total_crypto_assets']}")
    print("By asset type:")
    for k, v in sorted(by_type.items()):
        print(f"  {k:>24}: {v}")
    if by_risk:
        print("By risk class:")
        for k in ("exposed-key-material", "deprecated", "quantum-vulnerable",
                  "acceptable", "pqc-ready"):
            if k in by_risk:
                print(f"  {k:>24}: {by_risk[k]}")
    if risky:
        print("\nPriority findings (exposed keys + deprecated + quantum-vulnerable):")
        for n, r, locs in risky:
            loc = ", ".join(locs[:3]) + (" …" if len(locs) > 3 else "")
            print(f"  [{r}] {n}  {loc}")
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
