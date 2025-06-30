import Foundation

extension Category {
    var displayName: String {
        switch self {
        case .career:     "Career"
        case .spiritual:  "Spiritual"
        case .mental:     "Mental"
        case .emotion:    "Emotion"
        case .physical:   "Physical"
        case .social:     "Social"
        case .finances:   "Finances"
        }
    }

    /// Small emoji for list / prompt
    var emoji: String {
        switch self {
        case .career:     "💼"
        case .spiritual:  "✨"
        case .mental:     "🧠"
        case .emotion:    "❤️"
        case .physical:   "💪"
        case .social:     "👥"
        case .finances:   "💵"
        }
    }

    /// SF-symbol for the tile (fallback if you prefer SF symbols)
    var iconName: String {
        switch self {
        case .career:     "briefcase.fill"
        case .spiritual:  "sparkles"
        case .mental:     "brain.head.profile"
        case .emotion:    "heart"
        case .physical:   "figure.strengthtraining.functional"
        case .social:     "person.2.fill"
        case .finances:   "dollarsign"
        }
    }
}