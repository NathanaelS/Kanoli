# Kanoli Security Policy

This document describes Kanoli's security goals, release trust model, and vulnerability reporting process.

## Security Goals

Kanoli aims to provide:

- Local-first storage where user board data remains in user-selected local files.
- Human-readable board data that can be inspected outside the app.
- Clear release verification instructions.
- Release artifacts that users can independently verify.
- A transparent path toward signed, notarized, and provenance-backed releases.

## Release Trust Model

Kanoli users should be able to confirm that a release:

- Came from the official Kanoli repository.
- Matches the published release version.
- Has not been corrupted or modified after publication.
- Was produced by the expected developer identity once signing is adopted.
- Includes checksums and verification instructions.

## Official Project Locations

| Item | Location |
| --- | --- |
| Official repository | https://github.com/NathanaelS/Kanoli |
| Release page | https://github.com/NathanaelS/Kanoli/releases |
| Security contact | GitHub Issues |

## Reporting a Vulnerability

Please report suspected security issues using GitHub Issues in the official repository.

When possible, include:

- A clear description of the issue.
- Steps to reproduce it.
- Potential impact.
- Affected platform or release version.
- Any sample board file only if it is safe to share.

## Scope

This policy applies to the Kanoli app, release artifacts, and release verification process.

## Response Expectations

Kanoli is an independent open-source project. Security reports will be reviewed as time permits and prioritized based on impact, exploitability, and affected users.

## Current Status

Kanoli is still adopting formal release verification. Identity, signing, checksum, and attestation details will be updated as the release process matures.
