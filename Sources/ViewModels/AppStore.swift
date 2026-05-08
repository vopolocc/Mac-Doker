import Foundation
import Combine
import AppKit

/// 应用状态管理 (ViewModel)
class AppStore: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var activeCategory: AppCategory = .all
    @Published var searchQuery: String = ""
    @Published var sortBy: SortOption = .name
    @Published var viewMode: ViewMode = .default
    @Published var collapsedGroups: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var statusMessage: String = ""

    enum SortOption: String, CaseIterable {
        case name = "name"
        case category = "category"
        case pinned = "pinned"
        case usage = "usage"

        var displayName: String {
            switch self {
            case .name: return "按名称"
            case .category: return "按分类"
            case .pinned: return "⭐ 收藏"
            case .usage: return "🔥 频次"
            }
        }
    }

    enum ViewMode: String, CaseIterable {
        case `default` = "default"
        case grid = "grid"
        case compact = "compact"
        case cluster = "cluster"
    }

    var categoryCounts: [AppCategory: Int] {
        var counts: [AppCategory: Int] = [:]
        for app in apps {
            counts[app.category, default: 0] += 1
        }
        counts[.all] = apps.count
        counts[.pinned] = apps.filter { $0.isPinned }.count
        return counts
    }

    var filteredApps: [AppInfo] {
        var result = apps

        if activeCategory == .pinned {
            result = result.filter { $0.isPinned }
        } else if activeCategory != .all {
            result = result.filter { $0.category == activeCategory }
        }

        if !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        switch sortBy {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .usage:
            result.sort { ($0.usageCount, $0.name) > ($1.usageCount, $1.name) }
        case .pinned:
            result.sort { ($0.isPinned ? 1 : 0, $0.name) > ($1.isPinned ? 1 : 0, $1.name) }
        case .category:
            result.sort { $0.category.rawValue < $1.category.rawValue }
        }

        return result
    }

    var groupedApps: [AppCategory: [AppInfo]] {
        Dictionary(grouping: filteredApps, by: { $0.category })
    }

    init() {
        scanAndLoadApps()
    }

    func saveApps() {
        if let data = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(data, forKey: "macDokerApps")
        }
        let viewData: [String: Any] = [
            "activeCategory": activeCategory.rawValue,
            "sortBy": sortBy.rawValue,
            "viewMode": viewMode.rawValue,
            "collapsedGroups": Array(collapsedGroups)
        ]
        UserDefaults.standard.set(viewData, forKey: "macDokerViewState")
    }

    func loadApps() {
        if let data = UserDefaults.standard.data(forKey: "macDokerApps"),
           let savedApps = try? JSONDecoder().decode([AppInfo].self, from: data) {
            apps = savedApps
        }

        if let viewData = UserDefaults.standard.dictionary(forKey: "macDokerViewState") {
            if let catStr = viewData["activeCategory"] as? String,
               let cat = AppCategory(rawValue: catStr) {
                activeCategory = cat
            }
            if let sortStr = viewData["sortBy"] as? String,
               let sort = SortOption(rawValue: sortStr) {
                sortBy = sort
            }
            if let modeStr = viewData["viewMode"] as? String,
               let mode = ViewMode(rawValue: modeStr) {
                viewMode = mode
            }
            if let groups = viewData["collapsedGroups"] as? [String] {
                collapsedGroups = Set(groups)
            }
        }
    }

    func launchApp(_ app: AppInfo) {
        incrementUsage(app)
        if let path = app.path {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }
    }

    func incrementUsage(_ app: AppInfo) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].usageCount += 1
            saveApps()
        }
    }

    func togglePin(_ app: AppInfo) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isPinned.toggle()
            saveApps()
        }
    }

    func resetUsage(_ app: AppInfo) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].usageCount = 0
            saveApps()
        }
    }

    func removeApp(_ app: AppInfo) {
        apps.removeAll { $0.id == app.id }
        saveApps()
    }

    func updateAppCategory(_ app: AppInfo, to category: AppCategory) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].category = category
            saveApps()
        }
    }

    func toggleGroupCollapse(_ category: AppCategory) {
        if collapsedGroups.contains(category.rawValue) {
            collapsedGroups.remove(category.rawValue)
        } else {
            collapsedGroups.insert(category.rawValue)
        }
        saveApps()
    }

    func scanAndLoadApps() {
        isLoading = true
        statusMessage = "正在扫描应用..."

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scanner = AppScannerService()
            var discoveredApps = scanner.scanApplications()
            let total = discoveredApps.count

            DispatchQueue.main.async {
                self?.statusMessage = "正在加载图标 (0/\(total))..."
            }

            // 为每个应用加载图标（带进度反馈）
            for i in discoveredApps.indices {
                discoveredApps[i].iconData = scanner.getAppIconData(for: discoveredApps[i])
                discoveredApps[i].emoji = scanner.guessEmoji(for: discoveredApps[i].name)

                // 每 10 个更新一次进度
                if i % 10 == 0 {
                    let progress = i + 1
                    DispatchQueue.main.async {
                        self?.statusMessage = "正在加载图标 (\(progress)/\(total))..."
                    }
                }
            }

            DispatchQueue.main.async {
                self?.apps = discoveredApps
                self?.saveApps()
                self?.isLoading = false
                self?.statusMessage = "已加载 \(discoveredApps.count) 个应用"
            }
        }
    }

    func scanApps() {
        scanAndLoadApps()
    }

    func refreshIcons() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scanner = AppScannerService()

            guard let self else { return }

            for i in self.apps.indices {
                if let iconData = scanner.getAppIconData(for: self.apps[i]) {
                    DispatchQueue.main.async {
                        self.apps[i].iconData = iconData
                    }
                }
            }

            DispatchQueue.main.async {
                self.saveApps()
            }
        }
    }

    func clearData() {
        UserDefaults.standard.removeObject(forKey: "macDokerApps")
        UserDefaults.standard.removeObject(forKey: "macDokerViewState")
        apps.removeAll()
        scanAndLoadApps()
    }
}