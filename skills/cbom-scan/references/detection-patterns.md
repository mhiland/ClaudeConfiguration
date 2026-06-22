# Detection patterns — finding cryptography in source

How to find crypto assets in a repo with source-level (static) scanning. This is heuristic: it finds *declared* and *called* crypto. It misses crypto resolved dynamically, hidden in binaries, or delegated to a managed service. Record what you couldn't see — that's the report's limitations section.

## Table of contents
1. Detection strategy (order of operations)
2. Crypto libraries by ecosystem (manifests)
3. Algorithm & API patterns by language
4. Protocol & TLS configuration
5. Keys, certificates & key material (files + embedded)
6. Algorithm classification tables (deprecated / quantum-vulnerable / PQC)
7. Mapping a finding to a CBOM component
8. Higher-fidelity detection: CBOMkit

---

## 1. Detection strategy (order of operations)

1. **Manifests first.** Dependency files tell you which crypto libraries are in play, which narrows what algorithms are reachable and how API calls will look.
2. **Then source calls.** Grep for algorithm names and the crypto APIs of the libraries you found. Record file:line for each.
3. **Then config & protocols.** TLS/SSH/IPsec config files, server configs, infra-as-code.
4. **Then material.** Key/cert files and embedded PEM blocks.
5. **Dedup & attribute.** Collapse repeated hits of the same algorithm into one asset with many occurrences. Wire up relationships (protocol→ciphers, cert→sig algorithm).

Use ripgrep where available (`rg -n -i 'pattern' --glob '!**/{node_modules,vendor,dist,build,target}/**'`). Case-insensitive helps; algorithm names vary in casing.

## 2. Crypto libraries by ecosystem (manifests)

Parse these and flag any crypto provider. Presence of the library is itself a CBOM-relevant fact (it's a dependency that ships crypto).

| Ecosystem | Manifest | Crypto libraries to flag |
|---|---|---|
| Node/JS | `package.json`, lockfiles | `crypto` (built-in), `node-forge`, `crypto-js`, `bcrypt`, `bcryptjs`, `jsonwebtoken`, `jose`, `tweetnacl`, `libsodium-wrappers`, `elliptic`, `openpgp`, `noble-*` (`@noble/hashes`, `@noble/curves`) |
| Python | `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py` | `cryptography` (pyca), `pycryptodome`/`pycrypto`, `pynacl`, `pyopenssl`, `bcrypt`, `passlib`, `argon2-cffi`, `hashlib`/`hmac`/`ssl`/`secrets` (stdlib), `jwcrypto`, `pyjwt` |
| Java/Kotlin | `pom.xml`, `build.gradle(.kts)` | JCA/JCE (`javax.crypto`, `java.security`), `bouncycastle` (`bcprov`, `bcpkix`), `tink`, `jjwt`, `nimbus-jose-jwt`, `conscrypt` |
| Go | `go.mod` | stdlib `crypto/*`, `golang.org/x/crypto`, `filippo.io/edwards25519`, `cloudflare/circl` (PQC) |
| Rust | `Cargo.toml` | `ring`, `rustls`, `openssl`, `rust-crypto`/`RustCrypto` crates (`aes`, `sha2`, `rsa`, `ed25519-dalek`, `x25519-dalek`), `sodiumoxide`, `pqcrypto` |
| .NET | `*.csproj`, `packages.config` | `System.Security.Cryptography`, `BouncyCastle.NetCore`/`BouncyCastle.Cryptography`, `NSec`, `Portable.BouncyCastle` |
| Ruby | `Gemfile` | `openssl` (stdlib), `bcrypt`, `rbnacl`, `jwt` |
| PHP | `composer.json` | `openssl`/`sodium` (ext), `phpseclib`, `firebase/php-jwt`, `paragonie/*` |
| C/C++ | build files, includes | OpenSSL/`libssl`/`libcrypto`, `mbedtls`, `wolfssl`, `libsodium`, `libgcrypt`, `BoringSSL`, `Botan`, `liboqs` (PQC) |
| System | OS packages, Dockerfiles | `openssl`, `gnutls`, `libgcrypt`, `nss` |

## 3. Algorithm & API patterns by language

Grep for algorithm names (language-agnostic) and library-specific API calls. Names below are case-insensitive search terms.

**Algorithm name tokens (search across all source):**
`AES`, `DES`, `3DES`/`TripleDES`/`DESede`, `RC4`, `Blowfish`, `ChaCha20`, `Salsa20`, `RSA`, `DSA`, `ECDSA`, `ECDH`, `EdDSA`, `Ed25519`, `X25519`, `Curve25519`, `secp256`, `prime256`, `DH`/`DiffieHellman`, `ElGamal`, `MD5`, `SHA1`/`SHA-1`, `SHA256`/`SHA-256`, `SHA512`, `SHA3`, `BLAKE2`/`BLAKE3`, `HMAC`, `PBKDF2`, `bcrypt`, `scrypt`, `Argon2`, `HKDF`, `Kyber`/`ML-KEM`, `Dilithium`/`ML-DSA`, `SPHINCS`/`SLH-DSA`, `Falcon`.

**Python (pyca/cryptography, hashlib, PyCryptodome):**
- `hashlib.md5(`, `hashlib.sha1(`, `hashlib.sha256(`, `hashlib.new(`
- `Cipher(algorithms.AES(`, `modes.GCM(`, `modes.CBC(`, `modes.ECB(`
- `rsa.generate_private_key(`, `ec.generate_private_key(`, `ec.SECP256R1`, `ed25519.`, `x25519.`
- `padding.OAEP`, `padding.PKCS1v15`, `hashes.SHA256(`
- `hmac.new(`, `PBKDF2HMAC(`, `Scrypt(`, `bcrypt.`, `argon2.`
- `ssl.SSLContext(`, `ssl.PROTOCOL_`, `Crypto.Cipher`, `Crypto.PublicKey.RSA`

**Java (JCA/JCE, BouncyCastle):**
- `MessageDigest.getInstance("MD5"|"SHA-1"|"SHA-256")`
- `Cipher.getInstance("AES/GCM/NoPadding"|"AES/CBC/PKCS5Padding"|"RSA/ECB/OAEPPadding"|"DES"|"DESede")`
- `KeyPairGenerator.getInstance("RSA"|"EC"|"DSA")`, `KeyGenerator.getInstance("AES")`
- `Signature.getInstance("SHA256withRSA"|"SHA256withECDSA")`, `Mac.getInstance("HmacSHA256")`
- `SSLContext.getInstance("TLS"|"TLSv1.2")`, `SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")`
- BouncyCastle: `new BouncyCastleProvider()`, `org.bouncycastle.*`
- Note: `Cipher.getInstance(someVariable)` hides the concrete algorithm — flag as `unknown` and note it needs runtime/AST resolution.

**Node/JS:**
- `crypto.createHash('md5'|'sha1'|'sha256')`, `crypto.createHmac(`, `crypto.createCipheriv('aes-256-gcm'|'aes-128-cbc'|'des-ede3')`
- `crypto.generateKeyPair('rsa'|'ec'|'ed25519')`, `crypto.createSign(`, `crypto.pbkdf2(`, `crypto.scrypt(`
- `bcrypt.hash(`, `jwt.sign(.. algorithm: 'RS256'|'HS256'|'ES256')`, `new TextEncoder` near `subtle.encrypt`
- WebCrypto: `crypto.subtle.encrypt(`, `subtle.digest('SHA-256')`, `subtle.generateKey(`

**Go:**
- imports: `crypto/aes`, `crypto/des`, `crypto/rc4`, `crypto/rsa`, `crypto/ecdsa`, `crypto/ed25519`, `crypto/md5`, `crypto/sha1`, `crypto/sha256`, `crypto/hmac`, `crypto/tls`, `golang.org/x/crypto/...`
- calls: `aes.NewCipher(`, `cipher.NewGCM(`, `rsa.GenerateKey(`, `tls.Config{`, `md5.New(`, `sha256.Sum256(`

**Go/Rust/.NET TLS config:** `tls.Config{MinVersion:`, `rustls`, `SslProtocols.Tls12`, cipher-suite lists.

## 4. Protocol & TLS configuration

Look in server/infra config, not just code:
- **Web servers:** `nginx.conf` (`ssl_protocols`, `ssl_ciphers`), Apache `SSLProtocol`/`SSLCipherSuite`, `httpd.conf`.
- **App config:** `application.yml`/`.properties` (`server.ssl.*`, `ssl.enabled-protocols`, `ciphers`), `appsettings.json`.
- **IaC / k8s:** Ingress TLS annotations, `tls.minVersion`, cert-manager `Issuer`/`Certificate`, service-mesh mTLS (Istio `PeerAuthentication`, Linkerd).
- **SSH:** `sshd_config` (`Ciphers`, `MACs`, `KexAlgorithms`, `HostKeyAlgorithms`).
- **Code-level TLS:** min/max version pins, cipher-suite arrays, `InsecureSkipVerify`/`verify=False`/`rejectUnauthorized:false` (flag as a finding — disabled verification).

Each TLS/SSH instance → a `protocol` asset; its cipher suites → `cipherSuites[]` with `bom-ref` links to the algorithm assets.

## 5. Keys, certificates & key material (files + embedded)

**File globs:** `*.pem` `*.crt` `*.cer` `*.der` `*.key` `*.p12` `*.pfx` `*.jks` `*.keystore` `*.gpg` `*.asc` `*.pub` `id_rsa*` `id_ed25519*`.

**Embedded PEM blocks (grep):** `-----BEGIN CERTIFICATE-----`, `-----BEGIN (RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----`, `-----BEGIN PUBLIC KEY-----`, `ssh-rsa `, `ssh-ed25519 `.

**Handling:**
- **Certificates** → `certificate` asset. If a cert file is present and parseable, extract `subjectName`, `issuerName`, `notValidBefore/After`, signature algorithm (`openssl x509 -in f.pem -noout -subject -issuer -dates -text` is fine). Flag expired certs and SHA-1 signatures.
- **Keys** → `related-crypto-material` asset (`type: private-key`/`public-key`/`secret-key`). Record type, algorithm, size, format, location. **A hardcoded private key in the repo is a high-severity finding** — note it, never print its contents.
- Distinguish real material from test fixtures, but still inventory test keys (note they're test).

## 6. Algorithm classification tables

Use these to set risk class, `classicalSecurityLevel`, and `nistQuantumSecurityLevel`, and to drive the report's risk findings.

### Classically broken / deprecated — already unsafe (highest priority)
| Algorithm | Why | classicalSecurityLevel |
|---|---|---|
| MD5, MD4, MD2 | collision-broken | 0 |
| SHA-1 | collision-broken (SHAttered) | 0 |
| DES | 56-bit, brute-forceable | 0 |
| 3DES / DESede | Sweet32, deprecated by NIST (2023) | ~80–112, treat as weak |
| RC4 | biased keystream, broken | 0 |
| Blowfish (64-bit block) | Sweet32 | weak |
| ECB mode (any cipher) | leaks plaintext structure | n/a — flag the mode |
| RSA/DSA/DH < 2048-bit | insufficient | <112 |
| PBKDF2 with low iterations, or MD5/SHA-1 password hashing, unsalted hashes | weak KDF | weak |

### Quantum-vulnerable — broken by Shor's algorithm (PQC migration targets)
| Algorithm | Note | nistQuantumSecurityLevel |
|---|---|---|
| RSA (any size) | factoring | 0 |
| ECDSA / ECDH / EdDSA / Ed25519 / X25519 | discrete log on curves | 0 |
| DSA, Diffie-Hellman (finite field) | discrete log | 0 |
| ElGamal | discrete log | 0 |

All public-key crypto in the table above is `nistQuantumSecurityLevel: 0` regardless of key size — bigger keys do not help against Shor. These form the "post-quantum migration posture" section.

### Acceptable today (but symmetric/hash crypto is *weakened*, not broken, by Grover)
| Algorithm | nistQuantumSecurityLevel |
|---|---|
| AES-128 | 1 |
| AES-192 | 3 |
| AES-256 | 5 |
| ChaCha20-Poly1305 | ~5 |
| SHA-256 | 1 |
| SHA-384 | 3 |
| SHA-512, SHA-3 | 5 |
| HMAC-SHA-256+ | inherits hash |
| Argon2id, scrypt, bcrypt (password hashing) | acceptable KDFs |

Note in the report: AES-128/SHA-256 are fine today but sit at category 1; high-value long-lived data may warrant AES-256 for Grover margin.

### PQC-ready — quantum-resistant (NIST FIPS, 2024)
| Algorithm | Standard | Purpose |
|---|---|---|
| ML-KEM (Kyber) | FIPS 203 | key encapsulation |
| ML-DSA (Dilithium) | FIPS 204 | signatures |
| SLH-DSA (SPHINCS+) | FIPS 205 | stateless hash-based signatures |
| FALCON (FN-DSA) | draft FIPS 206 | compact signatures |
| LMS / XMSS | NIST SP 800-208 | stateful hash-based signatures |

Finding any of these is good news — note crypto-agility / PQC adoption in the report.

## 7. Mapping a finding to a CBOM component

| Finding | assetType | key fields to set |
|---|---|---|
| Algorithm name / API call | `algorithm` | `primitive`, `parameterSetIdentifier` (key size), `mode`, `cryptoFunctions`, security levels |
| TLS/SSH/IPsec usage or config | `protocol` | `type`, `version`, `cipherSuites[]` |
| `.crt`/`.pem` cert, embedded CERTIFICATE block | `certificate` | subject/issuer/validity/sig alg/format |
| Key file, embedded PRIVATE/PUBLIC KEY, keystore | `related-crypto-material` | `type`, `algorithmRef`, `size`, `format`, `state` |
| Crypto library dependency | (optionally) a `library` component | record as dependency context; algorithms it provides become `algorithm` assets |

Primitive mapping cheat-sheet: block ciphers (AES/DES/3DES) → `blockcipher` (or `ae` when used with GCM/CCM/Poly1305); stream ciphers (RC4/ChaCha20) → `streamcipher`/`ae`; RSA/ECC encryption → `pke`; RSA/ECDSA/EdDSA signing → `signature`; ECDH/DH/X25519 → `key-agree`; ML-KEM → `kem`; hashes → `hash`; HMAC → `mac`; PBKDF2/HKDF/scrypt/Argon2 → `kdf`; DRBG/CSPRNG → `drbg`.

## 8. Higher-fidelity detection: CBOMkit

When the user needs production depth (resolving dynamic algorithm selection, container-image scanning) or already has it, point them to the de-facto open-source toolset from IBM Research / Post-Quantum Cryptography Alliance:

- **CBOMkit-hyperion** (Sonar Cryptography plugin) — AST-based detection in SonarQube; resolves which concrete algorithm a generic crypto call uses. Strong for Java (JCA, BouncyCastle), with Python/Go/C support.
- **CBOMkit-theia** — detects crypto assets in container images and directories.
- **CBOMkit-coeus** — viewer/stats for generated CBOMs.
- **CBOMkit GitHub Action** — generate CBOMs in CI.

These output the same CycloneDX CBOM format, so their results merge with this skill's. Repo: `github.com/cbomkit/cbomkit`. This skill's self-contained scan is the no-install default; CBOMkit is the upgrade path for accuracy and CI integration.
