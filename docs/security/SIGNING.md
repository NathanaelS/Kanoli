# Kanoli Signing

This document defines the signing identity and release verification policy for Kanoli release artifacts.

## Signing Identity

Kanoli release artifacts should be signed by the official Kanoli developer identity.

| Platform | Expected identity |
| --- | --- |
| Windows | Nathanael Stutz |
| macOS | Nathanael Christopher Stutz |
| macOS Team ID | 5Z6FYPML23 |

## Signing Policy

- Public release artifacts should be produced from the official Kanoli release process.
- Release artifacts should be named consistently with the published version.
- Release artifacts should be accompanied by SHA-256 checksums.
- Signed and notarized artifacts should be preferred once the required developer accounts and certificates are available.
- Unsigned preview or beta artifacts must be clearly labeled in release notes.

## Platform Expectations

### Windows

Windows executables and installers should be signed with an Authenticode code-signing certificate.

Expected publisher:

```text
Nathanael Stutz
```

### macOS

macOS app bundles and disk images should be signed with a Developer ID Application certificate and submitted for Apple notarization before public release.

Expected Team ID:

```text
5Z6FYPML23
```

## Verification Procedure

For each release:

1. Build release artifacts from the intended source commit.
2. Sign platform artifacts when signing credentials are available.
3. Notarize macOS artifacts when Apple Developer credentials are available.
4. Generate `SHA256SUMS.txt`.
5. Sign `SHA256SUMS.txt` when checksum signing is adopted.
6. Publish artifacts, checksums, signatures, release notes, and any available provenance attestations together.

## Current Status

Kanoli is still adopting this process. Until this document is fully completed, users should treat identity values marked `TODO` as not yet finalized.
