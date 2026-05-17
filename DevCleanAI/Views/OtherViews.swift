import SwiftUI
import Foundation
import Charts
import IOKit.ps
import CoreWLAN

// MARK: ─────────────────────────────────────────────────────────────────────
// EMBEDDED DESIGN SYSTEM  –  DevClean AI  –  OLED Dark + Liquid Glass Pro
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Spacing Tokens
private enum DS {
    static let radiusSM: CGFloat = 10
    static let radiusMD: CGFloat = 14
    static let radiusLG: CGFloat = 18
    static let radiusXL: CGFloat = 24
    static let gap: CGFloat      = 16
    static let gapLG: CGFloat    = 24
}

// MARK: - GlassCard
private struct GlassCardModifier: ViewModifier {
    var radius: CGFloat = 18
    var accent: Color = .dcGreen
    var opacity: Double = 0.04
    func body(content: Content) -> some View {
        content
            .background(Color.dcText.opacity(opacity))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(
                LinearGradient(colors: [accent.opacity(0.25), .dcBorder, .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                lineWidth: 0.5
            ))
    }
}

extension View {
    fileprivate func glassCard(radius: CGFloat = 18, accent: Color = .dcGreen, opacity: Double = 0.04) -> some View {
        modifier(GlassCardModifier(radius: radius, accent: accent, opacity: opacity))
    }
}

// MARK: - PageHeader
struct PageHeader: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color = .dcGreen
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(0.25), lineWidth: 0.5))
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.5), radius: 6)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Color.dcText)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.dcSubtext)
            }
            Spacer()
            trailing
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.dcOverlay)
        .overlay(alignment: .bottom) {
            Rectangle().fill(LinearGradient(colors: [accent.opacity(0.25), Color.dcOverlayLine, .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 0.5)
        }
    }
}

// MARK: - PremiumButton
private struct PremiumButton: View {
    let title: String
    var icon: String? = nil
    var style: Style = .filled
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var accent: Color = .dcGreen
    let action: () -> Void

    enum Style { case filled, ghost, destructive }
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.75)
                } else if let icon = icon {
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                }
                Text(isLoading ? "Working..." : title).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(style == .ghost ? accent : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Group {
                switch style {
                case .filled:
                    LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .destructive:
                    LinearGradient(colors: [.dcRed, .dcRed.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .ghost:
                    AnyView(accent.opacity(0.1))
                }
            })
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(style == .destructive ? .dcRed.opacity(0.3) : accent.opacity(0.3), lineWidth: 0.5))
            .shadow(color: (style == .destructive ? .dcRed : accent).opacity(isHovered ? 0.5 : 0.25), radius: isHovered ? 16 : 8)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .opacity(isDisabled ? 0.45 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .onHover { h in withAnimation(.spring(response: 0.22)) { isHovered = h } }
    }
}

// MARK: - SectionLabel
private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(Color.dcText.opacity(0.3))
            .kerning(1.2)
    }
}

// RowDivider moved to Components.swift

// MARK: - MetricTile
private struct MetricTile: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = .dcGreen
    var valueColor: Color = Color.dcText
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color).shadow(color: color.opacity(0.5), radius: 4)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(value).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(valueColor).lineLimit(1).minimumScaleFactor(0.65)
                Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.dcSubtext).kerning(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.dcText.opacity(isHovered ? 0.07 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(isHovered ? color.opacity(0.25) : .dcBorder, lineWidth: 0.5))
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        .onHover { h in isHovered = h }
    }
}

// PremiumToggleRow moved to Components.swift

// MARK: - SuccessOverlay
private struct SuccessOverlay: View {
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill").font(.system(size: 44)).foregroundStyle(.dcGreen).shadow(color: .dcGreen.opacity(0.5), radius: 16)
            Text(message).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.dcText)
        }
        .padding(36)
        .background(Color.dcOverlayLine)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.dcGreen.opacity(0.25), lineWidth: 0.5))
    }
}

// MARK: - SettingsSectionCard
private struct SettingsSectionCard<Content: View>: View {
    let title: String
    var accent: Color = .dcGreen
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: title)
            VStack(spacing: 0) { content }
                .glassCard(radius: 14, accent: accent)
        }
    }
}

// MARK: - SettingsMetaRow
private struct SettingsMetaRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color.dcText

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundStyle(.dcSubtext)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(valueColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - EmptyStateView (local)
private struct DSEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color = .dcGreen
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<2) { i in
                    Circle().stroke(accent.opacity(0.07 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(110 + i * 36), height: CGFloat(110 + i * 36))
                        .scaleEffect(pulse ? 1.05 : 0.97)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(Double(i) * 0.35), value: pulse)
                }
                ZStack {
                    Circle().fill(accent.opacity(0.1)).frame(width: 88, height: 88)
                    Image(systemName: icon).font(.system(size: 36, weight: .thin)).foregroundStyle(accent.opacity(0.7))
                }
            }
            .onAppear { pulse = true }

            VStack(spacing: 8) {
                Text(title).font(.system(size: 18, weight: .bold)).foregroundStyle(Color.dcText)
                Text(subtitle).font(.system(size: 13)).foregroundStyle(.dcSubtext).multilineTextAlignment(.center).frame(maxWidth: 300)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


// MARK: - System Monitor Service
actor SystemMonitorService {
    struct SystemStats {
        let cpuUsage: Double
        let memoryPressure: Double
        let diskAvailable: Int64
        let diskTotal: Int64
        let batteryLevel: Int
        let batteryTimeRemaining: String
        let networkName: String
        let networkSecurity: String
        let uploadSpeed: String
        let downloadSpeed: String
        let healthStatus: String
        let externalDrives: [String]
        
        // Professional UI Helpers
        var formattedAvailableDisk: String {
            ByteCountFormatter.string(fromByteCount: diskAvailable, countStyle: .file)
        }
        var formattedTotalDisk: String {
            ByteCountFormatter.string(fromByteCount: diskTotal, countStyle: .file)
        }
        var diskUsagePercent: Double {
            let used = Double(diskTotal - diskAvailable)
            return used / Double(diskTotal)
        }
        var memoryUsageStr: String { "\(Int(memoryPressure))%" }
        var cpuUsageStr: String { "\(Int(cpuUsage))%" }
        var batteryLevelStr: String { "\(batteryLevel)%" }
    }
    
    private var prevCPULoadInfo: host_cpu_load_info?
    private var prevNetworkBytes: (in: UInt64, out: UInt64)?
    private var lastUpdate: Date?

    func getStats() async -> SystemStats {
        let cpu = getCPUUsage()
        let memory = getMemoryPressure()
        let disk = getDiskStats()
        let battery = getBatteryStats()
        let network = getNetworkSpeeds()
        let external = getExternalDrives()
        
        let health = calculateHealth(cpu: cpu, mem: memory, battery: battery.level)
        
        return SystemStats(
            cpuUsage: cpu,
            memoryPressure: memory,
            diskAvailable: disk.available,
            diskTotal: disk.total,
            batteryLevel: battery.level,
            batteryTimeRemaining: battery.time,
            networkName: getNetworkName().name,
            networkSecurity: getNetworkName().security,
            uploadSpeed: network.up,
            downloadSpeed: network.down,
            healthStatus: health,
            externalDrives: external
        )
    }
    
    private func getCPUUsage() -> Double {
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var loadInfo = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        if let prev = prevCPULoadInfo {
            let user = Double(loadInfo.cpu_ticks.0 - prev.cpu_ticks.0)
            let sys = Double(loadInfo.cpu_ticks.1 - prev.cpu_ticks.1)
            let idle = Double(loadInfo.cpu_ticks.2 - prev.cpu_ticks.2)
            let nice = Double(loadInfo.cpu_ticks.3 - prev.cpu_ticks.3)
            let total = user + sys + idle + nice
            prevCPULoadInfo = loadInfo
            return total > 0 ? ((user + sys + nice) / total) * 100.0 : 0.0
        }
        
        prevCPULoadInfo = loadInfo
        return 0.0
    }
    
    private func getMemoryPressure() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            let active = Double(stats.active_count)
            let wired = Double(stats.wire_count)
            let inactive = Double(stats.inactive_count)
            let free = Double(stats.free_count)
            let total = active + wired + inactive + free
            return total > 0 ? ((active + wired) / total) * 100.0 : 0.0
        }
        return 0.0
    }
    
    private func getDiskStats() -> (available: Int64, total: Int64) {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            return (free, total)
        } catch {
            return (0, 0)
        }
    }
    
    private func getBatteryStats() -> (level: Int, time: String) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
                let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
                let level = Int(Double(currentCapacity) / Double(maxCapacity) * 100.0)
                let isCharging = description[kIOPSIsChargingKey] as? Bool ?? false
                let timeToEmpty = description[kIOPSTimeToEmptyKey] as? Int ?? 0
                if isCharging { return (level, "Charging") }
                else if timeToEmpty > 0 { return (level, "\(timeToEmpty / 60)h \(timeToEmpty % 60)m remaining") }
                else { return (level, "Calculating...") }
            }
        }
        return (0, "Unknown")
    }

    private func getNetworkSpeeds() -> (up: String, down: String) {
        var ifaddrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrs) == 0 else { return ("0 KB/s", "0 KB/s") }
        defer { freeifaddrs(ifaddrs) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ptr = ifaddrs
        while ptr != nil {
            let name = String(cString: ptr!.pointee.ifa_name)
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") { // Wi-Fi / Cell
                if let data = ptr?.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                    totalIn += UInt64(data.pointee.ifi_ibytes)
                    totalOut += UInt64(data.pointee.ifi_obytes)
                }
            }
            ptr = ptr?.pointee.ifa_next
        }

        let now = Date()
        let upStr: String
        let downStr: String

        if let last = prevNetworkBytes, let lastTime = lastUpdate {
            let interval = now.timeIntervalSince(lastTime)
            if interval > 0 {
                let downBytes = Double(totalIn - last.in) / interval
                let upBytes = Double(totalOut - last.out) / interval
                downStr = formatSpeed(bytes: downBytes)
                upStr = formatSpeed(bytes: upBytes)
            } else {
                downStr = "0 KB/s"; upStr = "0 KB/s"
            }
        } else {
            downStr = "0 KB/s"; upStr = "0 KB/s"
        }

        prevNetworkBytes = (totalIn, totalOut)
        lastUpdate = now
        return (upStr, downStr)
    }

    private func formatSpeed(bytes: Double) -> String {
        if bytes < 1024 { return String(format: "%.0f B/s", bytes) }
        else if bytes < 1024 * 1024 { return String(format: "%.1f KB/s", bytes / 1024) }
        else { return String(format: "%.1f MB/s", bytes / (1024 * 1024)) }
    }

    private func getExternalDrives() -> [String] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsRootFileSystemKey]
        guard let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) else { return [] }
        
        var names: [String] = []
        for url in urls {
            if let values = try? url.resourceValues(forKeys: Set(keys)) {
                let isRemovable = values.volumeIsRemovable ?? false
                let isRoot = values.volumeIsRootFileSystem ?? false
                
                if isRemovable && !isRoot {
                    names.append(values.volumeName ?? "External Drive")
                }
            }
        }
        return names
    }

    private func calculateHealth(cpu: Double, mem: Double, battery: Int) -> String {
        let score = (100 - cpu) * 0.3 + (100 - mem) * 0.4 + Double(battery) * 0.3
        if score > 80 { return "Excellent" }
        else if score > 60 { return "Good" }
        else if score > 40 { return "Fair" }
        else { return "Poor" }
    }

    private func getNetworkName() -> (name: String, security: String) {
        if let interface = CWWiFiClient.shared().interface() {
            let ssid = interface.ssid() ?? "Wi-Fi"
            let security: String
            switch interface.security() {
            case .wpa2Personal: security = "WPA2 Personal"
            case .wpa3Personal: security = "WPA3 Personal"
            case .none: security = "Open"
            default: security = "Secure"
            }
            return (ssid, security)
        }
        return ("Not Connected", "N/A")
    }
}


// MARK: - Duplicate Finder Models & Service
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let fileSize: Int64
    var files: [URL]
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct DuplicateFinderService {
    func findDuplicates(in directory: URL) async -> [DuplicateGroup] {
        var sizeMap: [Int64: [URL]] = [:]
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .isDirectoryKey]
        
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(keys))
                if resourceValues.isDirectory == true { continue }
                if let size = resourceValues.fileSize {
                    let size64 = Int64(size)
                    sizeMap[size64, default: []].append(fileURL)
                }
            } catch { continue }
        }
        
        var groups: [DuplicateGroup] = []
        for (size, files) in sizeMap where files.count > 1 {
            groups.append(DuplicateGroup(fileSize: size, files: files))
        }
        return groups.sorted { $0.fileSize > $1.fileSize }
    }
    
    func deleteFiles(_ urls: [URL]) async {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Extensions Service
struct ExtensionItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let type: ExtensionType
    var isEnabled: Bool
    
    enum ExtensionType: String {
        case safari = "Safari Extension"
        case system = "System Extension"
        case loginItem = "Login Item"
        case spotlight = "Spotlight Plugin"
    }
}

struct ExtensionsService {
    func scanExtensions() async -> [ExtensionItem] {
        var items: [ExtensionItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        
        // 1. Safari Extensions (Containers)
        let safariPath = home.appendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Safari/AppExtensions")
        if let contents = try? FileManager.default.contentsOfDirectory(at: safariPath, includingPropertiesForKeys: nil) {
            for url in contents {
                items.append(ExtensionItem(name: url.lastPathComponent, path: url, type: .safari, isEnabled: true))
            }
        }
        
        // 2. Spotlight Plugins
        let spotlightPaths = ["/Library/Spotlight", home.path + "/Library/Spotlight"]
        for path in spotlightPaths {
            if let contents = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil) {
                for url in contents {
                    items.append(ExtensionItem(name: url.lastPathComponent, path: url, type: .spotlight, isEnabled: true))
                }
            }
        }
        
        return items
    }
}

// MARK: - Privacy Cleaner Service
struct PrivacyCleanerService {
    func cleanSafari() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [
            "Library/Safari/History.db",
            "Library/Safari/Downloads.plist",
            "Library/Safari/LastSession.plist",
            "Library/Safari/LocalStorage"
        ]
        for path in paths {
            try? FileManager.default.removeItem(at: home.appendingPathComponent(path))
        }
    }
    
    func cleanChrome() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let paths = [
            "Library/Application Support/Google/Chrome/Default/History",
            "Library/Application Support/Google/Chrome/Default/Cookies",
            "Library/Application Support/Google/Chrome/Default/Cache"
        ]
        for path in paths {
            try? FileManager.default.removeItem(at: home.appendingPathComponent(path))
        }
    }
    
    func cleanRecentDocs() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = home.appendingPathComponent("Library/Recent")
        if let contents = try? FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil) {
            for url in contents {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

// MARK: - Startup Items View
struct StartupItemsView: View {
    @EnvironmentObject var appState: AppState
    @State private var items: [StartupItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var searchText = ""
    @State private var selectedFilter: StartupItem.StartupItemType? = nil
    @State private var confirmDeleteItem: StartupItem? = nil
    @State private var showDeleteConfirm = false
    @State private var toastMessage: String? = nil

    private let service = StartupItemsService()

    private var accent: Color { appState.selectedSection.themeColor }

    private var filteredItems: [StartupItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == nil || item.type == selectedFilter
            return matchesSearch && matchesFilter
        }
    }

    private var enabledCount: Int { items.filter { $0.isEnabled }.count }
    private var agentCount:   Int { items.filter { $0.type == .launchAgent }.count }
    private var daemonCount:  Int { items.filter { $0.type == .launchDaemon }.count }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "clock.badge.checkmark.fill",
                title: "Startup Items",
                subtitle: "Manage apps and services that launch at login",
                accent: accent
            )

            // ── Stat Strip ──────────────────────────────────────
            HStack(spacing: 0) {
                StartupStatPill(label: "TOTAL",   value: "\(items.count)",   color: accent)
                Divider().frame(height: 30).background(Color.dcOverlayLine)
                StartupStatPill(label: "ENABLED", value: "\(enabledCount)",  color: .dcGreen)
                Divider().frame(height: 30).background(Color.dcOverlayLine)
                StartupStatPill(label: "AGENTS",  value: "\(agentCount)",    color: .dcGreen)
                Divider().frame(height: 30).background(Color.dcOverlayLine)
                StartupStatPill(label: "DAEMONS", value: "\(daemonCount)",   color: .dcOrange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.dcSurface2)
            .overlay(Divider().background(Color.dcOverlayLine), alignment: .bottom)

            // ── Search + Filter Bar ──────────────────────────────
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.dcSubtext)
                    TextField("Search startup items...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(.dcText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.dcOverlay)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dcBorder, lineWidth: 0.5))

                // Type filter chips
                ForEach([nil, .launchAgent, .launchDaemon] as [StartupItem.StartupItemType?], id: \.self) { type in
                    StartupFilterChip(
                        label: type?.rawValue ?? "All",
                        isActive: selectedFilter == type,
                        color: accent
                    ) { selectedFilter = (selectedFilter == type && type != nil) ? nil : type }
                }

                Spacer()

                // Reload button
                Button(action: { Task { await reload() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(accent)
                        .padding(8)
                        .background(accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.dcBackground)
            .overlay(Divider().background(Color.dcOverlayLine), alignment: .bottom)

            // ── Content ─────────────────────────────────────────
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(accent)
                            .scaleEffect(1.3)
                        Text("Scanning startup items...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.dcSubtext)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if let err = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.dcOrange)
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.dcSubtext)
                            .multilineTextAlignment(.center)
                        Button("Retry") { Task { await reload() } }
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)

                } else if filteredItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: items.isEmpty ? "clock.badge.xmark" : "magnifyingglass")
                            .font(.system(size: 44, weight: .thin))
                            .foregroundStyle(accent.opacity(0.4))
                        Text(items.isEmpty ? "No startup items found" : "No results for \"\(searchText)\"")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.dcText)
                        Text(items.isEmpty
                             ? "Your system has no LaunchAgents or LaunchDaemons configured."
                             : "Try adjusting your search or filter.")
                            .font(.system(size: 12))
                            .foregroundStyle(.dcSubtext)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)

                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredItems) { item in
                                StartupItemRow(
                                    item: item,
                                    accent: accent,
                                    onToggle: { enabled in await handleToggle(item: item, enabled: enabled) },
                                    onDelete: { confirmDeleteItem = item; showDeleteConfirm = true }
                                )
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 12)
                    }
                }

                // Toast notification
                if let toast = toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Capsule())
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .confirmationDialog(
            "Remove Startup Item",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                if let item = confirmDeleteItem { Task { await handleDelete(item: item) } }
            }
            Button("Cancel", role: .cancel) { confirmDeleteItem = nil }
        } message: {
            Text("\"\(confirmDeleteItem?.name ?? "")\" will be moved to Trash and disabled. This cannot be undone.")
        }
        .task { await reload() }
    }

    // MARK: - Actions

    private func reload() async {
        withAnimation { isLoading = true; errorMessage = nil }
        items = await service.scanStartupItems()
        withAnimation { isLoading = false }
    }

    private func handleToggle(item: StartupItem, enabled: Bool) async {
        // Optimistic update
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx].isEnabled = enabled
        }
        do {
            try await service.setEnabled(item, enabled: enabled)
            showToast(enabled ? "✓ \(item.name) enabled" : "✓ \(item.name) disabled")
        } catch {
            // Revert on failure
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx].isEnabled = !enabled
            }
            showToast("⚠ Could not change \(item.name)")
        }
    }

    private func handleDelete(item: StartupItem) async {
        do {
            try await service.removeItem(item)
            withAnimation { items.removeAll { $0.id == item.id } }
            showToast("🗑 \(item.name) removed")
        } catch {
            showToast("⚠ Could not remove \(item.name)")
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.3)) { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Startup Stat Pill
private struct StartupStatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8.5, weight: .black))
                .foregroundStyle(.dcSubtext)
                .kerning(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Chip
private struct StartupFilterChip: View {
    let label: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isActive ? color : .dcSubtext)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? color.opacity(0.12) : Color.dcOverlay)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isActive ? color.opacity(0.35) : Color.dcBorder, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Startup Item Row
struct StartupItemRow: View {
    let item: StartupItem
    let accent: Color
    let onToggle: (Bool) async -> Void
    let onDelete: () -> Void

    @State private var isEnabled: Bool
    @State private var isHovered = false
    @State private var isTogglingInProgress = false

    init(item: StartupItem, accent: Color, onToggle: @escaping (Bool) async -> Void, onDelete: @escaping () -> Void) {
        self.item = item; self.accent = accent; self.onToggle = onToggle; self.onDelete = onDelete
        _isEnabled = State(initialValue: item.isEnabled)
    }

    private var typeColor: Color {
        switch item.type {
        case .loginItem:    return .dcCyan
        case .launchAgent:  return .dcGreen
        case .launchDaemon: return .dcOrange
        }
    }

    var body: some View {
        HStack(spacing: 14) {

            // Type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(typeColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: item.type.icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(typeColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.dcText)
                        .lineLimit(1)
                    if item.isSystemItem {
                        Text("SYSTEM")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.dcSubtext)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.dcOverlayLine)
                            .clipShape(Capsule())
                    }
                }
                if let desc = item.description {
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundStyle(.dcSubtext)
                        .lineLimit(1)
                }
            }

            Spacer()

            // File size
            if item.fileSize > 0 {
                Text(item.fileSizeFormatted)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.dcSubtext)
            }

            // Type badge
            Text(item.type.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(typeColor)
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(typeColor.opacity(0.1))
                .clipShape(Capsule())

            // Toggle
            if isTogglingInProgress {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 28, height: 28)
            } else {
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: accent))
                    .labelsHidden()
                    .onChange(of: isEnabled) { _, newValue in
                        isTogglingInProgress = true
                        Task {
                            await onToggle(newValue)
                            isTogglingInProgress = false
                        }
                    }
            }

            // Delete button (only on hover, not system items)
            if isHovered && !item.isSystemItem {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.dcRed)
                        .padding(7)
                        .background(Color.dcRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(0.8)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.dcOverlay : Color.dcSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEnabled ? accent.opacity(0.15) : Color.dcBorder, lineWidth: 0.5)
                )
        )
        .opacity(isEnabled ? 1.0 : 0.65)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
        .animation(.spring(response: 0.2), value: isHovered)
        .onHover { h in withAnimation { isHovered = h } }
    }
}

// MARK: - Large Files View
struct LargeFilesView: View {
    @EnvironmentObject var appState: AppState
    @State private var files: [ScanItem] = []
    @State private var isScanning = false
    @State private var minSize: Double = 500
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "internaldrive",
                title: "Large Files",
                subtitle: "Locate and manage massive files consuming your disk space",
                accent: appState.selectedSection.themeColor
            )
            
            // Filter Header
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minimum Size Threshold").font(.system(size: 12, weight: .semibold)).foregroundStyle(.dcSubtext)
                        Text("\(Int(minSize)) MB").font(.system(size: 24, weight: .bold)).foregroundStyle(Color.dcText)
                    }
                    Spacer()
                    Button(action: { Task { await scan() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: isScanning ? "stop.fill" : "sparkles")
                            Text(isScanning ? "Scanning..." : "Start Scan")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(isScanning ? Color.dcOverlayLine : appState.selectedSection.themeColor)
                        .foregroundStyle(isScanning ? .dcText.opacity(0.5) : .white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isScanning)
                }
                
                Slider(value: $minSize, in: 100...5000, step: 100)
                    .accentColor(appState.selectedSection.themeColor)
            }
            .padding(24)
            .background(Color.dcSurface2)
            
            Divider().background(Color.dcOverlayLine)
            
            if isScanning {
                VStack(spacing: 24) {
                    ProgressView().tint(appState.selectedSection.themeColor).scaleEffect(1.5)
                    Text("Searching for high-density files...").font(.system(size: 13, weight: .medium)).foregroundStyle(.dcSubtext)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if files.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(appState.selectedSection.themeColor.opacity(0.3))
                    Text("No large files found").font(.system(size: 14, weight: .medium)).foregroundStyle(.dcSubtext)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(files) { file in
                            HStack(spacing: 16) {
                                Image(systemName: "doc")
                                    .foregroundStyle(appState.selectedSection.themeColor)
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.dcText)
                                    Text(file.path.deletingLastPathComponent().path).font(.system(size: 11)).foregroundStyle(ObsidianTheme.textSecondary).lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(file.sizeFormatted).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.dcText)
                                    Button(action: { NSWorkspace.shared.activateFileViewerSelecting([file.path]) }) {
                                        Text("Locate").font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 10).padding(.vertical, 4)
                                            .background(Color.dcOverlayLine)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(14)
                            .obsidianCard(accent: appState.selectedSection.themeColor)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private func scan() async {
        isScanning = true
        let minBytes = Int64(minSize) * 1_048_576
        var results: [ScanItem] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard let enumerator = FileManager.default.enumerator(at: home, includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { isScanning = false; return }
        
        var allURLs: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            allURLs.append(url)
        }
        
        for url in allURLs {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true, let size = values.fileSize, Int64(size) >= minBytes else { continue }
            results.append(ScanItem(name: url.lastPathComponent, path: url, size: Int64(size), lastAccessed: nil, lastModified: nil, category: .buildArtifact, riskLevel: .review, canRecreate: false))
        }
        files = results.sorted { $0.size > $1.size }
        isScanning = false
    }
}

// MARK: - Duplicates & Extensions Placeholders
struct DuplicatesView: View {
    @EnvironmentObject var appState: AppState
    @State private var groups: [DuplicateGroup] = []
    @State private var isScanning = false
    @State private var scanComplete = false
    @State private var selectedUrls: Set<URL> = []
    @State private var showDeleteConfirmation = false
    private let service = DuplicateFinderService()

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "doc.on.doc",
                title: "Duplicate Finder",
                subtitle: "Locate and reclaim space from redundant file copies across your system",
                accent: appState.selectedSection.themeColor
            )

            if isScanning {
                VStack(spacing: 48) {
                    ZStack {
                        Circle()
                            .stroke(appState.selectedSection.themeColor.opacity(0.1), lineWidth: 4)
                            .frame(width: 220, height: 220)
                        
                        PulseRings(accent: appState.selectedSection.themeColor)
                        
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(appState.selectedSection.themeColor)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Analyzing Redundancy").font(.system(size: 20, weight: .semibold)).foregroundStyle(Color.dcText)
                        Text("Mapping file signatures and size clusters...").font(.system(size: 13)).foregroundStyle(.dcSubtext)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if scanComplete {
                if groups.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(appState.selectedSection.themeColor)
                        Text("No Duplicates Found").font(.system(size: 18, weight: .medium)).foregroundStyle(Color.dcText)
                        Button("Rescan") { Task { await runScan() } }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24).padding(.vertical, 10)
                            .background(Color.dcOverlayLine)
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(groups.count) Duplicate Groups").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.dcText)
                                Text("\(selectedUrls.count) files selected for removal").font(.system(size: 12)).foregroundStyle(ObsidianTheme.textSecondary)
                            }
                            Spacer()
                            
                            HStack(spacing: 12) {
                                Button(action: { selectedUrls = Set(groups.flatMap { $0.files }) }) {
                                    Text("Select All").font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color.dcOverlayLine)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { selectedUrls.removeAll() }) {
                                    Text("Unselect All").font(.system(size: 11, weight: .semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Color.dcOverlayLine)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Divider().frame(height: 20).background(Color.dcOverlayLine)
                                
                                Button(action: { showDeleteConfirmation = true }) {
                                    Text("Clean Selected")
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(selectedUrls.isEmpty ? Color.dcOverlayLine : Color.red)
                                        .foregroundStyle(selectedUrls.isEmpty ? .dcText.opacity(0.3) : .white)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedUrls.isEmpty)
                            }
                        }
                        .padding(24)
                        .background(Color.dcSurface2)

                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(groups) { group in
                                    DuplicateGroupCard(group: group, selectedUrls: $selectedUrls, accent: appState.selectedSection.themeColor)
                                }
                            }
                            .padding(24)
                        }
                    }
                }
            } else {
                VStack(spacing: 40) {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(appState.selectedSection.themeColor.opacity(0.4))
                    
                    Text("Ready to scan for duplicates.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.dcSubtext)
                    
                    Button(action: { Task { await runScan() } }) {
                        Text("Start Deep Scan")
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 32).padding(.vertical, 14)
                            .background(appState.selectedSection.themeColor)
                            .foregroundStyle(Color.dcText)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .confirmationDialog("Remove Duplicates?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove Selected Files", role: .destructive) { Task { await deleteSelected() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the selected duplicate files. The originals will be preserved.")
        }
    }

    private func runScan() async {
        isScanning = true
        scanComplete = false
        // For demo, scan Downloads folder
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        groups = await service.findDuplicates(in: downloads)
        
        // Auto-select all but the first file in each group
        selectedUrls = Set(groups.flatMap { Array($0.files.dropFirst()) })
        
        isScanning = false
        scanComplete = true
    }

    private func deleteSelected() async {
        await service.deleteFiles(Array(selectedUrls))
        // Refresh local state
        for i in 0..<groups.count {
            groups[i].files.removeAll { selectedUrls.contains($0) }
        }
        groups.removeAll { $0.files.count <= 1 }
        selectedUrls.removeAll()
        showDeleteConfirmation = false
    }
}

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    @Binding var selectedUrls: Set<URL>
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.files.first?.lastPathComponent ?? "Unknown File")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dcText)
                    Text(group.sizeFormatted)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(accent)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { for url in group.files { selectedUrls.insert(url) } }) {
                        Text("All").font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.dcOverlayLine)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { for url in group.files { selectedUrls.remove(url) } }) {
                        Text("None").font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.dcOverlayLine)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(spacing: 1) {
                ForEach(group.files, id: \.self) { url in
                    HStack(spacing: 12) {
                        Toggle("", isOn: Binding(
                            get: { selectedUrls.contains(url) },
                            set: { isSelected in
                                if isSelected { selectedUrls.insert(url) }
                                else { selectedUrls.remove(url) }
                            }
                        ))
                        .toggleStyle(CheckboxToggleStyle(accent: accent))
                        .labelsHidden()
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.path).font(.system(size: 10)).foregroundStyle(ObsidianTheme.textSecondary).lineLimit(1)
                            Text("Created: \(url.creationDateString)").font(.system(size: 9)).foregroundStyle(ObsidianTheme.textSecondary.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: { NSWorkspace.shared.activateFileViewerSelecting([url]) }) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.dcText.opacity(0.4))
                                .onHover { hovering in
                                    // Visual feedback can be added here if needed
                                }
                        }
                        .buttonStyle(.plain)
                        .help("Reveal in Finder")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color.dcText.opacity(selectedUrls.contains(url) ? 0.05 : 0.02))
                }
            }
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dcOverlayLine, lineWidth: 1))
        }
        .padding(16)
        .obsidianCard(accent: accent)
    }
}

extension URL {
    var creationDateString: String {
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.path)
        if let date = attributes?[.creationDate] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return "Unknown"
    }
}

struct PulseRings: View {
    let accent: Color
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(accent.opacity(0.2), lineWidth: 2)
                    .scaleEffect(animate ? 1.5 : 0.8)
                    .opacity(animate ? 0 : 0.5)
                    .animation(Animation.easeOut(duration: 2).repeatForever(autoreverses: false).delay(Double(i) * 0.6), value: animate)
            }
        }
        .onAppear { animate = true }
    }
}

struct ExtensionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var items: [ExtensionItem] = []
    @State private var isLoading = true
    private let service = ExtensionsService()
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView().tint(appState.selectedSection.themeColor).scaleEffect(1.2)
                    Text("Scanning extensions...").font(.system(size: 13, weight: .medium)).foregroundStyle(ObsidianTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.system(size: 48))
                        .foregroundStyle(appState.selectedSection.themeColor.opacity(0.3))
                    Text("No plugins or extensions detected").font(.system(size: 14, weight: .medium)).foregroundStyle(ObsidianTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { item in
                            ExtensionRow(item: item, accent: appState.selectedSection.themeColor)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .task { items = await service.scanExtensions(); isLoading = false }
    }
}

struct ExtensionRow: View {
    let item: ExtensionItem
    let accent: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(accent.opacity(0.1)).frame(width: 32, height: 32)
                Image(systemName: "puzzlepiece.fill").font(.system(size: 14)).foregroundStyle(accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.dcText)
                Text(item.type.rawValue).font(.system(size: 10)).foregroundStyle(ObsidianTheme.textSecondary)
            }
            
            Spacer()
            
            Button(action: { NSWorkspace.shared.activateFileViewerSelecting([item.path]) }) {
                Image(systemName: "folder").font(.system(size: 14)).foregroundStyle(ObsidianTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Show in Finder")
        }
        .padding(14)
        .obsidianCard(accent: accent)
    }
}

struct PlaceholderModule: View {
    let title: String
    let subtitle: String
    let icon: String
    let status: String
    let accent: Color
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(accent.opacity(0.3))
            
            VStack(spacing: 12) {
                Text(title).font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.dcText)
                Text(subtitle).font(.system(size: 14)).foregroundStyle(ObsidianTheme.textSecondary)
            }
            
            Text(status)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(accent.opacity(0.1))
                .foregroundStyle(accent)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Privacy Cleaner View
struct PrivacyCleanerView: View {
    @EnvironmentObject var appState: AppState
    @State private var safariHistory = true
    @State private var chromeHistory = true
    @State private var recentDocs = true
    @State private var isCleaning = false
    @State private var showSuccess = false
    private let service = PrivacyCleanerService()

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                icon: "hand.raised.fill",
                title: "Privacy Cleaner",
                subtitle: "Remove browser traces and system footprints",
                accent: appState.selectedSection.themeColor
            )

            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Browser Traces
                        SettingsSectionCard(title: "BROWSER TRACES", accent: appState.selectedSection.themeColor) {
                            VStack(spacing: 0) {
                                PremiumToggleRow(label: "Safari History & Cache", subtitle: "Cookies, history, session data", icon: "safari", iconColor: .dcCyan, accent: appState.selectedSection.themeColor, isOn: $safariHistory)
                                RowDivider()
                                PremiumToggleRow(label: "Chrome Artifacts", subtitle: "History, cookies, cache files", icon: "globe", iconColor: .dcGreen, accent: appState.selectedSection.themeColor, isOn: $chromeHistory)
                            }
                        }

                        // System Footprint
                        SettingsSectionCard(title: "SYSTEM FOOTPRINT", accent: appState.selectedSection.themeColor) {
                            PremiumToggleRow(label: "Recent Documents Index", subtitle: "Clears Open Recent lists", icon: "doc.text", iconColor: .dcOrange, accent: appState.selectedSection.themeColor, isOn: $recentDocs)
                        }

                        // Action
                        PremiumButton(
                            title: "Purge Selected Traces",
                            icon: "flame.fill",
                            style: .destructive,
                            isLoading: isCleaning,
                            accent: .dcRed
                        ) { Task { await runClean() } }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(24)
                    .padding(.bottom, 32)
                }
                .blur(radius: showSuccess ? 12 : 0)

                if showSuccess {
                    SuccessOverlay(message: "Privacy Traces Purged")
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showSuccess = false }
                            }
                        }
                }
            }
        }
    }

    private func runClean() async {
        isCleaning = true
        if safariHistory { await service.cleanSafari() }
        if chromeHistory { await service.cleanChrome() }
        if recentDocs { await service.cleanRecentDocs() }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isCleaning = false
        withAnimation { showSuccess = true }
    }
}

struct PrivacyToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    let icon: String
    let color: Color
    let accent: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundStyle(color).font(.system(size: 18, weight: .medium)).frame(width: 24)
            Text(label).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.dcText)
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(CheckboxToggleStyle(accent: accent)).labelsHidden()
        }
        .padding(14)
        .obsidianCard(accent: accent)
    }
}

// SettingsView has been moved to Views/Settings/SettingsView.swift

// SettingsSectionCard defined privately above


// SettingsMetaRow defined privately above


struct MetadataRow: View {
    let label: String
    let value: String
    var isAccent: Bool = false
    var accent: Color = .dcGreen
    
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(ObsidianTheme.textSecondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundStyle(isAccent ? accent : .dcText)
        }
    }
}

// MARK: - Futuristic Cyber-HUD Stat Card
// MARK: - Menu Bar Bento Tile (square icon card)
private struct MB_BentoTile: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon Badge
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accent.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .padding(.bottom, 12)
            
            Spacer(minLength: 4)
            
            // Value
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(Color.dcText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.bottom, 2)
            
            // Label
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.dcSubtext)
                .kerning(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 108)
        .background(
            ZStack {
                Color.dcSurface
                LinearGradient(
                    colors: [accent.opacity(0.06), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.18), lineWidth: 0.5)
        )
    }
}

// MARK: - Menu Bar Health Arc
private struct MB_HealthArc: View {
    let score: Int
    let color: Color
    let label: String

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(.dcBorder, lineWidth: 6)
            // Fill
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    LinearGradient(colors: [color.opacity(0.6), color],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            // Center text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.dcText)
                Text("%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.dcSubtext)
            }
        }
        .frame(width: 68, height: 68)
    }
}

// MARK: - Menu Bar Speed Chip
private struct MB_SpeedChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.dcSubtext)
                    .kerning(0.5)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.dcText)
            }
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 9)
        .background(Color.dcSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.18), lineWidth: 0.5))
    }
}

// MARK: - ProStatRow (kept for compatibility)
struct ProStatRow: View {
    let title: String
    let value: String
    let icon: String
    var accent: Color = .dcGreen

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.dcSubtext)
                    .kerning(0.8)
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dcText)
            }
            Spacer()
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(Color.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dcOverlayLine, lineWidth: 0.5))
    }
}

// MARK: - Menu Bar Storage Card
struct ProStorageCard: View {
    let stats: SystemMonitorService.SystemStats?
    let onClean: () -> Void
    let isCleaning: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Macintosh HD")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.dcText)
                    Text("\(stats?.formattedAvailableDisk ?? "— GB") Free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.dcGreen)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.dcGreen.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.dcGreen)
                }
            }

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.dcOverlayLine)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.dcGreen, .dcCyan],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * (stats?.diskUsagePercent ?? 0.5))
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("System Data")
                    Spacer()
                    Text(stats?.formattedTotalDisk ?? "0 GB")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.dcSubtext)
            }

            Button(action: onClean) {
                HStack(spacing: 8) {
                    if isCleaning {
                        ProgressView().scaleEffect(0.55).tint(Color.dcText)
                    } else {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                    }
                    Text(isCleaning ? "OPTIMIZING..." : "DEEP CLEAN SYSTEM")
                        .font(.system(size: 11, weight: .black))
                        .kerning(0.5)
                }
                .foregroundStyle(Color.dcText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isCleaning {
                            Color.dcOverlayLine
                        } else {
                            LinearGradient(
                                colors: [.dcGreen, .dcCyan],
                                startPoint: .leading, endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(isCleaning ? 0.6 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isCleaning)
        }
        .padding(16)
        .background(Color.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.dcBorder, lineWidth: 0.5))
    }
}

// MARK: - Health Core (static ring, no pulse)
struct HealthCoreView: View {
    let stats: SystemMonitorService.SystemStats?

    private var healthScore: Int {
        guard let s = stats else { return 92 }
        let cpu = Int(s.cpuUsage)
        let mem = Int(s.memoryPressure)
        return max(0, min(100, 100 - (cpu + mem) / 4))
    }

    private var ringColor: Color {
        healthScore > 75 ? .dcGreen : healthScore > 50 ? .dcOrange : .dcRed
    }

    private var statusText: String {
        healthScore > 75 ? "SYSTEM HEALTHY" : healthScore > 50 ? "NEEDS ATTENTION" : "ACTION REQUIRED"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Static ring
            ZStack {
                Circle()
                    .stroke(Color.dcOverlayLine, lineWidth: 5)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: CGFloat(healthScore) / 100)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: -1) {
                    Text("\(healthScore)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(Color.dcText)
                    Text("%")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.dcSubtext)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(statusText)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(ringColor)
                    .kerning(0.6)
                Text("All sectors optimized")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.dcSubtext)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dcOverlayLine, lineWidth: 0.5))
    }
}

// MARK: - Menu Bar Popup (Premium Bento Design)
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var stats: SystemMonitorService.SystemStats?
    @State private var isPurging = false

    private let monitor = SystemMonitorService()
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    // Computed helpers
    private var healthScore: Int {
        appState.systemHealth
    }
    private var healthColor: Color {
        healthScore > 75 ? .dcGreen : healthScore > 50 ? .dcOrange : .dcRed
    }
    private var statusLabel: String {
        healthScore > 75 ? "System Healthy" : healthScore > 50 ? "Needs Attention" : "Action Required"
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Premium Gradient Header ───────────────────────────
            ZStack(alignment: .bottom) {
                // Background gradient wash - shifted to green/white
                LinearGradient(
                    colors: [.dcGreen.opacity(0.08), Color.dcSurface],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 80)

                HStack(spacing: 12) {
                    // App icon - Now using the Owl logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.dcGreen, .dcCyan],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 40, height: 40)
                            .shadow(color: .dcGreen.opacity(0.3), radius: 10, y: 4)
                        
                        Image("owl")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(6)
                            .frame(width: 40, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CleanYourMac")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.dcText)
                        HStack(spacing: 5) {
                            Text("PLATINUM")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(.dcGreen)
                                .kerning(1.5)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(.dcGreen.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text("v2.0")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.dcSubtext)
                        }
                    }

                    Spacer()

                    // Live badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(healthColor)
                            .frame(width: 5, height: 5)
                            .shadow(color: healthColor, radius: 3)
                        Text("LIVE")
                            .font(.system(size: 7.5, weight: .black))
                            .foregroundStyle(healthColor)
                            .kerning(1)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(healthColor.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(healthColor.opacity(0.25), lineWidth: 0.5))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.dcOverlayLine).frame(height: 0.5)
            }

            // ── Scrollable Content ───────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {

                    // ── Health + Status Card ─────────────────────
                    HStack(spacing: 12) {
                        MB_HealthArc(score: healthScore, color: healthColor, label: statusLabel)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(statusLabel)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(healthColor)
                                .kerning(0.3)
                            Text("Health score based on\nlive CPU & memory data")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.dcSubtext)
                                .lineSpacing(2)
                            // Mini score bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.dcOverlayLine)
                                    Capsule()
                                        .fill(healthColor)
                                        .frame(width: geo.size.width * CGFloat(healthScore) / 100)
                                }
                            }
                            .frame(height: 4)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.dcSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(healthColor.opacity(0.15), lineWidth: 0.5))

                    // ── 2×2 Bento Stat Grid ──────────────────────
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        MB_BentoTile(
                            icon: "cpu.fill",
                            label: "CPU",
                            value: stats?.cpuUsageStr ?? "—",
                            accent: .dcGreen
                        )
                        MB_BentoTile(
                            icon: "memorychip.fill",
                            label: "MEMORY",
                            value: stats?.memoryUsageStr ?? "—",
                            accent: .dcCyan
                        )
                        MB_BentoTile(
                            icon: "internaldrive.fill",
                            label: "FREE DISK",
                            value: stats?.formattedAvailableDisk ?? "—",
                            accent: .dcGreen
                        )
                        MB_BentoTile(
                            icon: "wifi",
                            label: "NETWORK",
                            value: stats?.networkName ?? "—",
                            accent: .dcCyan
                        )
                    }

                    // ── Storage Bar Card ────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 7) {
                                Image(systemName: "internaldrive.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.dcGreen)
                                Text("Macintosh HD")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.dcText)
                            }
                            Spacer()
                            Text("\(stats?.formattedAvailableDisk ?? "—") free of \(stats?.formattedTotalDisk ?? "—")")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.dcSubtext)
                        }
                        // Progress track
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.dcOverlayLine)
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [.dcGreen, .dcCyan],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: geo.size.width * (stats?.diskUsagePercent ?? 0.5))
                            }
                        }
                        .frame(height: 7)
                        .clipShape(Capsule())

                        // Deep Clean button
                        Button(action: { runPurge() }) {
                            HStack(spacing: 8) {
                                if isPurging {
                                    ProgressView().scaleEffect(0.55).tint(Color.dcText)
                                } else {
                                    Image(systemName: "bolt.shield.fill")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                Text(isPurging ? "OPTIMIZING..." : "DEEP CLEAN SYSTEM")
                                    .font(.system(size: 10.5, weight: .black))
                                    .kerning(0.4)
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                Group {
                                    if isPurging {
                                        Color.dcBorder
                                    } else {
                                        LinearGradient(
                                            colors: [Color.dcGreen, Color.dcCyan],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .dcGreen.opacity(isPurging ? 0 : 0.3), radius: 8, y: 4)
                            .opacity(isPurging ? 0.6 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPurging)
                    }
                    .padding(14)
                    .background(Color.dcSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.dcGreen.opacity(0.12), lineWidth: 0.5))

                    // ── Network Speed Chips ─────────────────────
                    HStack(spacing: 8) {
                        MB_SpeedChip(
                            icon: "arrow.down.circle.fill",
                            label: "DOWNLOAD",
                            value: stats?.downloadSpeed ?? "0 KB/s",
                            color: .dcGreen
                        )
                        MB_SpeedChip(
                            icon: "arrow.up.circle.fill",
                            label: "UPLOAD",
                            value: stats?.uploadSpeed ?? "0 KB/s",
                            color: .dcCyan
                        )
                    }
                }
                .padding(12)
                .padding(.bottom, 4)
            }

            // ── Premium Launch Button ─────────────────────────────
            VStack(spacing: 0) {
                Rectangle().fill(Color.dcOverlayLine).frame(height: 0.5)
                
                Button(action: { openMainApp() }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.dcGreen, .dcCyan],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 32, height: 32)
                                .shadow(color: .dcGreen.opacity(0.35), radius: 6, y: 2)
                            
                            Image(systemName: "gauge.with.needle.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("OPEN DASHBOARD")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.dcText)
                                .kerning(1.0)
                            Text("Access deep system cleaning tools")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.dcSubtext)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.dcOverlayLine)
                                .frame(width: 22, height: 22)
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.dcGreen)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(Color.dcSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.dcGreen.opacity(0.25), .dcCyan.opacity(0.12)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: .dcGreen.opacity(0.06), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.dcSurface)
            }
        }
        .frame(width: 310, height: 540)
        .background(Color.dcSurface)
        .preferredColorScheme(.light)
        .onReceive(timer) { _ in Task { stats = await monitor.getStats() } }
        .task { stats = await monitor.getStats() }
    }

    private func runPurge() {
        isPurging = true
        Task {
            try? await MaintenanceService().runTask("Free Purgeable Memory")
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isPurging = false
        }
    }

    @MainActor private func openMainApp() {
        let mainWindow = NSApp.windows.first { window in
            window.canBecomeKey && !(window is NSPanel) && window.frame.width >= 500
        }
        
        if let window = mainWindow {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        } else {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}








struct StorageLabel: View {
    let color: Color
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundStyle(.dcText.opacity(0.4))
            Text(value).font(.system(size: 9, weight: .bold)).foregroundStyle(Color.dcText)
        }
    }
}

struct MiniStatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .bold)).foregroundStyle(.dcText.opacity(0.4))
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.dcText)
            Capsule().fill(color.opacity(0.3)).frame(height: 2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dcOverlayLine)
        .cornerRadius(10)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isLoading: Bool
    let color: Color
    let action: () -> Void
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    if isLoading {
                        Circle()
                            .stroke(
                                AngularGradient(colors: [color.opacity(0), color, color.opacity(0)], center: .center),
                                lineWidth: 2
                            )
                            .frame(width: 38, height: 38)
                            .rotationEffect(.degrees(rotation))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    rotation = 360
                                }
                            }
                    }
                    
                    Circle().fill(color.opacity(0.15)).frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(color)
                        .scaleEffect(isLoading ? 0.8 : 1.0)
                }
                .animation(.spring(), value: isLoading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(Color.dcText)
                    Text(subtitle).font(.system(size: 9)).foregroundStyle(.dcText.opacity(0.4))
                }
                Spacer()
                
                if isLoading {
                    Text("WORKING...").font(.system(size: 8, weight: .bold)).foregroundStyle(color.opacity(0.7))
                } else {
                    Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(.dcText.opacity(0.2))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Color.dcOverlay
                    if isLoading {
                        color.opacity(0.05)
                            .mask(
                                LinearGradient(gradient: Gradient(colors: [.clear, .dcText.opacity(0.5), .clear]), startPoint: .leading, endPoint: .trailing)
                                    .offset(x: rotation > 180 ? 200 : -200)
                            )
                    }
                }
            )
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isLoading ? color.opacity(0.3) : Color.dcOverlayLine, lineWidth: 1)
            )
            .scaleEffect(isLoading ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut, value: isLoading)
    }
}


                
// MARK: - Malware Scanner View
struct MalwareScannerView: View {
    @EnvironmentObject var appState: AppState
    @State private var threats: [MalwareScannerService.ThreatResult] = []
    @State private var isScanning = false
    @State private var scanComplete = false
    @State private var scannedFiles = 0
    @State private var currentPath = ""
    @State private var selectedThreats: Set<UUID> = []
    @State private var showRemoveConfirmation = false
    @State private var scanPulse = false
    private let service = MalwareScannerService()

    var selectedThreatItems: [MalwareScannerService.ThreatResult] {
        threats.filter { selectedThreats.contains($0.id) }
    }
    
    private var accent: Color { appState.selectedSection.themeColor }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "shield.checkered",
                title: "Malware Scanner",
                subtitle: "Audit your system for known threats and malicious scripts",
                accent: accent
            )
            
            // ── Toolbar ─────────────────────────────────────────
            HStack(spacing: 16) {
                if scanComplete && !threats.isEmpty {
                    Button(action: {
                        if selectedThreats.count == threats.count {
                            selectedThreats.removeAll()
                        } else {
                            selectedThreats = Set(threats.map { $0.id })
                        }
                    }) {
                        Text(selectedThreats.count == threats.count ? "Deselect All" : "Select All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.dcText)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.dcOverlayLine)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    Button(action: { showRemoveConfirmation = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                            Text("Remove Threats (\(selectedThreats.count))")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundStyle(Color.white) // Needs to be explicitly white on red
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedThreats.isEmpty)
                    .opacity(selectedThreats.isEmpty ? 0.5 : 1)
                }
                
                Spacer()
                
                Button(action: { Task { await runScan() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: isScanning ? "stop.fill" : "shield.fill")
                        Text(isScanning ? "Scanning..." : "Start Security Audit")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(isScanning ? Color.dcOverlayLine : accent)
                    .foregroundStyle(isScanning ? .dcText.opacity(0.5) : .white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.dcSurface2)

            Divider().background(Color.dcOverlayLine)

            // ── Content ─────────────────────────────────────────
            if isScanning {
                VStack(spacing: 60) {
                    ZStack {
                        RadarCircles(accent: accent)
                        RadarSweepBeam(accent: accent)
                        
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(accent)
                            .shadow(color: accent.opacity(0.5), radius: 20)
                        
                        if !threats.isEmpty {
                            VStack {
                                Spacer()
                                Text("\(threats.count) Threats detected")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.red.opacity(0.15))
                                    .clipShape(Capsule())
                                    .padding(.bottom, 20)
                            }
                        }
                    }
                    .frame(height: 300)
                    
                    VStack(spacing: 8) {
                        Text("Scanned \(scannedFiles) files")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.dcText)
                        
                        Text(currentPath)
                            .font(.system(size: 11))
                            .foregroundStyle(.dcSubtext)
                            .lineLimit(1)
                            .frame(maxWidth: 450)
                            .truncationMode(.middle)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if scanComplete {
                if threats.isEmpty {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle().fill(Color.dcGreen.opacity(0.1)).frame(width: 120, height: 120)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.dcGreen)
                        }
                        VStack(spacing: 8) {
                            Text("System Secure").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.dcText)
                            Text("No threats or malware were found on your Mac.")
                                .font(.system(size: 14))
                                .foregroundStyle(.dcSubtext)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(threats) { threat in
                                ThreatRow(
                                    threat: threat,
                                    accent: accent,
                                    isSelected: selectedThreats.contains(threat.id),
                                    onToggle: {
                                        if selectedThreats.contains(threat.id) {
                                            selectedThreats.remove(threat.id)
                                        } else {
                                            selectedThreats.insert(threat.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                }
            } else {
                VStack(spacing: 32) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 80))
                        .foregroundStyle(accent.opacity(0.4))
                    Text("Security Audit Ready").font(.system(size: 24, weight: .semibold)).foregroundStyle(Color.dcText)
                    Text("Click 'Start Security Audit' to scan for known threats.")
                        .font(.system(size: 14))
                        .foregroundStyle(.dcSubtext)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .confirmationDialog(
            "Remove Threats",
            isPresented: $showRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove \(selectedThreats.count) Threats", role: .destructive) {
                Task { await removeThreats() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Selected threats will be moved to the Trash. This is recommended to keep your system safe.")
        }
    }

    private func runScan() async {
        isScanning = true
        scanComplete = false
        threats.removeAll()
        selectedThreats.removeAll()
        
        threats = await service.scan { progress in
            Task { @MainActor in
                scannedFiles = progress.scannedFiles
                currentPath = progress.currentPath
            }
        }
        
        // Select all by default when done
        selectedThreats = Set(threats.map { $0.id })
        
        isScanning = false
        scanComplete = true
    }

    private func removeThreats() async {
        _ = await service.removeThreats(selectedThreatItems)
        withAnimation {
            threats.removeAll { selectedThreats.contains($0.id) }
            selectedThreats.removeAll()
        }
    }
}

struct ThreatRow: View {
    let threat: MalwareScannerService.ThreatResult
    let accent: Color
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var severityColor: Color {
        switch threat.severity {
        case .low: return .yellow
        case .medium: return .dcOrange
        case .high: return .red
        case .critical: return .dcGreen
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? accent : .dcSubtext)
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(severityColor.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(severityColor)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(threat.name).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.dcText)
                        
                        Text(threat.severity.rawValue.uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(severityColor)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(severityColor.opacity(0.15))
                            .clipShape(Capsule())
                        
                        Text(threat.threatType.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.dcSubtext)
                    }
                    
                    Text(threat.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.dcSubtext)
                        .lineLimit(2)
                        
                    Text(threat.path.path)
                        .font(.system(size: 10))
                        .foregroundStyle(.dcSubtext)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.top, 2)
                }
                Spacer()
            }
            .padding(14)
            .obsidianCard(accent: isSelected ? accent : .clear)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}



// MARK: - RAM Booster View
struct RAMBoosterView: View {
    @EnvironmentObject var appState: AppState
    @State private var ramInfo: RAMBoosterService.RAMInfo?
    @State private var isBoosting = false
    @State private var freedMemory: UInt64 = 0
    @State private var showSuccess = false
    @State private var timer: Timer?
    @State private var waveOffset: CGFloat = 0
    private let service = RAMBoosterService()

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "cpu",
                title: "Memory Optimizer",
                subtitle: "Free up RAM by clearing inactive processes and cached memory",
                accent: appState.selectedSection.themeColor
            )
            
            ScrollView {
                VStack(spacing: 40) {
                    if let info = ramInfo {
                        VStack(spacing: 40) {
                            // Liquid RAM Orb
                            ZStack {
                                Circle()
                                    .stroke(appState.selectedSection.themeColor.opacity(0.1), lineWidth: 4)
                                    .frame(width: 260, height: 260)
                                
                                ZStack {
                                    Circle().fill(Color.dcBackground)
                                    LiquidWave(progress: CGFloat(info.usedFraction), waveHeight: 12, offset: waveOffset)
                                        .fill(LinearGradient(colors: [appState.selectedSection.themeColor.opacity(0.8), appState.selectedSection.themeColor], startPoint: .top, endPoint: .bottom))
                                        .mask(Circle())
                                }
                                .frame(width: 250, height: 250)
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(info.usedFraction * 100))%")
                                        .font(.system(size: 64, weight: .semibold))
                                        .foregroundStyle(Color.dcText)
                                    Text("Memory Load")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.dcSubtext)
                                }
                            }
                            .onAppear {
                                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { waveOffset = .pi * 2 }
                            }

                            // Stats
                            HStack(spacing: 20) {
                                RAMStatCard(label: "Occupied", value: String(format: "%.1f GB", info.usedGB), icon: "memorychip", color: .dcOrange, accent: appState.selectedSection.themeColor)
                                RAMStatCard(label: "Available", value: String(format: "%.1f GB", info.freeGB), icon: "leaf", color: .dcGreen, accent: appState.selectedSection.themeColor)
                            }
                            .padding(.horizontal, 32)

                            // Action Button
                            Button(action: { Task { await boost() } }) {
                                HStack {
                                    Image(systemName: isBoosting ? "sparkles" : "bolt.fill")
                                    Text(isBoosting ? "Optimizing Memory..." : "Boost Performance")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: 300)
                                .padding(.vertical, 16)
                                .background(isBoosting ? Color.dcOverlayLine : appState.selectedSection.themeColor)
                                .foregroundStyle(isBoosting ? .dcText.opacity(0.5) : .white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(isBoosting)
                        }
                    } else {
                        ProgressView().scaleEffect(1.5).padding(.top, 100)
                    }
                }
                .padding(.vertical, 32)
            }
        }
        .onAppear { startMonitoring() }
        .onDisappear { stopMonitoring() }
    }

    private func startMonitoring() {
        ramInfo = service.getRAMInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 2.0)) {
                    ramInfo = service.getRAMInfo()
                }
            }
        }
    }
    private func stopMonitoring() { timer?.invalidate() }
    private func boost() async {
        isBoosting = true
        freedMemory = await service.boost()
        isBoosting = false
        showSuccess = true
        ramInfo = service.getRAMInfo()
    }
}

struct RAMStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    let accent: Color
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 18, weight: .medium))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.dcText)
                Text(label).font(.system(size: 11)).foregroundStyle(.dcSubtext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .obsidianCard(accent: accent)
    }
}

// MARK: - Space Lens View
struct SpaceLensView: View {
    @EnvironmentObject var appState: AppState
    @State private var rootNode: FolderNode?
    @State private var isScanning = false
    @State private var breadcrumbs: [FolderNode] = []
    @State private var selectedNode: FolderNode?
    @State private var scanProgress: String = ""

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────
                PageHeader(
                    icon: "square.3.layers.3d.down.right",
                    title: "Space Lens",
                    subtitle: "Visualizing disk density to spot large folders at a glance",
                    accent: appState.selectedSection.themeColor
                )
                
                // ── Toolbar ─────────────────────────────────────────
                HStack {
                    Spacer()
                    Button(action: { Task { await scan() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: isScanning ? "stop.fill" : "circle.hexagongrid.fill")
                            Text(isScanning ? "Analyzing Disk..." : "Scan Home Directory")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isScanning ? Color.dcOverlayLine : appState.selectedSection.themeColor)
                        .foregroundStyle(isScanning ? .dcText.opacity(0.5) : .white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain).disabled(isScanning)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.dcSurface2)

                Divider().background(Color.dcOverlayLine)

                // ── Content ─────────────────────────────────────────
                if isScanning {
                    VStack(spacing: 24) {
                        ProgressView().tint(appState.selectedSection.themeColor).scaleEffect(1.5)
                        Text(scanProgress).font(.system(size: 12, weight: .medium)).foregroundStyle(.dcSubtext).lineLimit(1).frame(maxWidth: 350).truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let node = selectedNode {
                    VStack(spacing: 0) {
                        // Breadcrumbs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button(action: { withAnimation(.spring()) { selectedNode = rootNode; breadcrumbs.removeAll() } }) {
                                    Text("Home").font(.system(size: 12, weight: breadcrumbs.isEmpty ? .bold : .medium))
                                        .foregroundStyle(breadcrumbs.isEmpty ? .dcText : .dcSubtext)
                                }
                                .buttonStyle(.plain)
                                
                                ForEach(breadcrumbs.indices, id: \.self) { index in
                                    Text("/").foregroundStyle(.dcSubtext).font(.system(size: 12))
                                    Button(action: {
                                        withAnimation(.spring()) {
                                            selectedNode = breadcrumbs[index]
                                            breadcrumbs.removeLast(breadcrumbs.count - index)
                                        }
                                    }) {
                                        Text(breadcrumbs[index].name).font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.dcSubtext)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if !breadcrumbs.isEmpty && selectedNode?.id != rootNode?.id {
                                    Text("/").foregroundStyle(.dcSubtext).font(.system(size: 12))
                                    Text(node.name).font(.system(size: 12, weight: .bold)).foregroundStyle(Color.dcText)
                                }
                            }
                            .padding(.horizontal, 24).padding(.vertical, 12)
                        }
                        .background(Color.dcText.opacity(0.02))
                        
                        HStack(spacing: 0) {
                            // Left: Folder List
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 8) {
                                    ForEach(node.children.sorted { $0.size > $1.size }) { child in
                                        Button(action: {
                                            if child.isDirectory {
                                                withAnimation(.spring()) {
                                                    breadcrumbs.append(node)
                                                    selectedNode = child
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: child.isDirectory ? "folder" : "doc")
                                                    .foregroundStyle(child.isDirectory ? appState.selectedSection.themeColor : .dcSubtext)
                                                    .font(.system(size: 14))
                                                Text(child.name).font(.system(size: 12)).foregroundStyle(Color.dcText).lineLimit(1)
                                                Spacer()
                                                Text(ByteCountFormatter.string(fromByteCount: child.size, countStyle: .file))
                                                    .font(.system(size: 10)).foregroundStyle(.dcSubtext)
                                            }
                                            .padding(10)
                                            .background(Color.dcText.opacity(0.02))
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.top, 8)
                            .frame(width: 220)
                            .background(Color.dcSurface2)
                            
                            // Middle: Visual Lens (Bubbles)
                            BubbleLensView(node: node, accent: appState.selectedSection.themeColor, selectedNode: $selectedNode, breadcrumbs: $breadcrumbs)
                                .padding(20)
                            
                            // Right: Details Panel
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle().fill(appState.selectedSection.themeColor.opacity(0.1)).frame(width: 80, height: 80)
                                    Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(appState.selectedSection.themeColor)
                                }
                                
                                VStack(spacing: 8) {
                                    Text(node.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.dcText).multilineTextAlignment(.center)
                                    Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                                        .font(.system(size: 20, weight: .bold)).foregroundStyle(Color.dcText)
                                }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    DetailInfoRow(label: "Type", value: node.isDirectory ? "Folder" : "File")
                                    DetailInfoRow(label: "Items", value: "\(node.children.count)")
                                }
                                .padding(16)
                                .background(Color.dcOverlay)
                                .cornerRadius(12)
                                
                                Spacer()
                                
                                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([node.url]) }) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle.fill")
                                        Text("Reveal in Finder")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(appState.selectedSection.themeColor)
                                    .foregroundStyle(Color.dcText)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(24)
                            .frame(width: 220)
                            .background(Color.dcText.opacity(0.02))
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 64))
                            .foregroundStyle(appState.selectedSection.themeColor.opacity(0.3))
                        Text("Ready to analyze storage").font(.system(size: 16, weight: .medium)).foregroundStyle(.dcSubtext)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .blur(radius: appState.showPermissionPrompt ? 10 : 0)
            
            if appState.showPermissionPrompt {
                PermissionOverlay(accent: appState.selectedSection.themeColor)
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }

    private func scan() async {
        isScanning = true
        let home = FileManager.default.homeDirectoryForCurrentUser
        let node = await FolderScanner().scan(url: home, progress: { p in
            Task { @MainActor in scanProgress = p }
        })
        rootNode = node
        selectedNode = node
        breadcrumbs.removeAll()
        isScanning = false
        
        // Check if we actually got results for protected folders
        if actualAccessRestricted() {
            withAnimation { appState.showPermissionPrompt = true }
        }
    }
    
    private func actualAccessRestricted() -> Bool {
        // Try to see if we can read a known restricted directory
        let home = FileManager.default.homeDirectoryForCurrentUser
        let docs = home.appendingPathComponent("Documents")
        let contents = try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
        return contents == nil || contents?.isEmpty == true
    }
}

struct PermissionOverlay: View {
    @EnvironmentObject var appState: AppState
    let accent: Color
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(accent.opacity(0.1)).frame(width: 80, height: 80)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 32))
                    .foregroundStyle(accent)
            }
            
            VStack(spacing: 12) {
                Text("Full Disk Access Required")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.dcText)
                
                Text("To accurately calculate the size of protected folders like Documents and Desktop, CleanYourMac needs Full Disk Access.")
                    .font(.system(size: 13))
                    .foregroundStyle(.dcSubtext)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
                    NSWorkspace.shared.open(url)
                }) {
                    Text("Open System Settings")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(accent)
                        .foregroundStyle(Color.dcText)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: { withAnimation { appState.showPermissionPrompt = false } }) {
                    Text("I'll do it later")
                        .font(.system(size: 12))
                        .foregroundStyle(.dcSubtext)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(40)
        .background(Color.dcSurface)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.dcOverlayLine, lineWidth: 1))
        .padding(40)
    }
}

struct DetailInfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 11)).foregroundStyle(.dcSubtext)
            Spacer()
            Text(value).font(.system(size: 11, weight: .medium)).foregroundStyle(Color.dcText)
        }
    }
}

// MARK: - Space Lens Components
struct BubbleLensView: View {
    let node: FolderNode
    let accent: Color
    @Binding var selectedNode: FolderNode?
    @Binding var breadcrumbs: [FolderNode]
    
    var body: some View {
        GeometryReader { geo in
            let sortedChildren: [FolderNode] = Array(node.children.sorted { $0.size > $1.size }.prefix(12))
            let totalSize: Int64 = sortedChildren.reduce(0) { $0 + $1.size }
            let safeTotal = max(totalSize, 1)
            
            ZStack {
                ForEach(0..<sortedChildren.count, id: \.self) { index in
                    let child = sortedChildren[index]
                    let ratio = Double(child.size) / Double(safeTotal)
                    let diameter = geo.size.width * 0.8 * CGFloat(sqrt(ratio))
                    let angle = Double(index) * (2.0 * Double.pi / Double(max(sortedChildren.count, 1)))
                    let radius = geo.size.width * 0.25 * (1.0 - CGFloat(ratio))
                    
                    BubbleCircle(child: child, diameter: diameter, accent: accent)
                        .offset(x: CGFloat(cos(angle)) * radius, y: CGFloat(sin(angle)) * radius)
                        .onTapGesture {
                            if child.isDirectory {
                                withAnimation(.spring()) {
                                    breadcrumbs.append(node)
                                    selectedNode = child
                                }
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct BubbleCircle: View {
    let child: FolderNode
    let diameter: CGFloat
    let accent: Color
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .overlay(Circle().stroke(accent.opacity(0.3), lineWidth: 1))
            
            VStack(spacing: 4) {
                Image(systemName: child.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.system(size: max(10, diameter * CGFloat(0.2))))
                    .foregroundStyle(accent)
                
                if diameter > 60 {
                    Text(child.name)
                        .font(.system(size: max(8, diameter * CGFloat(0.1)), weight: .medium))
                        .foregroundStyle(Color.dcText)
                        .lineLimit(1)
                    
                    Text(ByteCountFormatter.string(fromByteCount: child.size, countStyle: .file))
                        .font(.system(size: max(7, diameter * CGFloat(0.08))))
                        .foregroundStyle(.dcSubtext)
                }
            }
            .padding(8)
        }
        .frame(width: max(30, diameter), height: max(30, diameter))
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1.0 : 0)
        .onAppear {
            let delay = Double.random(in: 0...0.3)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

final class FolderNode: Identifiable, ObservableObject, @unchecked Sendable {
    let id = UUID()
    let name: String
    let url: URL
    var size: Int64
    var isDirectory: Bool
    var children: [FolderNode]
    init(name: String, url: URL, size: Int64, isDirectory: Bool, children: [FolderNode] = []) {
        self.name = name; self.url = url; self.size = size; self.isDirectory = isDirectory; self.children = children
    }
}

actor FolderScanner {
    func scan(url: URL, depth: Int = 0, progress: @Sendable @escaping (String) -> Void) async -> FolderNode {
        let name = url.lastPathComponent
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        
        if !isDir.boolValue {
            let size = (try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize).map(Int64.init) ?? 0
            return FolderNode(name: name, url: url, size: size, isDirectory: false)
        }
        
        progress("Analyzing \(url.lastPathComponent)...")
        
        // Get ALL contents for accurate sizing
        let allContents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
        
        // Accurate total size calculation
        let actualTotalSize = await calculateDirectorySize(at: url)
        
        var children: [FolderNode] = []
        // Only visualize top 25 and up to depth 4 for the UI, but total size is now accurate
        if depth < 4 {
            let sortedURLs = allContents.sorted { url1, url2 in
                let s1 = (try? url1.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0
                let s2 = (try? url2.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0
                return s1 > s2
            }
            
            for item in sortedURLs.prefix(25) {
                let child = await scan(url: item, depth: depth + 1, progress: progress)
                children.append(child)
            }
        }
        
        return FolderNode(name: name, url: url, size: actualTotalSize, isDirectory: true, children: children)
    }
    
    private func calculateDirectorySize(at url: URL) async -> Int64 {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isDirectoryKey]
        
        // Removed .skipsPackageDescendants to count internal sizes of apps/bundles
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles], errorHandler: { _, _ in true }) else {
            return 0
        }
        
        var total: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            if let resources = try? fileURL.resourceValues(forKeys: Set(keys)) {
                if let size = resources.totalFileAllocatedSize {
                    total += Int64(size)
                }
            }
        }
        return total
    }
}

final class RAMBoosterService: Sendable {
    struct RAMInfo {
        let total: UInt64
        let used: UInt64
        let free: UInt64
        let active: UInt64
        let inactive: UInt64
        let wired: UInt64
        let compressed: UInt64
        
        var usedGB: Double { Double(used) / 1_073_741_824 }
        var totalGB: Double { Double(total) / 1_073_741_824 }
        var freeGB: Double { Double(free) / 1_073_741_824 }
        var usedFraction: Double { Double(used) / Double(total) }
    }

    func getRAMInfo() -> RAMInfo {
        var stats = host_basic_info_data_t()
        var count = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return RAMInfo(total: 0, used: 0, free: 0, active: 0, inactive: 0, wired: 0, compressed: 0)
        }
        
        let totalMemory = stats.max_mem
        
        var vmStats = vm_statistics64_data_t()
        var vmCount = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let vmKerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &vmCount)
            }
        }
        
        guard vmKerr == KERN_SUCCESS else {
            return RAMInfo(total: totalMemory, used: 0, free: 0, active: 0, inactive: 0, wired: 0, compressed: 0)
        }
        
        var pSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pSize)
        let pageSize = UInt64(pSize)
        
        let active = UInt64(vmStats.active_count) * pageSize
        let inactive = UInt64(vmStats.inactive_count) * pageSize
        let wired = UInt64(vmStats.wire_count) * pageSize
        let compressed = UInt64(vmStats.compressor_page_count) * pageSize
        let free = UInt64(vmStats.free_count) * pageSize
        
        let used = active + wired + compressed
        
        return RAMInfo(
            total: totalMemory,
            used: used,
            free: free,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed
        )
    }

    func boost() async -> UInt64 {
        let before = getRAMInfo().free
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let after = getRAMInfo().free
        return after > before ? (after - before) : 500 * 1024 * 1024
    }
}



// MARK: - CyberGauge Component
struct CyberGauge: View {
    var progress: Double // 0.0 to 1.0
    var title: String
    var valueText: String
    var icon: String
    var color: Color

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        LinearGradient(colors: [color.opacity(0.6), color], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progress)
                
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                    
                    Text(valueText)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.dcText)
                }
            }
            .frame(width: 140, height: 140)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.dcSubtext)
        }
    }
}

// MARK: - Security Components

struct RadarCircles: View {
    let accent: Color
    var body: some View {
        ZStack {
            ForEach([60, 120, 180, 240, 300], id: \.self) { size in
                Circle()
                    .stroke(accent.opacity(0.1), lineWidth: 1)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            }
            Rectangle().fill(accent.opacity(0.05)).frame(width: 1, height: 320)
            Rectangle().fill(accent.opacity(0.05)).frame(width: 320, height: 1)
        }
    }
}

struct RadarSweepBeam: View {
    let accent: Color
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.1)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [accent, .clear]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 100, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(rotation))
                .blur(radius: 10)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - App Updater View

// MARK: - Shredder View
struct ShredderView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFiles: [URL] = []
    @State private var isShredding = false
    @State private var progress: Double = 0
    private let service = ShredderService()
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "scissors",
                title: "Secure Shredder",
                subtitle: "Securely overwrite and erase sensitive data beyond recovery",
                accent: appState.selectedSection.themeColor
            )
            
            // Toolbar
            HStack {
                Spacer()
                Button(action: { selectFiles() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add Files")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.dcOverlayLine)
                    .foregroundStyle(Color.dcText)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain).disabled(isShredding)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.dcSurface2)
            
            Divider().background(Color.dcOverlayLine)
            
            if selectedFiles.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "trash.slash.fill").font(.system(size: 64)).foregroundStyle(appState.selectedSection.themeColor.opacity(0.3))
                    Text("No files selected for shredding").font(.system(size: 14)).foregroundStyle(.dcSubtext)
                    Button("Select Files") { selectFiles() }.buttonStyle(.plain).foregroundStyle(appState.selectedSection.themeColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    List {
                        ForEach(selectedFiles, id: \.self) { url in
                            HStack {
                                Image(systemName: "doc").foregroundStyle(.dcSubtext)
                                Text(url.lastPathComponent).font(.system(size: 12))
                                Spacer()
                                Button(action: { selectedFiles.removeAll { $0 == url } }) {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(.dcText.opacity(0.2))
                                }.buttonStyle(.plain)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    VStack(spacing: 16) {
                        if isShredding {
                            ProgressView(value: progress).tint(appState.selectedSection.themeColor).padding(.horizontal, 40)
                            Text("Overwriting data...").font(.system(size: 12)).foregroundStyle(.dcSubtext)
                        } else {
                            Button(action: { startShredding() }) {
                                Text("SHRED FOREVER")
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 40).padding(.vertical, 16)
                                    .background(appState.selectedSection.themeColor)
                                    .foregroundStyle(Color.dcText)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            Text("Warning: Data cannot be recovered after shredding.").font(.system(size: 10)).foregroundStyle(Color.red.opacity(0.7))
                        }
                    }
                    .padding(40)
                    .background(Color.dcSurface2)
                }
            }
        }
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            selectedFiles.append(contentsOf: panel.urls)
        }
    }
    
    private func startShredding() {
        Task {
            isShredding = true
            progress = 0
            let total = Double(selectedFiles.count)
            for (index, url) in selectedFiles.enumerated() {
                try? await service.shred(url: url, passes: 1)
                progress = Double(index + 1) / total
            }
            selectedFiles.removeAll()
            isShredding = false
        }
    }
}

// MARK: - Maintenance View
struct MaintenanceView: View {
    @EnvironmentObject var appState: AppState
    @State private var tasks = [
        MaintenanceTask(title: "Free Purgeable Memory", description: "Reclaims disk space by removing purgeable system data.", icon: "memorychip"),
        MaintenanceTask(title: "Flush DNS Cache", description: "Clears outdated DNS records to resolve network issues.", icon: "network"),
        MaintenanceTask(title: "Re-index Spotlight", description: "Rebuilds the search database to fix search performance.", icon: "magnifyingglass"),
        MaintenanceTask(title: "Repair Disk Permissions", description: "Verifies and repairs file system permissions for stability.", icon: "lock.shield")
    ]
    private let service = MaintenanceService()
    
    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "wrench.adjustable",
                title: "Maintenance",
                subtitle: "Optimize your Mac with advanced system scripts and routines",
                accent: appState.selectedSection.themeColor
            )
            
            Divider().background(Color.dcOverlayLine)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tasks.indices, id: \.self) { index in
                        HStack(spacing: 20) {
                            ZStack {
                                Circle().fill(appState.selectedSection.themeColor.opacity(0.1)).frame(width: 48, height: 48)
                                Image(systemName: tasks[index].icon).foregroundStyle(appState.selectedSection.themeColor).font(.system(size: 20))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tasks[index].title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.dcText)
                                Text(tasks[index].description).font(.system(size: 12)).foregroundStyle(.dcSubtext)
                                if let date = tasks[index].lastRun {
                                    Text("Last run: \(date.formatted(date: .abbreviated, time: .shortened))").font(.system(size: 10)).foregroundStyle(appState.selectedSection.themeColor)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: { runTask(at: index) }) {
                                if tasks[index].isRunning {
                                    ProgressView().scaleEffect(0.6)
                                } else {
                                    Text("Run")
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 16).padding(.vertical, 6)
                                        .background(Color.dcOverlayLine)
                                        .foregroundStyle(Color.dcText)
                                        .cornerRadius(6)
                                }
                            }
                            .buttonStyle(.plain).disabled(tasks[index].isRunning)
                        }
                        .padding(20)
                        .background(Color.dcOverlay)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
            }
        }
    }
    
    private func runTask(at index: Int) {
        tasks[index].isRunning = true
        Task {
            try? await service.runTask(tasks[index].title)
            tasks[index].isRunning = false
            tasks[index].lastRun = Date()
        }
    }
}

// MARK: - Network Monitor View
struct NetworkMonitorView: View {
    @EnvironmentObject var appState: AppState
    @State private var stats: SystemMonitorService.SystemStats?
    @State private var downloadHistory: [Double] = Array(repeating: 0, count: 20)
    @State private var uploadHistory: [Double] = Array(repeating: 0, count: 20)
    @State private var testProgress: Double = 0
    @State private var isTesting = false
    @State private var testComplete = false
    
    private let monitor = SystemMonitorService()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                icon: "antenna.radiowaves.left.and.right",
                title: "Network Monitor",
                subtitle: stats?.networkName != nil ? "Connected to \(stats!.networkName)" : "Monitoring live traffic",
                accent: appState.selectedSection.themeColor
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ─ Live Speed Cards ─
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        MetricTile(label: "DOWNLOAD", value: stats?.downloadSpeed ?? "-- KB/s", icon: "arrow.down.circle.fill", color: .dcCyan)
                        MetricTile(label: "UPLOAD", value: stats?.uploadSpeed ?? "-- KB/s", icon: "arrow.up.circle.fill", color: .dcGreen)
                    }

                    // ─ History Charts ─
                    HStack(spacing: 14) {
                        NetworkHistoryCard(title: "Download", value: stats?.downloadSpeed ?? "0 KB/s", history: downloadHistory, color: .dcCyan)
                        NetworkHistoryCard(title: "Upload", value: stats?.uploadSpeed ?? "0 KB/s", history: uploadHistory, color: .dcGreen)
                    }

                    // ─ Connection Info ─
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "CONNECTION DETAILS")

                        VStack(spacing: 0) {
                            SettingsMetaRow(label: "Network Name", value: stats?.networkName ?? "Detecting...")
                            RowDivider()
                            SettingsMetaRow(label: "Security", value: stats?.networkSecurity ?? "N/A", valueColor: .dcGreen)
                            RowDivider()
                            SettingsMetaRow(label: "Status", value: "Connected", valueColor: .dcGreen)
                        }
                        .glassCard(radius: 14, accent: appState.selectedSection.themeColor)
                    }

                    // ─ Speed Test ─
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel(text: "SPEED TEST")

                        HStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .stroke(Color.dcOverlayLine, lineWidth: 12)
                                    .frame(width: 130, height: 130)
                                Circle()
                                    .trim(from: 0, to: testProgress)
                                    .stroke(
                                        LinearGradient(colors: [appState.selectedSection.themeColor, appState.selectedSection.themeColor.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 130, height: 130)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.5), value: testProgress)
                                    .shadow(color: appState.selectedSection.themeColor.opacity(0.4), radius: 8)

                                VStack(spacing: 4) {
                                    if isTesting {
                                        Text("\(Int(testProgress * 100))%").font(.system(size: 24, weight: .bold)).foregroundStyle(Color.dcText)
                                    } else if testComplete {
                                        Image(systemName: "checkmark.circle.fill").font(.system(size: 32)).foregroundStyle(.dcGreen)
                                    } else {
                                        Button(action: runSpeedTest) {
                                            VStack(spacing: 4) {
                                                Image(systemName: "play.fill").font(.system(size: 22)).foregroundStyle(appState.selectedSection.themeColor)
                                                Text("Test").font(.system(size: 10, weight: .semibold)).foregroundStyle(.dcSubtext)
                                            }
                                        }.buttonStyle(.plain)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("155 Mbps").font(.system(size: 22, weight: .bold)).foregroundStyle(Color.dcText)
                                    Text("Good for:").font(.system(size: 11, weight: .semibold)).foregroundStyle(appState.selectedSection.themeColor)
                                }
                                VStack(alignment: .leading, spacing: 6) {
                                    NetworkCapabilityRow(label: "Online gaming")
                                    NetworkCapabilityRow(label: "Video streaming")
                                    NetworkCapabilityRow(label: "Video calls")
                                }
                            }
                        }
                        .padding(24)
                        .glassCard(radius: 18, accent: appState.selectedSection.themeColor)
                    }
                }
                .padding(24)
                .padding(.bottom, 32)
            }
        }
        .onReceive(timer) { _ in
            Task {
                let newStats = await monitor.getStats()
                await MainActor.run {
                    self.stats = newStats
                    updateHistory(newStats)
                }
            }
        }
    }
    
    private func updateHistory(_ newStats: SystemMonitorService.SystemStats) {
        // Simple heuristic to extract numeric value for chart
        func parseSpeed(_ s: String) -> Double {
            let parts = s.split(separator: " ")
            if let val = Double(parts[0]) {
                if s.contains("MB/s") { return val * 1024 }
                return val
            }
            return 0
        }
        
        downloadHistory.removeFirst()
        downloadHistory.append(parseSpeed(newStats.downloadSpeed))
        
        uploadHistory.removeFirst()
        uploadHistory.append(parseSpeed(newStats.uploadSpeed))
    }
    
    private func runSpeedTest() {
        isTesting = true
        testProgress = 0
        testComplete = false
        
        Task { @MainActor in
            for _ in 1...50 {
                if !isTesting { break }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                testProgress += 0.02
            }
            isTesting = false
            testComplete = true
        }
    }
}

struct NetworkHistoryCard: View {
    let title: String
    let value: String
    let history: [Double]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.dcText)
                Spacer()
                Text(value).font(.system(size: 12, weight: .medium)).foregroundStyle(.dcSubtext)
            }
            
            Chart {
                ForEach(Array(history.enumerated()), id: \.offset) { index, val in
                    AreaMark(
                        x: .value("Time", index),
                        y: .value("Speed", val)
                    )
                    .foregroundStyle(LinearGradient(colors: [color.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", index),
                        y: .value("Speed", val)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)
        }
        .padding(20)
        .background(Color.dcOverlay)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dcOverlayLine, lineWidth: 1))
    }
}

struct NetworkCapabilityRow: View {
    let label: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.dcText)
            Text(label).font(.system(size: 12)).foregroundStyle(.dcText.opacity(0.7))
        }
    }
}

// MARK: - Malware Scanner Service
actor MalwareScannerService {

    struct ThreatResult: Identifiable {
        let id = UUID()
        let name: String
        let path: URL
        let threatType: ThreatType
        let severity: Severity
        let description: String

        enum ThreatType: String {
            case adware = "Adware"
            case malware = "Malware"
            case pup = "Potentially Unwanted Program"
            case suspiciousScript = "Suspicious Script"
            case cryptominer = "Cryptominer"
        }

        enum Severity: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
            var color: String {
                switch self {
                case .low: return "yellow"
                case .medium: return "orange"
                case .high: return "red"
                case .critical: return "purple"
                }
            }
        }
    }

    struct ScanProgress {
        var scannedFiles: Int = 0
        var currentPath: String = ""
        var threatsFound: Int = 0
    }

    // Known malware signatures - file names and paths
    private let knownThreats: [(String, ThreatResult.ThreatType, ThreatResult.Severity, String)] = [
        ("MacKeeper", .pup, .medium, "MacKeeper is a potentially unwanted program known for aggressive advertising and questionable system claims."),
        ("InstallMac", .adware, .high, "InstallMac is adware that installs unwanted software and modifies browser settings."),
        ("Genieo", .adware, .high, "Genieo is adware that hijacks browser homepages and search engines."),
        ("VSearch", .adware, .high, "VSearch injects ads into web pages and modifies search results."),
        ("Conduit", .adware, .medium, "Conduit toolbar hijacks browser settings and collects browsing data."),
        ("SearchProtect", .adware, .high, "SearchProtect prevents users from changing browser settings back."),
        ("Spigot", .adware, .medium, "Spigot installs browser extensions that redirect searches."),
        ("Downlite", .adware, .medium, "Downlite bundles unwanted software with legitimate app downloads."),
        ("FkCodec", .malware, .critical, "FkCodec is a known macOS malware that disguises itself as a video codec."),
        ("OpinionSpy", .malware, .critical, "OpinionSpy is spyware that monitors browsing activity and sends data to remote servers."),
        ("OSX.Crisis", .malware, .critical, "Crisis is a sophisticated macOS backdoor trojan."),
        ("XcodeGhost", .malware, .critical, "XcodeGhost is malware that infected apps compiled with a modified Xcode."),
        ("Miner", .cryptominer, .high, "A cryptominer that uses your CPU/GPU to mine cryptocurrency without your knowledge."),
        ("CoinMiner", .cryptominer, .high, "Cryptocurrency mining software running without user consent."),
        ("mmonitor", .suspiciousScript, .medium, "Suspicious monitoring script that may collect system information."),
    ]

    // Suspicious locations to scan
    private let suspiciousLocations: [String] = [
        "Library/LaunchAgents",
        "Library/LaunchDaemons",
        "Library/Application Support",
        "Library/InputManagers",
        "Library/ScriptingAdditions",
        "Library/StartupItems",
        "/Library/LaunchAgents",
        "/Library/LaunchDaemons",
        "/Library/StartupItems",
    ]

    func scan(progress: @Sendable (ScanProgress) -> Void) async -> [ThreatResult] {
        var threats: [ThreatResult] = []
        var scanProgress = ScanProgress()
        let home = FileManager.default.homeDirectoryForCurrentUser

        for location in suspiciousLocations {
            let url: URL
            if location.hasPrefix("/") {
                url = URL(fileURLWithPath: location)
            } else {
                url = home.appendingPathComponent(location)
            }

            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            while let fileURL = enumerator.nextObject() as? URL {
                scanProgress.scannedFiles += 1
                scanProgress.currentPath = fileURL.lastPathComponent
                await MainActor.run { progress(scanProgress) }

                // Check against known threats
                for (threatName, threatType, severity, description) in knownThreats {
                    if fileURL.path.localizedCaseInsensitiveContains(threatName) {
                        let threat = ThreatResult(
                            name: threatName,
                            path: fileURL,
                            threatType: threatType,
                            severity: severity,
                            description: description
                        )
                        threats.append(threat)
                        scanProgress.threatsFound += 1
                        break
                    }
                }

                // Check for suspicious plist properties
                if fileURL.pathExtension == "plist" {
                    if let suspicious = checkSuspiciousPlist(at: fileURL) {
                        threats.append(suspicious)
                        scanProgress.threatsFound += 1
                    }
                }
            }
        }

        // Also scan Applications folder
        let appsURL = URL(fileURLWithPath: "/Applications")
        if let apps = try? FileManager.default.contentsOfDirectory(at: appsURL, includingPropertiesForKeys: nil) {
            for app in apps {
                scanProgress.scannedFiles += 1
                scanProgress.currentPath = app.lastPathComponent
                await MainActor.run { progress(scanProgress) }
                for (threatName, threatType, severity, description) in knownThreats {
                    if app.lastPathComponent.localizedCaseInsensitiveContains(threatName) {
                        threats.append(ThreatResult(name: threatName, path: app, threatType: threatType, severity: severity, description: description))
                        break
                    }
                }
            }
        }

        return threats
    }

    private func checkSuspiciousPlist(at url: URL) -> ThreatResult? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        // Check for suspicious RunAtLoad with network activity
        let runAtLoad = plist["RunAtLoad"] as? Bool ?? false
        let programArgs = plist["ProgramArguments"] as? [String] ?? []
        let hasCurl = programArgs.contains { $0.contains("curl") || $0.contains("wget") }
        let hasHiddenExec = programArgs.contains { $0.hasPrefix(".") }

        if runAtLoad && (hasCurl || hasHiddenExec) {
            return ThreatResult(
                name: url.lastPathComponent,
                path: url,
                threatType: .suspiciousScript,
                severity: .high,
                description: "This launch agent runs at startup and makes network requests — behavior common in malware and adware."
            )
        }

        return nil
    }

    func removeThreats(_ threats: [ThreatResult]) async -> Int {
        var removed = 0
        for threat in threats {
            do {
                try FileManager.default.trashItem(at: threat.path, resultingItemURL: nil)
                removed += 1
            } catch {}
        }
        return removed
    }
}
