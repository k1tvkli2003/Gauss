# Gauss Android signing continuity

The released Flutter application owns Android package ID `com.gauss.app`.
Every future release must retain this package ID and the same signing key so
Android can install it as an update rather than a separate application.

## Current signing record

- Alias: `gauss-release`
- Certificate SHA-256:
  `F5:0C:33:38:BF:6C:1C:FB:E0:58:F6:EC:E5:79:E2:24:B2:D5:37:D1:25:48:A9:49:C3:5F:79:B5:73:B7:68:44`
- Local protected keystore: `%USERPROFILE%\.gauss\signing\gauss-release.jks`
- Local backup: `%USERPROFILE%\Documents\Gauss Signing Backup\gauss-release.jks`
- Password record: Windows Credential Manager target
  `Gauss.Android.ReleaseSigning`

The keystore and its password are never committed, logged, attached to a
release, or copied into a build cache. GitHub stores the key only as the four
repository secrets referenced by the release workflow.

## One-time migration from the bad release

GitHub release `v1.0.84` was a different Kotlin/Compose APK and used a
runner-generated Android debug certificate. Android cannot update it in place
to the Flutter release. Because the old build has no compatible signing
lineage, uninstall **Gauss** once before installing the first corrected Flutter
release. Subsequent Flutter releases will update normally.

## Verify a downloaded APK

```powershell
apksigner verify --verbose --print-certs gauss-v*.apk
aapt dump badging gauss-v*.apk
```

Confirm package `com.gauss.app`, the intended version, a valid v2 signature,
and the certificate SHA-256 recorded above. Do not install a release whose
certificate is `CN=Android Debug`.
