import Foundation

/// Shared, session-local coaching contract. Quotes always retain raw transcript text.
enum ObjectionCategory: String, Sendable {
    case priceBudget
}

struct ObjectionCard: Identifiable, Equatable, Sendable {
    let id: UUID
    let category: ObjectionCategory
    let title: String
    let quote: String
    let suggestedReply: String
    let followUpQuestion: String
}

/// Deterministic English phrase matching, not semantic classification.
/// Accepts only finalized utterances, independent of assistant modes and credentials.
struct ObjectionCoaching {
    private(set) var cards: [ObjectionCard] = []
    private var lastProcessedUtteranceID: UUID?

    mutating func consumeFinalized(_ utterance: Utterance) {
        guard utterance.id != lastProcessedUtteranceID else { return }
        lastProcessedUtteranceID = utterance.id
        guard utterance.speaker.isRemote, Self.matchesPriceObjection(utterance.text) else { return }
        let card = ObjectionCard(
            id: cards.first(where: { $0.category == .priceBudget })?.id ?? UUID(),
            category: .priceBudget,
            title: "Price / budget",
            quote: utterance.text,
            suggestedReply: "I hear you. Let's weigh the cost against the outcome you need before deciding whether it makes sense.",
            followUpQuestion: "Is the main concern the available budget, or whether the outcome justifies the cost?"
        )
        if let index = cards.firstIndex(where: { $0.category == .priceBudget }) {
            cards[index] = card
        } else {
            cards.append(card)
        }
    }

    mutating func dismiss(_ id: UUID) {
        cards.removeAll { $0.id == id }
    }

    mutating func reset() {
        cards.removeAll(keepingCapacity: true)
        lastProcessedUtteranceID = nil
    }

    // Compiled once; matching never creates tasks or calls a provider.
    private static let clauseBreak = try! NSRegularExpression(pattern: #"[.!?;\n]|\b(?:but|however|yet)\b"#)
    private static let wordBreak = try! NSRegularExpression(pattern: #"[^\p{L}\p{N}]+"#)
    private static let pricePhrase = try! NSRegularExpression(pattern:
        #"\b(?:too (?:expensive|pricey|pricy|costly)|(?:price|cost|pricing) (?:is |seems |feels )?too (?:high|much)|(?:cant|cannot|can not) afford|(?:dont|do not) have (?:the |any |enough )?budget|(?:no|not enough|insufficient) budget|(?:over|outside|beyond) (?:our|my|the) budget)\b"#
    )
    private static let denial = try! NSRegularExpression(pattern:
        #"\b(?:not|never|no|isnt|arent|wasnt|werent|dont|doesnt|didnt|cant|cannot)\b"#
    )
    private static let budgetNonObjection = try! NSRegularExpression(pattern:
        #"^ (?:issues?|problems?|concerns?|limits?|constraints?|needed|required)\b"#
    )

    private static func matchesPriceObjection(_ text: String) -> Bool {
        let lowercase = text.lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "‘", with: "")
        let separated = clauseBreak.stringByReplacingMatches(
            in: lowercase, range: NSRange(lowercase.startIndex..., in: lowercase), withTemplate: "\n"
        )
        for clause in separated.split(separator: "\n") {
            let raw = String(clause)
            let normalized = wordBreak.stringByReplacingMatches(
                in: raw, range: NSRange(raw.startIndex..., in: raw), withTemplate: " "
            ).trimmingCharacters(in: .whitespaces)
            let range = NSRange(normalized.startIndex..., in: normalized)
            for match in pricePhrase.matches(in: normalized, range: range) {
                guard let phraseRange = Range(match.range, in: normalized) else { continue }
                let prefix = String(normalized[..<phraseRange.lowerBound])
                    .replacingOccurrences(of: "not only ", with: "")
                if denial.firstMatch(in: prefix, range: NSRange(prefix.startIndex..., in: prefix)) != nil {
                    continue
                }
                let phrase = normalized[phraseRange]
                if phrase.hasSuffix("budget") {
                    let suffix = String(normalized[phraseRange.upperBound...])
                    if budgetNonObjection.firstMatch(in: suffix, range: NSRange(suffix.startIndex..., in: suffix)) != nil {
                        continue
                    }
                }
                return true
            }
        }
        return false
    }
}
