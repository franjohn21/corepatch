import SwiftUI

// MARK: - Card background & padding -----------------------------------------

/// Rounded-rectangle card with configurable inner padding.
private struct CardModifier: ViewModifier {
    let insets: EdgeInsets
    func body(content: Content) -> some View {
        content
            .padding(insets)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
            )
    }
}

extension View {
    /// Default card: 16-pt padding on all sides.
    func cardStyle(
        insets: EdgeInsets = EdgeInsets(top: 16, leading: 16,
                                        bottom: 16, trailing: 16)
    ) -> some View {
        modifier(CardModifier(insets: insets))
    }
}

// MARK: - Tiny helpers -------------------------------------------------------

extension Text {
    /// Small grey, all-caps label used at top of cards.
    func cardSectionLabel() -> some View {
        self.font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Generic card container --------------------------------------------

/// Lays out leading content plus an optional trailing circle icon.
struct CardContainer<Content: View>: View {
    let insets: EdgeInsets
    let iconName: String?
    let iconTint: Color
    @ViewBuilder let content: Content

    init(
        insets: EdgeInsets = EdgeInsets(top: 16, leading: 16,
                                        bottom: 16, trailing: 16),
        iconName: String? = nil,
        iconTint: Color = .accentColor,
        @ViewBuilder content: () -> Content
    ) {
        self.insets = insets
        self.iconName = iconName
        self.iconTint = iconTint
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top) {
            content

            if let iconName {
                Spacer(minLength: 12)
                ZStack {
                    Circle()
                        .fill(iconTint.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundStyle(iconTint)
                }
            }
        }
        .cardStyle(insets: insets)
    }
}