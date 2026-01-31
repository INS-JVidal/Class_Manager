# Prototype UI Plan v3

This document updates the Prototype UI Plan to reflect the fixes and UI
adjustments applied during the current iteration.

## Goals
- Keep the UI light but slightly darker overall, using forest green as the main
  brand shade.
- Ensure the desktop app runs as a single instance.
- Remove unnecessary actions in the "Mòduls" view.
- Fix scroll overflow in long lists, with proper mouse interaction.

## Theme and Visual Style
- Primary color: forest green (`#1B5E20`) as the main seed and primary color.
- Light surfaces are slightly darker than before, but still in a light theme.
  - `surface` and `background`: `#F1F4F1`
  - `surfaceVariant`: `#E1E7E1`
- Material 3 theme stays enabled.

## Desktop Behavior
- Enforce single-instance behavior using a file lock.
- If another instance is already running, the new instance exits early.

## Screen Updates

### Mòduls View
- Remove the "+ Afegir mòdul" button from the header.
- Remove the "Afegiu-ne un." prompt from the empty state.
- Remove the `/moduls/new` navigation route.

### Configuració del currículum
- Fix overflow in "Pas 2: Mòduls a importar".
- Make the full content scrollable.
- Show a visible scrollbar that supports mouse wheel and click-drag.

## Fixed Issues Summary
- Single-instance desktop guard added.
- Forest green palette applied to light theme.
- Removed unnecessary "Afegir mòdul" UI and route.
- Scroll overflow resolved and scrollbar now interactive.
