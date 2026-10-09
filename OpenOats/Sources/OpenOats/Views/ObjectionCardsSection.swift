import SwiftUI

struct ObjectionCardsSection: View {
    let cards: [ObjectionCard]
    let isRecordingPaused: Bool
    let onDismiss: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Objection coaching")
                .font(.system(size: 12, weight: .medium))
            if cards.isEmpty {
                Text(isRecordingPaused
                     ? "Recording paused. Coaching resumes with finalized remote speech."
                     : "Waiting for a finalized remote objection.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("app.objections.waiting")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(cards) { card in
                            cardView(card)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardView(_ card: ObjectionCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(card.title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Button {
                    onDismiss(card.id)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .help("Dismiss this objection")
                .accessibilityLabel("Dismiss \(card.title) objection")
                .accessibilityIdentifier("app.objections.dismiss.\(card.category.rawValue)")
            }
            Text(card.quote)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .accessibilityIdentifier("app.objections.quote.\(card.category.rawValue)")
            VStack(alignment: .leading, spacing: 3) {
                Text("Suggested reply")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(card.suggestedReply)
                    .accessibilityIdentifier("app.objections.reply.\(card.category.rawValue)")
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Follow-up question")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(card.followUpQuestion)
                    .accessibilityIdentifier("app.objections.followUp.\(card.category.rawValue)")
            }
        }
        .font(.system(size: 12))
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
