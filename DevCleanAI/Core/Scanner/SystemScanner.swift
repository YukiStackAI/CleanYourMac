import Foundation

actor SystemScanner {

    func scan(progress: (@Sendable (Double) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []
        let tasks: [() async -> [ScanItem]] = [
            { await self.scanAppCaches() },
            { await self.scanSystemLogs() },
            { await self.scanTempFiles() },
            { await self.scanBrowserCaches() },
            { await self.scanMailAttachments() },
            { await self.scanLanguageFiles() },
            { await self.scanTrash() }
        ]

        for (index, task) in tasks.enumerated() {
            let result = await task()
            items.append(contentsOf: result)
            progress?(Double(index + 1) / Double(tasks.count))
        }

        return items
    }

    // MARK: - App Caches

    private func scanAppCaches() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cachesPath = home.appendingPathComponent("Library/Caches")

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: cachesPath,
            includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return [] }

        for url in contents {
            let size = await directorySize(at: url)
            guard size > 1_000_000 else { continue } // Skip < 1MB

            let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey])
            let item = ScanItem(
                name: url.lastPathComponent,
                path: url,
                size: size,
                lastAccessed: attrs?.contentAccessDate,
                lastModified: attrs?.contentModificationDate,
                category: .appCache,
                riskLevel: .safe,
                canRecreate: true
            )
            items.append(item)
        }

        return items
    }

    // MARK: - System Logs

    private func scanSystemLogs() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let logPaths = [
            home.appendingPathComponent("Library/Logs"),
            URL(fileURLWithPath: "/private/var/log"),
            URL(fileURLWithPath: "/Library/Logs")
        ]

        for logPath in logPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: logPath,
                includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for url in contents {
                let size = await directorySize(at: url)
                guard size > 500_000 else { continue }

                let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey])
                let item = ScanItem(
                    name: url.lastPathComponent,
                    path: url,
                    size: size,
                    lastAccessed: attrs?.contentAccessDate,
                    lastModified: nil,
                    category: .systemLog,
                    riskLevel: .safe,
                    canRecreate: false
                )
                items.append(item)
            }
        }

        return items
    }

    // MARK: - Temp Files

    private func scanTempFiles() async -> [ScanItem] {
        var items: [ScanItem] = []
        let tempPaths = [
            URL(fileURLWithPath: NSTemporaryDirectory()),
            URL(fileURLWithPath: "/private/tmp"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/CrashReporter")
        ]

        for tempPath in tempPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: tempPath,
                includingPropertiesForKeys: [.fileSizeKey, .contentAccessDateKey],
                options: .skipsHiddenFiles
            ) else { continue }

            for url in contents {
                let ext = url.pathExtension.lowercased()
                guard ["tmp", "temp", "crash", "ips"].contains(ext) || url.lastPathComponent.hasPrefix("tmp") else { continue }

                let size = await directorySize(at: url)
                guard size > 10_000 else { continue }

                let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey])
                let item = ScanItem(
                    name: url.lastPathComponent,
                    path: url,
                    size: size,
                    lastAccessed: attrs?.contentAccessDate,
                    lastModified: nil,
                    category: .tempFile,
                    riskLevel: .safe,
                    canRecreate: false
                )
                items.append(item)
            }
        }

        return items
    }

    // MARK: - Browser Caches

    private func scanBrowserCaches() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let browserPaths: [(String, String)] = [
            ("Safari", "Library/Caches/com.apple.Safari"),
            ("Chrome", "Library/Caches/Google/Chrome"),
            ("Firefox", "Library/Caches/Firefox"),
            ("Edge", "Library/Caches/Microsoft Edge"),
            ("Arc", "Library/Caches/company.thebrowser.Browser"),
            ("Brave", "Library/Caches/BraveSoftware/Brave-Browser"),
            ("Opera", "Library/Caches/com.operasoftware.Opera"),
        ]

        for (browserName, relativePath) in browserPaths {
            let url = home.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let size = await directorySize(at: url)
            guard size > 1_000_000 else { continue }

            let item = ScanItem(
                name: "\(browserName) Cache",
                path: url,
                size: size,
                lastAccessed: nil,
                lastModified: nil,
                category: .browserCache,
                riskLevel: .safe,
                canRecreate: true
            )
            items.append(item)
        }

        return items
    }

    // MARK: - Mail Attachments

    private func scanMailAttachments() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let mailPath = home.appendingPathComponent("Library/Mail")
        guard FileManager.default.fileExists(atPath: mailPath.path) else { return [] }

        let size = await directorySize(at: mailPath)
        guard size > 10_000_000 else { return [] }

        return [ScanItem(
            name: "Mail Downloads & Attachments",
            path: mailPath,
            size: size,
            lastAccessed: nil,
            lastModified: nil,
            category: .mailAttachment,
            riskLevel: .review,
            canRecreate: false
        )]
    }

    // MARK: - Language Files

    private func scanLanguageFiles() async -> [ScanItem] {
        var items: [ScanItem] = []
        let appPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        let preferredLanguages = Set(Locale.preferredLanguages.map { String($0.prefix(2)) })

        for appsDir in appPaths {
            guard let apps = try? FileManager.default.contentsOfDirectory(
                at: appsDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
            ) else { continue }

            for app in apps where app.pathExtension == "app" {
                let resourcesPath = app.appendingPathComponent("Contents/Resources")
                guard let resources = try? FileManager.default.contentsOfDirectory(
                    at: resourcesPath, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles
                ) else { continue }

                for resource in resources where resource.pathExtension == "lproj" {
                    let langCode = String(resource.lastPathComponent.prefix(2))
                    guard !preferredLanguages.contains(langCode) else { continue }

                    let size = await directorySize(at: resource)
                    guard size > 100_000 else { continue }

                    let item = ScanItem(
                        name: "\(app.deletingPathExtension().lastPathComponent) — \(resource.lastPathComponent)",
                        path: resource,
                        size: size,
                        lastAccessed: nil,
                        lastModified: nil,
                        category: .languageFile,
                        riskLevel: .caution,
                        canRecreate: false
                    )
                    items.append(item)
                }
            }
        }

        return items
    }

    // MARK: - Trash

    private func scanTrash() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let trashPath = home.appendingPathComponent(".Trash")
        guard FileManager.default.fileExists(atPath: trashPath.path) else { return [] }

        let size = await directorySize(at: trashPath)
        guard size > 0 else { return [] }

        return [ScanItem(
            name: "Trash",
            path: trashPath,
            size: size,
            lastAccessed: nil,
            lastModified: nil,
            category: .trashBin,
            riskLevel: .safe,
            canRecreate: false
        )]
    }

    // MARK: - Utility

    func directorySize(at url: URL) async -> Int64 {
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
