## Approved sales-call workspace design

[Open the editable Penpot proposal](https://design.penpot.app/#/workspace?team-id=19c47d73-0a5d-8067-8008-bcb63bc31944&project-id=19c47d73-0a5d-8067-8008-bcb63bc34431&file-id=fd558256-f8c8-8184-8008-c1ea2c4cc442&page-id=07937856-67d9-80a3-8008-c2c6af313cac) — **ObjectionHandler · Sales-call proposal #1**, in the existing file. The verified Current UI baseline and unrelated page are preserved.

### Layout
- Incorporated the owner's requested pane order: **Transcript and My Notes on the left; objections in the majority-width right pane**. At 1080 px, the panes are 340 / 740 px.
- **Three complete objection cards visible together at 1080 × 720**, in light and dark appearances.
- At 1080 × 560, two complete cards remain visible and the third scrolls. At 520 × 560, one complete stacked card is visible; independent viewports keep transcript, notes and recording controls accessible. A separate compact board demonstrates scrolling to the last card. Longer real content wraps and increases card height rather than being truncated.
- Nine editable workspace boards cover waiting, detected, multiple and dismissed states, minimum widths/heights, dark appearance and keyboard focus.

### Card and interaction contract
Every card has stable identity, category/title, exact illustrative prospect words, a product-neutral suggested reply, a follow-up question, Copy and Dismiss. New cards are embedded and non-modal; they never activate the window, change first responder or move the user's scroll position.

Copy includes reply + follow-up, shows Copied briefly and retains focus. Dismiss removes the identified card, not the transcript. Respect macOS Keyboard Navigation: Tab/Shift-Tab traverses controls, Space/Return activates the focused button. Use a 2 px accent focus ring with 2 px offset. Keyboard dismissal moves focus to the next card's Dismiss, then previous, then the objection heading if empty. No single-letter shortcuts interfere with typing in My Notes.

Light/dark follow macOS semantic colors and existing system typography; Reduce Motion removes insertion/removal animation. Recording consent and existing Stop/Pause/Mute/status/error behavior are unchanged. The editable implementation-handoff board contains these requirements.

### Verification
PNG exports visually inspected for all required states and compact/wide light/dark sizes. Descendant containment, rendered-text bounds and card-row overlap checks found **zero violations across nine workspace boards and the handoff board**. Checked text contrast pairs meet AA (minimum **5.10:1**). Baseline SVG remains identical after normalizing export-generated IDs. User-moved card contents and scratchpad text were restored before the requested layout revision.

This is a design deliverable; no application code changed. Scroll/focus/clipboard/detection behavior is specified for implementation, not claimed as running app behavior. Local brief, review and PNG exports are in `.design/sales-call-workspace/`.

### Owner approval
The repo owner explicitly approved this proposal in the design session: “Also I approve.” Approval covers the revised majority-width right objection pane with three complete cards visible at 1080×720, and Transcript and My Notes on the left. Issue #4 must use this approved design.

Approval record: https://github.com/Stoots/objectionhandler/issues/1#issuecomment-6071912983 . Issue #1 is closed with its acceptance checklist complete.

### Inspected previews

![Sales-call workspace: three cards on the right, light/dark, and the four compact states](https://github.com/user-attachments/assets/6abdea96-8727-4e6a-827f-bbff2d070af2)
