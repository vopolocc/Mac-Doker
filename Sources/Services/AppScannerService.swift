import Foundation
import AppKit

/// 应用扫描服务
class AppScannerService {

    // MARK: - 扫描路径

    /// 计算需要扫描的目录列表（扫描时动态计算，确保最新）
    private func buildScanPaths() -> [String] {
        var paths = ["/Applications"]
        let fileManager = FileManager.default

        // 扫描 /Applications 的一级子目录（如 Utilities）
        if let contents = try? fileManager.contentsOfDirectory(atPath: "/Applications") {
            for item in contents where !item.hasSuffix(".app") {
                let subPath = "/Applications/\(item)"
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: subPath, isDirectory: &isDir), isDir.boolValue {
                    paths.append(subPath)
                }
            }
        }

        // 用户主目录下的 Applications（常见于 TestFlight 安装）
        let homeApps = "\(NSHomeDirectory())/Applications"
        if fileManager.fileExists(atPath: homeApps) {
            paths.append(homeApps)
        }

        return paths
    }

    // MARK: - 应用扫描

    /// 扫描所有目录下的应用
    func scanApplications() -> [AppInfo] {
        var apps: [AppInfo] = []
        var seenPaths: Set<String> = []
        let fileManager = FileManager.default
        let scanPaths = buildScanPaths()

        for scanPath in scanPaths {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: scanPath) else {
                continue
            }

            for item in contents where item.hasSuffix(".app") {
                let appPath = "\(scanPath)/\(item)"

                // 去重
                guard !seenPaths.contains(appPath) else { continue }
                seenPaths.insert(appPath)

                let appName = item.replacingOccurrences(of: ".app", with: "")

                // 从 Info.plist 读取 bundle 名称（更准确）
                let displayName = getBundleDisplayName(from: appPath) ?? appName

                var app = AppInfo(name: displayName, path: appPath)
                app.category = autoCategorize(displayName)
                apps.append(app)
            }
        }

        // 按名称排序
        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return apps
    }

    /// 从 Info.plist 获取应用显示名称
    private func getBundleDisplayName(from appPath: String) -> String? {
        let infoPlistPath = "\(appPath)/Contents/Info.plist"
        guard let plistData = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        else { return nil }

        // 优先使用 CFBundleDisplayName，再用 CFBundleName
        return plist["CFBundleDisplayName"] as? String
            ?? plist["CFBundleName"] as? String
    }

    // MARK: - 图标加载

    /// 获取应用图标并转换为 PNG Data（多重 fallback）
    func getAppIconData(for app: AppInfo) -> Data? {
        guard let path = app.path else { return nil }

        // 方法1: 从 Info.plist 解析图标文件名，直接读取
        if let iconData = loadIconFromBundle(appPath: path) {
            return iconData
        }

        // 方法2: NSWorkspace 系统级获取（最可靠）
        let nsImage = NSWorkspace.shared.icon(forFile: path)
        // 检查是否是默认图标（32x32 通常是默认）
        if nsImage.size.width > 32 {
            return imageToPNGData(nsImage, size: NSSize(width: 128, height: 128))
        }

        return nil
    }

    /// 从应用 bundle 中直接加载图标文件
    private func loadIconFromBundle(appPath: String) -> Data? {
        let infoPlistPath = "\(appPath)/Contents/Info.plist"
        guard let plistData = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        else { return nil }

        let resourcePath = "\(appPath)/Contents/Resources"

        // 尝试 CFBundleIconFile（旧格式）
        if let iconFile = plist["CFBundleIconFile"] as? String {
            if let data = loadIconFile(named: iconFile, inPath: resourcePath) {
                return data
            }
        }

        // 尝试 CFBundleIcons > CFBundlePrimaryIcon > CFBundleIconFiles（新格式）
        if let icons = plist["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let firstName = iconFiles.last {  // 取最后一个（通常最大）
            if let data = loadIconFile(named: firstName, inPath: resourcePath) {
                return data
            }
        }

        // 尝试 CFBundleIconName（asset catalog）
        if let iconName = plist["CFBundleIconName"] as? String {
            if let data = loadIconFile(named: iconName, inPath: resourcePath) {
                return data
            }
        }

        return nil
    }

    /// 根据图标名加载文件（自动尝试多种扩展名）
    private func loadIconFile(named iconName: String, inPath resourcePath: String) -> Data? {
        // 如果已有扩展名，直接尝试
        if iconName.hasSuffix(".icns") || iconName.hasSuffix(".png") {
            let fullPath = "\(resourcePath)/\(iconName)"
            if let image = NSImage(contentsOfFile: fullPath) {
                return imageToPNGData(image, size: NSSize(width: 128, height: 128))
            }
        }

        // 尝试添加各种扩展名
        for ext in ["icns", "png", "jpg"] {
            let fullPath = "\(resourcePath)/\(iconName).\(ext)"
            if let image = NSImage(contentsOfFile: fullPath) {
                return imageToPNGData(image, size: NSSize(width: 128, height: 128))
            }
        }

        return nil
    }

    /// 获取应用图标 (NSImage)
    func getAppIcon(for app: AppInfo) -> NSImage? {
        guard let path = app.path else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }

    /// 将 NSImage 转换为 PNG Data，并缩放到指定尺寸
    private func imageToPNGData(_ image: NSImage, size: NSSize = NSSize(width: 128, height: 128)) -> Data? {
        // 创建缩放后的图像
        let resized = NSImage(size: size)
        resized.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        resized.unlockFocus()

        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }

    // MARK: - 分类

    /// 自动分类应用（基于名称关键词匹配，注意优先级）
    func autoCategorize(_ name: String) -> AppCategory {
        let n = name.lowercased()

        // AI 工具（精确匹配，避免和其他分类冲突）
        if containsAny(n, in: ["chatgpt", "claude", "gemini", "copilot", "doubao", "豆包", "kimi", "midjourney", "imagen", "runway", "perplexity", "字节ai", "ima.copilot"]) {
            return .ai
        }
        if n == "ima" || n.hasPrefix("ima ") || n.hasSuffix(" ima") { return .ai }

        // 开发工具
        if containsAny(n, in: ["xcode", "android studio", "intellij", "pycharm", "webstorm", "goland", "phpstorm", "rubymine", "clion", "datagrip", "rider", "appcode", "sourcetree", "gitkraken", "tower", "fork", "tableplus", "sequel pro", "dbeaver", "postman", "insomnia", "paw", "proxyman", "charles", "simulator", "instruments", "docker"]) {
            return .dev
        }
        if containsAny(n, in: ["vscode", "cursor", "sublime text", "textmate", "nova", "bbedit", "coderunner", "iterm", "hyper", "warp", "terminal"]) {
            return .dev
        }

        // 办公效率
        if containsAny(n, in: ["microsoft word", "microsoft excel", "microsoft powerpoint", "microsoft onenote", "pages", "numbers", "keynote", "wps", "libreoffice", "openoffice"]) {
            return .office
        }
        if containsAny(n, in: ["notion", "obsidian", "bear", "ulysses", "ia writer", "typora", "drafts", "day one", "evernote", "onenote", "有道云笔记", "印象笔记", "语雀", "石墨文档", "腾讯文档"]) {
            return .office
        }
        if containsAny(n, in: ["pdf", "adobe acrobat", "preview", "文档", "笔记", "预览"]) {
            return .office
        }

        // 沟通协作（精确匹配，避免误分类）
        if containsAny(n, in: ["wechat", "企业微信", "qq", "tim", "dingtalk", "钉钉", "lark", "feishu", "飞书", "slack", "discord", "telegram", "whatsapp", "line", "signal", "microsoft teams", "zoom", "tencent meeting", "腾讯会议", "webex", "skype", "facetime"]) {
            return .communication
        }
        if containsAny(n, in: ["mail", "outlook", "airmail", "spark", "mimestream", "mailmate"]) && !containsAny(n, in: ["gmail app", "fastmail"]) {
            return .communication
        }

        // 娱乐休闲
        if containsAny(n, in: ["steam", "epic games", "gog galaxy", "itch.io", "battle.net", "league of legends", "minecraft", "roblox"]) {
            return .entertainment
        }
        if containsAny(n, in: ["spotify", "apple music", "网易云音乐", "qq音乐", "酷狗", "酷我"]) {
            return .entertainment
        }
        if containsAny(n, in: ["netflix", "腾讯视频", "爱奇艺", "优酷", "bilibili", "哔哩哔哩", "youtube", "twitch", "plex", "infuse", "vlc", "iina"]) {
            return .entertainment
        }

        // 媒体创作
        if containsAny(n, in: ["photoshop", "lightroom", "illustrator", "indesign", "premiere", "after effects", "animate", "audition", "bridge", "dimension", "dreamweaver", "fireworks", "fresco"]) {
            return .media
        }
        if containsAny(n, in: ["final cut pro", "logic pro", "motion", "compressor", "garageband", "mainstage"]) {
            return .media
        }
        if containsAny(n, in: ["figma", "sketch", "affinity", "pixelmator", "procreate", "acorn", "canva"]) {
            return .media
        }
        if containsAny(n, in: ["blender", "cinema 4d", "maya", "unity", "unreal", "davinci resolve", "resolve", "handbrake", "ffmpeg"]) {
            return .media
        }

        // 系统工具
        if containsAny(n, in: ["alfred", "raycast", "launchbar", "hazel", "bartender", "cleanmymac", "ccleaner", "onyx", "popclip", "magnet", "rectangle", "moom", "bettertouchtool", "karabiner", "keyboard maestro"]) {
            return .system
        }
        if containsAny(n, in: ["chrome", "safari", "firefox", "edge", "brave", "opera", "vivaldi", "arc"]) {
            return .system
        }
        if containsAny(n, in: ["todesk", "向日葵", "anydesk", "teamviewer", "remote desktop", "screens", "vnc"]) {
            return .system
        }
        if containsAny(n, in: ["parallels", "vmware fusion", "virtualbox", "utm"]) {
            return .system
        }
        if containsAny(n, in: ["transmission", "motrix", "aria", "迅雷"]) {
            return .system
        }
        if containsAny(n, in: ["1password", "bitwarden", "keychain", "lastpass", "dashlane"]) {
            return .system
        }

        return .other
    }

    private func containsAny(_ name: String, in keywords: [String]) -> Bool {
        keywords.contains { name.contains($0) }
    }

    // MARK: - 表情图标

    /// 根据应用名猜测表情
    func guessEmoji(for name: String) -> String {
        let n = name.lowercased()

        // 沟通
        if containsAny(n, in: ["wechat", "weixin", "微信"]) { return "💬" }
        if n == "qq" || n == "tim" { return "💬" }
        if containsAny(n, in: ["dingtalk", "钉钉"]) { return "🔔" }
        if containsAny(n, in: ["lark", "feishu", "飞书"]) { return "🐦" }
        if containsAny(n, in: ["slack"]) { return "💬" }
        if containsAny(n, in: ["discord"]) { return "🎮" }
        if containsAny(n, in: ["telegram"]) { return "✈️" }
        if containsAny(n, in: ["whatsapp"]) { return "📱" }
        if containsAny(n, in: ["zoom"]) { return "📹" }
        if containsAny(n, in: ["teams"]) { return "👥" }
        if containsAny(n, in: ["mail", "outlook", "spark", "airmail"]) { return "📧" }

        // 浏览器
        if containsAny(n, in: ["chrome"]) { return "🌐" }
        if containsAny(n, in: ["safari"]) { return "🧭" }
        if containsAny(n, in: ["firefox"]) { return "🦊" }
        if containsAny(n, in: ["edge"]) { return "🌊" }
        if containsAny(n, in: ["arc"]) { return "🌈" }
        if containsAny(n, in: ["brave"]) { return "🦁" }

        // 开发
        if containsAny(n, in: ["xcode"]) { return "🔨" }
        if containsAny(n, in: ["cursor"]) { return "💻" }
        if containsAny(n, in: ["vscode", "code"]) { return "💻" }
        if containsAny(n, in: ["android studio"]) { return "🤖" }
        if containsAny(n, in: ["iterm", "terminal", "warp"]) { return "⬛" }
        if containsAny(n, in: ["docker"]) { return "🐳" }
        if containsAny(n, in: ["postman"]) { return "📮" }
        if containsAny(n, in: ["tableplus", "dbeaver", "datagrip"]) { return "🗃️" }
        if containsAny(n, in: ["sourcetree", "fork", "tower"]) { return "🌿" }

        // AI
        if containsAny(n, in: ["chatgpt"]) { return "🤖" }
        if containsAny(n, in: ["claude"]) { return "🤖" }
        if containsAny(n, in: ["doubao", "豆包"]) { return "🫘" }
        if containsAny(n, in: ["kimi"]) { return "🌙" }
        if containsAny(n, in: ["midjourney"]) { return "🎨" }
        if containsAny(n, in: ["ima"]) { return "✨" }
        if containsAny(n, in: ["copilot"]) { return "🤝" }

        // 办公
        if containsAny(n, in: ["notion"]) { return "📓" }
        if containsAny(n, in: ["obsidian"]) { return "💎" }
        if containsAny(n, in: ["bear"]) { return "🐻" }
        if containsAny(n, in: ["wps"]) { return "📝" }
        if containsAny(n, in: ["word", "pages"]) { return "📄" }
        if containsAny(n, in: ["excel", "numbers"]) { return "📊" }
        if containsAny(n, in: ["powerpoint", "keynote"]) { return "📽️" }
        if containsAny(n, in: ["pdf"]) { return "📕" }

        // 媒体创作
        if containsAny(n, in: ["photoshop"]) { return "🖼️" }
        if containsAny(n, in: ["illustrator"]) { return "🖌️" }
        if containsAny(n, in: ["premiere"]) { return "🎬" }
        if containsAny(n, in: ["after effects"]) { return "✨" }
        if containsAny(n, in: ["final cut"]) { return "🎬" }
        if containsAny(n, in: ["logic pro"]) { return "🎵" }
        if containsAny(n, in: ["garageband"]) { return "🎸" }
        if containsAny(n, in: ["figma"]) { return "🎨" }
        if containsAny(n, in: ["sketch"]) { return "✏️" }
        if containsAny(n, in: ["blender"]) { return "🧊" }
        if containsAny(n, in: ["davinci resolve"]) { return "🎬" }

        // 娱乐
        if containsAny(n, in: ["steam"]) { return "🎮" }
        if containsAny(n, in: ["spotify"]) { return "🎵" }
        if containsAny(n, in: ["apple music", "music"]) { return "🎵" }
        if containsAny(n, in: ["netflix"]) { return "🎬" }
        if containsAny(n, in: ["bilibili", "哔哩哔哩"]) { return "📺" }
        if containsAny(n, in: ["youtube"]) { return "▶️" }
        if containsAny(n, in: ["iina", "vlc"]) { return "🎥" }
        if containsAny(n, in: ["twitch"]) { return "🎮" }

        // 系统工具
        if containsAny(n, in: ["alfred", "raycast"]) { return "⚡" }
        if containsAny(n, in: ["cleanmymac"]) { return "🧹" }
        if containsAny(n, in: ["1password", "bitwarden"]) { return "🔑" }
        if containsAny(n, in: ["magnet", "rectangle"]) { return "🪟" }
        if containsAny(n, in: ["bartender"]) { return "🍸" }
        if containsAny(n, in: ["parallels", "vmware", "utm"]) { return "🖥️" }
        if containsAny(n, in: ["todesk", "向日葵", "anydesk"]) { return "🖥️" }
        if containsAny(n, in: ["transmission", "motrix"]) { return "⬇️" }
        if containsAny(n, in: ["迅雷"]) { return "⚡" }

        return "📱"
    }
}
