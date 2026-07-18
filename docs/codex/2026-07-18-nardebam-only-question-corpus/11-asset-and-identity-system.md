# Asset Decomposition and Identity System

## Identity Concept

The selected Theorem Star combines a circular Gauss/G orbit, four directional
geometric primitives, a central teal coordinate, and a compass-like theorem
axis. It represents navigation among mathematical forms rather than a literal
portrait or generic calculator.

## Canonical Brand Assets

| Role | Asset |
|---|---|
| Core mark | `assets/visual/brand/theorem_star.svg` |
| App icon master | `assets/visual/brand/theorem_star_app_icon.svg` |
| Maskable icon master | `assets/visual/brand/theorem_star_app_icon_maskable.svg` |
| Artistic name | `assets/visual/brand/gauss_wordmark.png` |
| Flutter semantic wrappers | `lib/widgets/gauss_brand.dart` |

Android adaptive, monochrome, legacy mipmap, launch-screen, favicon, standard
web, and maskable web derivatives are wired from this system. Tests check
package/icon contracts and non-trivial raster assets.

## Visual Decomposition

| Layer | Format/implementation | Why |
|---|---|---|
| Astronomical atmosphere | authored raster backgrounds | Rich texture and depth at low layout cost |
| Sculpted nodes/landmarks | separate raster assets | High-fidelity material detail and independent placement |
| Brand marks | SVG/vector plus raster derivatives | Crisp geometry across icon contexts |
| Wordmark | authored raster image with semantic label | Preserves artistic typography consistently |
| Route/path | live CustomPainter geometry | Responsive, selectable, and continuous |
| Cards, glass, state rings | live Flutter UI | Dynamic state, accessibility, and responsive sizing |
| Question/Persian/math text | live content blocks | Searchable, readable, directional, and data-driven |
| Question ink | live CustomPaint overlay | Immediate interaction without source mutation |

## Rules

1. Never use a whole-screen mockup as the implementation.
2. Decorative static copy may be flattened only when it is not dynamic,
   critical, or interactive and has a semantic equivalent.
3. Real controls, question content, progress, and error states remain live.
4. Every visual asset must preserve aspect ratio and declare its composition
   role; arbitrary cropping is not acceptable.
5. App icon changes must cover Android adaptive/monochrome/legacy, web standard
   and maskable, manifest references, launch screen, and tests.
6. Brand review includes navigation, headers, footers, preview plates,
   posters/marketing surfaces, logos, wordmarks, slogans, empty/error/loading
   states, and system icons—not only the hero screen.

## Verification

The Android contract test verifies package, activity, adaptive/monochrome icon
references, launch background, canonical SVG colors, web manifest icons, and
non-placeholder raster sizes. Web and native runtime captures verify that the
wordmark, mark, backgrounds, nodes, landmarks, and live UI compose correctly.
