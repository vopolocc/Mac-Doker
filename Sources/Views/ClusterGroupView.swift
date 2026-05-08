import SwiftUI

/// 聚类分组视图 (类似 iOS 文件夹)
struct ClusterGroupView: View {
    let category: AppCategory
    let apps: [AppInfo]
    let isCollapsed: Bool
    let onToggle: () -> Void
    let onLaunch: (AppInfo) -> Void
    let onPin: (AppInfo) -> Void
    let onEdit: (AppInfo) -> Void
    let onDelete: (AppInfo) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 分组标题栏
            clusterHeader
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onToggle()
                    }
                }

            // 内容区域
            if isCollapsed {
                collapsedPreview
            } else {
                expandedContent
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - 标题栏

    private var clusterHeader: some View {
        HStack(spacing: 12) {
            // 分类颜色圆点
            Circle()
                .fill(Color(hex: category.colorHex))
                .frame(width: 12, height: 12)
                .shadow(color: Color(hex: category.colorHex).opacity(0.5), radius: 4)

            // 分类名称
            Text(category.displayName)
                .font(.headline)
                .foregroundColor(.primary)

            // 应用数量
            Text("\(apps.count) 个应用")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())

            Spacer()

            // 折叠/展开箭头
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isCollapsed ? -90 : 0))
                .animation(.easeInOut(duration: 0.3), value: isCollapsed)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            !isCollapsed
            ? Color.primary.opacity(0.03)
            : Color.clear
        )
    }

    // MARK: - 折叠预览

    private var collapsedPreview: some View {
        HStack(spacing: 8) {
            ForEach(Array(apps.prefix(12)), id: \.id) { app in
                Group {
                    if let iconData = app.iconData,
                       let nsImage = NSImage(data: iconData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Text(app.emoji)
                    }
                }
                .frame(width: 28, height: 28)
                .opacity(0.7)
            }

            if apps.count > 12 {
                Text("+\(apps.count - 12)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - 展开内容

    private var expandedContent: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 110), spacing: 12)],
            spacing: 12
        ) {
            ForEach(apps) { app in
                AppCardView(
                    app: app,
                    viewMode: .default,
                    onLaunch: { onLaunch(app) },
                    onPin: { onPin(app) },
                    onEdit: { onEdit(app) },
                    onDelete: { onDelete(app) }
                )
            }
        }
        .padding(16)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}
