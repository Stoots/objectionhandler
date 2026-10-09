import XCTest
@testable import OpenOatsKit

final class ObjectionBoardPresentationTests: XCTestCase {
    private func card(
        _ category: ObjectionCategory = .priceBudget,
        id: UUID = UUID(),
        quote: String = "That is too expensive!",
        reply: String = "Let's weigh the cost against the outcome.",
        question: String = "Is the concern the budget, or the outcome?"
    ) -> ObjectionCard {
        ObjectionCard(
            id: id, category: category, title: "Price / budget",
            quote: quote, suggestedReply: reply, followUpQuestion: question
        )
    }

    // MARK: - Clipboard payload

    func testClipboardTextContainsReplyAndFollowUpButNotTheProspectQuote() {
        let card = self.card(
            quote: "We don't have the budget!",
            reply: "Let's weigh the cost.",
            question: "Is it budget or outcome?"
        )
        let text = card.clipboardText

        XCTAssertTrue(text.contains("Let's weigh the cost."))
        XCTAssertTrue(text.contains("Is it budget or outcome?"))
        XCTAssertFalse(text.contains(card.quote), "The exact prospect words must not reach the clipboard")
    }

    // MARK: - Board phase

    func testEmptyBoardIsWaitingUnlessPausedOrDismissed() {
        XCTAssertEqual(
            ObjectionBoardPresentation(cards: [], isRecordingPaused: false, hasDismissed: false).phase,
            .waiting
        )
        XCTAssertEqual(
            ObjectionBoardPresentation(cards: [], isRecordingPaused: true, hasDismissed: false).phase,
            .paused
        )
        XCTAssertEqual(
            ObjectionBoardPresentation(cards: [], isRecordingPaused: false, hasDismissed: true).phase,
            .dismissed
        )
    }

    func testDismissedPhaseOutranksPausedOnceEveryCardIsGone() {
        let presentation = ObjectionBoardPresentation(cards: [], isRecordingPaused: true, hasDismissed: true)
        XCTAssertEqual(presentation.phase, .dismissed)
    }

    func testCardsProduceActivePhaseAndMultipleFlag() {
        let one = ObjectionBoardPresentation(cards: [card()], isRecordingPaused: false, hasDismissed: false)
        XCTAssertEqual(one.phase, .active)
        XCTAssertFalse(one.isMultiple)
        XCTAssertNil(one.emptyMessage)

        let many = ObjectionBoardPresentation(
            cards: [card(.priceBudget), card(.timingPriority)],
            isRecordingPaused: false, hasDismissed: false
        )
        XCTAssertEqual(many.phase, .active)
        XCTAssertTrue(many.isMultiple)
    }

    // MARK: - Focus plan

    func testDismissingMiddleCardFocusesTheCardBelow() {
        let cards = [card(id: UUID()), card(id: UUID()), card(id: UUID())]
        let focus = ObjectionBoardFocusPlan.focusAfterDismiss(dismissingAt: 1, in: cards)
        XCTAssertEqual(focus, .dismiss(cards[2].id))
    }

    func testDismissingTopCardFocusesTheCardBelow() {
        let cards = [card(id: UUID()), card(id: UUID())]
        let focus = ObjectionBoardFocusPlan.focusAfterDismiss(dismissingAt: 0, in: cards)
        XCTAssertEqual(focus, .dismiss(cards[1].id))
    }

    func testDismissingLastCardFocusesTheCardAbove() {
        let cards = [card(id: UUID()), card(id: UUID())]
        let focus = ObjectionBoardFocusPlan.focusAfterDismiss(dismissingAt: 1, in: cards)
        XCTAssertEqual(focus, .dismiss(cards[0].id))
    }

    func testDismissingTheOnlyCardFallsBackToTheHeading() {
        let cards = [card(id: UUID())]
        XCTAssertEqual(ObjectionBoardFocusPlan.focusAfterDismiss(dismissingAt: 0, in: cards), .heading)
    }
}
