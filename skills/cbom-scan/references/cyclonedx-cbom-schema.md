# CycloneDX 1.6 CBOM — data model reference

Emit a **CycloneDX 1.6** Bill of Materials (`bomFormat: "CycloneDX"`, `specVersion: "1.6"`). CBOM is not a separate format — it is CycloneDX with cryptographic-asset components. CycloneDX 1.6 is published as the international standard **ECMA-424**.

> **Version note.** Earlier IBM/CBOM examples used `bomFormat: "CBOM"`, `specVersion: "1.4-cbom-1.0"`, and `type: "crypto-asset"`. That is the *pre-standard* form. Always target the upstreamed standard: `bomFormat: "CycloneDX"`, `specVersion: "1.6"`, component `type: "cryptographic-asset"`. In 1.6, `classicalSecurityLevel` and `nistQuantumSecurityLevel` live **inside** `algorithmProperties`.

## Table of contents
1. Top-level document
2. The `cryptographic-asset` component
3. `cryptoProperties` by `assetType`
   - algorithm
   - certificate
   - related-crypto-material
   - protocol
4. Evidence / occurrences (traceability)
5. Dependencies
6. Enum quick-reference (use these exact values)
7. Full valid example

---

## 1. Top-level document

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-21T10:00:00Z",
    "component": {
      "type": "application",
      "bom-ref": "pkg:generic/my-app@1.0.0",
      "name": "my-app",
      "version": "1.0.0"
    },
    "tools": {
      "components": [
        { "type": "application", "name": "cbom-scan", "version": "1.0.0" }
      ]
    }
  },
  "components": [ /* cryptographic-asset entries — see below */ ],
  "dependencies": [ /* relationships — see §5 */ ]
}
```

- `serialNumber` — a `urn:uuid:` value. If you cannot generate a real UUID, use `python3 -c "import uuid;print(uuid.uuid4())"`.
- `timestamp` — ISO-8601 UTC. Use the real current time.
- `metadata.component` — the application/repo being scanned (the subject of the CBOM).
- `metadata.tools.components` — what generated the CBOM (this skill).

## 2. The `cryptographic-asset` component

Every crypto asset is one entry in `components[]`:

```json
{
  "type": "cryptographic-asset",
  "name": "AES-256-GCM",
  "bom-ref": "crypto/algorithm/aes-256-gcm",
  "cryptoProperties": { "...": "shaped by assetType" },
  "evidence": { "occurrences": [ /* §4 */ ] }
}
```

- `type` is always `"cryptographic-asset"`.
- `name` — human-readable asset name (`"AES-256-GCM"`, `"RSA-2048"`, `"TLSv1.2"`, `"SHA-256"`).
- `bom-ref` — a unique id you reference elsewhere. Use a stable scheme: `crypto/algorithm/<slug>`, `crypto/protocol/<slug>`, `crypto/certificate/<slug>`, `crypto/key/<slug>`. (OIDs like `oid:2.16.840.1.101.3.4.1.46` are also valid bom-refs.)
- `cryptoProperties` — required for crypto assets; its shape depends on `assetType`.
- `evidence` — where in the code this asset was found (strongly recommended; it's what makes the CBOM auditable).

## 3. `cryptoProperties` by `assetType`

`cryptoProperties.assetType` is one of: **`algorithm`**, **`certificate`**, **`related-crypto-material`**, **`protocol`**. `cryptoProperties.oid` (the algorithm/object OID) is optional and allowed on any of them.

### assetType: `algorithm`

```json
"cryptoProperties": {
  "assetType": "algorithm",
  "algorithmProperties": {
    "primitive": "ae",
    "parameterSetIdentifier": "256",
    "mode": "gcm",
    "padding": "none",
    "cryptoFunctions": ["keygen", "encrypt", "decrypt", "tag"],
    "executionEnvironment": "software-plain-ram",
    "implementationPlatform": "x86_64",
    "certificationLevel": ["none"],
    "classicalSecurityLevel": 256,
    "nistQuantumSecurityLevel": 1
  },
  "oid": "2.16.840.1.101.3.4.1.46"
}
```

`algorithmProperties` fields:

| field | type | notes |
|---|---|---|
| `primitive` | enum | the kind of primitive — see §6 |
| `parameterSetIdentifier` | string | key size / parameter set, e.g. `"256"`, `"2048"`, `"p256"` |
| `curve` | string | named curve for ECC, e.g. `"secp256r1"`, `"curve25519"` |
| `mode` | enum | block-cipher mode — see §6 |
| `padding` | enum | padding scheme — see §6 |
| `cryptoFunctions` | array of enum | what it's used for — see §6 |
| `executionEnvironment` | enum | where it executes — see §6 |
| `implementationPlatform` | enum | target arch — see §6 |
| `certificationLevel` | array of enum | FIPS/CC level(s) — see §6 |
| `classicalSecurityLevel` | integer | bits of classical security (e.g. AES-256 → 256) |
| `nistQuantumSecurityLevel` | integer 0–6 | NIST PQC category. **0 = no quantum resistance** (use for RSA/ECC/DH/DSA). 1/3/5 map to AES-128/192/256-equivalent PQC categories |

### assetType: `certificate`

```json
"cryptoProperties": {
  "assetType": "certificate",
  "certificateProperties": {
    "subjectName": "CN=example.com,O=Example Inc,C=US",
    "issuerName": "CN=Example CA,O=Example Inc,C=US",
    "notValidBefore": "2025-01-01T00:00:00Z",
    "notValidAfter": "2026-01-01T00:00:00Z",
    "signatureAlgorithmRef": "crypto/algorithm/sha256-rsa",
    "subjectPublicKeyRef": "crypto/key/rsa-2048-pub",
    "certificateFormat": "X.509",
    "certificateExtension": "crt"
  }
}
```

`signatureAlgorithmRef` and `subjectPublicKeyRef` are `bom-ref` pointers to other components (the cert's signing algorithm and its public key) — wire them up when those assets exist.

### assetType: `related-crypto-material`

Keys, secrets, signatures, digests, IVs, etc.

```json
"cryptoProperties": {
  "assetType": "related-crypto-material",
  "relatedCryptoMaterialProperties": {
    "type": "private-key",
    "id": "key-001",
    "state": "active",
    "size": 2048,
    "format": "PEM",
    "algorithmRef": "crypto/algorithm/rsa-2048",
    "securedBy": { "mechanism": "Software", "algorithmRef": "crypto/algorithm/aes-256-gcm" },
    "creationDate": "2025-01-01T00:00:00Z"
  }
}
```

`type` enum and `state` enum: see §6. **Never put actual private-key bytes in `value`.** Record existence + metadata only.

### assetType: `protocol`

```json
"cryptoProperties": {
  "assetType": "protocol",
  "protocolProperties": {
    "type": "tls",
    "version": "1.2",
    "cipherSuites": [
      {
        "name": "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
        "algorithms": [
          "crypto/algorithm/ecdhe",
          "crypto/algorithm/rsa-2048",
          "crypto/algorithm/aes-256-gcm",
          "crypto/algorithm/sha-384"
        ],
        "identifiers": ["0xC0", "0x30"]
      }
    ],
    "cryptoRefArray": ["crypto/certificate/example.com"]
  }
}
```

`type` enum: see §6. `cipherSuites[].algorithms` and `cryptoRefArray` are `bom-ref` pointers.

## 4. Evidence / occurrences (traceability)

Attach to the component (sibling of `cryptoProperties`):

```json
"evidence": {
  "occurrences": [
    { "location": "src/auth/tokens.py", "line": 42 },
    { "location": "src/auth/tokens.py", "line": 88, "additionalContext": "JWT signing" }
  ]
}
```

`occurrences[]` fields: `location` (file path, required), `line`, `offset`, `symbol`, `additionalContext`. Dedup one asset across many files into one component with many occurrences.

## 5. Dependencies

Express relationships you can observe:

```json
"dependencies": [
  { "ref": "crypto/protocol/tls-1.2", "dependsOn": ["crypto/algorithm/aes-256-gcm", "crypto/algorithm/rsa-2048"] },
  { "ref": "crypto/certificate/example.com", "dependsOn": ["crypto/algorithm/sha256-rsa"] },
  { "ref": "pkg:generic/my-app@1.0.0", "dependsOn": ["crypto/algorithm/aes-256-gcm"] }
]
```

CycloneDX 1.6 also supports `provides` for "implements" semantics, but `dependsOn` ("uses") is sufficient and widely consumed.

## 6. Enum quick-reference (use these exact values)

Use these CycloneDX 1.6 values. When unsure, use `"other"` or `"unknown"` — do not invent values.

- **assetType:** `algorithm` · `certificate` · `related-crypto-material` · `protocol`
- **algorithmProperties.primitive:** `drbg` · `mac` · `blockcipher` · `streamcipher` · `signature` · `hash` · `pke` (public-key encryption) · `ae` (authenticated encryption) · `combiner` · `kdf` · `key-agree` · `kem` · `other` · `unknown`
- **cryptoFunctions:** `generate` · `keygen` · `encrypt` · `decrypt` · `digest` · `tag` · `keyderive` · `sign` · `verify` · `encapsulate` · `decapsulate` · `other` · `unknown`
- **mode:** `cbc` · `ecb` · `ccm` · `gcm` · `cfb` · `ofb` · `ctr` · `other` · `unknown`
- **padding:** `pkcs5` · `pkcs7` · `pkcs1v15` · `oaep` · `raw` · `other` · `unknown`
- **executionEnvironment:** `software-plain-ram` · `software-encrypted-ram` · `software-tee` · `hardware` · `other` · `unknown`
- **implementationPlatform:** `x86_32` · `x86_64` · `armv7-a` · `armv7-m` · `armv8-a` · `armv8-m` · `armv9-a` · `armv9-m` · `s390x` · `ppc64` · `ppc64le` · `generic` · `other` · `unknown`
- **certificationLevel** (array): `none` · `fips140-1-l1`…`l4` · `fips140-2-l1`…`l4` · `fips140-3-l1`…`l4` · `cc-eal1`…`cc-eal7` (with `+`) · `other` · `unknown`
- **relatedCryptoMaterialProperties.type:** `private-key` · `public-key` · `secret-key` · `key` · `ciphertext` · `signature` · `digest` · `initialization-vector` · `nonce` · `seed` · `salt` · `shared-secret` · `tag` · `additional-data` · `password` · `credential` · `token` · `other` · `unknown`
- **relatedCryptoMaterialProperties.state:** `pre-activation` · `active` · `suspended` · `deactivated` · `compromised` · `destroyed`
- **protocolProperties.type:** `tls` · `ssh` · `ipsec` · `ike` · `sstp` · `wpa` · `other` · `unknown`
- **certificateProperties.certificateFormat:** typical values `X.509` · `PEM` · `DER` · `PKCS7` · `PKCS12`

### nistQuantumSecurityLevel guidance
- `0` — no quantum security: **RSA, ECC (ECDSA/ECDH/EdDSA), DH, DSA, ElGamal**. These are the migration targets.
- `1` — equivalent to AES-128 brute force (e.g. AES-128, SHA-256, ML-KEM-512, ML-DSA-44).
- `3` — equivalent to AES-192 (AES-192, SHA-384, ML-KEM-768, ML-DSA-65).
- `5` — equivalent to AES-256 (AES-256, SHA-512, ML-KEM-1024, ML-DSA-87).
- Symmetric ciphers and hashes are *weakened* by Grover but not broken — AES/SHA keep a non-zero level; public-key crypto vulnerable to Shor is `0`.

## 7. Full valid example

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.6",
  "serialNumber": "urn:uuid:3e671687-395b-41f5-a30f-a58921a69b79",
  "version": 1,
  "metadata": {
    "timestamp": "2026-06-21T10:00:00Z",
    "component": {
      "type": "application",
      "bom-ref": "pkg:generic/acme-api@2.3.0",
      "name": "acme-api",
      "version": "2.3.0"
    },
    "tools": { "components": [ { "type": "application", "name": "cbom-scan", "version": "1.0.0" } ] }
  },
  "components": [
    {
      "type": "cryptographic-asset",
      "name": "AES-256-GCM",
      "bom-ref": "crypto/algorithm/aes-256-gcm",
      "cryptoProperties": {
        "assetType": "algorithm",
        "algorithmProperties": {
          "primitive": "ae",
          "parameterSetIdentifier": "256",
          "mode": "gcm",
          "cryptoFunctions": ["encrypt", "decrypt"],
          "executionEnvironment": "software-plain-ram",
          "classicalSecurityLevel": 256,
          "nistQuantumSecurityLevel": 5
        }
      },
      "evidence": { "occurrences": [ { "location": "src/crypto/cipher.py", "line": 17 } ] }
    },
    {
      "type": "cryptographic-asset",
      "name": "RSA-2048",
      "bom-ref": "crypto/algorithm/rsa-2048",
      "cryptoProperties": {
        "assetType": "algorithm",
        "algorithmProperties": {
          "primitive": "pke",
          "parameterSetIdentifier": "2048",
          "cryptoFunctions": ["sign", "verify"],
          "classicalSecurityLevel": 112,
          "nistQuantumSecurityLevel": 0
        }
      },
      "evidence": { "occurrences": [ { "location": "src/auth/jwt.py", "line": 33, "additionalContext": "JWT RS256 signing" } ] }
    },
    {
      "type": "cryptographic-asset",
      "name": "MD5",
      "bom-ref": "crypto/algorithm/md5",
      "cryptoProperties": {
        "assetType": "algorithm",
        "algorithmProperties": {
          "primitive": "hash",
          "cryptoFunctions": ["digest"],
          "classicalSecurityLevel": 0,
          "nistQuantumSecurityLevel": 0
        }
      },
      "evidence": { "occurrences": [ { "location": "src/util/cache_key.py", "line": 5, "additionalContext": "cache key — broken hash" } ] }
    },
    {
      "type": "cryptographic-asset",
      "name": "TLSv1.2",
      "bom-ref": "crypto/protocol/tls-1.2",
      "cryptoProperties": {
        "assetType": "protocol",
        "protocolProperties": {
          "type": "tls",
          "version": "1.2",
          "cipherSuites": [
            { "name": "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384", "algorithms": ["crypto/algorithm/rsa-2048", "crypto/algorithm/aes-256-gcm"] }
          ]
        }
      },
      "evidence": { "occurrences": [ { "location": "deploy/nginx.conf", "line": 12 } ] }
    }
  ],
  "dependencies": [
    { "ref": "crypto/protocol/tls-1.2", "dependsOn": ["crypto/algorithm/rsa-2048", "crypto/algorithm/aes-256-gcm"] },
    { "ref": "pkg:generic/acme-api@2.3.0", "dependsOn": ["crypto/algorithm/aes-256-gcm", "crypto/algorithm/rsa-2048", "crypto/algorithm/md5"] }
  ]
}
```
