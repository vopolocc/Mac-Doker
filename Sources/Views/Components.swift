import SwiftUI

/// 搜索栏
struct SearchBarView: View {
    @Binding var searchQuery: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("搜索应用...", text: $searchQuery)
                .textFieldStyle(.plain)

            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

/// 分类标签
struct CategoryTab: View {
    let category: AppCategory
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category.displayName)

                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                        ? Color.white.opacity(0.3)
                        : Color.secondary.opacity(0.15)
                    )
                    .clipShape(Capsule())
            }
            .font(.callout)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? Color.accentColor
                : Color.secondary.opacity(0.08)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// 设置视图
struct SettingsView: View {
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("关闭") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // 设置项
            VStack(alignment: .leading, spacing: 16) {
                // 默认视图
                HStack {
                    Text("默认视图")
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $store.viewMode) {
                        ForEach(AppStore.ViewMode.allCases, id: \.self) { mode in
                            Text(viewModeName(mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }

                // 默认排序
                HStack {
                    Text("默认排序")
                        .foregroundColor(.secondary)
                    Spacer()
                    Picker("", selection: $store.sortBy) {
                        ForEach(AppStore.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
            }
            .padding()

            Spacer()

            // 数据管理
            HStack {
                Button(role: .destructive) {
                    if confirm("确定清除所有数据？") {
                        clearAllData()
                    }
                } label: {
                    Label("清除所有数据", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Spacer()
            }
            .padding()
        }
        .frame(width: 500, height: 350)
        .padding()
    }

    private func viewModeName(_ mode: AppStore.ViewMode) -> String {
        switch mode {
        case .default: return "默认"
        case .grid: return "大图标"
        case .compact: return "紧凑"
        case .cluster: return "聚类"
        }
    }

    private func confirm(_ message: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func clearAllData() {
        store.apps.removeAll()
        UserDefaults.standard.removeObject(forKey: "macDokerApps")
        UserDefaults.standard.removeObject(forKey: "macDokerViewState")
        store.loadApps()
    }
}

/// 编辑应用视图
struct EditAppView: View {
    let app: AppInfo
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: AppCategory = .other

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("编辑应用")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("关闭") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // 表单
            VStack(alignment: .leading, spacing: 16) {
                // 名称
                HStack {
                    Text("应用名称")
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    TextField("", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                // 分类
                HStack {
                    Text("所属分类")
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Picker("", selection: $category) {
                        ForEach(AppCategory.allCases.filter { $0 != .all && $0 != .pinned }, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .labelsHidden()
                }
            }
            .padding()

            Spacer()

            // 操作按钮
            HStack {
                Button(role: .destructive) {
                    store.removeApp(app)
                    dismiss()
                } label: {
                    Label("移除", systemImage: "trash")
                }

                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button("保存") {
                    saveChanges()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .onAppear {
            name = app.name
            category = app.category
        }
    }

    private func saveChanges() {
        if let index = store.apps.firstIndex(where: { $0.id == app.id }) {
            store.apps[index].name = name
            store.apps[index].category = category
            store.saveApps()
        }
    }
}
