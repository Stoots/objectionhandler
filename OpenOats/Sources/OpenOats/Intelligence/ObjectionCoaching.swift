import Foundation

/// Shared, session-local coaching contract. Quotes always retain raw transcript text.
enum ObjectionCategory: String, Sendable {
    case priceBudget
    case timingPriority
    case existingProvider
    case lackOfInterest
    case sendInformation
    case decisionMaker
    case implementationEffort
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
    private var remoteChunks: [(utterance: Utterance, normalized: String)] = []
    private var suppressedUntil: [ObjectionCategory: Date] = [:]

    mutating func consumeFinalized(_ utterance: Utterance, now: Date = .now) {
        guard utterance.id != lastProcessedUtteranceID else { return }
        lastProcessedUtteranceID = utterance.id
        guard utterance.speaker.isRemote else {
            remoteChunks.removeAll(keepingCapacity: true)
            return
        }

        let current = Self.normalize(utterance.text)
        var combined: String?
        var boundary = 0
        if let previous = remoteChunks.last,
           previous.utterance.speaker != utterance.speaker ||
           !(0...15).contains(utterance.timestamp.timeIntervalSince(previous.utterance.timestamp)) {
            remoteChunks.removeAll(keepingCapacity: true)
        }
        remoteChunks.removeAll { utterance.timestamp.timeIntervalSince($0.utterance.timestamp) > 15 }
        if !remoteChunks.isEmpty {
            let text = remoteChunks.map { $0.normalized }.joined(separator: " ")
            let range = NSRange(text.startIndex..., in: text)
            // Retain unfinished text after the last complete phrase, including negated ones.
            // This allows "too expensive and send" + "me information" without replaying price.
            let completedEnd = Self.playbook.reduce(0) { end, rule in
                max(end, rule.phrase.matches(in: text, range: range).last.map { NSMaxRange($0.range) } ?? 0)
            }
            let prefix = (text as NSString).substring(from: completedEnd)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !prefix.isEmpty {
                boundary = prefix.utf16.count + 1
                combined = prefix + " " + current
            }
        }
        remoteChunks.append((utterance, current))
        // All playbook phrases fit within twelve words; bound retained fragmented input too.
        if remoteChunks.count > 12 { remoteChunks.removeFirst() }

        for rule in Self.playbook {
            guard suppressedUntil[rule.category].map({ now >= $0 }) ?? true else { continue }
            let quote: String
            if Self.matches(rule, in: current),
               combined.map({ Self.matches(rule, in: $0) }) ?? true {
                quote = utterance.text
            } else if let combined,
                      Self.matches(rule, in: combined, crossing: boundary) {
                quote = remoteChunks.map { $0.utterance.text }.joined(separator: "\n")
            } else {
                continue
            }
            let id = cards.first(where: { $0.category == rule.category })?.id ?? UUID()
            cards.removeAll { $0.category == rule.category }
            cards.insert(ObjectionCard(
                id: id, category: rule.category, title: rule.title, quote: quote,
                suggestedReply: rule.reply, followUpQuestion: rule.question
            ), at: 0)
            if cards.count > 5 { cards.removeLast() }
        }
    }

    mutating func dismiss(_ id: UUID, now: Date = .now) {
        guard let card = cards.first(where: { $0.id == id }) else { return }
        suppressedUntil[card.category] = now.addingTimeInterval(30)
        cards.removeAll { $0.id == id }
    }

    mutating func reset() {
        cards.removeAll(keepingCapacity: true)
        lastProcessedUtteranceID = nil
        remoteChunks.removeAll(keepingCapacity: true)
        suppressedUntil.removeAll(keepingCapacity: true)
    }

    private struct Rule {
        let category: ObjectionCategory
        let title: String
        let reply: String
        let question: String
        let phrase: NSRegularExpression
        let nonObjectionSuffix: NSRegularExpression

        init(_ category: ObjectionCategory, _ title: String, _ reply: String,
             _ question: String, _ pattern: String, suffix: String = #"^ (?:anymore|any longer)\b"#) {
            self.category = category
            self.title = title
            self.reply = reply
            self.question = question
            phrase = try! NSRegularExpression(pattern: #"\b(?:"# + pattern + #")\b"#)
            nonObjectionSuffix = try! NSRegularExpression(pattern: suffix)
        }
    }

    // Compiled once; matching never creates tasks or calls a provider.
    private static let playbook: [Rule] = [
        Rule(.priceBudget, "Price / budget",
             "I hear you. Let's weigh the cost against the outcome you need before deciding whether it makes sense.",
             "Is the main concern the available budget, or whether the outcome justifies the cost?",
             #"too (?:expensive|pricey|pricy|costly)|(?:price|cost|pricing) (?:is |seems |feels )?too (?:high|much)|(?:cant|cannot|can not) afford|(?:dont|do not) have (?:the |any |enough )?budget|(?:no|not enough|insufficient) budget|(?:over|outside|beyond) (?:our|my|the) budget"#,
             suffix: #"^ (?:issues?|problems?|concerns?|limits?|constraints?|needed|required|anymore|any longer)\b"#),
        Rule(.timingPriority, "Timing / priority",
             "Understood. We can work around your priorities rather than force a decision now.",
             "What would need to change for this to become a priority?",
             #"not (?:right )?now|(?:bad|wrong) time|(?:not|isnt) (?:a |our |my )?priority|(?:dont|do not) have time|too busy|(?:call|check|come) back (?:later|next (?:week|month|quarter))"#,
             suffix: #"^ (?:a (?:bad|wrong) time|too busy|not (?:a )?priority|anymore|any longer)\b"#),
        Rule(.existingProvider, "Existing provider",
             "That makes sense. I don't want to replace something that is working without a clear reason.",
             "Is there anything your current approach leaves unresolved?",
             #"(?:already|currently) (?:have|use|using|work with|working with) (?:a |an |another |our )?(?:provider|vendor|supplier|solution|tool)|(?:happy|satisfied) with (?:our|my|the) (?:current |existing )?(?:provider|vendor|supplier|solution)|(?:under|in) (?:a )?contract with"#,
             suffix: #"^ (?:issues?|problems?|concerns?|anymore|any longer)\b"#),
        Rule(.lackOfInterest, "Interest / need",
             "Understood. I don't want to push something you don't need.",
             "Is this already handled, or simply not relevant to your team?",
             #"(?:not|arent|isnt) interested|(?:dont|do not|doesnt|does not) need (?:it|this|that|a new|another)|(?:no|dont see|do not see) (?:a )?need for|(?:not|isnt) relevant|(?:not|isnt) necessary"#,
             suffix: #"^ (?:in (?:delaying|waiting)|to (?:wait|delay)|anymore|any longer)\b"#),
        Rule(.sendInformation, "Send information / email",
             "I can send a brief summary so you can decide whether it is worth exploring.",
             "What should the summary address to be useful to you?",
             #"(?:send|email) (?:me|us) (?:an? |some |the |more )?(?:email|information|info|details|summary|brochure)|(?:just )?email (?:me|us)|(?:put|send) (?:it|that|this) in (?:an? )?email"#,
             suffix: #"^ (?:is (?:not|irrelevant)|anymore|any longer)\b"#),
        Rule(.decisionMaker, "Authority / decision maker",
             "Thanks for clarifying. Let's respect how your team makes this decision.",
             "Who else should be involved, and what will they need to evaluate?",
             #"(?:not|im not|i am not) (?:the |a )?decision maker|(?:cant|cannot|can not) (?:make (?:that|this|the) decision|approve (?:this|that|it))|(?:need|have) to (?:ask|check with|talk to|consult) (?:my|our|the) (?:boss|manager|team|partner)|(?:my|our|the) (?:boss|manager|team|partner) (?:makes|has to approve) (?:the |this |that )?decision"#),
        Rule(.implementationEffort, "Implementation / change effort",
             "Change takes effort. We should understand the work involved before deciding.",
             "Which part of the transition would be hardest for your team?",
             #"(?:implementation|migration|switching|changing|rollout|integration) (?:is |seems |would be |will be )?too (?:hard|difficult|complex|disruptive|much work)|too (?:hard|difficult|complex) to (?:implement|switch|migrate|integrate)|(?:cant|cannot|can not) (?:handle|manage) (?:the |a )?(?:migration|implementation|transition)|(?:dont|do not) want to (?:switch|change|migrate)|(?:worried|concerned) about (?:the |a )?(?:implementation|migration|integration|disruption)"#),
    ]
    private static let clauseBreak = try! NSRegularExpression(
        pattern: #"[.!?;\n]|\b(?:but|however|yet|and)\b|,(?=\s*(?:i|we|it|this|that|our|the|please|send|not)\b)"#
    )
    private static let wordBreak = try! NSRegularExpression(pattern: #"[^\p{L}\p{N}\n]+"#)
    private static let denial = try! NSRegularExpression(
        pattern: #"\b(?:not|never|no|isnt|arent|wasnt|werent|dont|doesnt|didnt|cant|cannot|do not|does not)\b"#
    )

    private static func normalize(_ text: String) -> String {
        let lowercase = text.lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "‘", with: "")
        let separated = clauseBreak.stringByReplacingMatches(
            in: lowercase, range: NSRange(lowercase.startIndex..., in: lowercase), withTemplate: "\n"
        )
        return wordBreak.stringByReplacingMatches(
            in: separated, range: NSRange(separated.startIndex..., in: separated), withTemplate: " "
        ).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matches(_ rule: Rule, in text: String, crossing boundary: Int? = nil) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        for match in rule.phrase.matches(in: text, range: range) {
            if let boundary, !(match.range.location < boundary && NSMaxRange(match.range) > boundary) {
                continue // An old complete objection plus unrelated text is not a new objection.
            }
            guard let phraseRange = Range(match.range, in: text) else { continue }
            let prefix = String(text[..<phraseRange.lowerBound].split(separator: "\n", omittingEmptySubsequences: false).last ?? "")
                .replacingOccurrences(of: "not only ", with: "")
            if denial.firstMatch(in: prefix, range: NSRange(prefix.startIndex..., in: prefix)) != nil {
                continue
            }
            let suffix = String(text[phraseRange.upperBound...])
            if rule.nonObjectionSuffix.firstMatch(in: suffix, range: NSRange(suffix.startIndex..., in: suffix)) != nil {
                continue
            }
            return true
        }
        return false
    }
}
