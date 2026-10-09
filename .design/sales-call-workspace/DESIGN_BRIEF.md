# Design Brief: Sales-call workspace

## Problem
The rep needs to glance at an objection and return to the conversation without losing the live transcript, scratchpad, or recording controls.

## Solution
A native macOS live-call workspace with an embedded, non-modal objection section. At 520 px, a bounded card viewport sits above Transcript and My Notes. At 1080 px, Transcript and My Notes occupy a 340 px left pane and objections occupy the majority-width 740 px right pane. Three complete cards are visible together at 1080×720. Recording controls remain pinned below both.

## Experience Principles
1. Conversation over interruption: new cards never steal keyboard focus, open a modal, or move the current scroll position.
2. Context over persuasion: preserve exact prospect words and offer short, product-neutral replies and questions.
3. Persistent tools over full-card density: independent scrolling keeps transcript, notes, and recording controls reachable at minimum size.

## Aesthetic Direction
- Philosophy: functionalist, native macOS utility; compact typography, separators, restrained rounding, one blue functional accent.
- Tone: calm, legible, discreet.
- Reference: verified Current UI page in the existing Penpot file.
- Anti-reference: web dashboards, marketing layouts, decorative gradients, KPI tiles.

## Existing Patterns
- SwiftUI system typography: 13 px semibold application name, 12 px section headings and text, 11 px metadata. Penpot uses the baseline's Inter Tight surrogate because SF Pro is unavailable; implementation uses the existing system font.
- Neutral macOS chrome; 16 px horizontal padding; 6 px editor/button rounding; dividers instead of shadows.
- Existing Notes Workspace and Settings actions, Transcript, My Notes, Stop, Pause, Mute, elapsed time, audio meter, and selected model remain.
- Existing minimum window is 520×560; expanded minimum is 1080×560.

## Component Inventory
| Component | Status | Notes |
| --- | --- | --- |
| Native application header | Exists | Preserve Notes Workspace and Settings |
| Transcript section | Modify | Independent viewport; preserve copy and separate-window actions |
| My Notes scratchpad | Modify | Persistent viewport and existing editable text |
| Recording footer | Exists | Pinned; preserve existing status, errors and controls |
| Objection section | New | Waiting, detected, multiple and dismissed states |
| Objection card | New | Stable identity, category/title, exact prospect quote, suggested reply, follow-up, copy, dismiss |
| Dismissal feedback | New | Inline confirmation; never alter transcript |

## Key Interactions
- Detection appends a stable-identity card without activating the app/window or changing first responder. Only confirmed prospect speech triggers cards. Illustrative examples are labelled.
- Copy copies only the suggested reply and follow-up question, not the exact quote; shows Copied briefly, without moving focus.
- Dismiss removes that card by stable identity; leaves its transcript utterance intact. With no cards remaining, show a quiet dismissed state and continue waiting.
- Keyboard: follow macOS Keyboard Navigation settings. Tab/Shift-Tab traverses actions and the note editor; Space/Return activates the focused button. Card containers and quote text do not become redundant tab stops. No global single-letter shortcuts; typing in My Notes must remain typing.
- Use a visible 2 px accent focus ring with 2 px offset; focus remains on Copy after copying. After keyboard dismissal, focus moves to the next card's Dismiss button, then previous card's Dismiss, then the objection-section heading when empty. Detection never moves focus. Native transcript/editor keyboard behavior is preserved.
- Screen reader: labelled section and grouped cards, speaker and exact quote, clearly distinct reply and question; concise low-priority announcement on detection/dismissal without rereading the transcript.

## Responsive Behavior
- 520–879 px: vertical split. Full-width cards; bounded scrollable card viewport, transcript viewport, and notes editor. Compact screenshots explicitly include 520×560.
- 880 px and above: two columns, a 340 px context pane on the left and the remaining, majority-width objection pane on the right. At 1080×720, three full 168 px cards fit vertically. Each wide card places suggested reply and follow-up side by side; category/title and exact quote stay above them, with copy/dismiss below.
- At 1080×560, two full wide cards are visible with a third reachable by independent scrolling. At 520×560, one full stacked card is visible and the remaining cards scroll. Longer real text wraps without ellipsis and increases card height; three visible cards is a capacity demonstrated with concise examples, not a reason to truncate content. Preserve scroll position on insertion and provide a new-card count when scrolled away. Do not squeeze text or hide notes.
- Resizing preserves editor selection, focus, stable card order and scroll position. Section splitters may redistribute body space, never the pinned recording footer.
- Existing recording errors occupy footer space before discretionary body space; body scrolls rather than hiding recording controls. Consent workflow is unchanged.

## Accessibility Requirements
- All content text meets WCAG AA 4.5:1 in light and dark examples; focus boundaries meet 3:1 against adjacent surfaces.
- Native system font, 13 px card body, 18 px leading; avoid color-only category/state cues.
- Light/dark follow macOS appearance and semantic AppKit/SwiftUI colors; no theme toggle added. Reduce Transparency uses solid backgrounds. Reduce Motion uses immediate insertion/removal with no animation.
- Native labelled controls and text selection; no focus trap, modal overlay or automatic card expiry.

## Out of Scope
Application code, detector implementation, product capabilities, discounts, customer proof, invented metrics, changed consent behavior, onboarding, home dashboard, mobile/web UI. Owner approval is required before implementation or issue closure.
