# Design Review: Sales-call workspace

Reviewed against: DESIGN_BRIEF.md and Stoots/objectionhandler#1, including the owner's requested majority-width right objection pane.
Philosophy: native macOS functionalist utility.

## Screenshots Captured
All images are exported from the editable proposal in the existing Penpot file, not from application code.

| Screenshot | Size/state |
| --- | --- |
| `screenshots/waiting-520-light.png` | 520×560, waiting |
| `screenshots/detected-520-light.png` | 520×560, detected, notes focus retained |
| `screenshots/multiple-520-light.png` | 520×560, three active cards, first visible |
| `screenshots/dismissed-520-light.png` | 520×560, dismissed, transcript preserved |
| `screenshots/three-cards-1080-light.png` | 1080×720, three complete cards on right |
| `screenshots/three-cards-1080-dark.png` | 1080×720, dark, Copy keyboard focus |
| `screenshots/detected-520-dark.png` | 520×560, dark, notes focus retained |
| `screenshots/three-cards-1080-min-height.png` | 1080×560, two complete cards plus third by scrolling |
| `screenshots/multiple-520-scrolled.png` | 520×560, last card scrolled into view |
| `screenshots/compact-states.png` | Montage of the four required light states |

## Findings and Verification
- Visually inspected light/dark wide layouts, all four compact states, compact dark appearance, minimum-height wide layout and last-card scroll state.
- At 1080×720, Transcript and My Notes occupy the 340 px left pane; objections occupy the 740 px majority-width right pane. Three complete 168 px cards fit without clipping.
- At 1080×560, two complete cards remain visible, with a third reachable through independent objection scrolling. At 520×560, one complete card, live transcript, scratchpad and recording controls remain visible.
- Penpot descendant containment and rendered-text bounds checks returned zero violations across nine workspace boards and the implementation-handoff board. Separate card-row intersection checks returned zero overlaps.
- Light/dark text contrast pairs checked numerically: minimum 5.10:1. Light body/card 12.54:1; secondary/chrome 5.50:1; dark body/card 12.12:1; dark secondary/card 7.40:1. Focus accent contrast on dark chrome 7.41:1.
- Baseline SVG comparison was identical after normalizing export-generated render and stroke IDs. No baseline or unrelated page edits were applied.
- Restored the user-moved card contents and scratchpad text before applying the requested pane-order change. Restored previews were exported and inspected.
- Every card contains category/title, exact illustrative prospect quote, product-neutral reply, follow-up question, Copy and Dismiss. Third example concerns an existing provider; no capabilities or proof claims were introduced.
- Keyboard/focus, copy/dismiss, long-text wrapping, light/dark semantic colors, screen-reader and reduced-motion contracts are specified in the brief and an editable Penpot handoff board.

## Must Fix
None identified in the exported proposal.

## Implementation Limits
This is a design deliverable. Scroll, keyboard focus, detection, clipboard, persistence and consent behaviors are implementation requirements, not implemented application behavior. No application tests were run or app code changed. Longer real text must grow card height; three visible cards is a demonstrated capacity for concise examples, not a truncation rule.

## Approval Gate
The repo owner explicitly approved the revised proposal in the design session: “Also I approve.” Implementation must use this approved design, including the left context pane and majority-width right objection pane with three complete cards at 1080×720.

Approval request and the attached light/dark + four-state preview sheet: https://github.com/Stoots/objectionhandler/issues/1#issuecomment-6071885629

Owner approval recorded: https://github.com/Stoots/objectionhandler/issues/1#issuecomment-6071912983 . Issue #1 is closed and its acceptance checklist is complete. The approved Penpot handoff annotation was exported and visually inspected.
