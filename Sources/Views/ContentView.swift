import SwiftUI

/// 主视图
struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var showSettings = false
    @State private var showAddCategory = false
    @State private var editingApp: AppInfo?

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                categoryTabsView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                sortBarView
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // 加载状态
                if store.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(.circular)

                        Text(store.statusMessage)
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Text("首次扫描需要 10-30 秒，请稍候...")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if store.viewMode == .cluster {
                            clusterView
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        } else {
                            appGridView
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(store: store)
        }
        .sheet(item: $editingApp) { app in
            EditAppView(app: app, store: store)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 10) {
                Text("🚀")
                    .font(.title2)
                Text("Mac Doker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#4fc3f7"), Color(hex: "#81d4fa")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Spacer()

            SearchBarView(searchQuery: $store.searchQuery)
                .frame(width: 280)

            viewModeToggle

            HStack(spacing: 8) {
                Button(action: { store.refreshIcons() }) {
                    Label("刷新图标", systemImage: "arrow.clockwise")
                }
                .buttonStyle(GlassButtonStyle())

                Button(action: { store.scanApps() }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(GlassAccentButtonStyle())

                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            ForEach(AppStore.ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    store.viewMode = mode
                    store.saveApps()
                }) {
                    viewModeIcon(for: mode)
                        .font(.system(size: 14))
                        .frame(width: 32, height: 28)
                        .background(
                            store.viewMode == mode
                            ? Color.blue.opacity(0.3)
                            : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func viewModeIcon(for mode: AppStore.ViewMode) -> some View {
        Group {
            switch mode {
            case .default: Text("⊞")
            case .grid: Text("⊟")
            case .compact: Text("☰")
            case .cluster: Text("▣")
            }
        }
        .foregroundColor(store.viewMode == mode ? .accentColor : .secondary)
    }

    // MARK: - 分类标签

    private var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppCategory.allCases.filter { $0 != .pinned }, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        count: store.categoryCounts[category] ?? 0,
                        isSelected: store.activeCategory == category
                    ) {
                        store.activeCategory = category
                        store.saveApps()
                    }
                }
            }
            .padding(12)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 排序栏

    private var sortBarView: some View {
        HStack {
            Text("共 \(store.filteredApps.count) 个应用")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 4) {
                ForEach(AppStore.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        store.sortBy = option
                        store.saveApps()
                    }) {
                        Text(option.displayName)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                store.sortBy == option
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 应用网格

    private var appGridView: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: 16
        ) {
            ForEach(store.filteredApps) { app in
                AppCardView(
                    app: app,
                    viewMode: store.viewMode,
                    onLaunch: { store.launchApp(app) },
                    onPin: { store.togglePin(app) },
                    onEdit: { editingApp = app },
                    onDelete: { store.removeApp(app) }
                )
                .onTapGesture(count: 2) {
                    editingApp = app
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat
        switch store.viewMode {
        case .default: minWidth = 110
        case .grid: minWidth = 140
        case .compact: minWidth = 200
        case .cluster: minWidth = 110
        }
        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
    }

    // MARK: - 聚类视图

    private var clusterView: some View {
        VStack(spacing: 20) {
            let sortedCategories = AppCategory.allCases.filter { store.groupedApps[$0] != nil && !store.groupedApps[$0]!.isEmpty }

            ForEach(sortedCategories, id: \.self) { category in
                if let apps = store.groupedApps[category] {
                    ClusterGroupView(
                        category: category,
                        apps: apps,
                        isCollapsed: store.collapsedGroups.contains(category.rawValue),
                        onToggle: { store.toggleGroupCollapse(category) },
                        onLaunch: { store.launchApp($0) },
                        onPin: { store.togglePin($0) },
                        onEdit: { editingApp = $0 },
                        onDelete: { store.removeApp($0) }
                    )
                }
            }
        }
    }
}

extension AppCategory: Hashable {}