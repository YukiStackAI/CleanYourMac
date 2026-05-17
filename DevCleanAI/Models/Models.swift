import Foundation
import SwiftUI

// MARK: - Scan Item (universal model for everything found)

struct ScanItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let lastAccessed: Date?
    let lastModified: Date?
    let category: ItemCategory
    let riskLevel: RiskLevel
    let canRecreate: Bool
    var isSelected: Bool = false
    var explanation: String? // LLM-generated

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var lastAccessedFormatted: String {
        guard let date = lastAccessed else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var ageInDays: Int? {
        guard let date = lastAccessed else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }
}

// MARK: - Categories

enum ItemCategory: String, CaseIterable {
    // System
    case appCache = "App Cache"
    case systemLog = "System Logs"
    case tempFile = "Temp Files"
    case browserCache = "Browser Cache"
    case mailAttachment = "Mail Attachments"
    case trashBin = "Trash"
    case languageFile = "Language Files"

    // Dev-specific
    case nodeModules = "node_modules"
    case npmCache = "npm Cache"
    case yarnCache = "Yarn Cache"
    case pnpmCache = "pnpm Cache"
    case pythonVenv = "Python Virtualenv"
    case pipCache = "pip Cache"
    case condaEnv = "Conda Environment"
    case dockerImage = "Docker Image"
    case dockerContainer = "Docker Container"
    case dockerBuildCache = "Docker Build Cache"
    case xcodeSimulator = "Xcode Simulator"
    case xcodeDerivedData = "Xcode DerivedData"
    case xcodeArchive = "Xcode Archive"
    case gradleCache = "Gradle Cache"
    case mavenCache = "Maven Cache"
    case cargoCache = "Cargo Cache"
    case gemCache = "Gem Cache"
    case cocoaPodsCache = "CocoaPods Cache"
    case buildArtifact = "Build Artifact"
    case unusedProject = "Unused Project"

    var icon: String {
        switch self {
        case .appCache, .browserCache: return "clock.arrow.circlepath"
        case .systemLog: return "doc.text"
        case .tempFile: return "doc.badge.clock"
        case .mailAttachment: return "paperclip"
        case .trashBin: return "trash"
        case .languageFile: return "globe"
        case .nodeModules, .npmCache, .yarnCache, .pnpmCache: return "shippingbox"
        case .pythonVenv, .pipCache, .condaEnv: return "terminal.fill"
        case .dockerImage, .dockerContainer, .dockerBuildCache: return "shippingbox.fill"
        case .xcodeSimulator, .xcodeDerivedData, .xcodeArchive: return "hammer.circle"
        case .gradleCache, .mavenCache: return "cup.and.saucer"
        case .cargoCache: return "gear"
        case .gemCache: return "diamond"
        case .cocoaPodsCache: return "circle.hexagonpath"
        case .buildArtifact: return "wrench.and.screwdriver"
        case .unusedProject: return "folder.badge.questionmark"
        }
    }

    var groupLabel: String {
        switch self {
        case .appCache, .systemLog, .tempFile, .browserCache,
             .mailAttachment, .trashBin, .languageFile:
            return "System"
        case .nodeModules, .npmCache, .yarnCache, .pnpmCache,
             .pythonVenv, .pipCache, .condaEnv:
            return "Node & Python"
        case .dockerImage, .dockerContainer, .dockerBuildCache:
            return "Docker"
        case .xcodeSimulator, .xcodeDerivedData, .xcodeArchive:
            return "Xcode"
        case .gradleCache, .mavenCache, .cargoCache, .gemCache,
             .cocoaPodsCache, .buildArtifact, .unusedProject:
            return "Other Dev"
        }
    }
}

// MARK: - Risk Level

enum RiskLevel: Int, Comparable {
    case safe = 0
    case review = 1
    case caution = 2
    case danger = 3

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .safe: return "Safe to delete"
        case .review: return "Review first"
        case .caution: return "Use caution"
        case .danger: return "Do not delete"
        }
    }

    var color: Color {
        switch self {
        case .safe: return .green
        case .review: return .yellow
        case .caution: return .orange
        case .danger: return .red
        }
    }

    var icon: String {
        switch self {
        case .safe: return "checkmark.shield.fill"
        case .review: return "eye.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.shield.fill"
        }
    }
}

// MARK: - Scan Results

struct ScanResults {
    var systemItems: [ScanItem] = []
    var devItems: [ScanItem] = []
    var allItems: [ScanItem] = []

    var totalSize: Int64 { allItems.reduce(0) { $0 + $1.size } }
    var safeItems: [ScanItem] { allItems.filter { $0.riskLevel == .safe } }
    var reviewItems: [ScanItem] { allItems.filter { $0.riskLevel == .review } }
    var safeSize: Int64 { safeItems.reduce(0) { $0 + $1.size } }

    var groupedByCategory: [ItemCategory: [ScanItem]] {
        Dictionary(grouping: allItems, by: \.category)
    }

    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Installed App

struct InstalledApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleID: String
    let path: URL
    let version: String
    let size: Int64
    let lastUsed: Date?
    var relatedFiles: [URL] = [] // Caches, prefs, support files

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool { lhs.id == rhs.id }
    var totalSize: Int64 { size + relatedFiles.reduce(0) { acc, url in
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? nil
        return acc + Int64(fileSize ?? 0)
    }}
}

// MARK: - Startup Item

struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let type: StartupItemType
    var isEnabled: Bool
    let description: String?
    var fileSize: Int64 = 0

    var fileSizeFormatted: String {
        fileSize > 0 ? ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file) : "—"
    }

    var isSystemItem: Bool {
        path.path.hasPrefix("/System/Library") || path.path.hasPrefix("/usr/")
    }

    enum StartupItemType: String {
        case loginItem  = "Login Item"
        case launchAgent  = "Launch Agent"
        case launchDaemon = "Launch Daemon"

        var icon: String {
            switch self {
            case .loginItem:    return "person.circle.fill"
            case .launchAgent:  return "gear.circle.fill"
            case .launchDaemon: return "server.rack"
            }
        }

        var tintColor: String {
            switch self {
            case .loginItem:    return "dcCyan"
            case .launchAgent:  return "dcGreen"
            case .launchDaemon: return "dcOrange"
            }
        }
    }
}


// MARK: - Maintenance Task
struct MaintenanceTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    var isRunning: Bool = false
    var lastRun: Date?
}
