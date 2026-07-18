# Theorem Star icon fidelity pass

## Decision

The user-selected **Theorem Star** is the canonical Gauss application icon.
This is a refinement pass, not a new identity exploration: the open theorem
orbit, four geometric terminals, proof-star, ivory halo, and teal center are
preserved as the visual contract.

Approved visual reference:
[`assets/brand-concept-theorem-star-selected.png`](assets/brand-concept-theorem-star-selected.png).

## Surface ledger

| Surface | Decision | Source / implementation |
| --- | --- | --- |
| Canonical app-icon artwork | Keep and formalize | `flutter_app/assets/visual/brand/theorem_star_app_icon.svg` |
| Android adaptive foreground | Refine | Exact VectorDrawable geometry with an 18dp safe inset |
| Android Android-13 monochrome layer | Refine | Dedicated one-color Theorem Star VectorDrawable |
| Android pre-adaptive fallbacks | Replace | Density-specific PNGs rendered from the same SVG master |
| Android launch surface | Replace | Theorem Star replaces the default Flutter foreground reference |
| Web favicon, PWA, Apple touch icon | Replace | PNGs rendered from the canonical SVG and maskable SVG |
| In-app wordmark and map artwork | Keep | Separate identity surface; untouched by this focused correction |
| Legacy root Kotlin archive | Out of scope | Not the released Flutter Android/web product |

## Asset contract

| Asset | Purpose |
| --- | --- |
| `theorem_star_app_icon.svg` | Rounded-square icon for legacy Android, favicon, PWA `any`, and Apple touch icon |
| `theorem_star_app_icon_maskable.svg` | Full-bleed navy field with the mark inside the maskable safe region |
| `tool/render_brand_icons.py` | Deterministically rasterizes the two SVG masters into every checked-in PNG target |
| `ic_launcher_theorem_star.xml` | Android vector form of the selected mark |
| `ic_launcher_theorem_star_safe.xml` | Android adaptive foreground using an 18dp protective inset |
| `ic_launcher_theorem_star_mono_safe.xml` | Android 13+ themed-icon layer |

The shared palette is deep navy `#07151C`, gold `#F0C36A` / `#DCA847`, ivory
`#F6ECD6`, and theorem-center teal `#62AE9C`.

## Precision rules

- Android adaptive icons use a 108dp canvas. The visible mark is inset by
  18dp, keeping it inside the centered 66dp protected zone when a launcher
  applies a circular, squircle, or other device-specific mask.
- The rounded-square raster and the maskable raster are intentionally distinct:
  the former is a complete app tile; the latter retains a full navy field so
  launchers can crop it without clipping the orbit or terminal geometry.
- No default Flutter launcher artwork remains in any shipped Android density,
  web favicon, Apple touch icon, or PWA icon target.

## Data and behavior boundary

This pass changes brand assets and Android/web packaging metadata only. It does
not touch the preserved question corpus, media catalog, Room/SQLite data,
progress, missions, or routing.

## Verification record

| Check | Result |
| --- | --- |
| Deterministic raster generation | `python tool/render_brand_icons.py` rebuilt all Android density, favicon, PWA, and Apple-touch PNG outputs from the two SVG masters. |
| Static analysis | `dart analyze` completed with `No issues found!`. |
| Android identity contract | The focused `flutter test --no-pub ... --name "Android package..."` passed with exit code 0. It asserts the adaptive safe layer, Android 13 monochrome layer, splash reference, SVG master, and Web manifest contracts. |
| Map regression | The tablet radial-map widget test passed with exit code 0. |
| Local release APK | `flutter build apk --release --build-name 1.0.89 --build-number 89` completed successfully. `aapt` reported `com.gauss.app`, version `1.0.89 (89)`; `zipalign` passed; `apksigner` verified v2 signing with the Gauss certificate `F5:0C:33:38:BF:6C:1C:FB:E0:58:F6:EC:E5:79:E2:24:B2:D5:37:D1:25:48:A9:49:C3:5F:79:B5:73:B7:68:44`. |
| Android update and runtime | The signed release installed over `1.0.88` as `1.0.89` without uninstall. A stable API-35 emulator rendered the Android splash, launcher/app-info icon, and the live map after launch. |
| Web release | `flutter build web --release` completed successfully. SHA-256 hashes of `favicon.png`, `Icon-512.png`, and `Icon-maskable-512.png` match between `web/` and `build/web/`. |

Runtime evidence:

- [Android app-info icon](assets/gauss-icon-v1.0.89-emulator.png)
- [Android splash](assets/gauss-v1.0.89-splash-emulator.png)
- [Settled Android map](assets/gauss-v1.0.89-map-settled-emulator.png)

The expected system-level variation is intentional: the normal launcher uses a
device-selected adaptive mask, while Android splash presents the mark on its
full dark field. Both retain every selected terminal and the open orbit;
nothing is clipped.
