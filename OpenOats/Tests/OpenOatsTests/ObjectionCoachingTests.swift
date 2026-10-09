import XCTest
@testable import OpenOatsKit

final class ObjectionCoachingTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)
    private let examples: [(ObjectionCategory, [String], [String])] = [
        (.priceBudget,
         ["We don't have the budget.", "WE DON’T HAVE THE BUDGET!", "We do not have enough budget.", "We can't afford it.", "I cannot afford this.", "That's too pricey.", "The price is too high.", "This is outside our budget.", "We have no budget for this.", "There’s not enough budget.", "Too, expensive!", "The timing is not ideal, but we don't have the budget.", "It's not too expensive. We don't have the budget.", "This is not only too expensive, it is also unnecessary."],
         ["Can you tell me the price?", "We talked about the budget.", "Our budget is approved.", "It is not too expensive.", "It isn't too expensive.", "It’s not too expensive!", "I don't think it is too expensive.", "The price is not too high.", "We can afford it.", "It is not outside our budget.", "There are no budget concerns.", "No budget problems here.", "We don't have the budget issue anymore.", "That is never too expensive."]),
        (.timingPriority,
         ["Not now.", "This is not a priority.", "We're too busy.", "We don't have time.", "Call back next quarter.", "It's a bad time."],
         ["What is the timing?", "This is a priority.", "It is not a bad time.", "We're not too busy.", "I didn't say not now."]),
        (.existingProvider,
         ["We already have a provider.", "We're currently using another solution.", "We're happy with our current vendor.", "We're under contract with Acme."],
         ["Which provider?", "We don't already have a provider.", "We're not happy with our current vendor.", "We're not under contract with anyone."]),
        (.lackOfInterest,
         ["I'm not interested.", "We don't need this.", "I see no need for it.", "This isn't relevant."],
         ["This is interesting.", "We need this.", "I didn't say I'm not interested.", "We don't need to wait.", "I'm not interested in delaying."]),
        (.sendInformation,
         ["Send me some information.", "Just email me.", "Email us the details.", "Put it in an email."],
         ["What is your email?", "Don't send me information.", "Do not email us.", "No need to send me a summary.", "Please don't put it in an email."]),
        (.decisionMaker,
         ["I'm not the decision maker.", "I cannot approve this.", "I need to check with my boss.", "Our manager makes the decision."],
         ["Who is the decision maker?", "I am the decision maker.", "I don't need to check with my boss.", "I didn't say I'm not the decision maker."]),
        (.implementationEffort,
         ["Migration would be too difficult.", "It's too hard to implement.", "We don't want to switch.", "I'm worried about the integration."],
         ["Tell me about implementation.", "Migration is not too difficult.", "It's not too hard to implement.", "I'm not worried about the integration.", "I didn't say we don't want to switch."]),
    ]

    func testEachCategoryRecognizesMeaningfulPhrasesAndRejectsIncidentalOrNegatedObjections() {
        for (category, positives, negatives) in examples {
            for text in positives {
                var coaching = ObjectionCoaching()
                coaching.consumeFinalized(Utterance(text: text, speaker: .remote(3)))
                XCTAssertEqual(coaching.cards.map(\.category), [category], text)
                XCTAssertEqual(coaching.cards.first?.quote, text)
            }
            for text in negatives {
                var coaching = ObjectionCoaching()
                coaching.consumeFinalized(Utterance(text: text, speaker: .them))
                XCTAssertFalse(coaching.cards.contains { $0.category == category }, text)
            }
        }
    }

    func testLocalSpeechDoesNotCreateAnyCategoryAndRemoteVariantsRetainRawQuote() {
        for (category, positives, _) in examples {
            for speaker in [Speaker.them, .remote(1), .remote(4)] {
                var coaching = ObjectionCoaching()
                let text = positives[0]
                coaching.consumeFinalized(Utterance(text: text, speaker: .you))
                XCTAssertTrue(coaching.cards.isEmpty)
                coaching.consumeFinalized(Utterance(text: text, speaker: speaker, cleanedText: "A rewritten transcript"))
                XCTAssertEqual(coaching.cards.first?.category, category)
                XCTAssertEqual(coaching.cards.first?.quote, text)
            }
        }
    }

    func testMultipleCategoriesInOneUtteranceAreIndependentAndVisibleCollectionIsBoundedNewestFirst() throws {
        var coaching = ObjectionCoaching()
        let multi = "We don't have the budget, not interested, send me information."
        coaching.consumeFinalized(Utterance(text: multi, speaker: .them))
        XCTAssertEqual(Set(coaching.cards.map(\.category)), [.priceBudget, .lackOfInterest, .sendInformation])
        XCTAssertTrue(coaching.cards.allSatisfy { $0.quote == multi })
        coaching.reset()
        for (index, example) in examples.enumerated() {
            coaching.consumeFinalized(Utterance(text: example.1[0], speaker: .remote(index)))
            XCTAssertEqual(coaching.cards.count, min(index + 1, 5))
            XCTAssertEqual(coaching.cards.first?.category, example.0)
        }
        XCTAssertEqual(coaching.cards.map(\.category), examples.suffix(5).reversed().map { $0.0 })
        let original = try XCTUnwrap(coaching.cards.first { $0.category == .existingProvider })
        let updatedQuote = "We're happy with our current vendor."
        coaching.consumeFinalized(Utterance(text: updatedQuote, speaker: .them))
        XCTAssertEqual(coaching.cards.count, 5)
        XCTAssertEqual(coaching.cards.first?.id, original.id)
        XCTAssertEqual(coaching.cards.first?.quote, updatedQuote)
        XCTAssertEqual(coaching.cards.first?.category, .existingProvider)
    }

    func testAdjacentChunksCompletePhraseAtFifteenSecondsAndDoNotRetriggerOldText() throws {
        for gap in [0.0, 15.0] {
            var coaching = ObjectionCoaching()
            let first = Utterance(text: "We don't have", speaker: .remote(2), timestamp: epoch)
            let second = Utterance(text: "the budget!", speaker: .remote(2), timestamp: epoch.addingTimeInterval(gap))
            coaching.consumeFinalized(first, now: epoch)
            XCTAssertTrue(coaching.cards.isEmpty)
            coaching.consumeFinalized(second, now: epoch)
            let card = try XCTUnwrap(coaching.cards.first)
            XCTAssertEqual(card.quote, first.text + "\n" + second.text)
            coaching.consumeFinalized(Utterance(text: "Thanks for explaining.", speaker: .remote(2), timestamp: epoch.addingTimeInterval(gap + 1)), now: epoch)
            XCTAssertEqual(coaching.cards, [card])
        }
        var coaching = ObjectionCoaching()
        coaching.consumeFinalized(Utterance(text: "It is not", speaker: .them, timestamp: epoch))
        coaching.consumeFinalized(Utterance(text: "too expensive", speaker: .them, timestamp: epoch.addingTimeInterval(1)))
        XCTAssertTrue(coaching.cards.isEmpty, "Negation must carry across the same boundary")
    }

    func testFragmentedPhraseAndTrailingUnfinishedCategoryAfterCompletedObjection() throws {
        var coaching = ObjectionCoaching()
        for (index, text) in ["We", "don't have", "the budget."].enumerated() {
            coaching.consumeFinalized(Utterance(text: text, speaker: .them, timestamp: epoch.addingTimeInterval(Double(index))))
        }
        XCTAssertEqual(coaching.cards.first?.quote, "We\ndon't have\nthe budget.")
        coaching.reset()
        coaching.consumeFinalized(Utterance(text: "Too expensive and send", speaker: .them, timestamp: epoch))
        let price = try XCTUnwrap(coaching.cards.first)
        coaching.consumeFinalized(Utterance(text: "me information.", speaker: .them, timestamp: epoch.addingTimeInterval(1)))
        XCTAssertEqual(coaching.cards.map(\.category), [.sendInformation, .priceBudget])
        XCTAssertEqual(coaching.cards.last, price, "Completing email must not replay the earlier price phrase")
        XCTAssertEqual(coaching.cards.first?.quote, "Too expensive and send\nme information.")
    }

    func testSplitPhraseDoesNotCrossRepDifferentRemoteLongGapOrReversedTime() {
        let interruptions: [(Speaker?, TimeInterval)] = [(.you, 1), (.remote(4), 1), (nil, 15.001), (nil, -1)]
        for (interruption, gap) in interruptions {
            var coaching = ObjectionCoaching()
            coaching.consumeFinalized(Utterance(text: "Send me", speaker: .remote(2), timestamp: epoch))
            if let interruption {
                coaching.consumeFinalized(Utterance(text: "Sure.", speaker: interruption, timestamp: epoch))
            }
            coaching.consumeFinalized(Utterance(text: "some information", speaker: .remote(2), timestamp: epoch.addingTimeInterval(gap)))
            XCTAssertTrue(coaching.cards.isEmpty, "Interruption: \(String(describing: interruption)), gap: \(gap)")
        }
    }

    func testDismissalSuppressesOnlyItsCategoryUntilThirtySecondsAndReplayCannotRestoreIt() throws {
        var coaching = ObjectionCoaching()
        let first = Utterance(text: "We don't have the budget.", speaker: .them, timestamp: epoch)
        coaching.consumeFinalized(first, now: epoch)
        let card = try XCTUnwrap(coaching.cards.first)
        coaching.dismiss(UUID(), now: epoch)
        XCTAssertEqual(coaching.cards, [card])
        coaching.dismiss(card.id, now: epoch)
        coaching.consumeFinalized(first, now: epoch.addingTimeInterval(31))
        XCTAssertTrue(coaching.cards.isEmpty)
        coaching.consumeFinalized(Utterance(text: "Too expensive. Not now.", speaker: .them), now: epoch.addingTimeInterval(29.999))
        XCTAssertEqual(coaching.cards.map(\.category), [.timingPriority])
        coaching.consumeFinalized(Utterance(text: "Too expensive.", speaker: .remote(1)), now: epoch.addingTimeInterval(30))
        XCTAssertEqual(coaching.cards.first?.category, .priceBudget)
        XCTAssertNotEqual(coaching.cards.first?.id, card.id)
    }

    func testResetClearsCardsSuppressionAndSplitContext() throws {
        var coaching = ObjectionCoaching()
        let first = Utterance(text: "Too expensive.", speaker: .them, timestamp: epoch)
        coaching.consumeFinalized(first, now: epoch)
        let id = try XCTUnwrap(coaching.cards.first?.id)
        coaching.dismiss(id, now: epoch)
        coaching.consumeFinalized(Utterance(text: "Send me", speaker: .them, timestamp: epoch), now: epoch)
        coaching.reset()
        XCTAssertTrue(coaching.cards.isEmpty)
        coaching.consumeFinalized(Utterance(text: "information", speaker: .them, timestamp: epoch), now: epoch)
        XCTAssertTrue(coaching.cards.isEmpty)
        coaching.consumeFinalized(first, now: epoch)
        XCTAssertEqual(coaching.cards.first?.quote, first.text)
        XCTAssertNotEqual(coaching.cards.first?.id, id)
    }
}
