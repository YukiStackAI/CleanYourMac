import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case dark = "Dark"
    case light = "Light"
    public var id: String { self.rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}
@MainActor
class AppState: ObservableObject {
    @Published var selectedSection: SidebarSection = .dashboard
    @Published var isScanning: Bool = false
    @Published var lastScanDate: Date?
    @Published var totalJunkFound: Int64 = 0
    @Published var scanResults: ScanResults = ScanResults()
    @Published var showPermissionPrompt: Bool = false
    @Published var scanProgress: Double = 0.0
    @Published var systemHealth: Int = 92
    let cleanerEngine = CleanerEngine()
    private let monitor = SystemMonitorService()
    private var timerTask: Task<Void, Never>?

    init() {
        startRealTimeMonitoring()
    }

    deinit {
        timerTask?.cancel()
    }

    func startRealTimeMonitoring() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                let score = await calculateHealthScore()
                self.systemHealth = score
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func runFullScan() async {
        isScanning = true
        scanProgress = 0.0
        scanResults = ScanResults()
        
        // Phase 1: System Scan
        let s = await SystemScanner().scan { @Sendable progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = progress * 0.5
            }
        }
        
        // Phase 2: Dev Scan
        let d = await DevScanner().scan { @Sendable progress in
            Task { @MainActor [weak self] in
                self?.scanProgress = 0.5 + (progress * 0.5)
            }
        }
        
        scanResults.systemItems = s
        scanResults.devItems = d
        scanResults.allItems = s + d
        totalJunkFound = scanResults.allItems.reduce(0) { $0 + $1.size }
        lastScanDate = Date()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        isScanning = false
        scanProgress = 0.0
    }

    func removeCleanedItems(ids: Set<UUID>, freedSize: Int64) {
        scanResults.systemItems.removeAll { ids.contains($0.id) }
        scanResults.devItems.removeAll { ids.contains($0.id) }
        scanResults.allItems.removeAll { ids.contains($0.id) }
        totalJunkFound = max(0, totalJunkFound - freedSize)
    }

    private func calculateHealthScore() async -> Int {
        let stats = await monitor.getStats()
        return max(0, min(100, 100 - (Int(stats.cpuUsage) + Int(stats.memoryPressure)) / 4))
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard = "SMART CARE"
    case systemJunk = "CLEANUP"
    case devCleaner = "DEV WORKSPACE"
    case aiPromptCleaner = "PROMPT CLEANER"
    case largeFiles = "LARGE FILES"
    case duplicates = "DUPLICATES"
    case appUninstaller = "UNINSTALLER"
    case startupItems = "STARTUP"
    case malwareScanner = "PROTECTION"
    case ramBooster = "PERFORMANCE"
    case spaceLens = "SPACE LENS"
    case privacyCleaner = "PRIVACY"
    case shredder = "SHREDDER"
    case maintenance = "MAINTENANCE"
    case networkMonitor = "NETWORK"
    case settings = "SETTINGS"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "sparkles"
        case .systemJunk: return "trash"
        case .devCleaner: return "terminal"
        case .aiPromptCleaner: return "wand.and.stars"
        case .largeFiles: return "archivebox"
        case .duplicates: return "doc.on.doc"
        case .appUninstaller: return "app.dashed"
        case .startupItems: return "bolt"
        case .malwareScanner: return "shield.checkered"
        case .ramBooster: return "cpu"
        case .spaceLens: return "square.3.layers.3d.down.right"
        case .privacyCleaner: return "shield.lefthalf.filled"
        case .shredder: return "scissors"
        case .maintenance: return "wrench.adjustable"
        case .networkMonitor: return "wifi"
        case .settings: return "gearshape.2"
        }
    }

    var themeColor: Color {
        switch self {
        case .dashboard: return Color.dcGreen // Emerald
        case .systemJunk: return Color(hex: "#10B981") // Emerald Green
        case .devCleaner: return Color(hex: "#34D399") // Medium Emerald
        case .aiPromptCleaner: return Color(hex: "#10B981") // Emerald Green
        case .largeFiles: return Color(hex: "#FB923C") // Warm Orange (keep for warning/size)
        case .duplicates: return Color.dcCyan // Cyan
        case .appUninstaller: return Color(hex: "#10B981") // Emerald Green
        case .startupItems: return Color(hex: "#FACC15") // Golden Yellow (keep for action)
        case .malwareScanner: return Color(hex: "#2DD4BF") // Teal
        case .ramBooster: return Color.dcCyan // Cyan
        case .spaceLens: return Color(hex: "#06B6D4") // Dark Cyan
        case .privacyCleaner: return Color(hex: "#10B981") // Emerald
        case .shredder: return Color(hex: "#EF4444") // Red (keep for destructive)
        case .maintenance: return Color.dcOrange // Amber (keep for warning)
        case .networkMonitor: return Color.dcGreen // Green
        case .settings: return Color(hex: "#94A3B8") // Slate (keep for neutral)
        }
    }
}

// MARK: - Design System

public enum ObsidianTheme {
    public static let background = Color.dcBackground  // OLED dark
    public static let surface   = Color.dcSurface   // Slightly elevated surface
    public static let text = Color.dcText
    public static let textSecondary = Color.dcSubtext
    public static let cornerRadius: CGFloat = 16

    public struct GlassCard: ViewModifier {
        let accentColor: Color
        public func body(content: Content) -> some View {
            content
                .background(Color.dcOverlay)
                .cornerRadius(ObsidianTheme.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: ObsidianTheme.cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.25), Color.dcOverlayLine],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        }
    }
}

public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .withinWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    public func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    public func obsidianCard(accent: Color = .dcOverlayLine) -> some View {
        self.modifier(ObsidianTheme.GlassCard(accentColor: accent))
    }
}
