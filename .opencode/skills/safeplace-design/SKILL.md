---
name: safeplace-design
description: Use when designing, restyling, reviewing, or adding UI to the SafePlace iOS app (SwiftUI). Enforces the "warm editorial paper" art direction, the design tokens, accessibility rules, and an explicit anti-slop blacklist so screens don't look generic or AI-generated.
---

# SafePlace design skill

Committed art direction for the SafePlace app. Every screen, component and
motion must obey this. When in doubt, choose restraint and editorial hierarchy.

## Visual thesis

**Warm editorial paper.** The app should feel like a well-made notebook: warm
near-white paper, ink typography, a display serif for titles, a single
mood-tinted accent used with intent, and content expressed as sections and
lists separated by hairlines — not a grid of generic rounded cards. Calm,
tactile, unhurried, personal.

Content plan per screen: one idea, one dominant element, sparse copy.
Interaction thesis: at most 2–3 purposeful motions (staggered entrance, a
selection transition, one ambient motion), all respecting Reduce Motion.

## Tokens

### Surfaces (adaptive, warm)
- `canvas` `#FAF8F4` / dark `#000000`
- `surfaceSoft` `#F3EFE8` / `#141414`
- `surfaceCard` `#FFFFFF` / `#0E0E0E`
- `hairline` warm ink 10% / white 12%

### Ink
- `ink` `#2A2622` / `#F3EEE7`
- `inkSecondary` `#6B625A` / `#B8AFA6`
- `muted` ink 66% / white 55%

### Accent
- One accent = the mood tint (`appTheme.tint` / `appTheme.tintStrong`).
- Never introduce a second decorative accent.

### Type
- Display / titles: **system serif** (`Font.system(.title, design: .serif)`), weight ≤ 600.
- Body / UI: SF (`Font.system(.subheadline/.footnote/...)`), semantic styles only.
- Wordmark "SafePlace": serif, the loudest text on Home.

### Space & shape
- Spacing scale in 4s: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48.
- Radii: 8 / 12 / 16 / 24 / pill. Prefer hairlines over borders.
- Minimum touch target 44×44.

## Motifs
- A thin **asterisk / starburst** mark as the recurring brand glyph.
- **Date hierarchy**: large serif date numerals over small sans labels.
- Subtle paper grain (very low opacity) for atmosphere — never a heavy gradient.
- **Two-pole rows**: a secondary text action right-aligned opposite its label.

## Cards
- **Default: no cards.** Use sections, lists, and hairline dividers.
- A card is allowed only when the card *is* the interaction (a note you tap).
- Note cards are **paper fichas**: a thin colored spine/tab, serif title, sans
  body, hairline edge, no heavy shadow. Never nested cards.

## Components
- Buttons: pill or square, ink-filled primary; text/outline secondary.
- Avatar: a **brand element** (mood-tinted orb/blob with initial or the mini
  character), never a plain circle with a person glyph.
- Icons: prefer a small, consistent set; give icon-only buttons a label.

## Motion
- Easing: custom springs, not linear. 2–3 intentional motions max.
- Respect `accessibilityReduceMotion`; ambient loops stop when reduced.

## Accessibility (non-negotiable)
- Dynamic Type: semantic fonts, flexible heights (`minHeight`, not `height`).
- Contrast ≥ 4.5:1 text, ≥ 3:1 controls. Never color-only meaning.
- `accessibilityLabel` on icon buttons; decorative art hidden.
- Stable `accessibilityIdentifier` on primary controls for UI tests.

## Anti-slop blacklist (do NOT use)
- Generic fonts (Inter/Roboto/Arial/system-default) for display; purple/indigo
  gradients on white; centered hero + three feature cards.
- `rounded + shadow` on every surface; reflexive glassmorphism; icon-in-a-rounded-square.
- Cards nested in cards; pill soup; stat strips; emoji as bullets.
- Emoji/emoji-like SF symbols as the only way to convey meaning.
- Generic copy ("Elevate…", "Get started") — write in product language.

## Litmus checks
- Is the screen unmistakably SafePlace (not a template)?
- Is there one clear dominant element and clear hierarchy by type/space?
- Could any shadow or border be removed without hurting the interaction?
- Does it hold at AX5 text size, dark mode, and Reduce Motion?
