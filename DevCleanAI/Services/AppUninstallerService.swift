import Foundation
import AppKit

actor AppUninstallerService {

    func scanInstalledApps() async -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let appPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for appDir in appPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: appDir, includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for appURL in contents where appURL.pathExtension == "app" {
                if let app = await buildAppInfo(from: appURL) {
                    apps.append(app)
                }
            }
        }

        return apps.sorted { $0.size > $1.size }
    }

    private func buildAppInfo(from url: URL) async -> InstalledApp? {
        guard let bundle = Bundle(url: url) else { return nil }
        let bundleID = bundle.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        let size = await directorySize(at: url)
        let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey])
        let relatedFiles = findRelatedFiles(bundleID: bundleID)

        return InstalledApp(
            name: url.deletingPathExtension().lastPathComponent,
            bundleID: bundleID,
            path: url,
            version: version,
            size: size,
            lastUsed: attrs?.contentAccessDate,
            relatedFiles: relatedFiles
        )
    }

    func findRelatedFiles(bundleID: String) -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var related: [URL] = []

        let searchDirs: [(String, Bool)] = [
            ("Library/Application Support", true),
            ("Library/Caches", true),
            ("Library/Preferences", false),
            ("Library/Logs", true),
            ("Library/Saved Application State", true),
            ("Library/Containers", true),
            ("Library/Group Containers", true),
        ]

        let bundleComponents = bundleID.split(separator: ".").map(String.init)
        let searchTerms = Set(bundleComponents.filter { $0.count > 3 && $0 != "com" && $0 != "org" && $0 != "app" })

        for (dir, _) in searchDirs {
            let dirURL = home.appendingPathComponent(dir)
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: dirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
            ) else { continue }

            for item in contents {
                let itemName = item.lastPathComponent.lowercased()
                let matches = searchTerms.contains { term in
                    itemName.contains(term.lowercased())
                } || itemName.contains(bundleID.lowercased())

                if matches {
                    related.append(item)
                }
            }
        }

        return related
    }

    func uninstall(app: InstalledApp, removeRelatedFiles: Bool) async throws {
        // Move app to Trash
        try FileManager.default.trashItem(at: app.path, resultingItemURL: nil)

        if removeRelatedFiles {
            for fileURL in app.relatedFiles {
                try? FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            }
        }
    }

    private func directorySize(at url: URL) async -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return 0 }

        var total: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize else { continue }
            total += Int64(fileSize)
        }
        return total
    }
}
