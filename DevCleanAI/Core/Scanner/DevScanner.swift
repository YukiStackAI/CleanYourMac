import Foundation

actor DevScanner {

    private let systemScanner = SystemScanner()

    func scan(progress: (@Sendable (Double) -> Void)? = nil) async -> [ScanItem] {
        var items: [ScanItem] = []
        let tasks: [() async -> [ScanItem]] = [
            { await self.scanNodeModules() },
            { await self.scanNpmCache() },
            { await self.scanYarnCache() },
            { await self.scanPnpmCache() },
            { await self.scanPythonVenvs() },
            { await self.scanPipCache() },
            { await self.scanCondaEnvironments() },
            { await self.scanDockerArtifacts() },
            { await self.scanXcodeArtifacts() },
            { await self.scanGradleCache() },
            { await self.scanMavenCache() },
            { await self.scanCargoCache() },
            { await self.scanGemCache() },
            { await self.scanCocoaPodsCache() },
            { await self.scanBuildArtifacts() }
        ]

        for (index, task) in tasks.enumerated() {
            let result = await task()
            items.append(contentsOf: result)
            progress?(Double(index + 1) / Double(tasks.count))
        }

        return items
    }

    // MARK: - Node / npm

    private func scanNodeModules() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let searchPaths = [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Code"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Sites"),
            home
        ]

        for searchPath in searchPaths {
            guard FileManager.default.fileExists(atPath: searchPath.path) else { continue }
            let found = await findDirectories(named: "node_modules", under: searchPath, maxDepth: 6)
            for url in found {
                let size = await systemScanner.directorySize(at: url)
                guard size > 1_000_000 else { continue }

                let projectName = url.deletingLastPathComponent().lastPathComponent
                let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey])

                items.append(ScanItem(
                    name: "node_modules (\(projectName))",
                    path: url,
                    size: size,
                    lastAccessed: attrs?.contentAccessDate,
                    lastModified: attrs?.contentModificationDate,
                    category: .nodeModules,
                    riskLevel: .safe,
                    canRecreate: true
                ))
            }
        }

        return items
    }

    private func scanNpmCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cachePaths = [
            home.appendingPathComponent(".npm/_cacache"),
            home.appendingPathComponent(".npm"),
        ]
        return await scanCacheDirectories(paths: cachePaths, name: "npm cache", category: .npmCache, riskLevel: .safe)
    }

    private func scanYarnCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cachePaths = [
            home.appendingPathComponent("Library/Caches/Yarn"),
            home.appendingPathComponent(".yarn/cache"),
        ]
        return await scanCacheDirectories(paths: cachePaths, name: "Yarn cache", category: .yarnCache, riskLevel: .safe)
    }

    private func scanPnpmCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cachePaths = [
            home.appendingPathComponent("Library/pnpm"),
            home.appendingPathComponent(".pnpm-store"),
        ]
        return await scanCacheDirectories(paths: cachePaths, name: "pnpm store", category: .pnpmCache, riskLevel: .safe)
    }

    // MARK: - Python

    private func scanPythonVenvs() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let searchPaths = [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Code"),
            home.appendingPathComponent("Documents"),
            home
        ]

        let venvNames = [".venv", "venv", "env", ".env", "virtualenv", ".virtualenv"]

        for searchPath in searchPaths {
            guard FileManager.default.fileExists(atPath: searchPath.path) else { continue }
            for venvName in venvNames {
                let found = await findDirectories(named: venvName, under: searchPath, maxDepth: 5)
                for url in found {
                    // Verify it's actually a Python venv
                    guard isPythonVenv(at: url) else { continue }
                    let size = await systemScanner.directorySize(at: url)
                    guard size > 10_000_000 else { continue }

                    let projectName = url.deletingLastPathComponent().lastPathComponent
                    let attrs = try? url.resourceValues(forKeys: [.contentAccessDateKey, .contentModificationDateKey])

                    items.append(ScanItem(
                        name: "\(venvName) (\(projectName))",
                        path: url,
                        size: size,
                        lastAccessed: attrs?.contentAccessDate,
                        lastModified: attrs?.contentModificationDate,
                        category: .pythonVenv,
                        riskLevel: .safe,
                        canRecreate: true
                    ))
                }
            }
        }

        return items
    }

    private func scanPipCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cachePaths = [
            home.appendingPathComponent("Library/Caches/pip"),
            home.appendingPathComponent(".cache/pip"),
        ]
        return await scanCacheDirectories(paths: cachePaths, name: "pip cache", category: .pipCache, riskLevel: .safe)
    }

    private func scanCondaEnvironments() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let condaEnvPaths = [
            home.appendingPathComponent("opt/anaconda3/envs"),
            home.appendingPathComponent("opt/miniconda3/envs"),
            home.appendingPathComponent("anaconda3/envs"),
            home.appendingPathComponent("miniconda3/envs"),
            home.appendingPathComponent(".conda/envs"),
        ]

        for envsPath in condaEnvPaths {
            guard let envs = try? FileManager.default.contentsOfDirectory(
                at: envsPath, includingPropertiesForKeys: [.contentAccessDateKey], options: .skipsHiddenFiles
            ) else { continue }

            for envURL in envs {
                let size = await systemScanner.directorySize(at: envURL)
                guard size > 50_000_000 else { continue }
                let attrs = try? envURL.resourceValues(forKeys: [.contentAccessDateKey])

                items.append(ScanItem(
                    name: "Conda env: \(envURL.lastPathComponent)",
                    path: envURL,
                    size: size,
                    lastAccessed: attrs?.contentAccessDate,
                    lastModified: nil,
                    category: .condaEnv,
                    riskLevel: .review,
                    canRecreate: true
                ))
            }
        }

        return items
    }

    // MARK: - Docker

    private func scanDockerArtifacts() async -> [ScanItem] {
        var items: [ScanItem] = []

        // Docker Desktop data
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dockerPaths: [(String, ItemCategory, RiskLevel)] = [
            ("Library/Containers/com.docker.docker/Data/vms", .dockerImage, .review),
            ("Library/Application Support/Docker Desktop", .dockerBuildCache, .safe),
            (".docker", .dockerBuildCache, .safe),
        ]

        for (relativePath, category, risk) in dockerPaths {
            let url = home.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let size = await systemScanner.directorySize(at: url)
            guard size > 100_000_000 else { continue }

            items.append(ScanItem(
                name: "Docker: \(url.lastPathComponent)",
                path: url,
                size: size,
                lastAccessed: nil,
                lastModified: nil,
                category: category,
                riskLevel: risk,
                canRecreate: false
            ))
        }

        return items
    }

    // MARK: - Xcode

    private func scanXcodeArtifacts() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let xcodeArtifacts: [(String, String, ItemCategory, RiskLevel, Bool)] = [
            ("Library/Developer/Xcode/DerivedData", "Xcode DerivedData", .xcodeDerivedData, .safe, true),
            ("Library/Developer/Xcode/Archives", "Xcode Archives", .xcodeArchive, .review, false),
            ("Library/Developer/CoreSimulator/Devices", "Xcode Simulators", .xcodeSimulator, .review, true),
            ("Library/Caches/com.apple.dt.Xcode", "Xcode Cache", .xcodeDerivedData, .safe, true),
        ]

        for (relativePath, name, category, risk, canRecreate) in xcodeArtifacts {
            let url = home.appendingPathComponent(relativePath)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let size = await systemScanner.directorySize(at: url)
            guard size > 100_000_000 else { continue }

            items.append(ScanItem(
                name: name,
                path: url,
                size: size,
                lastAccessed: nil,
                lastModified: nil,
                category: category,
                riskLevel: risk,
                canRecreate: canRecreate
            ))
        }

        return items
    }

    // MARK: - JVM (Gradle / Maven)

    private func scanGradleCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [home.appendingPathComponent(".gradle/caches")]
        return await scanCacheDirectories(paths: paths, name: "Gradle cache", category: .gradleCache, riskLevel: .safe)
    }

    private func scanMavenCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [home.appendingPathComponent(".m2/repository")]
        return await scanCacheDirectories(paths: paths, name: "Maven local repo", category: .mavenCache, riskLevel: .review)
    }

    // MARK: - Other languages

    private func scanCargoCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [
            home.appendingPathComponent(".cargo/registry"),
            home.appendingPathComponent(".cargo/git"),
        ]
        return await scanCacheDirectories(paths: paths, name: "Cargo cache", category: .cargoCache, riskLevel: .safe)
    }

    private func scanGemCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [
            home.appendingPathComponent(".gem"),
            home.appendingPathComponent("Library/Ruby/Gems"),
        ]
        return await scanCacheDirectories(paths: paths, name: "Ruby Gems cache", category: .gemCache, riskLevel: .review)
    }

    private func scanCocoaPodsCache() async -> [ScanItem] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [home.appendingPathComponent("Library/Caches/CocoaPods")]
        return await scanCacheDirectories(paths: paths, name: "CocoaPods cache", category: .cocoaPodsCache, riskLevel: .safe)
    }

    // MARK: - Build Artifacts

    private func scanBuildArtifacts() async -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        let searchPaths = [
            home.appendingPathComponent("Projects"),
            home.appendingPathComponent("Developer"),
            home.appendingPathComponent("Code"),
        ]

        let buildDirNames = ["dist", "build", ".next", ".nuxt", "out", ".output",
                              "target", ".build", "__pycache__", ".pytest_cache",
                              ".parcel-cache", ".turbo", ".cache"]

        for searchPath in searchPaths {
            guard FileManager.default.fileExists(atPath: searchPath.path) else { continue }
            for dirName in buildDirNames {
                let found = await findDirectories(named: dirName, under: searchPath, maxDepth: 5)
                for url in found {
                    let size = await systemScanner.directorySize(at: url)
                    guard size > 5_000_000 else { continue }
                    let projectName = url.deletingLastPathComponent().lastPathComponent
                    let attrs = try? url.resourceValues(forKeys: [.contentModificationDateKey])

                    items.append(ScanItem(
                        name: "\(dirName)/ (\(projectName))",
                        path: url,
                        size: size,
                        lastAccessed: nil,
                        lastModified: attrs?.contentModificationDate,
                        category: .buildArtifact,
                        riskLevel: .safe,
                        canRecreate: true
                    ))
                }
            }
        }

        return items
    }

    // MARK: - Helpers

    private func scanCacheDirectories(
        paths: [URL],
        name: String,
        category: ItemCategory,
        riskLevel: RiskLevel
    ) async -> [ScanItem] {
        for path in paths {
            guard FileManager.default.fileExists(atPath: path.path) else { continue }
            let size = await systemScanner.directorySize(at: path)
            guard size > 1_000_000 else { continue }

            return [ScanItem(
                name: name,
                path: path,
                size: size,
                lastAccessed: nil,
                lastModified: nil,
                category: category,
                riskLevel: riskLevel,
                canRecreate: true
            )]
        }
        return []
    }

    private func findDirectories(named name: String, under root: URL, maxDepth: Int) async -> [URL] {
        var results: [URL] = []
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        // Collect all URLs synchronously to avoid the async `makeIterator` restriction on actors
        var allURLs: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            allURLs.append(url)
        }

        for url in allURLs {
            // Limit depth
            let depth = url.pathComponents.count - root.pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == true,
                  url.lastPathComponent == name else { continue }

            results.append(url)
        }

        return results
    }

    private func isPythonVenv(at url: URL) -> Bool {
        let binPython = url.appendingPathComponent("bin/python")
        let binPython3 = url.appendingPathComponent("bin/python3")
        let cfgFile = url.appendingPathComponent("pyvenv.cfg")
        let fm = FileManager.default
        return fm.fileExists(atPath: binPython.path) ||
               fm.fileExists(atPath: binPython3.path) ||
               fm.fileExists(atPath: cfgFile.path)
    }
}
