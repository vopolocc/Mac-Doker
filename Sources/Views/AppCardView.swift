import SwiftUI

/// 应用卡片视图
struct AppCardView: View {
    let app: AppInfo
    let viewMode: AppStore.ViewMode
    let onLaunch: () -> Void
    let onPin: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        Group {
            if viewMode == .compact {
                compactCard
            } else {
                defaultCard
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            contextMenuItems
        }
    }

    // MARK: - 默认卡片

    private var defaultCard: some View {
        VStack(spacing: 8) {
            // 图标区域（含悬停快捷操作）
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: app.category.colorHex).opacity(0.3))
                    .frame(width: iconSize, height: iconSize)

                if let iconData = app.iconData,
                   let nsImage = NSImage(data: iconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize - 8, height: iconSize - 8)
                        .opacity(isHovered ? 0.7 : 1.0)
                } else {
                    Text(app.emoji)
                        .font(.system(size: iconSize * 0.5))
                        .opacity(isHovered ? 0.7 : 1.0)
                }

                // 悬停时显示启动按钮
                if isHovered {
                    Image(systemName: "arrow.up.forward.app.fill")
                        .font(.system(size: iconSize * 0.35, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.7)))
                }

                // 置顶标记
                if app.isPinned {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .offset(x: iconSize/2 - 8, y: -iconSize/2 + 8)
                }

                // 使用次数
                if app.usageCount > 0 && !isHovered {
                    Text("\(app.usageCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.8))
                        .clipShape(Capsule())
                        .offset(x: iconSize/2 - 8, y: iconSize/2 - 8)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)

            // 名称
            Text(app.name)
                .font(.caption)
                .foregroundColor(isHovered ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 90)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? AnyShapeStyle(Color(hex: app.category.colorHex).opacity(0.15)) : AnyShapeStyle(.ultraThinMaterial))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered
                    ? Color(hex: app.category.colorHex).opacity(0.5)
                    : Color.white.opacity(0.1),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .scaleEffect(isHovered ? 1.04 : 1.0)
        .offset(y: isHovered ? -5 : 0)
        .shadow(
            color: isHovered ? Color(hex: app.category.colorHex).opacity(0.3) : .black.opacity(0.1),
            radius: isHovered ? 20 : 8
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onTapGesture {
            onLaunch()
        }
    }

    // MARK: - 紧凑卡片

    private var compactCard: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: app.category.colorHex).opacity(0.3))
                    .frame(width: 36, height: 36)

                if let iconData = app.iconData,
                   let nsImage = NSImage(data: iconData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else {
                    Text(app.emoji)
                        .font(.title3)
                }
            }

            // 名称
            Text(app.name)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            // 置顶
            if app.isPinned {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .onTapGesture {
            onLaunch()
        }
    }

    // MARK: - 右键菜单

    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: onLaunch) {
            Label("打开应用", systemImage: "rocket")
        }

        Button(action: onPin) {
            Label(app.isPinned ? "取消收藏" : "收藏", systemImage: app.isPinned ? "star.slash" : "star")
        }

        Divider()

        Button(action: onEdit) {
            Label("编辑", systemImage: "pencil")
        }

        Button(action: onEdit) {
            Label("重置频次", systemImage: "flame")
        }

        Divider()

        Button(role: .destructive, action: onDelete) {
            Label("移除", systemImage: "trash")
        }
    }

    // MARK: - Helper

    private var iconSize: CGFloat {
        viewMode == .grid ? 64 : 56
    }

    private var cardWidth: CGFloat {
        viewMode == .grid ? 130 : 110
    }
}
