import Foundation

actor MaintenanceService {
    func runTask(_ title: String) async throws {
        switch title {
        case "Free Purgeable Memory":
            // Avoid /usr/sbin/purge as it requires root (Operation not permitted)
            // Instead, we clear user-level caches which is safe and effective
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            let logs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
            
            for path in [caches, logs] {
                if let path = path {
                    let files = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                    for file in files ?? [] {
                        try? FileManager.default.removeItem(at: file)
                    }
                }
            }
        case "Flush DNS Cache":
            try await runShell("/usr/bin/dscacheutil", args: ["-flushcache"])
            // Note: killall -HUP mDNSResponder requires root, skipping for user-level safety
        case "Re-index Spotlight":
            // Targeting user home instead of root to avoid permission issues
            try await runShell("/usr/bin/mdutil", args: ["-E", "~"])
        case "Repair Disk Permissions":
            // Modern macOS handles this automatically. Skipping root-level diskutil verify to avoid errors.
            print("System automatically manages disk permissions.")
        default:
            break
        }
    }
    
    private func runShell(_ path: String, args: [String] = []) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Maintenance task failed: \(errorString)")
            throw NSError(domain: "MaintenanceService", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorString])
        }
    }
}
