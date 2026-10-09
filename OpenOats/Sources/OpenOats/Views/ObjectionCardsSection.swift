import SwiftUI

/// Non-modal objection board. Renders the waiting / paused / dismissed empty
/// states and the active card collection. Cards expose their category/title,
/// the exact prospect quote, a suggested reply and a follow-up question, plus
/// Copy and Dismiss controls. Copy writes reply + follow-up to the clipboard;
/// Dismiss removes the card by its stable identity. The board never activates
/// the window or steals focus when a card is inserted.
struct ObjectionCardsSection: View {
    let cards: [ObjectionCard]
    let isRecordingPaused: Bool
    let hasDismissed: Bool
    /// In the wide two-pane layout the suggested reply and follow-up question sit
    /// side by side, per the approved design.
    let isWideLayout: Bool
    let onCopy: (ObjectionCard) -> Void
    let onDismiss: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focus: ObjectionBoardFocus?
    @State private var copiedCardID: UUID?
    @State private var unseenCount = 0
    @State private var isScrolledAwayFromNewest = false

    private static let scrollSpace = "objectionBoardScroll"

    private var presentation: ObjectionBoardPresentation {
        ObjectionBoardPresentation(
            cards: cards,
            isRecordingPaused: isRecordingPaused,
            hasDismissed: hasDismissed
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            if presentation.isEmpty {
                emptyState
            } else {
                activeBoard
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    @ViewBuilder
    private var heading: some View {
        let title = HStack(spacing: 6) {
            Text("Objection coaching")
                .font(.system(size: 12, weight: .medium))
            if presentation.isMultiple {
                Text("(\(cards.count))")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .accessibilityAddTraits(.isHeader)

        // Only a tab stop when the board is empty, where the focus plan parks
        // focus after the last card is dismissed.
        if presentation.isEmpty {
            title
                .focusable()
                .focused($focus, equals: .heading)
        } else {
            title
        }
    }

    // MARK: - Empty states

    private var emptyState: some View {
        Text(presentation.emptyMessage ?? "")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("app.objections.waiting")
    }

    // MARK: - Active board

    private var activeBoard: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 6) {
                if unseenCount > 0 {
                    newObjectionsBanner(count: unseenCount) {
                        withAnimation(animation) {
                            proxy.scrollTo(cards.first?.id, anchor: .top)
                        }
                        unseenCount = 0
                    }
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        newestAnchor
                        ForEach(cards) { card in
                            cardView(card)
                                .id(card.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .coordinateSpace(name: Self.scrollSpace)
                .onPreferenceChange(BoardTopOffsetKey.self) { offset in
                    let away = offset < -4
                    guard away != isScrolledAwayFromNewest else { return }
                    isScrolledAwayFromNewest = away
                    if !away { unseenCount = 0 }
                }
            }
            .onChange(of: cards.count) { oldCount, newCount in
                guard isScrolledAwayFromNewest, newCount > oldCount else { return }
                unseenCount += newCount - oldCount
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var newestAnchor: some View {
        Color.clear
            .frame(height: 0)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: BoardTopOffsetKey.self,
                        value: geometry.frame(in: .named(Self.scrollSpace)).minY
                    )
                }
            )
    }

    private func newObjectionsBanner(count: Int, onJump: @escaping () -> Void) -> some View {
        let label = count == 1 ? "1 new objection" : "\(count) new objections"
        return Button(action: onJump) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityIdentifier("app.objections.newCount")
        .accessibilityLabel(label)
    }

    // MARK: - Card

    private func cardView(_ card: ObjectionCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(card.title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 4)
                Button {
                    dismiss(card)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .help("Dismiss this objection")
                .accessibilityLabel("Dismiss \(card.title) objection")
                .accessibilityIdentifier("app.objections.dismiss.\(card.category.rawValue)")
                .focusEffectDisabled()
                .focused($focus, equals: .dismiss(card.id))
                .modifier(FocusRing(isFocused: focus == .dismiss(card.id)))
            }

            Text(card.quote)
                .font(.system(size: 12))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("app.objections.quote.\(card.category.rawValue)")

            if isWideLayout {
                HStack(alignment: .top, spacing: 12) {
                    replyBlock(card)
                    followUpBlock(card)
                }
            } else {
                replyBlock(card)
                followUpBlock(card)
            }

            HStack(spacing: 8) {
                Button {
                    copy(card)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                        Text("Copy")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .help("Copy the suggested reply and follow-up question")
                .accessibilityLabel("Copy \(card.title) reply and follow-up question")
                .accessibilityIdentifier("app.objections.copy.\(card.category.rawValue)")
                .focusEffectDisabled()
                .focused($focus, equals: .copy(card.id))
                .modifier(FocusRing(isFocused: focus == .copy(card.id)))

                if copiedCardID == card.id {
                    Label("Copied", systemImage: "checkmark")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("app.objections.copied.\(card.category.rawValue)")
                        .accessibilityLabel("Copied reply and follow-up question")
                }
                Spacer(minLength: 0)
            }
        }
        .font(.system(size: 12))
        .fixedSize(horizontal: false, vertical: true)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityElement(children: .contain)
    }

    private func replyBlock(_ card: ObjectionCard) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Suggested reply")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(card.suggestedReply)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("app.objections.reply.\(card.category.rawValue)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func followUpBlock(_ card: ObjectionCard) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Follow-up question")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(card.followUpQuestion)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("app.objections.followUp.\(card.category.rawValue)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func copy(_ card: ObjectionCard) {
        onCopy(card)
        copiedCardID = card.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if copiedCardID == card.id { copiedCardID = nil }
        }
    }

    private func dismiss(_ card: ObjectionCard) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        let target = ObjectionBoardFocusPlan.focusAfterDismiss(dismissingAt: index, in: cards)
        onDismiss(card.id)
        // Move focus after the removed view releases it, so SwiftUI can honor the
        // reassignment instead of dropping focus to the window.
        DispatchQueue.main.async {
            focus = target
        }
    }

    private var animation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }
}

/// Reports the scroll offset of the top of the card list so the board can show
/// a new-objection count while the user has scrolled away from the newest card.
private struct BoardTopOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// A 2 px accent ring drawn 2 px outside the control when it holds keyboard focus.
private struct FocusRing: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .padding(-2)
            }
        }
    }
}
