import XCTest
@testable import OpenOatsKit

final class ObjectionCoachingTests: XCTestCase {
    func testOnlyFinalizedRemoteSpeechCreatesPriceCardWithExactQuote() throws {
        var coaching = ObjectionCoaching()
        coaching.consumeFinalized(Utterance(text: "They said: That is too expensive!", speaker: .you))
        XCTAssertTrue(coaching.cards.isEmpty)

        let quote = "That is TOO expensive!"
        coaching.consumeFinalized(Utterance(text: quote, speaker: .them))
        let card = try XCTUnwrap(coaching.cards.first)
        XCTAssertEqual(coaching.cards.count, 1)
        XCTAssertEqual(card.category, .priceBudget)
        XCTAssertEqual(card.quote, quote)
        XCTAssertEqual(card.title, "Price / budget")
    }

    func testPriceAndBudgetPhrasesRespectNegationAndIncidentalMentionBoundaries() {
        let objections = [
            "We don't have the budget.",
            "WE DON’T HAVE THE BUDGET!",
            "We do not have enough budget.",
            "We can't afford it.",
            "I cannot afford this.",
            "That's too pricey.",
            "The price is too high.",
            "This is outside our budget.",
            "We have no budget for this.",
            "There’s not enough budget.",
            "Too, expensive!",
            "The timing is not ideal, but we don't have the budget.",
            "It's not too expensive. We don't have the budget.",
            "This is not only too expensive, it is also unnecessary.",
        ]
        for phrase in objections {
            var coaching = ObjectionCoaching()
            coaching.consumeFinalized(Utterance(text: phrase, speaker: .remote(3)))
            XCTAssertEqual(coaching.cards.first?.quote, phrase, phrase)
        }

        let nonObjections = [
            "Can you tell me the price?",
            "We talked about the budget.",
            "Our budget is approved.",
            "It is not too expensive.",
            "It isn't too expensive.",
            "It’s not too expensive!",
            "I don't think it is too expensive.",
            "The price is not too high.",
            "We can afford it.",
            "It is not outside our budget.",
            "There are no budget concerns.",
            "No budget problems here.",
            "We don't have the budget issue anymore.",
            "That is never too expensive.",
        ]
        for phrase in nonObjections {
            var coaching = ObjectionCoaching()
            coaching.consumeFinalized(Utterance(text: phrase, speaker: .them))
            XCTAssertTrue(coaching.cards.isEmpty, phrase)
        }
    }

    func testDismissalIgnoresReplayButNewUtteranceAndResetCanSurfaceAgain() throws {
        var coaching = ObjectionCoaching()
        let utterance = Utterance(text: "We don't have the budget.", speaker: .remote(2))
        coaching.consumeFinalized(utterance)
        let first = try XCTUnwrap(coaching.cards.first)
        coaching.dismiss(UUID())
        XCTAssertEqual(coaching.cards.first?.id, first.id, "A stale dismiss must not remove another card")
        coaching.dismiss(first.id)
        coaching.consumeFinalized(utterance)
        XCTAssertTrue(coaching.cards.isEmpty)
        coaching.consumeFinalized(Utterance(text: utterance.text, speaker: .them))
        let next = try XCTUnwrap(coaching.cards.first)
        XCTAssertNotEqual(next.id, first.id)
        coaching.reset()
        XCTAssertTrue(coaching.cards.isEmpty)
        coaching.consumeFinalized(utterance)
        XCTAssertEqual(coaching.cards.first?.quote, utterance.text)
        XCTAssertNotEqual(coaching.cards.first?.id, next.id)
    }
}
