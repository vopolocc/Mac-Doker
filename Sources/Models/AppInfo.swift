import Foundation

/// 应用信息模型
struct AppInfo: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var path: String?
    var category: AppCategory
    var isPinned: Bool
    var usageCount: Int
    var iconData: Data?
    var emoji: String

    init(name: String, path: String? = nil, category: AppCategory = .other) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.category = category
        self.isPinned = false
        self.usageCount = 0
        self.iconData = nil
        self.emoji = "📱"
    }

    // Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, path, category, isPinned, usageCount, iconData, emoji
    }
}

/// 应用分类
enum AppCategory: String, Codable, CaseIterable, Identifiable {
    case all = "all"
    case pinned = "pinned"
    case dev = "dev"
    case office = "office"
    case communication = "communication"
    case entertainment = "entertainment"
    case ai = "ai"
    case media = "media"
    case system = "system"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "全部"
        case .pinned: return "⭐ 收藏"
        case .dev: return "开发工具"
        case .office: return "办公效率"
        case .communication: return "沟通协作"
        case .entertainment: return "娱乐休闲"
        case .ai: return "AI 工具"
        case .media: return "媒体创作"
        case .system: return "系统工具"
        case .other: return "其他"
        }
    }

    var colorHex: String {
        switch self {
        case .all: return "#4fc3f7"
        case .pinned: return "#ffd700"
        case .dev: return "#42a5f5"
        case .office: return "#66bb6a"
        case .communication: return "#26a69a"
        case .entertainment: return "#ab47bc"
        case .ai: return "#ec407a"
        case .media: return "#ffa726"
        case .system: return "#5c6bc0"
        case .other: return "#26c6da"
        }
    }
}

/// 应用分类颜色
enum CategoryColor: String, CaseIterable {
    case blue, green, red, orange, purple, pink, teal, indigo, yellow, cyan

    var hex: String {
        switch self {
        case .blue: return "#42a5f5"
        case .green: return "#66bb6a"
        case .red: return "#ef5350"
        case .orange: return "#ffa726"
        case .purple: return "#ab47bc"
        case .pink: return "#ec407a"
        case .teal: return "#26a69a"
        case .indigo: return "#5c6bc0"
        case .yellow: return "#ffee58"
        case .cyan: return "#26c6da"
        }
    }
}
