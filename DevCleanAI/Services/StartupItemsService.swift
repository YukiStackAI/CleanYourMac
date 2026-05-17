import Foundation

actor StartupItemsService {

    // MARK: - Scan

    func scanStartupItems() async -> [StartupItem] {
        var items: [StartupItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        let searchPaths: [(URL, StartupItem.StartupItemType)] = [
            (home.appendingPathComponent("Library/LaunchAgents"),    .launchAgent),
            (URL(fileURLWithPath: "/Library/LaunchAgents"),          .launchAgent),
            (URL(fileURLWithPath: "/Library/LaunchDaemons"),         .launchDaemon),
            (URL(fileURLWithPath: "/System/Library/LaunchAgents"),   .launchAgent),
        ]

        for (path, type) in searchPaths {
            guard let plists = try? FileManager.default.contentsOfDirectory(
                at: path, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles
            ) else { continue }

            for plist in plists where plist.pathExtension == "plist" {
                if let item = parseStartupPlist(at: plist, type: type) {
                    items.append(item)
                }
            }
        }

        // Deduplicate by label
        var seen = Set<String>()
        items = items.filter { seen.insert($0.name).inserted }

        return items.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: - Parse plist

    private func parseStartupPlist(at url: URL, type: StartupItem.StartupItemType) -> StartupItem? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        let label = plist["Label"] as? String ?? url.deletingPathExtension().lastPathComponent
        let isDisabled = plist["Disabled"] as? Bool ?? false
        let programArgs = plist["ProgramArguments"] as? [String]
        let program = plist["Program"] as? String ?? programArgs?.first

        // Check live status via launchctl list
        let liveStatus = checkLiveStatus(label: label)
        let isEnabled: Bool
        if let live = liveStatus {
            isEnabled = live
        } else {
            isEnabled = !isDisabled
        }

        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map { Int64($0) } ?? 0

        return StartupItem(
            name: label,
            path: url,
            type: type,
            isEnabled: isEnabled,
            description: program.map { "Runs: \($0.components(separatedBy: "/").last ?? $0)" },
            fileSize: fileSize
        )
    }

    // Check if service is live in launchctl
    private func checkLiveStatus(label: String) -> Bool? {
        let output = runCommand("/bin/launchctl", args: ["list", label])
        if output.contains("Could not find service") || output.contains("No such process") {
            return false
        }
        if output.contains("\"Label\"") || output.contains(label) {
            return true
        }
        return nil
    }

    // MARK: - Enable / Disable

    func setEnabled(_ item: StartupItem, enabled: Bool) async throws {
        if enabled {
            // Try bootstrap first (macOS 12+), fall back to load
            let domain = item.type == .launchAgent
                ? "gui/\(getUID())"
                : "system"
            let result = runCommand("/bin/launchctl", args: ["bootstrap", domain, item.path.path])
            if result.contains("already bootstrapped") || result.isEmpty {
                return // success or already running
            }
            // fallback
            _ = runCommand("/bin/launchctl", args: ["load", "-w", item.path.path])
        } else {
            let domain = item.type == .launchAgent
                ? "gui/\(getUID())"
                : "system"
            let result = runCommand("/bin/launchctl", args: ["bootout", "\(domain)/\(item.name)"])
            if result.contains("No such process") || result.isEmpty {
                // Already stopped, just disable via plist
                _ = runCommand("/bin/launchctl", args: ["unload", "-w", item.path.path])
            }
        }
    }

    // MARK: - Remove (move to trash)

    func removeItem(_ item: StartupItem) async throws {
        // Disable first
        try? await setEnabled(item, enabled: false)
        // Move plist to trash
        try FileManager.default.trashItem(at: item.path, resultingItemURL: nil)
    }

    // MARK: - Helpers

    private func getUID() -> uid_t {
        return getuid()
    }

    @discardableResult
    private func runCommand(_ executable: String, args: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
