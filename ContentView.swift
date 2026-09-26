import SwiftUI
import UIKit
import LocalAuthentication
import CryptoKit
import Security
import UniformTypeIdentifiers
import PhotosUI

struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }
}

extension View {
    func shinnGlass(radius: CGFloat = 22) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}

struct BackgroundView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(colors: [Color.primary.opacity(0.09), .clear], center: .topTrailing, startRadius: 20, endRadius: 500)
            RadialGradient(colors: [Color.primary.opacity(0.05), .clear], center: .bottomLeading, startRadius: 20, endRadius: 450)
        }
        .ignoresSafeArea()
    }
}

struct ScreenPrivacyGuard: View {
    @State private var captured = UIScreen.main.isCaptured
    var body: some View {
        Color.black
            .opacity(captured ? 1 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(captured)
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                captured = UIScreen.main.isCaptured
            }
    }
}

struct IconBox: View {
    let systemName: String
    var size: CGFloat = 56
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .frame(width: size, height: size)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
    }
}

struct Pill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.1), in: Capsule())
    }
}

enum ShinnLanguage: String, CaseIterable, Identifiable {
    case vi
    case en
    var id: String { rawValue }
    var title: String { self == .vi ? "Tiếng Việt" : "English" }
}

enum ShinnTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    var titleKey: K {
        switch self {
        case .system: return .themeSystem
        case .light: return .themeLight
        case .dark: return .themeDark
        }
    }
}

final class AppSettings: ObservableObject {
    @Published var theme: ShinnTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    @Published var language: ShinnLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "language") }
    }
    @Published var autoRefresh: Bool {
        didSet { UserDefaults.standard.set(autoRefresh, forKey: "autoRefresh") }
    }
    init() {
        let defaults = UserDefaults.standard
        theme = ShinnTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        if let raw = defaults.string(forKey: "language"), let language = ShinnLanguage(rawValue: raw) {
            self.language = language
        } else {
            self.language = .en
        }
        autoRefresh = defaults.object(forKey: "autoRefresh") as? Bool ?? true
    }
    func t(_ key: K) -> String { key.text.en }
    func countText(_ n: Int) -> String { n == 1 ? "1 package" : "\(n) packages" }
}

enum K {
    case heroFree, heroNote, categoriesTitle, allPackages, loadingText, loadFailed, retry
    case settingsTitle, settingsSub, aboutTitle, aboutSub
    case packagesTitle, packageCenter, packageCenterSub, searchPrompt, allLabel, notFound, notFoundDesc
    case versionLabel, authorLabel, categoryLabel, sizeLabel, descriptionLabel
    case downloadAction, downloading, downloaded, redownload, shareAction, savedHint, sha256OK
    case errHash, errHTTP, errURL
    case appearance, themeLabel, themeSystem, themeLight, themeDark, languageLabel
    case autoUpdate, repoSection, defaultSource, defaultBadge, repoLocked, refreshRepo, infoTitle
    case aboutDesc, madeBy, contactTitle, donateTitle, copy, copied
    case featRemote, featSHA
    case termsTitle, termsBody
    case supportTitle, telegramSub, reportTitle, reportSub
}

extension K {
    var text: (vi: String, en: String) {
        switch self {
        case .heroFree: return ("LÀ APP VÀ REPO HOÀN TOÀN FREE", "A COMPLETELY FREE APP AND REPO")
        case .heroNote: return ("Không bán key • Không khóa thiết bị", "No keys sold • No device lock")
        case .categoriesTitle: return ("DANH MỤC GÓI", "PACKAGE CATEGORIES")
        case .allPackages: return ("Tất cả gói", "All packages")
        case .loadingText: return ("Đang tải repo…", "Loading repo…")
        case .loadFailed: return ("Không tải được repo.", "Couldn't load the repo.")
        case .retry: return ("Thử lại", "Retry")
        case .settingsTitle: return ("Cài Đặt", "Settings")
        case .settingsSub: return ("Tùy chỉnh app", "Customize the app")
        case .aboutTitle: return ("Giới Thiệu", "About")
        case .aboutSub: return ("Thông tin app", "App information")
        case .packagesTitle: return ("Packages", "Packages")
        case .packageCenter: return ("Package Center", "Package Center")
        case .packageCenterSub: return ("Các package được cung cấp bởi Shinn Cheat", "Packages provided by Shinn Cheat")
        case .searchPrompt: return ("Tìm package", "Search packages")
        case .allLabel: return ("Tất cả", "All")
        case .notFound: return ("Không tìm thấy", "No results")
        case .notFoundDesc: return ("Không có package phù hợp.", "No packages match your search.")
        case .versionLabel: return ("Phiên bản", "Version")
        case .authorLabel: return ("Tác giả", "Author")
        case .categoryLabel: return ("Danh mục", "Category")
        case .sizeLabel: return ("Dung lượng", "Size")
        case .descriptionLabel: return ("Mô tả", "Description")
        case .downloadAction: return ("Tải xuống", "Download")
        case .downloading: return ("Đang tải…", "Downloading…")
        case .downloaded: return ("Đã tải xong", "Downloaded")
        case .redownload: return ("Tải lại", "Download again")
        case .shareAction: return ("Chia sẻ", "Share")
        case .savedHint: return ("File được lưu trong Tệp › Trên iPhone › Shinn Cheat.", "Saved in Files › On My iPhone › Shinn Cheat.")
        case .sha256OK: return ("Đã xác minh SHA256", "SHA256 verified")
        case .errHash: return ("File tải về không khớp SHA256.", "The downloaded file failed the SHA256 check.")
        case .errHTTP: return ("Lỗi máy chủ", "Server error")
        case .errURL: return ("Link tải không hợp lệ", "Invalid download link")
        case .appearance: return ("Giao diện", "Appearance")
        case .themeLabel: return ("Chủ đề", "Theme")
        case .themeSystem: return ("Theo hệ thống", "System")
        case .themeLight: return ("Sáng", "Light")
        case .themeDark: return ("Tối", "Dark")
        case .languageLabel: return ("Ngôn ngữ", "Language")
        case .autoUpdate: return ("Tự động cập nhật repo", "Auto-refresh repo")
        case .repoSection: return ("Nguồn repo", "Repository")
        case .defaultSource: return ("Nguồn mặc định", "Default source")
        case .defaultBadge: return ("MẶC ĐỊNH", "DEFAULT")
        case .repoLocked: return ("Nguồn mặc định của app.", "The app's built-in source.")
        case .refreshRepo: return ("Làm mới repo", "Refresh repo")
        case .infoTitle: return ("Thông tin", "Info")
        case .aboutDesc: return ("Shinn Cheat is an app for managing packages through Shinn's repository.", "Shinn Cheat is an app for managing packages through Shinn's repository.")
        case .madeBy: return ("App made by Shinn", "App made by Shinn")
        case .contactTitle: return ("Contact", "Contact")
        case .donateTitle: return ("Donate", "Donate")
        case .copy: return ("Copy", "Copy")
        case .copied: return ("Copied", "Copied")
        case .featRemote: return ("Sync data from the repository", "Sync data from the repository")
        case .featSHA: return ("Verify file integrity", "Verify file integrity")
        case .termsTitle: return ("Terms of use", "Terms of use")
        case .termsBody:
            return (
                "By installing and using this app, you agree to our policy.\n\n• The app and its repo are completely FREE.\n• Do not use the app for anything that violates the law.\n• Sabotage or deliberate violations will result in a warning.",
                "By installing and using this app, you agree to our policy.\n\n• The app and its repo are completely FREE.\n• Do not use the app for anything that violates the law.\n• Sabotage or deliberate violations will result in a warning."
            )
        case .supportTitle: return ("Support", "Support")
        case .telegramSub: return ("Contact the support team", "Contact the support team")
        case .reportTitle: return ("Report a bug", "Report a bug")
        case .reportSub: return ("Report a bug or issue", "Report a bug or issue")
        }
    }
}

extension AppInfo {
    static let telegramHandle = "@ShinnThieuu"
    static let telegramURL = URL(string: "https://t.me/ShinnThieuu")!
    static let bankName = "MB Bank"
    static let bankAccount = "104877777"
    static let defaultRepoName = "Shinn Cheat Share"
    static let defaultRepoURL = URL(string: "https://raw.githubusercontent.com/ShinnCheatCode/Mhieuu/main/shinn.json")!
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1"
    }
}

struct RepoManifest: Codable {
    let name: String?
    let description: String?
    let icon: String?
    let packages: [RepoPackage]
}

struct RepoPackage: Codable, Identifiable, Hashable {
    let identifier: String
    let name: String
    let author: String?
    let version: String?
    let summary: String?
    let description: String?
    let category: String?
    let tags: [String]?
    let download: String
    let sha256: String?
    let size: Int?
    let icon: String?
    let patchPath: String?
    let openURL: String?
    var id: String { identifier }
}

struct CategoryInfo: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

enum Route: Hashable {
    case packages(String?)
    case detail(String)
    case settings
    case about
    case support
    case repositoryManager
    case patchBuilder
    case patchProjects   // màn tạo patch kiểu 3105 (sẵn trong project)
    case cleanup         // dọn dẹp máy
}

func formatBytes(_ value: Int) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .file)
}

enum DLError: Error {
    case badURL, http(Int), hashMismatch, other(String)
}

enum PatchError: Error {
    case invalidPath, sourceNotFound, backupFailed, applyFailed, restoreFailed, other(String)
}

enum DownloadState { case idle, downloading, done(URL), failed(DLError) }
enum LoadState { case idle, loading, loaded, failed }
enum PatchState { case idle, applying, applied, restoring, restored, failed(String) }

func sha256Hex(of url: URL) throws -> String {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

@MainActor
final class RepoStore: ObservableObject {
    static func activeRepoURL() -> URL {
        if UserDefaults.standard.bool(forKey: "shinn.license.repoLocked") {
            return AppInfo.defaultRepoURL
        }
        let raw = UserDefaults.standard.string(forKey: "shinn.license.repo") ?? ""
        if let url = URL(string: raw), url.scheme != nil { return url }
        return AppInfo.defaultRepoURL
    }

    @Published private(set) var manifest: RepoManifest?
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var downloads: [String: DownloadState] = [:]
    @Published private(set) var patchStates: [String: PatchState] = [:]
    private var didBootstrap = false

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var cacheURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("repo_default.json")
    }
    private var backupDirectory: URL {
        documentsURL.appendingPathComponent(".ShinnBackups", isDirectory: true)
    }

    var packages: [RepoPackage] { manifest?.packages ?? [] }

    var categories: [CategoryInfo] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for p in packages {
            let category = p.category ?? "Other"
            if counts[category] == nil { order.append(category) }
            counts[category, default: 0] += 1
        }
        return order.map { CategoryInfo(name: $0, count: counts[$0] ?? 0) }
    }

    func bootstrap(autoRefresh: Bool) async {
        if didBootstrap { return }
        didBootstrap = true
        loadCache()
        if manifest == nil || autoRefresh { await refresh() }
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode(RepoManifest.self, from: data) else { return }
        manifest = decoded
        loadState = .loaded
    }

    func refresh() async {
        if UserDefaults.standard.bool(forKey: "shinn.license.repoLocked") {
            manifest = nil
            loadState = .failed
            return
        }
        loadState = .loading
        do {
            var request = URLRequest(url: RepoStore.activeRepoURL(), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }
            let decoded = try JSONDecoder().decode(RepoManifest.self, from: data)
            manifest = decoded
            try? data.write(to: cacheURL, options: .atomic)
            loadState = .loaded
        } catch {
            if manifest == nil { loadState = .failed } else { loadState = .loaded }
        }
    }

    private func destination(for pkg: RepoPackage) -> URL? {
        guard let url = URL(string: pkg.download) else { return nil }
        return documentsURL.appendingPathComponent(url.lastPathComponent)
    }

    func existingFile(for pkg: RepoPackage) -> URL? {
        guard let destination = destination(for: pkg) else { return nil }
        return FileManager.default.fileExists(atPath: destination.path) ? destination : nil
    }

    func state(for pkg: RepoPackage) -> DownloadState {
        if let state = downloads[pkg.id] { return state }
        if let file = existingFile(for: pkg) { return .done(file) }
        return .idle
    }

    func download(_ pkg: RepoPackage) async {
        guard let url = URL(string: pkg.download), let destination = destination(for: pkg) else {
            downloads[pkg.id] = .failed(.badURL)
            return
        }
        downloads[pkg.id] = .downloading
        do {
            let (temporaryURL, response) = try await URLSession.shared.download(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }
            if let expected = pkg.sha256?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !expected.isEmpty {
                let actual = try await Task.detached(priority: .utility) { try sha256Hex(of: temporaryURL) }.value
                if actual.lowercased() != expected {
                    try? FileManager.default.removeItem(at: temporaryURL)
                    throw DLError.hashMismatch
                }
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
            downloads[pkg.id] = .done(destination)
        } catch let error as DLError {
            downloads[pkg.id] = .failed(error)
        } catch {
            downloads[pkg.id] = .failed(.other(error.localizedDescription))
        }
    }

    private func decodedPatchProject(for pkg: RepoPackage) throws -> PatchProject {
        guard let archive = existingFile(for: pkg) else { throw PatchError.sourceNotFound }
        let data = try Data(contentsOf: archive, options: .mappedIfSafe)
        let summary = try PatchPackageCodec.inspect(data)
        guard !summary.isPasswordProtected else {
            throw PatchError.other("Gói .3105 này được bảo vệ bằng mật khẩu.")
        }
        return try PatchPackageCodec.decode(data, password: nil).project
    }

    /// path (lowercased) -> package id đang chiếm
    @Published private(set) var pathOwners: [String: String] = [:]
    @Published var lastApplyMessage: String?

    private let pathOwnersKey = "shinn.patch.pathOwners"

    private func loadPathOwners() {
        if let data = UserDefaults.standard.data(forKey: pathOwnersKey),
           let map = try? JSONDecoder().decode([String: String].self, from: data) {
            pathOwners = map
        }
    }

    private func savePathOwners() {
        if let data = try? JSONEncoder().encode(pathOwners) {
            UserDefaults.standard.set(data, forKey: pathOwnersKey)
        }
    }

    /// Lấy các đường dẫn đích từ gói (Mirror + patchPath metadata)
    private func destinationPaths(for pkg: RepoPackage, project: Any) -> [String] {
        var paths: [String] = []
        if let p = pkg.patchPath?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            paths.append(p)
        }
        paths.append(contentsOf: mirrorCollectPaths(project))
        // Chuẩn hoá
        return Array(Set(paths.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }))
    }

    private func mirrorCollectPaths(_ value: Any, depth: Int = 0) -> [String] {
        guard depth < 5 else { return [] }
        var found: [String] = []
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            let label = (child.label ?? "").lowercased()
            if let s = child.value as? String {
                let looksPath = s.contains("/") || s.hasSuffix(".bytes") || s.hasSuffix(".bundle")
                    || label.contains("path") || label.contains("dest") || label.contains("target")
                if looksPath && s.count > 3 && s.count < 400 {
                    found.append(s)
                }
            } else {
                let sub = Mirror(reflecting: child.value)
                if !sub.children.isEmpty {
                    found.append(contentsOf: mirrorCollectPaths(child.value, depth: depth + 1))
                } else if let arr = child.value as? [Any] {
                    for el in arr { found.append(contentsOf: mirrorCollectPaths(el, depth: depth + 1)) }
                }
            }
        }
        return found
    }

    func apply(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .applying
        lastApplyMessage = nil
        do {
            if pathOwners.isEmpty { loadPathOwners() }
            let project = try decodedPatchProject(for: pkg)
            let paths = destinationPaths(for: pkg, project: project)

            // Kiểm tra trùng đường dẫn với patch đang bật (khác id)
            for p in paths {
                let key = p.lowercased()
                if let owner = pathOwners[key], owner != pkg.id {
                    let name = packages.first(where: { $0.id == owner })?.name ?? owner
                    throw PatchError.other("Trùng đường dẫn với patch đang bật: «\(name)»\n→ \(p)")
                }
            }

            _ = try DevicePatchService.apply(project: project)

            // Ghi nhận path thuộc package này
            for p in paths {
                pathOwners[p.lowercased()] = pkg.id
            }
            // Gỡ path cũ của cùng package nếu đổi rule
            pathOwners = pathOwners.filter { $0.value != pkg.id || paths.map { $0.lowercased() }.contains($0.key) }
            for p in paths { pathOwners[p.lowercased()] = pkg.id }
            savePathOwners()

            patchStates[pkg.id] = .applied
            lastApplyMessage = paths.isEmpty
                ? "Áp dụng thành công: \(pkg.name)"
                : "Áp dụng thành công: \(pkg.name) (\(paths.count) đường dẫn)"
            openTargetApp(for: pkg)
        } catch {
            patchStates[pkg.id] = .failed(error.localizedDescription)
            lastApplyMessage = error.localizedDescription
        }
    }

    func restore(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .restoring
        lastApplyMessage = nil
        do {
            let project = try decodedPatchProject(for: pkg)
            guard let receipt = DevicePatchService.latestReceipt(projectID: project.id) else {
                throw PatchError.restoreFailed
            }
            try DevicePatchService.restore(receipt: receipt)
            // Giải phóng path
            pathOwners = pathOwners.filter { $0.value != pkg.id }
            savePathOwners()
            patchStates[pkg.id] = .restored
            lastApplyMessage = "Đã gỡ patch: \(pkg.name)"
        } catch {
            patchStates[pkg.id] = .failed(error.localizedDescription)
            lastApplyMessage = error.localizedDescription
        }
    }

    /// Áp dụng nhiều package: path khác nhau → OK; trùng path → báo lỗi từng cái
    func applyMultiple(_ pkgs: [RepoPackage]) async -> (ok: [String], fail: [(String, String)]) {
        var ok: [String] = []
        var fail: [(String, String)] = []
        for pkg in pkgs {
            await apply(pkg)
            if case .applied = patchStates[pkg.id] {
                ok.append(pkg.name)
            } else if case .failed(let m) = patchStates[pkg.id] {
                fail.append((pkg.name, m))
            } else {
                fail.append((pkg.name, "Unknown"))
            }
        }
        if fail.isEmpty {
            lastApplyMessage = "Thành công \(ok.count) patch: \(ok.joined(separator: ", "))"
        } else if ok.isEmpty {
            lastApplyMessage = "Tất cả thất bại. " + fail.map { "\($0.0): \($0.1)" }.joined(separator: " | ")
        } else {
            lastApplyMessage = "OK: \(ok.joined(separator: ", ")). Lỗi: " + fail.map { $0.0 }.joined(separator: ", ")
        }
        return (ok, fail)
    }

    func patchState(for pkg: RepoPackage) -> PatchState {
        patchStates[pkg.id] ?? .idle
    }

    func openTargetApp(for pkg: RepoPackage) {
        var schemes: [String] = []
        if let raw = pkg.openURL, !raw.isEmpty { schemes.append(raw) }
        switch (pkg.category ?? "").lowercased() {
        case "free fire": schemes += ["freefire://", "com.dts.freefireth://"]
        case "free fire max": schemes += ["freefiremax://", "com.dts.freefiremax://"]
        case "liên quân mobile", "lien quan": schemes += ["com.garena.game.kgvn://"]
        default: break
        }
        for raw in schemes {
            guard let url = URL(string: raw) else { continue }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
    }
}

func categoryIcon(_ name: String) -> String {
    switch name {
    case "AIM": return "scope"
    case "ESP": return "eye.fill"
    case "Free Fire": return "flame.fill"
    case "Free Fire Max": return "sparkles"
    case "MOD SKIN": return "paintbrush.fill"
    case "Liên Quân Mobile": return "gamecontroller.fill"
    default: return "shippingbox.fill"
    }
} // ===== SecondaryViews =====
struct LemonTargetApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let iconAssetName: String
}

enum FFH4XFeatureCategory: String, CaseIterable, Identifiable, Hashable {
    case aim, chams, modSkin
    var id: String { rawValue }
    var title: String {
        switch self { case .aim: return "Aim"; case .chams: return "Chams"; case .modSkin: return "Mod Skin" }
    }
    var subtitle: String {
        switch self { case .aim: return "Hỗ trợ kéo tâm"; case .chams: return "Định vị nhìn xuyên tường"; case .modSkin: return "Mod skin" }
    }
    var icon: String {
        switch self { case .aim: return "scope"; case .chams: return "eye.fill"; case .modSkin: return "tshirt.fill" }
    }
    var tint: Color {
        switch self { case .aim: return .blue; case .chams: return .purple; case .modSkin: return .orange }
    }
}

struct ProjectAppIcon: View {
    let assetName: String
    let size: CGFloat
    var body: some View {
        Image(assetName).resizable().scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
    }
}

struct InstalledAppIcon: View {
    let bundleID: String
    let size: CGFloat
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "app.fill").font(.system(size: size * 0.38, weight: .semibold)).frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .task(id: bundleID) {
            image = await Task.detached(priority: .userInitiated) { iconForBundleID(bundleID) }.value
        }
    }
}

// ===== UserRole / Session =====
enum UserRole: String, CaseIterable, Identifiable {
    case owner, admin, member
    var id: String { rawValue }
    var title: String {
        switch self { case .owner: return "Owner"; case .admin: return "Admin"; case .member: return "Member" }
    }
    var icon: String {
        switch self { case .owner: return "crown.fill"; case .admin: return "checkmark.shield.fill"; case .member: return "person.fill" }
    }
    /// Owner đỏ · Admin xanh dương · Member xanh lá
    var badgeColor: Color {
        switch self {
        case .owner: return .red
        case .admin: return .blue
        case .member: return .green
        }
    }
    var needsPassword: Bool { self != .member }
}

enum PatchFolder: String, CaseIterable, Identifiable {
    case aim, esp, menu, gunLoc, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .aim: return "AIM"
        case .esp: return "ESP / Chams"
        case .menu: return "Menu"
        case .gunLoc: return "Định vị súng"
        case .other: return "Khác"
        }
    }
    var icon: String {
        switch self {
        case .aim: return "scope"
        case .esp: return "eye.fill"
        case .menu: return "list.bullet.rectangle"
        case .gunLoc: return "location.viewfinder"
        case .other: return "shippingbox.fill"
        }
    }
    static func folder(for pkg: RepoPackage) -> PatchFolder {
        let c = (pkg.category ?? "").lowercased()
        let n = pkg.name.lowercased()
        let t = (pkg.tags ?? []).joined(separator: " ").lowercased()
        let blob = c + " " + n + " " + t
        if blob.contains("aim") || blob.contains("drag") || blob.contains("neck") || blob.contains("chest") || blob.contains("body") || blob.contains("magic") {
            return .aim
        }
        if blob.contains("esp") || blob.contains("chams") || blob.contains("wall") {
            return .esp
        }
        if blob.contains("menu") || blob.contains("mod menu") {
            return .menu
        }
        if blob.contains("định vị") || blob.contains("dinh vi") || blob.contains("gun") || blob.contains("súng") || blob.contains("sung") || blob.contains("weapon") {
            return .gunLoc
        }
        // category exact
        if c == "aim" { return .aim }
        if c == "esp" { return .esp }
        return .other
    }
}

final class Session: ObservableObject {
    @Published var role: UserRole?
    private static let passwordHash = "a43535812161a1aec35c04f0b6ea63bb4880d581f3d15df9ba7e68befe6b472e"
    func verify(_ input: String) -> Bool {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex == Session.passwordHash
    }
}

// ===== Keychain =====
enum KeychainKeyStore {
    private static let service = "shinn.license.biometric"
    private static let account = "activation-key"

    static func save(_ key: String) {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(add as CFDictionary, nil)
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension Notification.Name {
    static let shinnKeyNotice = Notification.Name("shinnKeyNotice")
}

// ===== Supabase =====
enum SupabaseConfig {
    static let projectURL = URL(string: "https://efhqbzdnrtifqjqlqseb.supabase.co")!
    static let anonKey = "sb_publishable_jnycTCgXRMrluvwJORd_4g_B7ojwi9R"
    /// Owner labels nhận diện trong app
    static let ownerLabels: [String] = ["NgVuMinhHieuu", "ShinnThieuu"]

    /// Dùng string URL trực tiếp — KHÔNG dùng appendingPathComponent (sẽ encode / thành %2F → path invalid)
    static func rpc(_ name: String) -> URL {
        URL(string: "https://efhqbzdnrtifqjqlqseb.supabase.co/rest/v1/rpc/\(name)")!
    }

    static var activateKeyURL: URL { rpc("activate_key") }
    static var createKeyURL: URL { rpc("create_shinn_key") }
    static var listKeysURL: URL { rpc("list_shinn_keys") }
    static var deleteKeyURL: URL { rpc("delete_shinn_key") }
    static var deleteAllKeysURL: URL { rpc("delete_all_shinn_keys") }
    static var addKeyRepoURL: URL { rpc("add_key_repo") }
}

struct KeyRepoItem: Codable, Hashable, Identifiable {
    var id: String { name + "|" + url }
    var name: String
    var url: String
    var locked: Bool?
}

struct ActivateKeyResponse: Decodable {
    let ok: Bool
    let error: String?
    let role: String?
    let key: String?
    let expires_at: String?
    let label: String?
    let repo_url: String?
    let repo_locked: Bool?
    let repos: [KeyRepoItem]?
}

@MainActor
final class LicenseManager: ObservableObject {
    @Published var isActivated: Bool
    @Published var isBusy = false
    @Published var lastError: String?
    @Published var boundRole: String?
    @Published var expiresAt: Date?
    @Published var savedLicenseKey: String
    @Published var holderName: String

    private let activatedKey = "shinn.license.activated"
    private let roleKey = "shinn.license.role"
    private let deviceKey = "shinn.license.device_id"
    private let savedKey = "shinn.license.key"
    private let expireKey = "shinn.license.expires"

    init() {
        let defaults = UserDefaults.standard
        boundRole = defaults.string(forKey: roleKey)
        savedLicenseKey = defaults.string(forKey: savedKey) ?? ""
        holderName = defaults.string(forKey: "shinn.license.holder") ?? ""
        if defaults.object(forKey: expireKey) != nil {
            expiresAt = Date(timeIntervalSince1970: defaults.double(forKey: expireKey))
        }
        isActivated = false
    }

    var deviceID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: deviceKey), !existing.isEmpty {
            return existing
        }
        let generated = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        defaults.set(generated, forKey: deviceKey)
        return generated
    }

    private static func parseExpiry(_ raw: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: raw) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: raw) { return d }
        return ISO8601DateFormatter().date(from: raw)
    }

    func activate(key raw: String, language: ShinnLanguage) async -> Bool {
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        lastError = nil
        guard !key.isEmpty else {
            lastError = "Enter an activation key."
            return false
        }
        isBusy = true
        defer { isBusy = false }

        do {
            let result = try await callActivate(key: key)
            if result.ok {
                UserDefaults.standard.set(true, forKey: activatedKey)
                UserDefaults.standard.set(key, forKey: savedKey)
                savedLicenseKey = key
                KeychainKeyStore.save(key)
                if let label = result.label {
                    holderName = label
                    UserDefaults.standard.set(label, forKey: "shinn.license.holder")
                }
                let repo = (result.repo_url ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                UserDefaults.standard.set(repo, forKey: "shinn.license.repo")
                UserDefaults.standard.set(result.repo_locked ?? false, forKey: "shinn.license.repoLocked")

                var list: [KeyRepoItem] = [
                    KeyRepoItem(name: "Repo ShinnCheat", url: AppInfo.defaultRepoURL.absoluteString, locked: false)
                ]
                if let extra = result.repos {
                    for r in extra where !r.url.isEmpty {
                        if !list.contains(where: { $0.url == r.url }) {
                            list.append(r)
                        }
                    }
                } else if let one = result.repo_url, !one.isEmpty {
                    list.append(KeyRepoItem(name: "Custom", url: one, locked: result.repo_locked))
                }
                if let data = try? JSONEncoder().encode(list) {
                    UserDefaults.standard.set(data, forKey: "shinn.license.repos")
                }

                if let role = result.role, !role.isEmpty {
                    UserDefaults.standard.set(role, forKey: roleKey)
                    boundRole = role
                }
                if let exp = result.expires_at, let date = Self.parseExpiry(exp) {
                    expiresAt = date
                    UserDefaults.standard.set(date.timeIntervalSince1970, forKey: expireKey)
                } else {
                    expiresAt = nil
                    UserDefaults.standard.removeObject(forKey: expireKey)
                }
                isActivated = true
                return true
            }
            lastError = mappedError(result.error)
            return false
        } catch {
            let msg = error.localizedDescription
            if msg.contains("path") || msg.contains("invalid") {
                lastError = "Key server path invalid. Check Supabase RPC activate_key."
            } else {
                lastError = "Could not reach the key server: \(msg)"
            }
            return false
        }
    }

    func signOutLicense() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: activatedKey)
        defaults.removeObject(forKey: roleKey)
        defaults.removeObject(forKey: savedKey)
        defaults.removeObject(forKey: expireKey)
        isActivated = false
        boundRole = nil
        savedLicenseKey = ""
        expiresAt = nil
        holderName = ""
        defaults.removeObject(forKey: "shinn.license.holder")
    }

    func restoreIfValid(language: ShinnLanguage) async -> Bool {
        let key = savedLicenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return false }
        if let exp = expiresAt, exp < Date(), (boundRole ?? "").lowercased() != "owner" {
            signOutLicense()
            return false
        }
        return await activate(key: key, language: language)
    }

    private func mappedError(_ code: String?) -> String {
        switch code {
        case "invalid_key": return "Invalid key."
        case "used_on_other_device": return "This key is already used on another device."
        case "missing_key": return "Missing key."
        case "missing_device": return "Missing device id."
        default: return "Could not activate the key."
        }
    }

    private func callActivate(key: String) async throws -> ActivateKeyResponse {
        var request = URLRequest(url: SupabaseConfig.activateKeyURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "p_key": key,
            "p_device_id": deviceID
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        print("[Supabase] url=\(request.url?.absoluteString ?? "nil")")
        print("[Supabase] status=\(http.statusCode)")
        print("[Supabase] body=\(String(data: data, encoding: .utf8) ?? "nil")")

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw URLError(.userAuthenticationRequired)
            }
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ActivateKeyResponse.self, from: data)
    }
}

// ===== AbuseGuard =====
@MainActor
final class AbuseGuard: ObservableObject {
    @Published var lockedUntil: Date?
    private let lockKey = "shinn.abuse.lock"
    private let keyFailsKey = "shinn.abuse.keyFails"
    private let passFailsKey = "shinn.abuse.passFails"
    private let patchTapsKey = "shinn.abuse.patchTaps"
    private let windowKey = "shinn.abuse.window"
    private let faceFailsKey = "shinn.abuse.faceFails"

    init() {
        let d = UserDefaults.standard
        if d.object(forKey: lockKey) != nil {
            let until = Date(timeIntervalSince1970: d.double(forKey: lockKey))
            lockedUntil = until > Date() ? until : nil
        }
    }

    var isLocked: Bool {
        if let until = lockedUntil, until > Date() { return true }
        return false
    }

    func remainText() -> String {
        guard let until = lockedUntil else { return "" }
        let s = max(0, Int(until.timeIntervalSinceNow))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func bump(_ key: String, limit: Int) {
        let d = UserDefaults.standard
        let window = d.double(forKey: windowKey)
        if Date().timeIntervalSince1970 - window > 600 {
            d.set(0, forKey: keyFailsKey)
            d.set(0, forKey: passFailsKey)
            d.set(0, forKey: patchTapsKey)
            d.set(Date().timeIntervalSince1970, forKey: windowKey)
        }
        let n = d.integer(forKey: key) + 1
        d.set(n, forKey: key)
        if n >= limit { lock() }
    }

    func keyFailed() { bump(keyFailsKey, limit: 5) }
    func passFailed() { bump(passFailsKey, limit: 5) }
    func patchToggled() { bump(patchTapsKey, limit: 15) }
    func keyOk() { UserDefaults.standard.set(0, forKey: keyFailsKey) }
    func passOk() { UserDefaults.standard.set(0, forKey: passFailsKey) }

    func faceFailed() -> Int {
        let d = UserDefaults.standard
        let n = d.integer(forKey: faceFailsKey) + 1
        d.set(n, forKey: faceFailsKey)
        return n
    }
    func faceOk() { UserDefaults.standard.set(0, forKey: faceFailsKey) }
    func faceFailCount() -> Int { UserDefaults.standard.integer(forKey: faceFailsKey) }

    private func lock() {
        let until = Date().addingTimeInterval(10 * 60)
        lockedUntil = until
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: lockKey)
        UserDefaults.standard.set(0, forKey: keyFailsKey)
        UserDefaults.standard.set(0, forKey: passFailsKey)
        UserDefaults.standard.set(0, forKey: patchTapsKey)
    }
} // ===== ContentView =====
struct ContentView: View {
    @StateObject var session = Session()
    @StateObject private var license = LicenseManager()
    @StateObject private var abuse = AbuseGuard()
    @StateObject private var settings = AppSettings()
    @StateObject private var store = RepoStore()
    /// Store / navigation của 3105 (module sẵn trong project)
    @StateObject private var patchProjectStore = PatchProjectStore()
    private let containerStore = ContainerStore.self
    // AppTabNavigationState là struct (Equatable), không dùng @StateObject / environmentObject
    @State private var tabNav = AppTabNavigationState()
    @State private var path: [Route] = []
    @State private var selectedTab: Int = 0
    // Giữ state của tab Tệp để việc mở thư mục/app hoạt động đúng.
    // Không dùng .constant(...) vì FilesTabSwitcherView cần cập nhật session khi người dùng chạm.
    @State private var filesSession = FilesTabSession()

    var body: some View {
        // Explicit type erasure fixes SwiftUI's "generic parameter R could not be inferred"
        // at the old Group/ViewBuilder root (ContentView.swift:1067).
        AnyView(
            Group {
                if abuse.isLocked {
                    AnyView(LockoutView(abuse: abuse))
                } else if !license.isActivated {
                    AnyView(ActivateKeyView())
                } else if session.role == nil {
                    AnyView(RoleGateView())
                } else {
                    AnyView(mainTabView)
                }
            }
            .environmentObject(session)
            .environmentObject(license)
            .environmentObject(abuse)
            .environmentObject(settings)
            .environmentObject(store)
            .environmentObject(patchProjectStore)
            .preferredColorScheme(settings.theme.colorScheme)
            .task {
                await store.bootstrap(autoRefresh: settings.autoRefresh)
                if !license.isActivated {
                    _ = await license.restoreIfValid(language: .en)
                }
                if license.isActivated,
                   let raw = license.boundRole,
                   let role = UserRole(rawValue: raw.lowercased()) {
                    session.role = role
                }
            }
            .animation(.easeInOut(duration: 0.25), value: session.role)
            .animation(.easeInOut(duration: 0.25), value: license.isActivated)
        )
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $path) {
                HomeView(open: { path.append($0) }, selectTab: { selectedTab = $0 })
                    .navigationDestination(for: Route.self) { route in
                        shinnDestination(route)
                    }
            }
            .tabItem { Label("Trang chủ", systemImage: "house.fill") }
            .tag(0)

            // Dùng FilesTabSwitcherView có sẵn trong project (không có ShinnFilesBrowserView)
            FilesTabSwitcherView(session: $filesSession)
                .tabItem { Label("Tệp", systemImage: "folder.fill") }
                .tag(1)

            NavigationStack {
                PatchProjectsView()
                    // Giữ nguyên giao diện Patch, nhưng chỉ Owner được thao tác/tạo patch.
                    .allowsHitTesting(session.role == .owner)
                    .overlay {
                        if session.role != .owner {
                            Color.clear
                                .contentShape(Rectangle())
                                .allowsHitTesting(true)
                        }
                    }
            }
            .tabItem { Label("Patch", systemImage: "shippingbox.fill") }
            .tag(2)

            NavigationStack {
                PhoneCleanupView()
            }
            .tabItem { Label("Dọn dẹp", systemImage: "trash.circle") }
            .tag(3)

            NavigationStack {
                ShinnAboutView()
            }
            .tabItem { Label("About", systemImage: "info.circle") }
            .tag(4)
        }
        .tint(.primary)
    }

    @ViewBuilder
    private func shinnDestination(_ route: Route) -> some View {
        switch route {
        case .packages(let category):
            PackagesView(initialCategory: category)
        case .detail(let id):
            PackageDetailView(packageID: id)
        case .settings:
            SettingsView()
        case .about:
            ShinnAboutView()
        case .support:
            SupportView()
        case .repositoryManager:
            RepositoryManagerView()
        case .patchBuilder:
            PatchBuilderView()
        case .patchProjects:
            // Chỉ Owner được mở khu vực tạo/quản lý project patch.
            if session.role == .owner {
                PatchProjectsView()
            } else {
                PatchOwnerOnlyView()
            }
        case .cleanup:
            PhoneCleanupView()
        }
    }
}

// ===== PatchOwnerOnlyView =====
struct PatchOwnerOnlyView: View {
    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Owner only")
                    .font(.title2.bold())
                Text("Chỉ Owner mới có quyền tạo hoặc chỉnh sửa Patch.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .navigationTitle("Patch")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ===== LockoutView =====
struct LockoutView: View {
    @ObservedObject var abuse: AbuseGuard
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill").font(.system(size: 44))
                Text("Temporarily locked").font(.title2.bold())
                Text("Try again in \(abuse.remainText())")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(timer) { _ in
            if !abuse.isLocked { abuse.lockedUntil = nil }
            abuse.objectWillChange.send()
        }
    }
}

// ===== ActivateKeyView =====
struct ActivateKeyView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @EnvironmentObject var license: LicenseManager
    @EnvironmentObject var abuse: AbuseGuard

    @State private var keyText = ""
    @State private var isBiometricRunning = false
    @State private var didAutoStartBiometric = false
    @FocusState private var focused: Bool

    private var hasSavedKey: Bool {
        (KeychainKeyStore.load() ?? "").isEmpty == false
    }

    var body: some View {
        ZStack {
            BackgroundView()
            ScreenPrivacyGuard()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    VStack(spacing: 22) {
                        Image(systemName: hasSavedKey ? "faceid" : "key.fill")
                            .font(.system(size: 46))

                        VStack(spacing: 6) {
                            Text("SHINN CHEAT")
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .tracking(-0.8)
                            Text(hasSavedKey
                                ? "Face ID or enter the key manually"
                                : "Enter a key to use the app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 12) {
                        Label("Activation key", systemImage: "lock.fill")
                            .font(.headline)

                        SecureField("Enter key manually or use Face ID", text: $keyText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($focused)
                            .padding(14)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if let err = license.lastError, !err.isEmpty {
                            Text(err).font(.footnote.bold()).foregroundStyle(.red)
                        }

                        if hasSavedKey {
                            Text("No Face ID or broken Face ID? You can still enter your key manually above.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button {
                                Task { await biometricUnlock() }
                            } label: {
                                Label("Retry Face ID", systemImage: "faceid")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(license.isBusy || isBiometricRunning)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                if license.isBusy {
                                    ProgressView().tint(Color(.systemBackground))
                                }
                                Text("Activate").font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)
                        .disabled(license.isBusy || keyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16)
                    .shinnGlass()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            keyText = ""
            if hasSavedKey {
                guard !didAutoStartBiometric else { return }
                didAutoStartBiometric = true
                Task { await biometricUnlock() }
            } else {
                DispatchQueue.main.async { focused = true }
            }
        }
    }

    private func quitApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
    }

    private func biometricUnlock() async {
        guard !isBiometricRunning else { return }
        guard let stored = KeychainKeyStore.load(), !stored.isEmpty else { return }

        isBiometricRunning = true
        defer { isBiometricRunning = false }

        let role = (license.boundRole ?? "").lowercased()
        if role != "owner", let exp = license.expiresAt, exp <= Date() {
            KeychainKeyStore.clear()
            return
        }

        keyText = ""

        let ctx = LAContext()
        var evalError: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evalError) else {
            license.lastError = "This device has no Face ID / Touch ID."
            return
        }

        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Scan Face ID to fill your key"
            )
            guard ok else { await handleFaceFail(); return }
            abuse.faceOk()
            license.lastError = nil
            keyText = stored
            await submit()
        } catch let error as LAError {
            switch error.code {
            case .authenticationFailed: await handleFaceFail()
            case .biometryLockout:
                license.lastError = "Face ID locked."
                quitApp()
            case .userCancel, .systemCancel, .appCancel:
                license.lastError = "Cancelled. Tap Retry Face ID."
            default: await handleFaceFail()
            }
        } catch {
            await handleFaceFail()
        }
    }

    private func handleFaceFail() async {
        let n = abuse.faceFailed()
        license.lastError = "Face ID failed (\(n)/3)"
        keyText = ""
        if n >= 3 { quitApp() }
    }

    private func submit() async {
        let raw = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        let ok = await license.activate(key: raw, language: .en)
        if ok {
            abuse.keyOk()
            abuse.faceOk()
            KeychainKeyStore.save(raw)
        } else {
            abuse.keyFailed()
            if hasSavedKey { keyText = "" }
        }
        guard ok else { return }

        if let rawRole = license.boundRole,
           let role = UserRole(rawValue: rawRole.lowercased()) {
            session.role = role
        } else {
            session.role = .member
        }
    }
}

// ===== RoleGateView =====
struct RoleGateView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @EnvironmentObject var abuse: AbuseGuard
    @State private var pending: UserRole?
    @State private var password = ""
    @State private var attempts = 0
    @State private var closing = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            BackgroundView()
            ScreenPrivacyGuard()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    if pending == nil {
                        VStack(spacing: 22) {
                            Image(systemName: "crown.fill").font(.system(size: 46))
                            VStack(spacing: 6) {
                                Text("SHINN CHEAT")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .tracking(-0.8)
                                Text("Choose a role to activate")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        Color.clear.frame(height: 12)
                    }

                    VStack(spacing: 12) {
                        ForEach(UserRole.allCases) { role in
                            roleCard(role)
                        }
                    }
                    .padding(.top, 8)

                    if let role = pending {
                        passwordCard(role)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: pending)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func roleCard(_ role: UserRole) -> some View {
        Button(action: { select(role) }) {
            HStack(spacing: 16) {
                IconBox(systemName: role.icon, size: 52)
                Text(role.title).font(.system(size: 20, weight: .bold, design: .rounded))
                Spacer(minLength: 0)
            }
            .padding(14)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }

    private func passwordCard(_ role: UserRole) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Password for " + role.title, systemImage: "lock.fill")
                .font(.headline)

            SecureField("Enter password", text: $password)
                .focused($focused)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit { submit() }
                .disabled(closing)

            if closing {
                Text("Wrong password. The app will close.")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            } else if attempts > 0 {
                Text("You are a cow")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Button(action: cancel) {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: submit) {
                    Text("Confirm")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Color(.systemBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .shinnGlass()
    }

    private func select(_ role: UserRole) {
        if closing { return }
        if role.needsPassword {
            pending = role
            password = ""
            DispatchQueue.main.async { focused = true }
        } else {
            session.role = role
        }
    }

    private func cancel() {
        if closing { return }
        pending = nil
        password = ""
        focused = false
    }

    private func submit() {
        guard let role = pending, !closing else { return }
        if session.verify(password) {
            session.role = role
            pending = nil
            password = ""
            attempts = 0
            abuse.passOk()
        } else {
            attempts += 1
            password = ""
            abuse.passFailed()
            if attempts >= 5 { focused = false }
        }
    }
}

// ===== OwnerKeyManager =====
struct CreateKeyResponse: Codable {
    let key: String
}

struct ShinnKeyRow: Codable, Identifiable {
    let key: String
    let role: String?
    let expires_at: String?
    let is_vip: Bool?
    let device_id: String?
    let label: String?
    var id: String { key }
}

@MainActor
final class OwnerKeyManager: ObservableObject {
    @Published var createdKey = ""
    @Published var keys: [ShinnKeyRow] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedRole = "member"
    @Published var selectedDays = 7
    @Published var selectedHours = 0
    @Published var createCount = 1
    @Published var lifetime = false
    @Published var keyLabel = ""
    @Published var customKey = ""

    private var actorKey: String {
        UserDefaults.standard.string(forKey: "shinn.license.key")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private var actorRole: String {
        UserDefaults.standard.string(forKey: "shinn.license.role")?.lowercased() ?? ""
    }

    private func actorPayload() -> [String: String] {
        ["p_created_by_key": actorKey, "p_creator_role": actorRole]
    }

    func createKey() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            var request = URLRequest(url: SupabaseConfig.createKeyURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            var body: [String: Any] = actorPayload()
            body["p_role"] = selectedRole
            body["p_days"] = lifetime ? -1 : selectedDays
            body["p_hours"] = lifetime ? 0 : selectedHours
            body["p_count"] = max(1, min(createCount, 20))
            body["p_label"] = keyLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            let custom = customKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !custom.isEmpty { body["p_custom_key"] = custom }
            guard !actorKey.isEmpty, !actorRole.isEmpty else {
                error = "Missing active Owner/Admin key."
                return
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let raw = String(decoding: data, as: UTF8.self)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                self.error = "HTTP \(code): \(raw.isEmpty ? "bad response" : raw)"
                return
            }
            if let list = try? JSONDecoder().decode([String].self, from: data), !list.isEmpty {
                createdKey = list.joined(separator: "\n")
            } else if let parsed = try? JSONDecoder().decode(CreateKeyResponse.self, from: data), !parsed.key.isEmpty {
                createdKey = parsed.key
            } else {
                createdKey = String(decoding: data, as: UTF8.self)
                    .replacingOccurrences(of: "\"", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            createdKey = createdKey
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "")
            if createdKey.isEmpty { error = "Could not create key" }
            await listKeys()
        } catch {
            if let urlErr = error as? URLError {
                self.error = "Network: \(urlErr.localizedDescription)"
            } else {
                self.error = error.localizedDescription.isEmpty ? "Could not create key" : error.localizedDescription
            }
        }
    }

    var prettyCreated: String {
        createdKey
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    func deleteAllKeys() async {
        do {
            var request = URLRequest(url: SupabaseConfig.deleteAllKeysURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            guard !actorKey.isEmpty, !actorRole.isEmpty else {
                error = "Missing active Owner/Admin key."
                return
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: actorPayload())
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                error = "Server rejected delete-all request."
                return
            }
            createdKey = ""
            await listKeys()
        } catch {
            self.error = "Could not delete keys"
        }
    }

    func listKeys() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: SupabaseConfig.listKeysURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            guard !actorKey.isEmpty, !actorRole.isEmpty else {
                error = "Missing active Owner/Admin key."
                return
            }
            // Khớp SQL list_shinn_keys(p_label, p_created_by_key, p_creator_role)
            var body = actorPayload()
            let holder = UserDefaults.standard.string(forKey: "shinn.license.holder")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? actorKey
            body["p_label"] = holder
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            let raw = String(decoding: data, as: UTF8.self)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                error = "List keys HTTP \(code): \(raw.prefix(200))"
                return
            }
            // Hỗ trợ cả mảng trực tiếp và { ok, keys: [...] }
            if let decoded = try? JSONDecoder().decode([ShinnKeyRow].self, from: data) {
                keys = decoded
                if !keys.isEmpty { error = nil }
            } else if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let arr = obj["keys"] as? [[String: Any]],
                      let arrData = try? JSONSerialization.data(withJSONObject: arr),
                      let decoded = try? JSONDecoder().decode([ShinnKeyRow].self, from: arrData) {
                keys = decoded
                if !keys.isEmpty { error = nil }
            } else {
                keys = []
                error = "Không parse được danh sách key."
            }
        } catch {
            self.error = "List keys: \(error.localizedDescription)"
        }
    }

    func deleteKey(_ key: String) async {
        do {
            var request = URLRequest(url: SupabaseConfig.deleteKeyURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            guard !actorKey.isEmpty, !actorRole.isEmpty else {
                error = "Missing active Owner/Admin key."
                return
            }
            if ["NgVuMinhHieuu", "ShinnThieuu"].contains(key) {
                error = "Không xoá được key Owner cố định."
                return
            }
            var body = actorPayload()
            body["p_key"] = key
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                error = "Delete failed: \(String(decoding: data, as: UTF8.self).prefix(180))"
                return
            }
            if createdKey.contains(key) {
                createdKey = createdKey
                    .split(separator: "\n")
                    .map(String.init)
                    .filter { $0 != key }
                    .joined(separator: "\n")
            }
            await listKeys()
        } catch {
            self.error = "Could not delete key"
        }
    }
}

// ===== RepositoryManagerView =====
// Repo V2 cố định — Owner chỉ chọn key được phép dùng.
// Key chưa được gán → không nhận repo khi activate.
struct RepositoryManagerView: View {
    private static let fixedRepoName = "ShinnCheat Repo V2"
    private static let fixedRepoURL  = "https://raw.githubusercontent.com/ShinnCheatCode/RepoV2/main/ShinnCheatV2.json"

    @StateObject private var manager = OwnerKeyManager()
    @State private var selectedKey = ""
    @State private var locked = false
    @State private var status = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("REPOSITORY MANAGER").font(.title.bold())
                Text("Gán ShinnCheat Repo V2 cho key được chọn. Chỉ key đó mới dùng được khi activate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Repo cố định").font(.caption.bold()).foregroundStyle(.secondary)
                    HStack {
                        Image(systemName: "lock.doc.fill")
                        Text(Self.fixedRepoName).font(.headline.bold())
                        Spacer()
                        Text("V2").font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.green.opacity(0.2), in: Capsule())
                    }
                    Text("URL gắn trên server — key chưa được Owner cấp sẽ không nhận repo.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .shinnGlass(radius: 14)

                Toggle("Lock repo for this key", isOn: $locked)

                Button {
                    Task { await save() }
                } label: {
                    Text(selectedKey.isEmpty
                         ? "Chọn key bên dưới rồi Save"
                         : "Gán Repo V2 cho key: \(selectedKey)")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedKey.isEmpty)

                if !status.isEmpty {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(status.contains("✅") ? .green : .red)
                }

                Text("Chọn key được phép dùng ShinnCheat Repo V2")
                    .font(.subheadline.bold())
                    .padding(.top, 4)

                ForEach(manager.keys) { row in
                    Button {
                        selectedKey = row.key
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.key).font(.headline)
                                Text((row.label ?? "").isEmpty ? (row.role ?? "member") : (row.label ?? ""))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedKey == row.key {
                                Text("selected")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .shinnGlass()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Repos")
        .task { await manager.listKeys() }
    }

    func save() async {
        status = "Saving…"
        do {
            var request = URLRequest(url: SupabaseConfig.addKeyRepoURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

            let ownerLabel = UserDefaults.standard.string(forKey: "shinn.license.holder")?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard ["ShinnThieuu", "NgVuMinhHieuu"].contains(ownerLabel) else {
                status = "❌ Only Owner can grant Repo V2."
                return
            }

            let trimmedKey = selectedKey.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedKey.isEmpty else {
                status = "❌ Chọn 1 key trong list."
                return
            }

            let body: [String: Any] = [
                "p_key":    trimmedKey,
                "p_name":   Self.fixedRepoName,
                "p_url":    Self.fixedRepoURL,
                "p_locked": locked,
                "p_label":  ownerLabel
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                status = "❌ No response from Supabase."
                return
            }

            let raw = String(decoding: data, as: UTF8.self)
            print("[add_key_repo] status=\(http.statusCode)\nbody=\(raw)")

            guard (200...299).contains(http.statusCode) else {
                status = "❌ HTTP \(http.statusCode): \(raw.prefix(200))"
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let ok = json["ok"] as? Bool, ok == true {
                    status = "✅ Đã gán ShinnCheat Repo V2 cho key \(trimmedKey)"
                    await manager.listKeys()
                } else {
                    let err = (json["error"] as? String) ?? "unknown"
                    status = "❌ Error: \(err)"
                }
            } else {
                status = "❌ Unexpected response"
            }
        } catch {
            status = "❌ Failed: \(error.localizedDescription)"
        }
    }
}

// ===== OwnerPanelView =====
struct OwnerPanelView: View {
    @EnvironmentObject var license: LicenseManager
    @EnvironmentObject var session: Session
    @StateObject private var manager = OwnerKeyManager()
    @State private var copied = false

    private let durations = [1, 3, 7, 30, 90, 365]

    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OWNER PANEL").font(.system(size: 28, weight: .black, design: .rounded))
                        Text("Create keys, set role and duration, delete keys")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Assigned to (tên người dùng)").font(.headline)
                        TextField("NgVuMinhHieuu / ShinnThieuu / tên khác", text: $manager.keyLabel)
                            .padding(12)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Custom key (tuỳ chọn)").font(.headline)
                        TextField("Để trống = server tự tạo key", text: $manager.customKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding(12)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Text("Role").font(.headline)
                        Picker("Role", selection: $manager.selectedRole) {
                            Text("Member").tag("member")
                            Text("Admin").tag("admin")
                        }
                        .pickerStyle(.segmented)

                        Text("Duration").font(.headline)
                        Picker("Duration", selection: $manager.selectedHours) {
                            Text("1 hour (Test)").tag(1)
                            Text("Use days").tag(0)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: manager.selectedHours) { v in
                            if v == 1 { manager.lifetime = false }
                        }

                        if manager.selectedHours == 0 {
                            Toggle("Lifetime / unlimited", isOn: $manager.lifetime)
                            if !manager.lifetime {
                                Picker("Days", selection: $manager.selectedDays) {
                                    ForEach(durations, id: \.self) { d in
                                        Text(d == 365 ? "1 year" : "\(d) days").tag(d)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        } else {
                            Text("Key name: Shinn-Cheat-TestN")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Stepper("How many: \(manager.createCount)", value: $manager.createCount, in: 1...20)

                        if manager.createdKey.isEmpty {
                            Text("No key created yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(manager.prettyCreated)
                                .font(.system(.body, design: .monospaced).weight(.bold))
                                .textSelection(.enabled)
                            Button {
                                UIPasteboard.general.string = manager.prettyCreated
                                copied = true
                            } label: {
                                Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button {
                            Task {
                                copied = false
                                await manager.createKey()
                            }
                        } label: {
                            Group {
                                if manager.isLoading {
                                    ProgressView().tint(Color(.systemBackground))
                                } else {
                                    Text("CREATE KEY")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)
                        .disabled(manager.isLoading)

                        if let error = manager.error {
                            Text(error).font(.caption.bold()).foregroundStyle(.red)
                        }
                    }
                    .padding(16)
                    .shinnGlass()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Key đã tạo (\(manager.keys.count))")
                                .font(.headline)
                            Spacer()
                            Button {
                                Task { await manager.listKeys() }
                            } label: {
                                Label(manager.isLoading ? "…" : "Refresh", systemImage: "arrow.clockwise")
                                    .font(.caption.bold())
                            }
                            .buttonStyle(.plain)
                            .disabled(manager.isLoading)
                        }

                        if manager.keys.isEmpty {
                            Text(manager.isLoading ? "Đang tải…" : "Chưa có key / chưa load được")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(manager.keys) { row in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(row.key)
                                                .font(.system(.footnote, design: .monospaced).weight(.bold))
                                                .textSelection(.enabled)
                                            HStack(spacing: 6) {
                                                let role = (row.role ?? "member").lowercased()
                                                Text(role.capitalized)
                                                    .font(.caption2.bold())
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        (role == "owner" ? Color.red :
                                                         role == "admin" ? Color.blue : Color.green).opacity(0.18),
                                                        in: Capsule()
                                                    )
                                                    .foregroundStyle(
                                                        role == "owner" ? Color.red :
                                                        role == "admin" ? Color.blue : Color.green
                                                    )
                                                if let label = row.label, !label.isEmpty {
                                                    Text(label)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Text(formatKeyExpiry(row.expires_at))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            if let did = row.device_id, !did.isEmpty {
                                                Text("Device: \(did.prefix(12))…")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        Spacer(minLength: 8)
                                        VStack(spacing: 6) {
                                            Button {
                                                UIPasteboard.general.string = row.key
                                            } label: {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.caption.bold())
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.primary.opacity(0.08), in: Circle())
                                            }
                                            .buttonStyle(.plain)

                                            if session.role == .owner,
                                               !["NgVuMinhHieuu", "ShinnThieuu"].contains(row.key) {
                                                Button {
                                                    Task { await manager.deleteKey(row.key) }
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.red)
                                                        .frame(width: 32, height: 32)
                                                        .background(Color.red.opacity(0.12), in: Circle())
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(16)
                    .shinnGlass()

                    if session.role == .owner {
                        Button {
                            Task { await manager.deleteAllKeys() }
                        } label: {
                            Label("Delete all keys", systemImage: "trash")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    if session.role == .owner {
                        NavigationLink(value: Route.patchProjects) {
                            Label("Tạo Patch (3105)", systemImage: "plus.app.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.primary, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: Route.patchBuilder) {
                            Label("Xuất JSON repo", systemImage: "doc.text")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: Route.cleanup) {
                            Label("Dọn dẹp máy", systemImage: "trash.circle.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        session.role = nil
                        license.signOutLicense()
                    } label: {
                        Label("Sign out / Change key", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Owner")
        .navigationBarTitleDisplayMode(.inline)
        .task { await manager.listKeys() }
    }
}

// ===== PatchBuilderView (Enhanced, Owner only, preset FF Max / FF) =====
struct PatchBuilderView: View {
    @EnvironmentObject var session: Session
    @State private var identifier = ""
    @State private var name = ""
    @State private var author = "Shinn Cheat"
    @State private var version = "3105"
    @State private var summary = ""
    @State private var description = "1. Bật Patch trong app\n2. Mở game\n3. Kiểm tra hiệu ứng"
    @State private var category = "Patch"
    @State private var tags = ""
    @State private var download = ""
    @State private var sha256 = ""
    @State private var size = ""
    @State private var icon = "https://raw.githubusercontent.com/ShinnCheatCode/Mhieuu/main/IMG_0621.jpeg"
    @State private var patchPath = ""
    @State private var openURL = ""
    @State private var copied = false
    @State private var saved = false

    @State private var showImporter = false
    @State private var isHashing = false
    @State private var hashError: String?
    @State private var isTestingURL = false
    @State private var urlTestStatus: String?
    @State private var urlTestOK = false
    @State private var localPackageURL: URL?
    @State private var isLocalTesting = false
    @State private var localTestStatus: String?
    @State private var localTestOK = false
    @State private var drafts: [PatchDraft] = PatchDraft.loadAll()
    @State private var showDrafts = false
    @State private var shareURL: URL?
    @State private var selectedPreset: PresetBundle?

    struct PresetBundle: Identifiable, Hashable {
        let id: String
        let label: String
        let bundleID: String
        let openURL: String
        let category: String
        let tags: String

        static let all: [PresetBundle] = [
            PresetBundle(id: "ffmax", label: "Free Fire Max", bundleID: "com.dts.freefiremax", openURL: "freefiremax://", category: "Free Fire Max", tags: "Free Fire Max, Patch"),
            PresetBundle(id: "ffth", label: "Free Fire", bundleID: "com.dts.freefireth", openURL: "freefire://", category: "Free Fire", tags: "Free Fire, Patch")
        ]
    }

    private var isOwner: Bool { session.role == .owner }

    struct PatchDraft: Identifiable, Codable {
        var id = UUID()
        var identifier: String
        var json: String
        var savedAt: Date

        static func loadAll() -> [PatchDraft] {
            guard let data = UserDefaults.standard.data(forKey: "shinn.patch.drafts"),
                  let list = try? JSONDecoder().decode([PatchDraft].self, from: data) else { return [] }
            return list
        }
        static func saveAll(_ list: [PatchDraft]) {
            if let data = try? JSONEncoder().encode(list) {
                UserDefaults.standard.set(data, forKey: "shinn.patch.drafts")
            }
        }
    }

    private var normalizedHash: String {
        sha256.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    private var hashIsValid: Bool {
        normalizedHash.isEmpty || (normalizedHash.count == 64 && normalizedHash.allSatisfy { $0.isHexDigit })
    }

    private var generated: String {
        var object: [String: Any] = [
            "identifier": identifier.trimmingCharacters(in: .whitespacesAndNewlines),
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "download": download.trimmingCharacters(in: .whitespacesAndNewlines)
        ]

        func put(_ key: String, _ value: String) {
            let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !v.isEmpty { object[key] = v }
        }

        put("author", author)
        put("version", version)
        put("summary", summary)
        put("description", description)
        put("category", category)
        put("icon", icon)
        put("patchPath", patchPath)
        put("openURL", openURL)

        let parsedTags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !parsedTags.isEmpty { object["tags"] = parsedTags }

        if let n = Int(size.trimmingCharacters(in: .whitespacesAndNewlines)), n >= 0 {
            object["size"] = n
        }
        if !normalizedHash.isEmpty { object["sha256"] = normalizedHash }

        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private var valid: Bool {
        isOwner &&
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !download.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hashIsValid
    }

    var body: some View {
        Group {
            if !isOwner {
                VStack(spacing: 14) {
                    Image(systemName: "lock.fill").font(.system(size: 44, weight: .semibold)).foregroundStyle(.secondary)
                    Text("Owner only").font(.title3.bold())
                    Text("Only the Owner can create patch entries.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CREATE PATCH").font(.system(size: 28, weight: .black, design: .rounded))
                            Text("Import .3105 từ Files → Test trên máy → Copy JSON up repo. Không cần app 3105 riêng.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }

                        formSection("Preset Bundle ID") {
                            HStack(spacing: 10) {
                                ForEach(PresetBundle.all) { preset in
                                    Button { applyPreset(preset) } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: preset.id == "ffmax" ? "sparkles" : "flame.fill").font(.title3)
                                            Text(preset.label).font(.caption.bold())
                                            Text(preset.bundleID).font(.caption2.monospaced())
                                                .foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.6)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background((selectedPreset == preset ? Color.primary : Color.primary.opacity(0.08)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .foregroundStyle(selectedPreset == preset ? Color(.systemBackground) : Color.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            Button { showImporter = true } label: {
                                Label(isHashing ? "Đang tính…" : "Import .3105", systemImage: "doc.badge.plus")
                                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain).disabled(isHashing)

                            Button { Task { await testDownloadURL() } } label: {
                                Label(isTestingURL ? "Đang test…" : "Test URL", systemImage: "network")
                                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain).disabled(isTestingURL || download.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        HStack(spacing: 10) {
                            Button {
                                Task { await testApplyLocal() }
                            } label: {
                                Label(isLocalTesting ? "Đang apply…" : "Test Apply", systemImage: "bolt.fill")
                                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocalTesting || localPackageURL == nil)

                            Button {
                                Task { await testRestoreLocal() }
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                            .disabled(isLocalTesting || localPackageURL == nil)
                        }

                        if localPackageURL != nil {
                            Text("Đã import: \(localPackageURL!.lastPathComponent)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if let hashError { Text(hashError).font(.caption.bold()).foregroundStyle(.red) }
                        if let urlTestStatus { Text(urlTestStatus).font(.caption.bold()).foregroundStyle(urlTestOK ? .green : .red) }
                        if let localTestStatus {
                            Text(localTestStatus)
                                .font(.caption.bold())
                                .foregroundStyle(localTestOK ? .green : .red)
                        }

                        formSection("Thông tin cơ bản") {
                            field("Identifier", text: $identifier, placeholder: "com.shinn.patchname")
                            field("Name", text: $name, placeholder: "Patch name")
                            field("Author", text: $author, placeholder: "Shinn")
                            field("Version", text: $version, placeholder: "3105")
                            field("Category", text: $category, placeholder: "Free Fire Max / Free Fire / Patch")
                            field("Tags", text: $tags, placeholder: "Free Fire Max, Patch")
                        }

                        formSection("File") {
                            field("Download URL", text: $download, placeholder: "https://raw.githubusercontent.com/...")
                            field("SHA-256", text: $sha256, placeholder: "64 ký tự hex")
                            if !hashIsValid {
                                Text("SHA256 phải là 64 ký tự hex").font(.caption2.bold()).foregroundStyle(.red)
                            }
                            field("Size (bytes)", text: $size, placeholder: "1048576")
                        }

                        formSection("Hiển thị (tuỳ chọn)") {
                            field("Summary", text: $summary, placeholder: "Mô tả ngắn")
                            field("Cách sử dụng / ghi chú", text: $description, placeholder: "Bật patch → mở game → …")
                            field("Icon / ảnh patch (URL)", text: $icon, placeholder: "https://raw.githubusercontent.com/.../icon.png")
                            field("Patch path", text: $patchPath, placeholder: "relative/path")
                            field("Open URL", text: $openURL, placeholder: "freefire:// hoặc freefiremax://")
                        }

                        Button {
                            UIPasteboard.general.string = generated
                            copied = true
                            saved = false
                        } label: {
                            Label(copied ? "Đã copy JSON" : "Copy JSON", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(Color.primary, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .foregroundStyle(Color(.systemBackground))
                        }
                        .buttonStyle(.plain).disabled(!valid)

                        HStack(spacing: 10) {
                            Button { saveDraft() } label: {
                                Label(saved ? "Đã lưu" : "Lưu draft", systemImage: saved ? "checkmark.circle" : "square.and.arrow.down")
                                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain).disabled(!valid)

                            if let shareURL {
                                ShareLink(item: shareURL) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            } else {
                                Button { exportJSON() } label: {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain).disabled(!valid)
                            }
                        }

                        if !drafts.isEmpty {
                            formSection("Drafts (\(drafts.count))") {
                                Button { showDrafts.toggle() } label: {
                                    HStack {
                                        Text(showDrafts ? "Ẩn drafts" : "Xem drafts")
                                        Spacer()
                                        Image(systemName: showDrafts ? "chevron.up" : "chevron.down")
                                    }
                                    .font(.subheadline.bold())
                                }
                                .buttonStyle(.plain)

                                if showDrafts {
                                    ForEach(drafts) { d in
                                        Button { loadDraft(d) } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(d.identifier).font(.footnote.bold())
                                                    Text(d.savedAt.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.caption2).foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Image(systemName: "arrow.down.doc")
                                            }
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    Button(role: .destructive) {
                                        drafts.removeAll()
                                        PatchDraft.saveAll(drafts)
                                    } label: {
                                        Label("Xoá tất cả drafts", systemImage: "trash").font(.caption.bold())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Generated JSON").font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(generated)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(12)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(18)
                }
            }
        }
        .navigationTitle("Create Patch")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImporter) {
            ShinnDocumentPicker(
                allowsMultipleSelection: false,
                onSelection: { result in
                    showImporter = false
                    if case .success(let urls) = result, let url = urls.first {
                        Task { await importPackage(url) }
                    }
                },
                onCancel: { showImporter = false }
            )
            .ignoresSafeArea()
        }
    }

    private func applyPreset(_ preset: PresetBundle) {
        selectedPreset = preset
        identifier = "com.shinn.\(preset.id).patch"
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            name = "\(preset.label) Patch"
        }
        category = preset.category
        tags = preset.tags
        openURL = preset.openURL
        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            summary = "\(preset.label) patch"
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .padding(15)
        .shinnGlass()
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.bold()).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(12)
                .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func importPackage(_ url: URL) async {
        isHashing = true
        hashError = nil
        localTestStatus = nil
        localPackageURL = nil
        defer { isHashing = false }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            // Kiểm tra gói .3105 hợp lệ (nếu codec có sẵn)
            do {
                let summary = try PatchPackageCodec.inspect(data)
                if summary.isPasswordProtected {
                    hashError = "Gói .3105 có mật khẩu — chưa hỗ trợ test local."
                }
            } catch {
                // Không chặn: vẫn cho import để hash + JSON
            }

            size = "\(data.count)"
            let digest = SHA256.hash(data: data)
            sha256 = digest.map { String(format: "%02x", $0) }.joined()

            // Lưu bản local để Test Apply (không cần URL)
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ShinnOwnerImports", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let dest = dir.appendingPathComponent(url.lastPathComponent)
            if FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
            }
            try data.write(to: dest, options: .atomic)
            localPackageURL = dest

            if identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let base = url.deletingPathExtension().lastPathComponent
                identifier = "com.shinn." + base
                    .lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .replacingOccurrences(of: " ", with: "")
            }
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = url.deletingPathExtension().lastPathComponent
            }
            localTestStatus = "Đã import. Bấm Test Apply để thử trên máy."
            localTestOK = true
        } catch {
            hashError = "Không đọc được file: \(error.localizedDescription)"
            localTestOK = false
        }
    }

    private func testApplyLocal() async {
        guard let fileURL = localPackageURL else {
            localTestStatus = "Chưa import file .3105"
            localTestOK = false
            return
        }
        isLocalTesting = true
        localTestStatus = "Đang apply…"
        defer { isLocalTesting = false }
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let summary = try PatchPackageCodec.inspect(data)
            if summary.isPasswordProtected {
                localTestStatus = "Gói có mật khẩu — không apply được."
                localTestOK = false
                return
            }
            let project = try PatchPackageCodec.decode(data, password: nil).project
            _ = try DevicePatchService.apply(project: project)
            localTestStatus = "Apply OK — kiểm tra trong game rồi Restore nếu cần."
            localTestOK = true
            // Mở app đích nếu có openURL
            let raw = openURL.trimmingCharacters(in: .whitespacesAndNewlines)
            if !raw.isEmpty, let u = URL(string: raw) {
                await MainActor.run { UIApplication.shared.open(u) }
            }
        } catch {
            localTestStatus = "Apply lỗi: \(error.localizedDescription)"
            localTestOK = false
        }
    }

    private func testRestoreLocal() async {
        guard let fileURL = localPackageURL else {
            localTestStatus = "Chưa import file .3105"
            localTestOK = false
            return
        }
        isLocalTesting = true
        localTestStatus = "Đang restore…"
        defer { isLocalTesting = false }
        do {
            let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
            let project = try PatchPackageCodec.decode(data, password: nil).project
            guard let receipt = DevicePatchService.latestReceipt(projectID: project.id) else {
                localTestStatus = "Không có receipt để restore."
                localTestOK = false
                return
            }
            try DevicePatchService.restore(receipt: receipt)
            localTestStatus = "Restore OK."
            localTestOK = true
        } catch {
            localTestStatus = "Restore lỗi: \(error.localizedDescription)"
            localTestOK = false
        }
    }

    private func testDownloadURL() async {
        let raw = download.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: raw), url.scheme != nil else {
            urlTestStatus = "URL không hợp lệ"
            urlTestOK = false
            return
        }
        isTestingURL = true
        urlTestStatus = nil
        defer { isTestingURL = false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                urlTestStatus = "Không có phản hồi"
                urlTestOK = false
                return
            }
            if (200..<300).contains(http.statusCode) {
                let len = http.value(forHTTPHeaderField: "Content-Length") ?? "?"
                urlTestStatus = "OK — HTTP \(http.statusCode), size=\(len)"
                urlTestOK = true
            } else {
                urlTestStatus = "HTTP \(http.statusCode)"
                urlTestOK = false
            }
        } catch {
            urlTestStatus = "Lỗi: \(error.localizedDescription)"
            urlTestOK = false
        }
    }

    private func saveDraft() {
        let draft = PatchDraft(identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines), json: generated, savedAt: Date())
        drafts.removeAll { $0.identifier == draft.identifier }
        drafts.insert(draft, at: 0)
        if drafts.count > 20 { drafts = Array(drafts.prefix(20)) }
        PatchDraft.saveAll(drafts)
        saved = true
        copied = false
    }

    private func loadDraft(_ draft: PatchDraft) {
        guard let data = draft.json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        identifier = dict["identifier"] as? String ?? ""
        name = dict["name"] as? String ?? ""
        author = dict["author"] as? String ?? ""
        version = dict["version"] as? String ?? "3105"
        summary = dict["summary"] as? String ?? ""
        description = dict["description"] as? String ?? ""
        category = dict["category"] as? String ?? "Patch"
        download = dict["download"] as? String ?? ""
        sha256 = dict["sha256"] as? String ?? ""
        size = (dict["size"] as? Int).map { "\($0)" } ?? ""
        icon = dict["icon"] as? String ?? ""
        patchPath = dict["patchPath"] as? String ?? ""
        openURL = dict["openURL"] as? String ?? ""
        if let tagList = dict["tags"] as? [String] {
            tags = tagList.joined(separator: ", ")
        }
        showDrafts = false
    }

    private func exportJSON() {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(identifier.isEmpty ? "patch" : identifier).json")
        do {
            try generated.write(to: tmp, atomically: true, encoding: .utf8)
            shareURL = tmp
        } catch {
            hashError = "Không export được: \(error.localizedDescription)"
        }
    }
} // ===== Placeholder views (tối giản để build pass) =====


// ===== Avatar (mọi key đều đổi được) =====
enum ProfileAvatarStore {
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("shinn_profile_avatar.jpg")
    }
    static func load() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL),
              let img = UIImage(data: data) else { return defaultCat() }
        return img
    }
    static func save(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.88) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
    /// Ảnh mèo mặc định từ bundle (nếu có)
    static func defaultCat() -> UIImage? {
        let names: [(String, String)] = [
            ("cat", "jpg"), ("cat", "png"), ("Cat", "jpg"),
            ("IMG_1253", "jpeg"), ("IMG_1253", "jpg"),
            ("avatar", "jpg"), ("avatar", "png"),
            ("AppIcon", "png")
        ]
        for (n, e) in names {
            if let p = Bundle.main.path(forResource: n, ofType: e),
               let img = UIImage(contentsOfFile: p) { return img }
        }
        // fallback: generated soft placeholder
        let size = CGSize(width: 200, height: 200)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            UIColor.secondarySystemFill.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64),
                .paragraphStyle: paragraph,
                .foregroundColor: UIColor.secondaryLabel
            ]
            "🐱".draw(in: CGRect(x: 0, y: 60, width: 200, height: 80), withAttributes: attrs)
        }
    }
}

func formatKeyExpiry(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty else { return "Lifetime / không hết hạn" }
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var date = iso.date(from: raw)
    if date == nil {
        iso.formatOptions = [.withInternetDateTime]
        date = iso.date(from: raw)
    }
    guard let date else { return "Hết hạn: \(raw)" }
    let s = Int(date.timeIntervalSinceNow)
    if s <= 0 { return "Đã hết hạn" }
    let d = s / 86400
    let h = (s % 86400) / 3600
    if d > 0 { return "Còn \(d) ngày \(h) giờ" }
    let m = (s % 3600) / 60
    if h > 0 { return "Còn \(h) giờ \(m) phút" }
    return "Còn \(m) phút"
}

func remainingKeyText(_ exp: Date) -> String {

    let s = Int(exp.timeIntervalSinceNow)
    if s <= 0 { return "Key đã hết hạn" }
    let d = s / 86400
    let h = (s % 86400) / 3600
    let m = (s % 3600) / 60
    if d > 0 { return "Còn \(d) ngày \(h) giờ" }
    if h > 0 { return "Còn \(h) giờ \(m) phút" }
    return "Còn \(m) phút"
}


struct HomeBrandCard: View {
    let avatar: UIImage?
    let onTapAvatar: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            Button(action: onTapAvatar) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let avatar {
                            Image(uiImage: avatar).resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable().scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(10)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
                    Image(systemName: "camera.fill")
                        .font(.system(size: 9, weight: .bold))
                        .padding(5)
                        .background(Color.primary, in: Circle())
                        .foregroundStyle(Color(.systemBackground))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.fill").font(.caption)
                    Text("APP").font(.caption.bold()).foregroundStyle(.secondary)
                }
                Text("SHINN CHEAT")
                    .font(.system(size: 22, weight: .black, design: .rounded))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .shinnGlass(radius: 20)
    }
}

struct HomeAccountCard: View {
    @EnvironmentObject var session: Session
    @EnvironmentObject var license: LicenseManager
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(session.role?.badgeColor ?? .green)
                VStack(alignment: .leading, spacing: 2) {
                    Text(license.holderName.isEmpty ? (session.role?.title ?? "Member") : license.holderName)
                        .font(.headline.bold())
                        .foregroundStyle(session.role?.badgeColor ?? .primary)
                    Text(session.role?.title ?? "Member")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(session.role?.badgeColor ?? .green)
            }
            HStack {
                Label("Expires", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if session.role == .owner {
                    Text("Lifetime").font(.subheadline.bold()).foregroundStyle(.red)
                } else if let exp = license.expiresAt {
                    Text(shortRemain(exp))
                        .font(.subheadline.bold())
                        .foregroundStyle(exp < Date() ? .red : .orange)
                } else {
                    Text("—").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Button {
                session.role = nil
                license.signOutLicense()
            } label: {
                Label("Sign out / Change key", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .shinnGlass(radius: 20)
    }
    private func shortRemain(_ exp: Date) -> String {
        let s = Int(exp.timeIntervalSinceNow)
        if s <= 0 { return "Expired" }
        let d = s / 86400
        if d > 0 { return "\(d)d left" }
        let h = s / 3600
        if h > 0 { return "\(h)h left" }
        return "\(max(1, s / 60))m left"
    }
}

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var session: Session
    @EnvironmentObject var license: LicenseManager
    let open: (Route) -> Void
    var selectTab: (Int) -> Void = { _ in }
    @State private var showFirstActivateNotice = false
    @State private var avatar: UIImage? = ProfileAvatarStore.load()
    @State private var photoItem: PhotosPickerItem?
    @State private var showAvatarOptions = false
    @State private var showPhotoPicker = false

    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "crown.fill").font(.system(size: 26))
                        Text("SHINN CHEAT")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                        Spacer()
                        Link(destination: AppInfo.telegramURL) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 40, height: 40)
                                .background(Color.primary.opacity(0.1), in: Circle())
                        }
                    }

                    HomeBrandCard(avatar: avatar) { showAvatarOptions = true }

                    HomeAccountCard()

                    if session.role == .owner || session.role == .admin {
                        NavigationLink { OwnerPanelView() } label: {
                            HStack {
                                IconBox(systemName: "crown.fill", size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Owner Panel").font(.headline.bold())
                                    Text("Create member keys").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(12).shinnGlass()
                        }
                        .buttonStyle(.plain)
                    }

                    if session.role == .owner {
                        NavigationLink { RepositoryManagerView() } label: {
                            HStack {
                                IconBox(systemName: "folder.badge.gearshape", size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Repository Manager").font(.headline.bold())
                                    Text("Chỉ Owner thêm repo · gán key").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                            .padding(12).shinnGlass()
                        }
                        .buttonStyle(.plain)
                    }

                    // Repositories
                    HStack {
                        Label("Repositories", systemImage: "externaldrive.fill")
                            .font(.headline.bold())
                        Spacer()
                        Text(session.role?.title ?? "Member")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background((session.role?.badgeColor ?? .green).opacity(0.18), in: Capsule())
                            .foregroundStyle(session.role?.badgeColor ?? .green)
                    }
                    .padding(.top, 4)

                    Button {
                        open(.packages(nil))
                    } label: {
                        HStack {
                            IconBox(systemName: "folder.fill", size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Repo ShinnCheat").font(.headline.bold())
                                Text("Open packages · \(store.packages.count) patch")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(12).shinnGlass()
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        QuickAction(title: "Patch", subtitle: "Tạo patch 3105", icon: "plus.app.fill") { selectTab(2) }
                        QuickAction(title: "Dọn dẹp", subtitle: "Giải phóng bộ nhớ", icon: "trash.circle") { selectTab(3) }
                    }

                    HStack(spacing: 12) {
                        QuickAction(title: "Settings", subtitle: "Customize the app", icon: "gearshape.fill") { open(.settings) }
                        QuickAction(title: "About", subtitle: "App information", icon: "info.circle.fill") { open(.about) }
                    }
                }
                .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 28)
            }
            .refreshable { await store.refresh() }

            if showFirstActivateNotice {
                VStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill").font(.title2)
                        Text("Thuê key Admin ib Owner: ShinnThieuu")
                            .font(.subheadline.bold())
                            .multilineTextAlignment(.center)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            maybeShowFirstActivateNotice()
            if avatar == nil { avatar = ProfileAvatarStore.load() }
        }
        .confirmationDialog("Ảnh đại diện", isPresented: $showAvatarOptions, titleVisibility: .visible) {
            Button("Chọn từ thư viện") {
                showPhotoPicker = true
            }
            Button("Khôi phục mặc định", role: .destructive) {
                ProfileAvatarStore.clear()
                avatar = ProfileAvatarStore.defaultCat()
            }
            Button("Huỷ", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    ProfileAvatarStore.save(img)
                    await MainActor.run { avatar = img }
                }
            }
        }
    }

    private func shortRemain(_ exp: Date) -> String {
        let s = Int(exp.timeIntervalSinceNow)
        if s <= 0 { return "Expired" }
        let d = s / 86400
        if d > 0 { return "\(d)d left" }
        let h = s / 3600
        if h > 0 { return "\(h)h left" }
        return "\(max(1, s / 60))m left"
    }

    private func maybeShowFirstActivateNotice() {
        let key = license.savedLicenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        let flag = "shinn.notice.first.\(key).\(license.deviceID)"
        if UserDefaults.standard.bool(forKey: flag) { return }
        UserDefaults.standard.set(true, forKey: flag)
        withAnimation { showFirstActivateNotice = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
            withAnimation { showFirstActivateNotice = false }
        }
    }
}

struct QuickAction: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.headline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18).contentShape(Rectangle()).shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

enum HeroBanner {
    static let image: UIImage? = {
        let names: [(String, String)] = [
            ("IMG_1253", "jpeg"), ("IMG_1253", "jpg"), ("IMG_1253", "JPG"), ("IMG_1253", "JPEG"), ("HeroBanner", "jpg")
        ]
        for (name, ext) in names {
            if let path = Bundle.main.path(forResource: name, ofType: ext),
               let img = UIImage(contentsOfFile: path) { return img }
        }
        return nil
    }()
}

struct PackagesView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @State private var searchText = ""
    @State private var category: String?
    @State private var expanded: Set<String> = Set(PatchFolder.allCases.map(\.rawValue))

    init(initialCategory: String?) {
        _category = State(initialValue: initialCategory)
    }

    private var filtered: [RepoPackage] {
        var result = store.packages
        if let category { result = result.filter { $0.category == category } }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(q) ||
                ($0.summary ?? "").localizedCaseInsensitiveContains(q) ||
                ($0.category ?? "").localizedCaseInsensitiveContains(q)
            }
        }
        return result
    }

    private var grouped: [PackageFolderGroup] {
        var map: [PatchFolder: [RepoPackage]] = [:]
        for p in filtered {
            let f = PatchFolder.folder(for: p)
            map[f, default: []].append(p)
        }
        return PatchFolder.allCases.compactMap { f in
            guard let list = map[f], !list.isEmpty else { return nil }
            return PackageFolderGroup(folder: f, items: list)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: []) {
                if store.packages.isEmpty {
                    ProgressView().padding(.top, 40)
                } else if filtered.isEmpty {
                    Text("No results").font(.headline).padding(.top, 40)
                } else {
                    ForEach(grouped, id: \.folder.id) { section in
                        PackageFolderSection(
                            folder: section.folder,
                            items: section.items,
                            isExpanded: expanded.contains(section.folder.id),
                            onToggle: {
                                if expanded.contains(section.folder.id) { expanded.remove(section.folder.id) }
                                else { expanded.insert(section.folder.id) }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
        }
        .background(BackgroundView())
        .navigationTitle("Repo ShinnCheat")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Tìm patch")
        .refreshable { await store.refresh() }
    }
}



struct PackageFolderGroup: Identifiable {
    var id: String { folder.id }
    let folder: PatchFolder
    let items: [RepoPackage]
}

struct PackageFolderSection: View {
    let folder: PatchFolder
    let items: [RepoPackage]
    let isExpanded: Bool
    let onToggle: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: folder.icon)
                    Text(folder.title).font(.headline.bold())
                    Text("(\(items.count))").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            if isExpanded {
                ForEach(items) { package in
                    NavigationLink(value: Route.detail(package.id)) {
                        PackageRow(pkg: package)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct PackageRow: View {
    let pkg: RepoPackage

    @ViewBuilder
    private var packageThumb: some View {
        let s = (pkg.icon ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: s), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    IconBox(systemName: categoryIcon(pkg.category ?? ""), size: 50)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            IconBox(systemName: categoryIcon(pkg.category ?? ""), size: 50)
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text).font(.caption2.weight(.medium))
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Color.primary.opacity(0.08), in: Capsule())
    }
    var body: some View {
        HStack(spacing: 14) {
            packageThumb
            VStack(alignment: .leading, spacing: 4) {
                Text(pkg.name).font(.system(size: 16, weight: .semibold, design: .rounded)).lineLimit(1)
                Text(pkg.summary ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    if let version = pkg.version { tag("v\(version)") }
                    if let size = pkg.size { tag(formatBytes(size)) }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote.bold()).foregroundStyle(.secondary)
        }
        .padding(12).contentShape(Rectangle()).shinnGlass(radius: 20)
    }
}


struct FlowTags: View {
    let tags: [String]
    var body: some View {
        // Simple wrap via flexible HStacks
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(stride(from: 0, to: tags.count, by: 3)), id: \.self) { start in
                HStack(spacing: 6) {
                    ForEach(tags[start..<min(start + 3, tags.count)], id: \.self) { t in
                        Text(t)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.08), in: Capsule())
                    }
                }
            }
        }
    }
}

struct PackageDetailView: View {
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var abuse: AbuseGuard
    let packageID: String
    @State private var patchOn = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var pkg: RepoPackage? {
        store.packages.first { $0.id == packageID }
    }

    var body: some View {
        ZStack {
            BackgroundView()
            if let pkg { content(pkg) } else { ProgressView() }
        }
        .navigationTitle(pkg?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(alertMessage) }
    }

    private func content(_ pkg: RepoPackage) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Ảnh patch
                patchHeroImage(pkg)

                Text(pkg.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                if let summary = pkg.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 0) {
                    infoRow("Version", pkg.version ?? "-")
                    infoRow("Author", pkg.author ?? "-")
                    infoRow("Category", pkg.category ?? "-")
                    infoRow("Size", pkg.size.map { formatBytes($0) } ?? "-")
                }
                .padding(.horizontal, 16).shinnGlass()

                // Cách sử dụng / ghi chú
                if let desc = pkg.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Cách sử dụng", systemImage: "text.book.closed.fill")
                            .font(.headline)
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .shinnGlass()
                }

                if let tags = pkg.tags, !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags").font(.headline)
                        FlowTags(tags: tags)
                    }
                    .padding(16)
                    .shinnGlass()
                }

                downloadSection(pkg)
            }
            .padding(.horizontal, 18).padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func patchHeroImage(_ pkg: RepoPackage) -> some View {
        let urlString = (pkg.icon ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: urlString), url.scheme != nil {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholderIcon(pkg)
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 160)
                @unknown default:
                    placeholderIcon(pkg)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        } else {
            placeholderIcon(pkg)
                .frame(height: 120)
        }
    }

    private func placeholderIcon(_ pkg: RepoPackage) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            Image(systemName: categoryIcon(pkg.category ?? ""))
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline).padding(.vertical, 13)
    }

    private func mainButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity).padding(.vertical, 15)
                .background(Color.primary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func downloadSection(_ pkg: RepoPackage) -> some View {
        VStack(spacing: 12) {
            switch store.state(for: pkg) {
            case .idle:
                mainButton("Download", icon: "arrow.down.circle.fill") {
                    Task { await store.download(pkg) }
                }
            case .downloading:
                HStack(spacing: 10) { ProgressView(); Text("Downloading…") }
                    .frame(maxWidth: .infinity).padding(.vertical, 15).shinnGlass(radius: 16)
            case .done:
                Toggle(isOn: Binding(
                    get: {
                        if case .applied = store.patchState(for: pkg) { return true }
                        return patchOn
                    },
                    set: { on in
                        patchOn = on
                        abuse.patchToggled()
                        Task {
                            if on {
                                await store.apply(pkg)
                                switch store.patchState(for: pkg) {
                                case .applied:
                                    alertTitle = "Thành công"
                                    alertMessage = store.lastApplyMessage ?? "Đã bật patch."
                                case .failed(let m):
                                    patchOn = false
                                    alertTitle = "Lỗi"
                                    alertMessage = m
                                default:
                                    alertTitle = "Thành công"
                                    alertMessage = store.lastApplyMessage ?? "Đã bật patch."
                                }
                            } else {
                                await store.restore(pkg)
                                alertTitle = "Đã gỡ"; alertMessage = store.lastApplyMessage ?? "Patch restored."
                            }
                            showAlert = true
                        }
                    }
                )) {
                    Text("Patch").font(.headline)
                }
                .padding(.horizontal, 16).padding(.vertical, 12).shinnGlass(radius: 16)
            case .failed(let error):
                Text(String(describing: error)).font(.subheadline).foregroundStyle(.red)
                mainButton("Retry", icon: "arrow.clockwise") {
                    Task { await store.download(pkg) }
                }
            }
        }
    }
}


struct ShinnAboutView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Giới thiệu").font(.title.bold())
                Text("Shinn Cheat — quản lý & áp dụng patch qua Repo ShinnCheat.")
                    .foregroundStyle(.secondary)
                Text("Version \(AppInfo.version)").font(.footnote).foregroundStyle(.secondary)
                Text("App by Shinn · Owner: NgVuMinhHieuu / ShinnThieuu")
                    .font(.footnote)

                if session.role == .owner {
                    NavigationLink(value: Route.patchProjects) {
                        Label("Tạo Patch (3105)", systemImage: "plus.app.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }

                Link(destination: AppInfo.telegramURL) {
                    Label("Support · @ShinnThieuu", systemImage: "paperplane.fill")
                }
                .padding(.top, 6)
            }
            .padding(18)
        }
        .background(BackgroundView())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// ===== Dọn dẹp máy =====

/// Hub tạo patch — không crash (tránh mở PatchProjectsView thiếu EnvironmentObject)
struct CreatePatchSafeHubView: View {
    @EnvironmentObject var session: Session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tạo Patch").font(.title.bold())
                Text("Dùng tab Tệp hoặc tab Patch phía dưới màn hình (giao diện 3105 gốc).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Cách tạo", systemImage: "1.circle.fill")
                        .font(.headline)
                    Text("• Tab Tệp → container game → Documents → giữ file → Tạo patch\n• Hoặc tab Patch → tạo / sửa dự án patch")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .shinnGlass()

                if session.role == .owner {
                    NavigationLink(value: Route.patchBuilder) {
                        Label("Xuất JSON / Import .3105 (Owner)", systemImage: "doc.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: Route.cleanup) {
                    Label("Dọn dẹp máy", systemImage: "trash.circle")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .background(BackgroundView())
        .navigationTitle("Tạo Patch")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PhoneCleanupView: View {
    @State private var isWorking = false
    @State private var log: [String] = []
    @State private var lastFreed: Int64 = 0

    private var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    private var caches: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }
    private var tmp: URL {
        FileManager.default.temporaryDirectory
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Dọn dẹp").font(.title.bold())
                Text("Xoá cache tải patch, file import tạm, URLCache — không xoá key hay cài đặt.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if lastFreed > 0 {
                    Text("Đã giải phóng ~\(ByteCountFormatter.string(fromByteCount: lastFreed, countStyle: .file))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }

                Button {
                    Task { await runCleanup() }
                } label: {
                    Group {
                        if isWorking {
                            ProgressView().tint(Color(.systemBackground))
                        } else {
                            Label("Dọn dẹp ngay", systemImage: "trash.circle.fill")
                                .font(.headline.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(isWorking)

                if !log.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chi tiết").font(.headline)
                        ForEach(log, id: \.self) { line in
                            Text("• \(line)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(14)
                    .shinnGlass(radius: 14)
                }
            }
            .padding(18)
        }
        .background(BackgroundView())
        .navigationTitle("Dọn dẹp")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func runCleanup() async {
        isWorking = true
        log = []
        lastFreed = 0
        defer { isWorking = false }

        var freed: Int64 = 0
        let fm = FileManager.default

        func clearDir(_ url: URL, label: String, keepRoot: Bool = true) {
            guard fm.fileExists(atPath: url.path) else {
                log.append("\(label): không có")
                return
            }
            var total: Int64 = 0
            if let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                for item in items {
                    total += (try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
                    try? fm.removeItem(at: item)
                }
            }
            freed += total
            log.append("\(label): \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))")
        }

        // Patch downloads (RepoStore)
        clearDir(documents.appendingPathComponent("ShinnDownloads", isDirectory: true), label: "ShinnDownloads")
        clearDir(documents.appendingPathComponent("Downloads", isDirectory: true), label: "Downloads")
        clearDir(documents.appendingPathComponent("ShinnOwnerImports", isDirectory: true), label: "Owner imports")
        clearDir(caches, label: "Caches")
        // Temp files of app
        if let items = try? fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: [.fileSizeKey]) {
            var total: Int64 = 0
            for item in items {
                total += (try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
                try? fm.removeItem(at: item)
            }
            freed += total
            log.append("tmp: \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))")
        }

        URLCache.shared.removeAllCachedResponses()
        log.append("URLCache: đã xoá")

        lastFreed = freed
        log.append("Xong.")
    }
}


func iconForBundleID(_ bundleID: String) -> UIImage? {
    nil
}

struct ShinnDocumentPicker: UIViewControllerRepresentable {
    var allowsMultipleSelection = false
    var onSelection: (Result<[URL], Error>) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data, .item], asCopy: true)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ShinnDocumentPicker
        init(_ parent: ShinnDocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onSelection(.success(urls))
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}
