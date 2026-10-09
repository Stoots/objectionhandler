import Foundation

extension ObjectionCard {
    /// Clipboard payload for the Copy control: the suggested reply and the
    /// follow-up question, and nothing else. The prospect's exact words are
    /// deliberately excluded so a rep cannot paste the quote back at them.
    var clipboardText: String {
        "\(suggestedReply)\n\n\(followUpQuestion)"
    }
}

/// Board phase derived from the live card collection and session flags.
/// Pure, so the waiting / paused / detected / dismissed contract is testable
/// without a running view.
enum ObjectionBoardPhase: Equatable {
    /// No cards yet; listening for the first finalized remote objection.
    case waiting
    /// No cards and the recording is paused; coaching resumes with speech.
    case paused
    /// Cards existed and the user dismissed them all this session.
    case dismissed
    /// One or more cards are on the board.
    case active
}

/// A snapshot of what the objection board should show. `cards` is newest-first,
/// matching the live collection the controller projects.
struct ObjectionBoardPresentation: Equatable {
    let phase: ObjectionBoardPhase
    let cards: [ObjectionCard]

    init(cards: [ObjectionCard], isRecordingPaused: Bool, hasDismissed: Bool) {
        self.cards = cards
        if cards.isEmpty {
            if hasDismissed {
                phase = .dismissed
            } else if isRecordingPaused {
                phase = .paused
            } else {
                phase = .waiting
            }
        } else {
            phase = .active
        }
    }

    var isEmpty: Bool { cards.isEmpty }
    var isMultiple: Bool { cards.count > 1 }

    /// Message for the empty board. Mirrors the two pre-existing strings so the
    /// waiting/paused copy the app already shipped is preserved verbatim.
    var emptyMessage: String? {
        switch phase {
        case .waiting:
            return "Waiting for a finalized remote objection."
        case .paused:
            return "Recording paused. Coaching resumes with finalized remote speech."
        case .dismissed:
            return "Objection dismissed. Still listening for the next one."
        case .active:
            return nil
        }
    }
}

/// A keyboard focus target inside the objection board.
enum ObjectionBoardFocus: Hashable {
    case dismiss(UUID)
    case copy(UUID)
    case heading
}

enum ObjectionBoardFocusPlan {
    /// Where focus should move once the card at `index` is dismissed.
    ///
    /// Visual order is array order (index 0 is newest, at the top). Preference is
    /// the card below the dismissed one (which slides up into its place), then
    /// the card above, then the section heading when the board is empty.
    static func focusAfterDismiss(dismissingAt index: Int, in cards: [ObjectionCard]) -> ObjectionBoardFocus {
        let remaining = cards.enumerated().filter { $0.offset != index }.map(\.element)
        if index < remaining.count {
            return .dismiss(remaining[index].id)
        }
        if let last = remaining.last {
            return .dismiss(last.id)
        }
        return .heading
    }
}
