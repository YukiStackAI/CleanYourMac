import Foundation

actor DiskSearcher {
    
    struct SearchCriteria {
        var extensions: Set<String> = []
        var folderNames: Set<String> = []
        var nameKeywords: Set<String> = []
        var sizeThreshold: Int64? = nil
        var targetSubfolders: [String] = []
    }
    
    func parsePrompt(_ prompt: String) -> SearchCriteria {
        let lower = prompt.lowercased()
        var criteria = SearchCriteria()
        
        // 1. Detect target subfolders if specified
        if lower.contains("downloads") { criteria.targetSubfolders.append("Downloads") }
        if lower.contains("documents") { criteria.targetSubfolders.append("Documents") }
        if lower.contains("desktop") { criteria.targetSubfolders.append("Desktop") }
        if lower.contains("developer") || lower.contains("projects") || lower.contains("code") {
            criteria.targetSubfolders.append("Developer")
            criteria.targetSubfolders.append("Projects")
            criteria.targetSubfolders.append("Code")
        }
        
        // Default target subfolders if none specified
        if criteria.targetSubfolders.isEmpty {
            criteria.targetSubfolders = ["Downloads", "Documents", "Desktop", "Developer", "Projects", "Code", "Library/Caches"]
        }
        
        // 2. Detect size
        if lower.contains("over") || lower.contains("greater") || lower.contains("larger") || lower.contains(">") || lower.contains("above") {
            if lower.contains("gb") || lower.contains("gigabyte") {
                if let num = extractNumber(from: lower, suffix: "gb") {
                    criteria.sizeThreshold = num * 1024 * 1024 * 1024
                } else {
                    criteria.sizeThreshold = 1024 * 1024 * 1024
                }
            } else if lower.contains("mb") || lower.contains("megabyte") {
                if let num = extractNumber(from: lower, suffix: "mb") {
                    criteria.sizeThreshold = num * 1024 * 1024
                } else {
                    criteria.sizeThreshold = 50 * 1024 * 1024
                }
            } else if lower.contains("kb") || lower.contains("kilobyte") {
                if let num = extractNumber(from: lower, suffix: "kb") {
                    criteria.sizeThreshold = num * 1024
                }
            }
        }
        
        // 3. Detect extensions
        let extensionKeywords = [
            ".log": "log", ".tmp": "tmp", ".temp": "temp", ".dmg": "dmg",
            ".pkg": "pkg", ".zip": "zip", ".tar": "tar", ".gz": "gz",
            ".cache": "cache"
        ]
        for (ext, keyword) in extensionKeywords {
            if lower.contains(keyword) {
                criteria.extensions.insert(ext.replacingOccurrences(of: ".", with: ""))
            }
        }
        
        // 4. Detect folder names
        let folderKeywords = [
            "node_modules": "node_modules", "node module": "node_modules", "node modules": "node_modules",
            "venv": "venv", ".venv": "venv", "virtualenv": "venv",
            "deriveddata": "DerivedData", "derived data": "DerivedData",
            "docker": "docker", "cache": "Caches", "caches": "Caches",
            "build": "build", "dist": "dist", "target": "target"
        ]
        for (keyword, folderName) in folderKeywords {
            if lower.contains(keyword) {
                criteria.folderNames.insert(folderName.lowercased())
            }
        }
        
        // 5. Name keywords - extract terms that might be search keywords
        let stopwords: Set<String> = [
            "find", "search", "show", "me", "all", "files", "folders", "related", "to",
            "in", "my", "on", "mac", "macintosh", "computer", "disk", "drive", "system",
            "over", "greater", "than", "larger", "above", "gb", "mb", "kb", "and", "or",
            "with", "named", "containing", "called", "that", "are", "have", "size",
            "delete", "remove", "clean", "clear", "any"
        ]
        let words = lower.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 && !stopwords.contains($0) }
        
        for word in words {
            criteria.nameKeywords.insert(word)
        }
        
        return criteria
    }
    
    private func extractNumber(from text: String, suffix: String) -> Int64? {
        let pattern = "(\\d+)\\s*\(suffix)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else {
            let digits = text.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
            if let first = digits.first, let val = Int64(first) {
                return val
            }
            return nil
        }
        if let range = Range(match.range(at: 1), in: text), let val = Int64(text[range]) {
            return val
        }
        return nil
    }
    
    func search(prompt: String, progress: (@Sendable (Double) -> Void)? = nil) async -> [ScanItem] {
        let criteria = parsePrompt(prompt)
        var results: [ScanItem] = []
        
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        
        let searchDirectories = criteria.targetSubfolders.map { home.appendingPathComponent($0) }
        let totalDirs = Double(searchDirectories.count)
        
        for (index, baseDir) in searchDirectories.enumerated() {
            guard fm.fileExists(atPath: baseDir.path) else { continue }
            
            let matched = await searchDirectory(baseDir, criteria: criteria, maxDepth: 4)
            results.append(contentsOf: matched)
            
            progress?(Double(index + 1) / totalDirs)
        }
        
        // De-duplicate results by path
        var uniqueResults: [ScanItem] = []
        var seenPaths = Set<String>()
        for item in results {
            if !seenPaths.contains(item.path.path) {
                seenPaths.insert(item.path.path)
                uniqueResults.append(item)
            }
        }
        
        // Sort by size descending
        return uniqueResults.sorted { $0.size > $1.size }
    }
    
    private func searchDirectory(_ root: URL, criteria: SearchCriteria, maxDepth: Int) async -> [ScanItem] {
        var matched: [ScanItem] = []
        let fm = FileManager.default
        
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentAccessDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        
        // Collect URLs to check
        var urlsToCheck: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            urlsToCheck.append(url)
            
            // Depth safeguard
            let depth = url.pathComponents.count - root.pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
            }
        }
        
        for url in urlsToCheck {
            guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentAccessDateKey, .contentModificationDateKey]) else {
                continue
            }
            
            let isDirectory = resourceValues.isDirectory ?? false
            let name = url.lastPathComponent
            let lowerName = name.lowercased()
            
            var isMatch = false
            var matchedCategory: ItemCategory = .tempFile
            var risk: RiskLevel = .safe
            
            // 1. Match folder names
            if isDirectory {
                if criteria.folderNames.contains(lowerName) {
                    isMatch = true
                    
                    if lowerName.contains("node_modules") {
                        matchedCategory = .nodeModules
                    } else if lowerName.contains("venv") {
                        matchedCategory = .pythonVenv
                    } else if lowerName.contains("deriveddata") {
                        matchedCategory = .xcodeDerivedData
                    } else if lowerName.contains("build") || lowerName.contains("dist") || lowerName.contains("target") {
                        matchedCategory = .buildArtifact
                    } else {
                        matchedCategory = .tempFile
                    }
                }
            } else {
                // 2. Match file extensions
                let pathExtension = url.pathExtension.lowercased()
                if criteria.extensions.contains(pathExtension) {
                    isMatch = true
                    matchedCategory = .tempFile
                }
            }
            
            // 3. Match name keywords
            if !isMatch && !criteria.nameKeywords.isEmpty {
                for keyword in criteria.nameKeywords {
                    if lowerName.contains(keyword) {
                        isMatch = true
                        break
                    }
                }
            }
            
            // 4. Filter by size if criteria specifies
            var size: Int64 = 0
            if isDirectory {
                size = await directorySize(at: url)
            } else {
                size = Int64(resourceValues.fileSize ?? 0)
            }
            
            if isMatch {
                if let minSize = criteria.sizeThreshold, size < minSize {
                    isMatch = false
                }
            }
            
            // Exclude empty sizes and dangerous files
            if isMatch && size > 0 && !url.path.contains("/System/") && !url.path.contains("/usr/") {
                if url.path.contains("Library/Caches") || matchedCategory == .xcodeDerivedData || matchedCategory == .nodeModules {
                    risk = .safe
                } else {
                    risk = .review
                }
                
                let explanation = "Matched prompt filter rule. Path: \(url.path)"
                
                matched.append(ScanItem(
                    name: isDirectory ? "\(name)/" : name,
                    path: url,
                    size: size,
                    lastAccessed: resourceValues.contentAccessDate,
                    lastModified: resourceValues.contentModificationDate,
                    category: matchedCategory,
                    riskLevel: risk,
                    canRecreate: isDirectory,
                    explanation: explanation
                ))
            }
        }
        
        return matched
    }
    
    private func directorySize(at url: URL) async -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        var allFiles: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            allFiles.append(fileURL)
        }
        for fileURL in allFiles {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
