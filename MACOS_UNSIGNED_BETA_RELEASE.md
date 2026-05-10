# macOS Unsigned Beta Release Notes

Current release target: `Kanoli 0.6.0 Beta`

Artifact target: `kanoli_flutter/dist/Kanoli-0.6.0-beta.dmg`

## Current Distribution Posture

Kanoli 0.6.0 Beta is prepared as an unsigned public beta for macOS.

This release is not signed with an Apple Developer ID certificate and is not notarized by Apple. macOS Gatekeeper may block the first launch because the app is from an unidentified developer.

## User Install Guidance

1. Download `Kanoli-0.6.0-beta.dmg`.
2. Open the DMG.
3. Drag `Kanoli.app` to `/Applications`.
4. Try to open Kanoli.
5. If macOS blocks launch, use one of these options:
   - In Finder, Control-click `Kanoli.app`, choose `Open`, then confirm.
   - Or open **System Settings > Privacy & Security** and choose **Open Anyway** after the blocked launch.

Do not describe this beta as Apple-reviewed, Developer ID signed, or notarized.

## Future Signed Release Path

A polished public macOS release should use Apple Developer Program membership and:

- Developer ID Application certificate
- Release build with minimal release entitlements
- Hardened runtime if required by the final notarization workflow
- `xcrun notarytool` submission
- `xcrun stapler` ticket stapling
- `spctl` Gatekeeper verification

This future signed/notarized path is not a blocker for the 0.6.0 unsigned public beta.

## Kanoli Release Identity

- App name: `Kanoli`
- Bundle ID: `ko.kanoli.kanoliFlutter`
- Flutter version: `0.6.0-beta+1`
- Release label: `0.6.0 Beta`
- macOS bundle marketing version: `0.6.0`
- Build number: `1`
- Git tag target: `v0.6.0-beta`
- GitHub release type: prerelease
