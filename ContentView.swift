import SwiftUI
import UIKit
import LocalAuthentication

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
            RadialGradient(
                colors: [Color.primary.opacity(0.09), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 500
            )
            RadialGradient(
                colors: [Color.primary.opacity(0.05), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 450
            )
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


// ===== AppShimn source: Localization.swift =====
import SwiftUI

enum ShinnLanguage: String, CaseIterable, Identifiable {
    case vi
    case en

    var id: String {
        rawValue
    }

    var title: String {
        self == .vi ? "Tiếng Việt" : "English"
    }
}

enum ShinnTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String {
        rawValue
    }

    var colorScheme: ColorScheme? {

        switch self {

        case .system:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }

    var titleKey: K {

        switch self {

        case .system:
            return .themeSystem

        case .light:
            return .themeLight

        case .dark:
            return .themeDark
        }
    }
}

final class AppSettings: ObservableObject {

    @Published var theme: ShinnTheme {
        didSet {
            UserDefaults.standard.set(
                theme.rawValue,
                forKey: "theme"
            )
        }
    }

    @Published var language: ShinnLanguage {
        didSet {
            UserDefaults.standard.set(
                language.rawValue,
                forKey: "language"
            )
        }
    }

    @Published var autoRefresh: Bool {
        didSet {
            UserDefaults.standard.set(
                autoRefresh,
                forKey: "autoRefresh"
            )
        }
    }

    init() {

        let defaults =
            UserDefaults.standard

        theme =
            ShinnTheme(
                rawValue:
                    defaults.string(
                        forKey: "theme"
                    ) ?? ""
            )
            ?? .system

        if let raw =
            defaults.string(
                forKey: "language"
            ),
           let language =
            ShinnLanguage(rawValue: raw) {

            self.language = language

        } else {

            let first =
                Locale.preferredLanguages.first
                ?? "en"

            self.language = .en
        }

        autoRefresh =
            defaults.object(
                forKey: "autoRefresh"
            ) as? Bool ?? true
    }

    func t(_ key: K) -> String {

        let pair = key.text

        return pair.en
    }

    func countText(_ n: Int) -> String {

        return n == 1 ? "1 package" : "\(n) packages"
    }
}

enum K {

    case heroFree
    case heroNote
    case categoriesTitle
    case allPackages
    case loadingText
    case loadFailed
    case retry

    case settingsTitle
    case settingsSub
    case aboutTitle
    case aboutSub

    case packagesTitle
    case packageCenter
    case packageCenterSub
    case searchPrompt
    case allLabel
    case notFound
    case notFoundDesc

    case versionLabel
    case authorLabel
    case categoryLabel
    case sizeLabel
    case descriptionLabel

    case downloadAction
    case downloading
    case downloaded
    case redownload
    case shareAction
    case savedHint
    case sha256OK

    case errHash
    case errHTTP
    case errURL

    case appearance
    case themeLabel
    case themeSystem
    case themeLight
    case themeDark
    case languageLabel

    case autoUpdate
    case repoSection
    case defaultSource
    case defaultBadge
    case repoLocked
    case refreshRepo
    case infoTitle

    case aboutDesc
    case madeBy
    case contactTitle
    case donateTitle
    case copy
    case copied

    case featRemote
    case featSHA

    case termsTitle
    case termsBody

    case supportTitle
    case telegramSub
    case reportTitle
    case reportSub
}

extension K {

    var text: (
        vi: String,
        en: String
    ) {

        switch self {

        case .heroFree:
            return (
                "LÀ APP VÀ REPO HOÀN TOÀN FREE",
                "A COMPLETELY FREE APP AND REPO"
            )

        case .heroNote:
            return (
                "Không bán key • Không khóa thiết bị",
                "No keys sold • No device lock"
            )

        case .categoriesTitle:
            return (
                "DANH MỤC GÓI",
                "PACKAGE CATEGORIES"
            )

        case .allPackages:
            return (
                "Tất cả gói",
                "All packages"
            )

        case .loadingText:
            return (
                "Đang tải repo…",
                "Loading repo…"
            )

        case .loadFailed:
            return (
                "Không tải được repo. Kiểm tra mạng và thử lại.",
                "Couldn't load the repo. Check your connection and try again."
            )

        case .retry:
            return (
                "Thử lại",
                "Retry"
            )

        case .settingsTitle:
            return (
                "Cài Đặt",
                "Settings"
            )

        case .settingsSub:
            return (
                "Tùy chỉnh app",
                "Customize the app"
            )

        case .aboutTitle:
            return (
                "Giới Thiệu",
                "About"
            )

        case .aboutSub:
            return (
                "Thông tin app",
                "App information"
            )

        case .packagesTitle:
            return (
                "Packages",
                "Packages"
            )

        case .packageCenter:
            return (
                "Package Center",
                "Package Center"
            )

        case .packageCenterSub:
            return (
                "Các package được cung cấp bởi Shinn Cheat",
                "Packages provided by Shinn Cheat"
            )

        case .searchPrompt:
            return (
                "Tìm package",
                "Search packages"
            )

        case .allLabel:
            return (
                "Tất cả",
                "All"
            )

        case .notFound:
            return (
                "Không tìm thấy",
                "No results"
            )

        case .notFoundDesc:
            return (
                "Không có package phù hợp với từ khóa.",
                "No packages match your search."
            )

        case .versionLabel:
            return (
                "Phiên bản",
                "Version"
            )

        case .authorLabel:
            return (
                "Tác giả",
                "Author"
            )

        case .categoryLabel:
            return (
                "Danh mục",
                "Category"
            )

        case .sizeLabel:
            return (
                "Dung lượng",
                "Size"
            )

        case .descriptionLabel:
            return (
                "Mô tả",
                "Description"
            )

        case .downloadAction:
            return (
                "Tải xuống",
                "Download"
            )

        case .downloading:
            return (
                "Đang tải…",
                "Downloading…"
            )

        case .downloaded:
            return (
                "Đã tải xong",
                "Downloaded"
            )

        case .redownload:
            return (
                "Tải lại",
                "Download again"
            )

        case .shareAction:
            return (
                "Chia sẻ / Mở bằng app khác",
                "Share / Open in another app"
            )

        case .savedHint:
            return (
                "File được lưu trong Tệp › Trên iPhone › Shinn Cheat.",
                "Saved in Files › On My iPhone › Shinn Cheat."
            )

        case .sha256OK:
            return (
                "Đã xác minh SHA256",
                "SHA256 verified"
            )

        case .errHash:
            return (
                "File tải về không khớp SHA256 nên đã bị hủy.",
                "The downloaded file failed the SHA256 check and was discarded."
            )

        case .errHTTP:
            return (
                "Lỗi máy chủ",
                "Server error"
            )

        case .errURL:
            return (
                "Link tải không hợp lệ",
                "Invalid download link"
            )

        case .appearance:
            return (
                "Giao diện",
                "Appearance"
            )

        case .themeLabel:
            return (
                "Chủ đề",
                "Theme"
            )

        case .themeSystem:
            return (
                "Theo hệ thống",
                "System"
            )

        case .themeLight:
            return (
                "Sáng",
                "Light"
            )

        case .themeDark:
            return (
                "Tối",
                "Dark"
            )

        case .languageLabel:
            return (
                "Ngôn ngữ",
                "Language"
            )

        case .autoUpdate:
            return (
                "Tự động cập nhật repo",
                "Auto-refresh repo"
            )

        case .repoSection:
            return (
                "Nguồn repo",
                "Repository"
            )

        case .defaultSource:
            return (
                "Nguồn mặc định",
                "Default source"
            )

        case .defaultBadge:
            return (
                "MẶC ĐỊNH",
                "DEFAULT"
            )

        case .repoLocked:
            return (
                "Nguồn mặc định của app, không thể xóa hoặc thay thế.",
                "The app's built-in source. It can't be removed or replaced."
            )

        case .refreshRepo:
            return (
                "Làm mới repo",
                "Refresh repo"
            )

        case .infoTitle:
            return (
                "Thông tin",
                "Info"
            )

        case .aboutDesc:
            return (
                "Shinn Cheat là ứng dụng quản lý và phân phối các package được cấu hình thông qua repository của Shinn.",
                "Shinn Cheat is an app for managing and distributing packages configured through Shinn's repository."
            )

        case .madeBy:
            return (
                "App được make bởi Shinn",
                "App made by Shinn"
            )

        case .contactTitle:
            return (
                "Liên hệ",
                "Contact"
            )

        case .donateTitle:
            return (
                "Donate",
                "Donate"
            )

        case .copy:
            return (
                "Copy",
                "Copy"
            )

        case .copied:
            return (
                "Copied",
                "Copied"
            )

        case .featRemote:
            return (
                "Cập nhật dữ liệu từ repository",
                "Sync data from the repository"
            )

        case .featSHA:
            return (
                "Kiểm tra tính toàn vẹn của file",
                "Verify file integrity"
            )

        case .termsTitle:
            return (
                "Điều khoản sử dụng",
                "Terms of use"
            )

        case .termsBody:

            return (
                """
                Khi cài đặt và sử dụng ứng dụng này, bạn đã đồng ý với chính sách của chúng tôi.

                • Ứng dụng và repo hoàn toàn MIỄN PHÍ.
                • Không sử dụng ứng dụng vào bất kỳ hành vi nào trái với pháp luật.
                • Mọi hành vi phá hoại, cố ý vi phạm sẽ bị cảnh báo.
                """,

                """
                By installing and using this app, you agree to our policy.

                • The app and its repo are completely FREE.
                • Do not use the app for anything that violates the law.
                • Sabotage or deliberate violations will result in a warning.
                """
            )

        case .supportTitle:
            return (
                "Hỗ trợ",
                "Support"
            )

        case .telegramSub:
            return (
                "Liên hệ nhóm hỗ trợ",
                "Contact the support team"
            )

        case .reportTitle:
            return (
                "Báo lỗi",
                "Report a bug"
            )

        case .reportSub:
            return (
                "Thông báo lỗi hoặc sự cố",
                "Report a bug or issue"
            )
        }
    }
}

import Foundation

extension AppInfo {

    static let telegramHandle =
        "@ShinnThieuu"

    static let telegramURL =
        URL(
            string: "https://t.me/ShinnThieuu"
        )!

    static let bankName =
        "MB Bank"

    static let bankAccount =
        "104877777"

    static let defaultRepoName =
        "Shinn Cheat Share"

    static let defaultRepoURL =
        URL(
            string:
                "https://raw.githubusercontent.com/ShinnCheatCode/Mhieuu/main/shinn.json"
        )!

    static var version: String {
        Bundle.main.object(
            forInfoDictionaryKey:
                "CFBundleShortVersionString"
        ) as? String ?? "2.1"
    }
}

struct RepoManifest: Codable {

    let name: String?
    let description: String?
    let icon: String?

    let packages: [
        RepoPackage
    ]
}

struct RepoPackage:
    Codable,
    Identifiable,
    Hashable {

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

    var id: String {
        identifier
    }
}

struct CategoryInfo:
    Identifiable {

    let name: String
    let count: Int

    var id: String {
        name
    }
}

enum Route: Hashable {

    case packages(String?)
    case detail(String)
    case settings
    case about
    case support
    case repositoryManager
}

func formatBytes(
    _ value: Int
) -> String {

    ByteCountFormatter.string(
        fromByteCount: Int64(value),
        countStyle: .file
    )
}

// ===== AppShimn source: RepoStore.swift =====
import Foundation
import CryptoKit
import UIKit

enum DLError: Error {
    case badURL
    case http(Int)
    case hashMismatch
    case other(String)
}

enum PatchError: Error {
    case invalidPath
    case sourceNotFound
    case backupFailed
    case applyFailed
    case restoreFailed
    case other(String)
}

enum DownloadState {
    case idle
    case downloading
    case done(URL)
    case failed(DLError)
}

enum LoadState {
    case idle
    case loading
    case loaded
    case failed
}

enum PatchState {
    case idle
    case applying
    case applied
    case restoring
    case restored
    case failed(String)
}

func sha256Hex(of url: URL) throws -> String {
    let data = try Data(
        contentsOf: url,
        options: .mappedIfSafe
    )

    return SHA256.hash(data: data)
        .map { String(format: "%02x", $0) }
        .joined()
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

    // MARK: - Locations

    private var documentsURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    private var cacheURL: URL {
        let dir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]

        return dir.appendingPathComponent("repo_default.json")
    }

    private var backupDirectory: URL {
        documentsURL.appendingPathComponent(
            ".ShinnBackups",
            isDirectory: true
        )
    }

    // MARK: - Package data

    var packages: [RepoPackage] {
        manifest?.packages ?? []
    }

    var categories: [CategoryInfo] {
        var order: [String] = []
        var counts: [String: Int] = [:]

        for p in packages {
            let category = p.category ?? "Other"

            if counts[category] == nil {
                order.append(category)
            }

            counts[category, default: 0] += 1
        }

        return order.map {
            CategoryInfo(
                name: $0,
                count: counts[$0] ?? 0
            )
        }
    }

    // MARK: - Bootstrap

    func bootstrap(autoRefresh: Bool) async {
        if didBootstrap {
            return
        }

        didBootstrap = true

        loadCache()

        if manifest == nil || autoRefresh {
            await refresh()
        }
    }

    private func loadCache() {
        guard
            let data = try? Data(contentsOf: cacheURL),
            let decoded = try? JSONDecoder().decode(
                RepoManifest.self,
                from: data
            )
        else {
            return
        }

        manifest = decoded
        loadState = .loaded
    }

    // MARK: - Remote JSON

    func refresh() async {
        if UserDefaults.standard.bool(forKey: "shinn.license.repoLocked") {
            manifest = nil
            loadState = .failed
            return
        }
        loadState = .loading

        do {
            var request = URLRequest(
                url: RepoStore.activeRepoURL(),
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 20
            )

            request.setValue(
                "no-cache",
                forHTTPHeaderField: "Cache-Control"
            )

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {
                throw DLError.http(http.statusCode)
            }

            let decoded = try JSONDecoder().decode(
                RepoManifest.self,
                from: data
            )

            manifest = decoded

            try? data.write(
                to: cacheURL,
                options: .atomic
            )

            loadState = .loaded

        } catch {
            if manifest == nil {
                loadState = .failed
            } else {
                loadState = .loaded
            }
        }
    }

    // MARK: - Download

    private func destination(for pkg: RepoPackage) -> URL? {
        guard
            let url = URL(string: pkg.download)
        else {
            return nil
        }

        let directory = documentsURL

        return directory.appendingPathComponent(
            url.lastPathComponent
        )
    }

    func existingFile(for pkg: RepoPackage) -> URL? {
        guard let destination = destination(for: pkg) else {
            return nil
        }

        guard FileManager.default.fileExists(
            atPath: destination.path
        ) else {
            return nil
        }

        return destination
    }

    func state(for pkg: RepoPackage) -> DownloadState {
        if let state = downloads[pkg.id] {
            return state
        }

        if let file = existingFile(for: pkg) {
            return .done(file)
        }

        return .idle
    }

    func download(_ pkg: RepoPackage) async {

        guard
            let url = URL(string: pkg.download),
            let destination = destination(for: pkg)
        else {
            downloads[pkg.id] = .failed(.badURL)
            return
        }

        downloads[pkg.id] = .downloading

        do {
            let (temporaryURL, response) =
                try await URLSession.shared.download(
                    from: url
                )

            if let http = response as? HTTPURLResponse,
               !(200..<300).contains(http.statusCode) {

                throw DLError.http(http.statusCode)
            }

            if let expected = pkg.sha256?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               !expected.isEmpty {

                let actual = try await Task.detached(
                    priority: .utility
                ) {
                    try sha256Hex(of: temporaryURL)
                }.value

                if actual.lowercased() != expected {
                    try? FileManager.default.removeItem(
                        at: temporaryURL
                    )

                    throw DLError.hashMismatch
                }
            }

            // A repo package is a real Make-iPA .3105 package.
            // Validate its envelope before exposing it as downloadable.
            do {
                let packageData = try Data(contentsOf: temporaryURL, options: .mappedIfSafe)
                _ = try PatchPackageCodec.inspect(packageData)
            } catch let error as PatchPackageError {
                try? FileManager.default.removeItem(at: temporaryURL)
                throw DLError.other(
                    "Gói .3105 không hợp lệ: \(error.localizedDescription)"
                )
            } catch {
                try? FileManager.default.removeItem(at: temporaryURL)
                throw DLError.other(
                    "Gói .3105 không hợp lệ: \(error.localizedDescription)"
                )
            }

            if FileManager.default.fileExists(
                atPath: destination.path
            ) {
                try FileManager.default.removeItem(
                    at: destination
                )
            }

            try FileManager.default.moveItem(
                at: temporaryURL,
                to: destination
            )

            downloads[pkg.id] = .done(destination)

        } catch let error as DLError {

            downloads[pkg.id] = .failed(error)

        } catch {

            downloads[pkg.id] = .failed(
                .other(error.localizedDescription)
            )
        }
    }

    // MARK: - Patch

    private func safeDocumentsPath(
        _ relativePath: String
    ) -> URL? {

        let clean = relativePath
            .trimmingCharacters(
                in: CharacterSet(
                    charactersIn: "/"
                )
            )

        guard !clean.isEmpty else {
            return nil
        }

        if clean.contains("..") {
            return nil
        }

        let candidate = documentsURL
            .appendingPathComponent(
                clean,
                isDirectory: false
            )

        let base = documentsURL.standardizedFileURL.path
        let path = candidate.standardizedFileURL.path

        guard
            path == base ||
            path.hasPrefix(base + "/")
        else {
            return nil
        }

        return candidate
    }

    private func packageArchive(
        _ pkg: RepoPackage
    ) -> URL? {
        existingFile(for: pkg)
    }

    private func patchDestination(
        _ pkg: RepoPackage
    ) -> URL? {

        if let custom = pkg.patchPath,
           !custom.isEmpty {

            return safeDocumentsPath(custom)
        }

        return safeDocumentsPath(
            "Applied/\(pkg.identifier)"
        )
    }

    private func backupURL(
        for pkg: RepoPackage
    ) -> URL {

        backupDirectory.appendingPathComponent(
            "\(pkg.identifier).backup",
            isDirectory: false
        )
    }

    private func createBackupDirectory() throws {

        if !FileManager.default.fileExists(
            atPath: backupDirectory.path
        ) {

            try FileManager.default.createDirectory(
                at: backupDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func backupCurrentTarget(
        _ target: URL,
        for pkg: RepoPackage
    ) throws {

        try createBackupDirectory()

        let backup = backupURL(for: pkg)

        if FileManager.default.fileExists(
            atPath: backup.path
        ) {
            try FileManager.default.removeItem(
                at: backup
            )
        }

        guard FileManager.default.fileExists(
            atPath: target.path
        ) else {
            return
        }

        try FileManager.default.copyItem(
            at: target,
            to: backup
        )
    }

    // MARK: - Make-iPA .3105 Patch

    private func decodedPatchProject(
        for pkg: RepoPackage
    ) throws -> PatchProject {
        guard let archive = existingFile(for: pkg) else {
            throw PatchError.sourceNotFound
        }

        let data = try Data(
            contentsOf: archive,
            options: .mappedIfSafe
        )

        let summary = try PatchPackageCodec.inspect(data)

        guard !summary.isPasswordProtected else {
            throw PatchError.other(
                "Gói .3105 này được bảo vệ bằng mật khẩu và không thể tự động áp dụng từ repo."
            )
        }

        return try PatchPackageCodec.decode(
            data,
            password: nil
        ).project
    }

    func apply(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .applying

        do {
            // IMPORTANT: do not copy/unzip the downloaded file.
            // The downloaded file is the actual Make-iPA .3105 envelope.
            // Decode it and let the native transaction engine perform the patch.
            let project = try decodedPatchProject(for: pkg)
            _ = try DevicePatchService.apply(project: project)

            patchStates[pkg.id] = .applied
            openTargetApp(for: pkg)
        } catch {
            patchStates[pkg.id] = .failed(
                errorMessage(error)
            )
        }
    }

    func restore(_ pkg: RepoPackage) async {
        patchStates[pkg.id] = .restoring

        do {
            let project = try decodedPatchProject(for: pkg)
            guard let receipt = DevicePatchService.latestReceipt(
                projectID: project.id
            ) else {
                throw PatchError.restoreFailed
            }

            try DevicePatchService.restore(receipt: receipt)
            patchStates[pkg.id] = .restored
        } catch {
            patchStates[pkg.id] = .failed(
                errorMessage(error)
            )
        }
    }

    func patchState(
        for pkg: RepoPackage
    ) -> PatchState {

        patchStates[pkg.id] ?? .idle
    }

    func openTargetApp(for pkg: RepoPackage) {
        var schemes: [String] = []

        if let raw = pkg.openURL, !raw.isEmpty {
            schemes.append(raw)
        }

        switch (pkg.category ?? "").lowercased() {
        case "free fire":
            schemes += ["freefire://", "com.dts.freefireth://"]
        case "free fire max":
            schemes += ["freefiremax://", "com.dts.freefiremax://"]
        case "liên quân mobile", "lien quan":
            schemes += ["com.garena.game.kgvn://"]
        default:
            break
        }

        for raw in schemes {
            guard let url = URL(string: raw) else { continue }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
    }

    private func unzip(
        _ zipURL: URL,
        to destination: URL
    ) throws {

        let fileManager = FileManager.default

        let temporaryDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        defer {
            try? fileManager.removeItem(
                at: temporaryDirectory
            )
        }

        #if targetEnvironment(simulator)
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/unzip"
        )

        process.arguments = [
            "-q",
            zipURL.path,
            "-d",
            temporaryDirectory.path
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw PatchError.applyFailed
        }

        let contents = try fileManager.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        if contents.count == 1,
           let first = contents.first,
           (try? first.resourceValues(
               forKeys: [.isDirectoryKey]
           ).isDirectory) == true {

            try fileManager.moveItem(
                at: first,
                to: destination
            )

        } else {

            try fileManager.moveItem(
                at: temporaryDirectory,
                to: destination
            )
        }
        #else
        try fileManager.copyItem(
            at: zipURL,
            to: destination
        )
        #endif
    }

    private func errorMessage(
        _ error: Error
    ) -> String {

        if let patchError = error as? PatchError {

            switch patchError {

            case .invalidPath:
                return "Đường dẫn patch không hợp lệ."

            case .sourceNotFound:
                return "Chưa tải package."

            case .backupFailed:
                return "Không thể tạo bản sao lưu."

            case .applyFailed:
                return "Không thể áp dụng package."

            case .restoreFailed:
                return "Không tìm thấy bản sao lưu."

            case .other(let message):
                return message
            }
        }

        return error.localizedDescription
    }
}

// ===== AppShimn source: HomeView.swift =====
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var session: Session
    @EnvironmentObject var license: LicenseManager
    let open: (Route) -> Void

    var body: some View {
        ZStack {
            BackgroundView()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 14) {
                    header
                    hero
                    licenseCard
                    ownerPanelLink
                    sectionTitle
                    reposSection
                    quickActions
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .refreshable { await store.refresh() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }


    private var ownerPanelLink: some View {
        Group {
            if session.role == .owner || session.role == .admin {
                VStack(spacing: 14) {
                NavigationLink {
                    OwnerPanelView()
                } label: {
                    HStack {
                        IconBox(systemName: "crown.fill", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Owner Panel")
                                .font(.headline.bold())
                            Text("Create member keys")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .shinnGlass()
                }
                .buttonStyle(.plain)

                NavigationLink {
                    RepositoryManagerView()
                } label: {
                    HStack {
                        IconBox(systemName: "folder.badge.gearshape", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Repository Manager")
                                .font(.headline.bold())
                            Text("Manage repositories & assign keys")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .shinnGlass()
                }
                .buttonStyle(.plain)
                }
            }
        }
    }

    private var licenseCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: session.role?.icon ?? "person.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(license.holderName.isEmpty ? (session.role?.title ?? "Member") : license.holderName)
                        .font(.headline.bold())
                        .foregroundStyle(roleTint)
                    Text(session.role?.title ?? "Member")
                        .font(.caption.bold())
                        .foregroundStyle(roleTint.opacity(0.8))
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(roleTint)
            }
            Divider()
            HStack {
                Label("Expires", systemImage: "clock")
                Spacer()
                Text(isLifetime ? "Lifetime" : remainString())
                    .fontWeight(.bold)
                    .foregroundStyle(remainColor)
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
        .padding()
        .shinnGlass()
    }

    private var roleTint: Color {
        switch session.role {
        case .owner: return .red
        case .admin: return .blue
        default: return .green
        }
    }

    private var isLifetime: Bool {
        let role = (session.role?.rawValue ?? license.boundRole ?? "").lowercased()
        if role == "owner" { return true }
        return license.expiresAt == nil
    }

    private var remainColor: Color {
        if isLifetime { return .green }
        if let exp = license.expiresAt, exp.timeIntervalSinceNow < 3600 { return .orange }
        return .secondary
    }

    private func remainString() -> String {
        guard let exp = license.expiresAt else { return "Lifetime" }
        let left = exp.timeIntervalSinceNow
        if left <= 0 { return "Expired" }
        let mins = Int(left / 60)
        let hours = Int(left / 3600)
        let days = Int(left / 86400)
        if days >= 1 { return "\(days)d left" }
        if hours >= 1 { return "\(hours)h left" }
        return "\(max(mins, 1))m left"
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 28))

            Text("SHINN CHEAT")
                .font(.system(size: 27, weight: .black, design: .rounded))
                .tracking(-0.8)

            Spacer()

            Button(action: { open(.support) }) {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                    .frame(width: 48, height: 48)
                    .background(Color.primary.opacity(0.08), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var hero: some View {
        if let ui = HeroBanner.image {
            bannerCard(ui)
        } else {
            classicHero
        }
    }

    private func bannerCard(_ ui: UIImage) -> some View {
        Image(uiImage: ui)
            .resizable()
            .scaledToFit()
            .scaleEffect(1.035)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    private var classicHero: some View {
        HStack(spacing: 16) {
            CatLogo(size: 84)

            VStack(alignment: .leading, spacing: 6) {
                Label("APP", systemImage: "crown.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Text("SHINN CHEAT")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(-1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .shinnGlass()
    }

    private var sectionTitle: some View {
        HStack {
            Label("Repositories", systemImage: "externaldrive.fill")
                .font(.system(size: 18, weight: .black, design: .rounded))
            Spacer()
            Button(action: { session.role = nil }) {
                Label(session.role?.title ?? "", systemImage: session.role?.icon ?? "person.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.primary.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    @ViewBuilder

    private var assignedRepos: [KeyRepoItem] {
        if let data = UserDefaults.standard.data(forKey: "shinn.license.repos"),
           let list = try? JSONDecoder().decode([KeyRepoItem].self, from: data),
           !list.isEmpty {
            return list
        }
        return [KeyRepoItem(name: "Repo ShinnCheat", url: AppInfo.defaultRepoURL.absoluteString, locked: false)]
    }

    private var reposSection: some View {
        VStack(spacing: 10) {
            ForEach(assignedRepos) { repo in
                Button {
                    UserDefaults.standard.set(repo.url, forKey: "shinn.license.repo")
                    UserDefaults.standard.set(repo.locked ?? false, forKey: "shinn.license.repoLocked")
                    Task { await store.refresh() }
                    open(.packages(nil))
                } label: {
                    HStack(spacing: 12) {
                        IconBox(systemName: (repo.locked ?? false) ? "lock.fill" : "folder.fill", size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(repo.name)
                                .font(.headline.bold())
                            Text((repo.locked ?? false) ? "Locked" : "Open packages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .shinnGlass()
                }
                .buttonStyle(.plain)
                .disabled(repo.locked ?? false)
            }
        }
    }

    @ViewBuilder
    private var categoriesSection: some View {
        if store.packages.isEmpty {
            stateCard
        } else {
            VStack(spacing: 10) {
                CategoryCard(icon: "square.grid.2x2.fill", title: settings.t(.allPackages), count: store.packages.count) {
                    open(.packages(nil))
                }
                ForEach(store.categories) { c in
                    CategoryCard(icon: categoryIcon(c.name), title: c.name, count: c.count) {
                        open(.packages(c.name))
                    }
                }
            }
        }
    }

    private var stateCard: some View {
        VStack(spacing: 12) {
            if store.loadState == .failed {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title)
                Text(settings.t(.loadFailed))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                Button(settings.t(.retry)) {
                    Task { await store.refresh() }
                }
                .buttonStyle(.bordered)
            } else {
                ProgressView()
                Text(settings.t(.loadingText))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .shinnGlass()
    }

    private var quickActions: some View {
        VStack(spacing: 12) {
        HStack(spacing: 12) {
            QuickAction(title: settings.t(.settingsTitle), subtitle: settings.t(.settingsSub), icon: "gearshape.fill") {
                open(.settings)
            }
            QuickAction(title: settings.t(.aboutTitle), subtitle: settings.t(.aboutSub), icon: "info.circle.fill") {
                open(.about)
            }
        }
        }
    }

    private var credit: some View {
        HStack {
            Image(systemName: "cube.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text("SHINN CHEAT").font(.headline.bold())
                Text("FREE FIRE • FREE FIRE MAX")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Play Smart\nStay Ahead")
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .italic()
                .multilineTextAlignment(.trailing)
        }
        .padding(18)
        .shinnGlass()
    }
}

struct CategoryCard: View {
    @EnvironmentObject var settings: AppSettings
    let icon: String
    let title: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconBox(systemName: icon, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(settings.countText(count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.bold())
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(0.08), in: Circle())
            }
            .padding(12)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
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
            .padding(18)
            .contentShape(Rectangle())
            .shinnGlass()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Logo mèo (dùng khi chưa có ảnh banner)

struct CatLogo: View {
    var size: CGFloat = 84

    private static let remoteURL = URL(string: "https://raw.githubusercontent.com/mhieuushinn-dev/ShinnCheatShare/main/IMG_0508.jpeg")

    private var bundled: UIImage? {
        guard let path = Bundle.main.path(forResource: "CatLogo", ofType: "jpg") else { return nil }
        return UIImage(contentsOfFile: path)
    }

    var body: some View {
        content
            .frame(width: size, height: size)
            .background(Color.primary.opacity(0.08))
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.25), lineWidth: 1.5))
    }

    @ViewBuilder
    private var content: some View {
        if let ui = bundled {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            AsyncImage(url: CatLogo.remoteURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    Image(systemName: "crown.fill")
                        .font(.system(size: size * 0.4))
                }
            }
        }
    }
}

// MARK: - Banner

enum HeroBanner {
    static let image: UIImage? = {
        let names: [(String, String)] = [
            ("IMG_1253", "jpeg"),
            ("IMG_1253", "jpg"),
            ("IMG_1253", "JPG"),
            ("IMG_1253", "JPEG"),
            ("HeroBanner", "jpg")
        ]
        for (name, ext) in names {
            if let path = Bundle.main.path(forResource: name, ofType: ext),
               let img = UIImage(contentsOfFile: path) {
                return img
            }
        }
        return nil
    }()
}


// ===== AppShimn source: PackageViews.swift =====
import SwiftUI
import UIKit

func categoryIcon(_ name: String) -> String {
    switch name {
    case "AIM":
        return "scope"

    case "ESP":
        return "eye.fill"

    case "Free Fire":
        return "flame.fill"

    case "Free Fire Max":
        return "sparkles"

    case "MOD SKIN":
        return "paintbrush.fill"

    case "Liên Quân Mobile":
        return "gamecontroller.fill"

    default:
        return "shippingbox.fill"
    }
}

// MARK: - Packages list

struct PackagesView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore

    @State private var searchText = ""
    @State private var category: String?

    init(initialCategory: String?) {
        _category = State(initialValue: initialCategory)
    }

    private func matches(
        _ package: RepoPackage,
        _ query: String
    ) -> Bool {

        if package.name.localizedCaseInsensitiveContains(query) {
            return true
        }

        if (package.summary ?? "")
            .localizedCaseInsensitiveContains(query) {
            return true
        }

        return (package.tags ?? [])
            .contains {
                $0.localizedCaseInsensitiveContains(query)
            }
    }

    private var filtered: [RepoPackage] {

        var result = store.packages

        if let category {
            result = result.filter {
                $0.category == category
            }
        }

        let query = searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !query.isEmpty {
            result = result.filter {
                matches($0, query)
            }
        }

        return result
    }

    var body: some View {

        ScrollView {

            LazyVStack(spacing: 12) {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(settings.t(.packageCenter))
                        .font(
                            .system(
                                size: 28,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    Text(settings.t(.packageCenterSub))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                chips

                if store.packages.isEmpty {

                    ProgressView()
                        .padding(.top, 40)

                } else if filtered.isEmpty {

                    VStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(settings.t(.notFound))
                            .font(.headline)

                        Text(settings.t(.notFoundDesc))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

                } else {

                    ForEach(filtered) { package in

                        NavigationLink(
                            value: Route.detail(
                                package.id
                            )
                        ) {
                            PackageRow(pkg: package)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .background(BackgroundView())
        .navigationTitle(settings.t(.packagesTitle))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            prompt: settings.t(.searchPrompt)
        )
        .refreshable {
            await store.refresh()
        }
    }

    private var chips: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 8) {

                chip(
                    settings.t(.allLabel),
                    selected: category == nil
                ) {
                    category = nil
                }

                ForEach(store.categories) { category in

                    chip(
                        category.name,
                        selected: self.category == category.name
                    ) {
                        self.category = category.name
                    }
                }
            }
        }
    }

    private func chip(
        _ title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selected
                    ? Color.primary
                    : Color.primary.opacity(0.08),
                    in: Capsule()
                )
                .foregroundStyle(
                    selected
                    ? Color(.systemBackground)
                    : Color.primary
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row

struct PackageRow: View {

    let pkg: RepoPackage

    private func tag(
        _ text: String
    ) -> some View {

        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Color.primary.opacity(0.08),
                in: Capsule()
            )
    }

    var body: some View {

        HStack(spacing: 14) {

            IconBox(
                systemName: categoryIcon(
                    pkg.category ?? ""
                ),
                size: 50
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(pkg.name)
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .lineLimit(1)

                Text(pkg.summary ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {

                    if let version = pkg.version {
                        tag("v\(version)")
                    }

                    if let size = pkg.size {
                        tag(formatBytes(size))
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .contentShape(Rectangle())
        .shinnGlass(radius: 20)
    }
}

// MARK: - Detail

struct PackageDetailView: View {

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: RepoStore
    @EnvironmentObject var abuse: AbuseGuard

    let packageID: String
    @State private var patchOn = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var pkg: RepoPackage? {
        store.packages.first {
            $0.id == packageID
        }
    }

    var body: some View {

        ZStack {

            BackgroundView()

            if let pkg {
                content(pkg)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(pkg?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func content(
        _ pkg: RepoPackage
    ) -> some View {

        ScrollView {

            VStack(spacing: 16) {

                remoteIcon(pkg)

                VStack(spacing: 4) {

                    Text(pkg.name)
                        .font(
                            .system(
                                size: 26,
                                weight: .bold,
                                design: .rounded
                            )
                        )

                    if let summary = pkg.summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 0) {

                    infoRow(
                        settings.t(.versionLabel),
                        pkg.version ?? "-"
                    )

                    infoRow(
                        settings.t(.authorLabel),
                        pkg.author ?? "-"
                    )

                    infoRow(
                        settings.t(.categoryLabel),
                        pkg.category ?? "-"
                    )

                    infoRow(
                        settings.t(.sizeLabel),
                        pkg.size.map {
                            formatBytes($0)
                        } ?? "-"
                    )
                }
                .padding(.horizontal, 16)
                .shinnGlass()

                downloadSection(pkg)

                if let description = pkg.description,
                   !description.isEmpty {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text(
                            settings.t(
                                .descriptionLabel
                            )
                        )
                        .font(.headline)

                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(16)
                    .shinnGlass()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func remoteIcon(
        _ pkg: RepoPackage
    ) -> some View {

        if let string = pkg.icon,
           let url = URL(string: string) {

            AsyncImage(url: url) { phase in

                switch phase {

                case .success(let image):

                    image
                        .resizable()
                        .scaledToFill()

                default:

                    Image(
                        systemName: categoryIcon(
                            pkg.category ?? ""
                        )
                    )
                    .font(
                        .system(
                            size: 38,
                            weight: .semibold
                        )
                    )
                }
            }
            .frame(
                width: 96,
                height: 96
            )
            .background(
                Color.primary.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
            )

        } else {

            IconBox(
                systemName: categoryIcon(
                    pkg.category ?? ""
                ),
                size: 96
            )
        }
    }

    private func infoRow(
        _ label: String,
        _ value: String
    ) -> some View {

        HStack {

            Text(label)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 13)
    }

    private func mainButton(
        _ title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Label(
                title,
                systemImage: icon
            )
            .font(
                .system(
                    size: 16,
                    weight: .bold,
                    design: .rounded
                )
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Color.primary,
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .foregroundStyle(
                Color(.systemBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private func message(
        _ error: DLError
    ) -> String {

        switch error {

        case .badURL:
            return settings.t(.errURL)

        case .http(let code):
            return settings.t(.errHTTP)
                + " (\(code))"

        case .hashMismatch:
            return settings.t(.errHash)

        case .other(let message):
            return message
        }
    }

    // MARK: - Download / Apply / Restore

    @ViewBuilder
    private func downloadSection(
        _ pkg: RepoPackage
    ) -> some View {

        VStack(spacing: 12) {

            switch store.state(for: pkg) {

            case .idle:

                mainButton(
                    settings.t(.downloadAction),
                    icon: "arrow.down.circle.fill"
                ) {
                    Task {
                        await store.download(pkg)
                    }
                }

            case .downloading:

                HStack(spacing: 10) {

                    ProgressView()

                    Text(
                        settings.t(.downloading)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .shinnGlass(radius: 16)

            case .done(let url):

                Label(
                    settings.t(.downloaded),
                    systemImage: "checkmark.circle.fill"
                )
                .font(.headline)

                if let hash = pkg.sha256,
                   !hash.isEmpty {

                    Label(
                        settings.t(.sha256OK),
                        systemImage: "checkmark.shield.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

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
                                    alertTitle = "On"
                                    alertMessage = "Patch enabled."
                                case .failed(let m):
                                    patchOn = false
                                    alertTitle = "Failed"
                                    alertMessage = m
                                default:
                                    alertTitle = "On"
                                    alertMessage = "Patch enabled."
                                }
                            } else {
                                await store.restore(pkg)
                                alertTitle = "Off"
                                alertMessage = "Patch restored."
                            }
                            showAlert = true
                        }
                    }
                )) {
                    Text("Patch")
                        .font(.headline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .shinnGlass(radius: 16)

                Button(
                    settings.t(.redownload)
                ) {

                    Task {
                        await store.download(pkg)
                    }
                }
                .font(.subheadline)

                patchStatus(pkg)

            case .failed(let error):

                Text(message(error))
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)

                mainButton(
                    settings.t(.retry),
                    icon: "arrow.clockwise"
                ) {
                    Task {
                        await store.download(pkg)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func patchStatus(
        _ pkg: RepoPackage
    ) -> some View {

        switch store.patchState(for: pkg) {

        case .idle:
            EmptyView()

        case .applying:

            Label(
                "Applying…",
                systemImage: "arrow.triangle.2.circlepath"
            )
            .foregroundStyle(.secondary)

        case .applied:

            Label(
                "Applied",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .restoring:

            Label(
                "Restoring…",
                systemImage: "arrow.uturn.backward"
            )
            .foregroundStyle(.secondary)

        case .restored:

            Label(
                "Restored",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)

        case .failed(let message):

            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}

// ===== AppShimn source: SecondaryViews.swift =====
import SwiftUI
import UIKit

// ===== Make-iPA compatibility models retained for existing browser views =====
struct LemonTargetApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let iconAssetName: String
}

enum FFH4XFeatureCategory: String, CaseIterable, Identifiable, Hashable {
    case aim
    case chams
    case modSkin

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aim: return "Aim"
        case .chams: return "Chams"
        case .modSkin: return "Mod Skin"
        }
    }

    var subtitle: String {
        switch self {
        case .aim: return "Hỗ trợ kéo tâm"
        case .chams: return "Định vị nhìn xuyên tường"
        case .modSkin: return "Mod skin"
        }
    }

    var icon: String {
        switch self {
        case .aim: return "scope"
        case .chams: return "eye.fill"
        case .modSkin: return "tshirt.fill"
        }
    }

    var tint: Color {
        switch self {
        case .aim: return .blue
        case .chams: return .purple
        case .modSkin: return .orange
        }
    }
}

struct ProjectAppIcon: View {
    let assetName: String
    let size: CGFloat

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
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
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
        .task(id: bundleID) {
            image = await Task.detached(priority: .userInitiated) {
                iconForBundleID(bundleID)
            }.value
        }
    }
}


// MARK: - AppShimn root
import SwiftUI
import CryptoKit

enum UserRole: String, CaseIterable, Identifiable {
    case owner, admin, member
    var id: String { rawValue }

    var title: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }

    var icon: String {
        switch self {
        case .owner: return "crown.fill"
        case .admin: return "checkmark.shield.fill"
        case .member: return "person.fill"
        }
    }

    var needsPassword: Bool { self != .member }
}

final class Session: ObservableObject {
    @Published var role: UserRole?

    // SHA256 của mật khẩu Owner/Admin
    private static let passwordHash = "a43535812161a1aec35c04f0b6ea63bb4880d581f3d15df9ba7e68befe6b472e"

    func verify(_ input: String) -> Bool {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex == Session.passwordHash
    }
}

import Foundation
import SwiftUI
import UIKit


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

enum SupabaseConfig {
    static let projectURL = URL(string: "https://efhqbzdnrtifqjqlqseb.supabase.co")!
    static let anonKey = "sb_publishable_jnycTCgXRMrluvwJORd_4g_B7ojwi9R"
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
            lastError = language == .vi ? "Enter an activation key." : "Enter an activation key."
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
            lastError = mappedError(result.error, language: language)
            return false
        } catch {
            lastError = language == .vi
                ? "Could not reach the key server."
                : "Could not reach the key server. Check your connection."
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

    private func mappedError(_ code: String?, language: ShinnLanguage) -> String {
        let vi = language == .vi
        switch code {
        case "invalid_key":
            return vi ? "Invalid key." : "Invalid key."
        case "used_on_other_device":
            return vi ? "This key is already used on another device." : "This key is already used on another device."
        case "missing_key":
            return vi ? "Missing key." : "Missing key."
        case "missing_device":
            return vi ? "Missing device id." : "Missing device id."
        default:
            return vi ? "Could not activate the key." : "Could not activate the key."
        }
    }

    private func callActivate(key: String) async throws -> ActivateKeyResponse {
        var request = URLRequest(
            url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/activate_key")
        )
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

        let body: [String: String] = [
            "p_key": key,
            "p_device_id": deviceID
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ActivateKeyResponse.self, from: data)
    }
}


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

struct ActivateKeyView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @EnvironmentObject var license: LicenseManager
    @EnvironmentObject var abuse: AbuseGuard

    @State private var keyText = ""
    @FocusState private var focused: Bool

    private var isVI: Bool { settings.language == .vi }
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
                            Text(
                                hasSavedKey
                                ? (isVI ? "Quét Face ID để tự nhập key" : "Scan Face ID to fill your key")
                                : (isVI ? "Enter a key to use the app" : "Enter a key to use the app")
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            isVI ? "Activation key" : "Activation key",
                            systemImage: "lock.fill"
                        )
                        .font(.headline)

                        SecureField(
                            hasSavedKey
                            ? (isVI ? "Chờ Face ID…" : "Waiting for Face ID…")
                            : (isVI ? "Nhập activation key" : "Enter activation key"),
                            text: $keyText
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focused)
                        .disabled(hasSavedKey)
                        .padding(14)
                        .background(
                            Color.primary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )

                        if let err = license.lastError, !err.isEmpty {
                            Text(err)
                                .font(.footnote.bold())
                                .foregroundStyle(.red)
                        }

                        if hasSavedKey {
                            Button {
                                Task { await biometricUnlock() }
                            } label: {
                                Label(
                                    isVI ? "Thử lại Face ID" : "Retry Face ID",
                                    systemImage: "faceid"
                                )
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(license.isBusy)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                if license.isBusy {
                                    ProgressView()
                                        .tint(Color(.systemBackground))
                                }
                                Text(isVI ? "Activate" : "Activate")
                                    .font(.system(size: 15, weight: .bold))
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
                focused = false
                Task { await biometricUnlock() }
            } else {
                DispatchQueue.main.async { focused = true }
            }
        }
    }

    private func quitApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            exit(0)
        }
    }

    private func biometricUnlock() async {
        guard let stored = KeychainKeyStore.load(), !stored.isEmpty else { return }

        let role = (license.boundRole ?? "").lowercased()
        if role != "owner", let exp = license.expiresAt, exp <= Date() {
            KeychainKeyStore.clear()
            return
        }

        keyText = ""

        let ctx = LAContext()
        var evalError: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &evalError) else {
            license.lastError = isVI
                ? "Máy không hỗ trợ Face ID / Touch ID."
                : "This device has no Face ID / Touch ID."
            return
        }

        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: isVI
                    ? "Quét Face ID để tự nhập key"
                    : "Scan Face ID to fill your key"
            )
            guard ok else {
                await handleFaceFail()
                return
            }
            abuse.faceOk()
            license.lastError = nil
            keyText = stored
            await submit()
        } catch let error as LAError {
            switch error.code {
            case .authenticationFailed:
                await handleFaceFail()
            case .biometryLockout:
                license.lastError = isVI ? "Face ID bị khóa." : "Face ID locked."
                quitApp()
            case .userCancel, .systemCancel, .appCancel:
                license.lastError = isVI
                    ? "Đã hủy. Bấm Thử lại Face ID."
                    : "Cancelled. Tap Retry Face ID."
            default:
                await handleFaceFail()
            }
        } catch {
            await handleFaceFail()
        }
    }

    private func handleFaceFail() async {
        let n = abuse.faceFailed()
        license.lastError = isVI
            ? "Sai Face ID (\(n)/3)"
            : "Face ID failed (\(n)/3)"
        keyText = ""
        if n >= 3 {
            quitApp()
        }
    }

    private func submit() async {
        let raw = keyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }

        let ok = await license.activate(key: raw, language: settings.language)
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



@MainActor
final class AbuseGuard: ObservableObject {
    @Published var lockedUntil: Date?
    private let lockKey = "shinn.abuse.lock"
    private let keyFailsKey = "shinn.abuse.keyFails"
    private let passFailsKey = "shinn.abuse.passFails"
    private let patchTapsKey = "shinn.abuse.patchTaps"
    private let windowKey = "shinn.abuse.window"

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
        var window = d.double(forKey: windowKey)
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

    private let faceFailsKey = "shinn.abuse.faceFails"

    func faceFailed() -> Int {
        let d = UserDefaults.standard
        let n = d.integer(forKey: faceFailsKey) + 1
        d.set(n, forKey: faceFailsKey)
        return n
    }

    func faceOk() {
        UserDefaults.standard.set(0, forKey: faceFailsKey)
    }

    func faceFailCount() -> Int {
        UserDefaults.standard.integer(forKey: faceFailsKey)
    }

    private func lock() {
        let until = Date().addingTimeInterval(10 * 60)
        lockedUntil = until
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: lockKey)
        UserDefaults.standard.set(0, forKey: keyFailsKey)
        UserDefaults.standard.set(0, forKey: passFailsKey)
        UserDefaults.standard.set(0, forKey: patchTapsKey)
    }
}

struct ContentView: View {
    @StateObject var session = Session()
    @StateObject private var license = LicenseManager()
    @StateObject private var abuse = AbuseGuard()
    @State private var path: [Route] = []
    var body: some View {
        Group {
            if abuse.isLocked {
                LockoutView(abuse: abuse)
            } else if !license.isActivated {
                ActivateKeyView()
            } else if session.role == nil {
                RoleGateView()
            } else {
                NavigationStack(path: $path) {
                    HomeView(open: { path.append($0) })
                        .navigationDestination(for: Route.self) { route in
                            switch route {
                            case .packages(let category):
                                PackagesView(initialCategory: category)
                            case .detail(let id):
                                PackageDetailView(packageID: id)
                            case .settings:
                                SettingsView()
                            case .about:
                                AboutView()
                            case .support:
                                SupportView()
                            case .repositoryManager:
                                RepositoryManagerView()
                            }
                        }
                }
                .tint(.primary)
            }
        }
        .environmentObject(session)
        .environmentObject(license)
        .environmentObject(abuse)
        .task {
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
    }
}

// MARK: - Chọn vai trò

struct RoleGateView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var session: Session
    @EnvironmentObject var abuse: AbuseGuard
    @State private var pending: UserRole?
    @State private var password = ""
    @State private var attempts = 0
    @State private var closing = false
    @FocusState private var focused: Bool

    private var isVI: Bool { settings.language == .vi }

    var body: some View {
        ZStack {
            BackgroundView()
            ScreenPrivacyGuard()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    if pending == nil {
                        VStack(spacing: 22) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 46))

                            VStack(spacing: 6) {
                                Text("SHINN CHEAT")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .tracking(-0.8)
                                Text(isVI ? "Choose a role to activate" : "Choose a role to activate")
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

                Text(role.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))

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
            Label((isVI ? "Password " : "Password for ") + role.title, systemImage: "lock.fill")
                .font(.headline)

            SecureField(isVI ? "Enter password" : "Enter password", text: $password)
                .focused($focused)
                .keyboardType(.numberPad)
                .padding(14)
                .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onSubmit { submit() }
                .disabled(closing)

            if closing {
                Text(isVI ? "Wrong password. The app will close." : "You are a cow. The app will close.")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            } else if attempts > 0 {
                Text(isVI ? "Wrong password" : "You are a cow")
                    .font(.footnote.bold())
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Button(action: cancel) {
                    Text(isVI ? "Cancel" : "Cancel")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: submit) {
                    Text(isVI ? "Confirm" : "Confirm")
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
            if attempts >= 5 {
                focused = false
            }
        }
    }
}



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

    func createKey() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            var request = URLRequest(
                url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/create_shinn_key")
            )
            request.httpMethod = "POST"
            request.timeoutInterval = 20
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "p_role": selectedRole,
                "p_days": lifetime ? -1 : selectedDays,
                "p_hours": lifetime ? 0 : selectedHours,
                "p_count": max(1, min(createCount, 20)),
                "p_label": keyLabel
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
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
            self.error = "Could not create key"
        }
    }

    var prettyCreated: String {
        createdKey
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "")
    }

    func deleteAllKeys() async {
        do {
            var request = URLRequest(
                url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/delete_all_shinn_keys")
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = Data("{}".utf8)
            _ = try await URLSession.shared.data(for: request)
            createdKey = ""
            await listKeys()
        } catch {
            self.error = "Could not delete keys"
        }
    }

    func listKeys() async {
        do {
            var request = URLRequest(
                url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/list_shinn_keys")
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = Data("{}".utf8)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else { return }
            keys = (try? JSONDecoder().decode([ShinnKeyRow].self, from: data)) ?? []
        } catch {
            // keep previous list
        }
    }

    func deleteKey(_ key: String) async {
        do {
            var request = URLRequest(
                url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/delete_shinn_key")
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: ["p_key": key])
            _ = try await URLSession.shared.data(for: request)
            if createdKey == key { createdKey = "" }
            await listKeys()
        } catch {
            self.error = "Could not delete key"
        }
    }
}


struct RepositoryManagerView: View {
    @StateObject private var manager = OwnerKeyManager()
    @State private var repoURL = ""
    @State private var repoName = ""
    @State private var selectedKey = ""
    @State private var locked = false
    @State private var status = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("REPOSITORY MANAGER").font(.title.bold())
                Text("Assign a JSON repo URL to a key. Lock blocks packages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Repo name (VIP 1)", text: $repoName)
                    .padding(12)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField("https://.../shinn.json", text: $repoURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(12)
                    .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Toggle("Lock repo for this key", isOn: $locked)

                Button("Save to selected key") {
                    Task { await save() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedKey.isEmpty || selectedKey == "Shinn-Ower")

                if !status.isEmpty {
                    Text(status).font(.footnote)
                }

                ForEach(manager.keys) { row in
                    Button {
                        selectedKey = row.key
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.key).font(.headline)
                            Text("\((row.label ?? "").isEmpty ? (row.role ?? "member") : row.label!) • \(selectedKey == row.key ? "selected" : "")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
            var request = URLRequest(
                url: SupabaseConfig.projectURL.appendingPathComponent("/rest/v1/rpc/add_key_repo")
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "p_key": selectedKey,
                "p_repo_url": repoURL,
                "p_locked": locked
            ])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                status = String(decoding: data, as: UTF8.self)
                return
            }
            status = "Saved"
            await manager.listKeys()
        } catch {
            status = "Failed"
        }
    }
}

struct OwnerPanelView: View {
    @EnvironmentObject var license: LicenseManager
    @EnvironmentObject var session: Session
    @StateObject private var manager = OwnerKeyManager()
    @State private var copied = false

    private let roles = ["member", "admin"]
    private let durations = [1, 3, 7, 30, 90, 365]

    var body: some View {
        ZStack {
            BackgroundView()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("OWNER PANEL")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                        Text("Create keys, set role and duration, delete keys")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Assigned to").font(.headline)
                        TextField("Name / who this key is for", text: $manager.keyLabel)
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

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Existing keys").font(.headline)
                        if manager.keys.isEmpty {
                            Text("No keys loaded")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(manager.keys) { row in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(row.key).font(.system(.footnote, design: .monospaced).weight(.bold))
                                    Text("\(row.label?.isEmpty == false ? row.label! : (row.role ?? "member").capitalized) • \((row.role ?? "member").capitalized) • \(row.expires_at ?? "lifetime")")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if session.role == .owner && row.key != "Shinn-Ower" {
                                    Button("Delete") {
                                        Task { await manager.deleteKey(row.key) }
                                    }
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 6)
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
