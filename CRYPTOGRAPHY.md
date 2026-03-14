# Cryptography Specification (v1.0)

This document provides a technical overview of the cryptographic implementation in **Aegis Note**.

## 1. Key Derivation Function (KDF)
To derive the Master Key from the user-provided password, we utilize **PBKDF2 (Password-Based Key Derivation Function 2)**.

- **Hash Algorithm**: HMAC-SHA256
- **Iteration Count**: 600,000
- **Salt**: 256-bit static salt.
- **Key Length**: 256-bit (32 bytes)

**Rationale**: While memory-hard functions like Argon2id offer theoretical advantages, PBKDF2 was selected to ensure 100% platform independence without native binary dependencies. The high iteration count (600k) is intentionally applied to compensate for the static salt, ensuring that brute-force attacks remain computationally prohibitive.

## 2. Authenticated Encryption
Encryption is performed using **XChaCha20-Poly1305**.

- **Algorithm**: XChaCha20 stream cipher.
- **Authentication**: Poly1305 MAC (Message Authentication Code).
- **Nonce**: 192-bit random nonce generated per encryption event using a secure PRNG.
- **Integrity**: AEAD (Authenticated Encryption with Associated Data) ensures that any unauthorized modification of the ciphertext results in a decryption failure.

## 3. Data Structure
The encrypted file format is a headerless binary stream to minimize metadata leakage:
`[24-byte Nonce] + [Variable-length Ciphertext] + [16-byte Auth Tag]`

## 4. Memory Management Policy
Aegis Note enforces a "Shortest Lifecycle" policy for sensitive keys:
- Keys are never swapped to disk (where OS support allows).
- References are nullified immediately upon logout or timeout.
- Process termination (`exit(0)`) is utilized to signal the OS to reclaim and wipe the heap.

## 5. Evolution Path
The current implementation represents a balance between high-grade security and disaster recovery requirements. Future versions may introduce optional dynamic salting or alternative KDFs as the project evolves, while maintaining backward compatibility through legacy headers.