# Verifying Kanoli Downloads

This document explains how to verify Kanoli release downloads.

## Release Assets

Official releases should provide the application artifact and a checksum file:

```text
Kanoli-<version>-<platform>.<extension>
SHA256SUMS.txt
```

Future releases may also include:

```text
SHA256SUMS.txt.sig
Artifact attestation
```

## Verify SHA-256 Checksums

Download the release artifact and `SHA256SUMS.txt` from the same GitHub release.

### macOS or Linux

Run:

```bash
shasum -a 256 Kanoli-<version>-<platform>.<extension>
```

Compare the output with the matching line in `SHA256SUMS.txt`.

### Windows PowerShell

Run:

```powershell
Get-FileHash .\Kanoli-<version>-<platform>.<extension> -Algorithm SHA256
```

Compare the hash with the matching line in `SHA256SUMS.txt`.

## Verify macOS Signing

Once Kanoli ships signed and notarized macOS releases, verify the app with:

```bash
codesign -dv --verbose=4 /Applications/Kanoli.app
spctl -a -vv -t exec /Applications/Kanoli.app
```

Expected identity:

```text
Nathanael Christopher Stutz
5Z6FYPML23
```

## Verify Windows Signing

Once Kanoli ships signed Windows releases, verify the publisher shown by Windows before installing.

Expected publisher:

```text
Nathanael Stutz
```

Advanced users can inspect the Authenticode signature in PowerShell:

```powershell
Get-AuthenticodeSignature .\Kanoli-<version>-Windows-x64.exe
```

## When Verification Fails

Do not run an artifact if:

- Its SHA-256 hash does not match `SHA256SUMS.txt`.
- Its signing identity differs from the expected identity.
- Its release notes say it should be signed, but the signature is missing or invalid.

Report suspicious release artifacts using the process in `SECURITY_POLICY.md`.
