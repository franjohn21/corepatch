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

    /// Description for each category
    var description: String {
        switch self {
        case .career:     "Professional growth, work goals, and career development"
        case .spiritual:  "Connection to purpose, meaning, and spiritual practices"
        case .mental:     "Thoughts, mindset, learning, and cognitive wellbeing"
        case .emotion:    "Feelings, emotional processing, and relationship with emotions"
        case .physical:   "Health, fitness, body care, and physical activities"
        case .social:     "Relationships, connections, and social interactions"
        case .finances:   "Money management, financial goals, and economic wellbeing"
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