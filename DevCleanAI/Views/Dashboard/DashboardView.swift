import SwiftUI
import Foundation
import Charts

// MARK: - Dashboard (Smart Care)
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var storageInfo = StorageInfo.current()

    var body: some View {
        ZStack {
            if appState.isScanning {
                LiquidScannerOrb()
                    .transition(.opacity.combined(with: .scale(0.98)))
            } else if appState.scanResults.allItems.isEmpty {
                SmartCareHero()
                    .transition(.opacity)
            } else {
                ScanResultsView(storageInfo: storageInfo)
                    .transition(.opacity)
            }

            // FAB Scan Button
            if !appState.isScanning {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ScanFAB()
                            .padding(32)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isScanning)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.scanResults.allItems.count)
        .task { storageInfo = StorageInfo.current() }
    }
}

// MARK: - FAB
struct ScanFAB: View {
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var body: some View {
        Button(action: { Task { await appState.runFullScan() } }) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                Text("Smart Scan")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.dcText)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.dcGreen, .dcCyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .dcGreen.opacity(isHovered ? 0.6 : 0.35), radius: isHovered ? 20 : 12)
            .scaleEffect(isHovered ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.spring(response: 0.25)) { isHovered = h } }
    }
}

// MARK: - Hero (pre-scan)
struct SmartCareHero: View {
    @EnvironmentObject var appState: AppState
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Central orb
            ZStack {
                // Outer pulse rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(.dcGreen.opacity(0.15 - Double(i) * 0.04), lineWidth: 1)
                        .frame(width: CGFloat(180 + i * 60), height: CGFloat(180 + i * 60))
                        .scaleEffect(pulse ? 1.08 : 0.95)
                        .animation(
                            .easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(Double(i) * 0.4),
                            value: pulse
                        )
                }

                // Main orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.dcGreen.opacity(0.25), .dcCyan.opacity(0.1), .clear],
                            center: .center, startRadius: 20, endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.dcGreen.opacity(0.6), .dcCyan.opacity(0.3)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )

                Image(systemName: "sparkles")
                    .font(.system(size: 52, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.dcGreen, .dcCyan],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .dcGreen.opacity(0.6), radius: 16)
            }
            .onAppear { pulse = true }

            Spacer().frame(height: 40)

            // Title
            VStack(spacing: 10) {
                Text("Smart Care")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.dcText)

                Text("Deep-scan your Mac to surface hidden junk,\nbrowser caches, dev artifacts, and more.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.dcText.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: 40)

            // Feature pills
            HStack(spacing: 12) {
                FeaturePill(icon: "internaldrive", label: "Storage", color: .dcCyan)
                FeaturePill(icon: "terminal", label: "Dev Cache", color: .dcGreen)
                FeaturePill(icon: "shield.checkered", label: "Security", color: .dcGreen)
                FeaturePill(icon: "doc.on.doc", label: "Duplicates", color: .dcOrange)
            }

            Spacer()
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeaturePill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.dcText.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Scan Results (Bento Grid)
struct ScanResultsView: View {
    @EnvironmentObject var appState: AppState
    let storageInfo: StorageInfo

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Top row: Health gauge + Storage bar side by side
                HStack(spacing: 16) {
                    HealthGaugeBento(health: appState.systemHealth)
                        .frame(maxWidth: 240)

                    StorageBentoCard(info: storageInfo)
                        .frame(maxWidth: .infinity)
                }

                // Stat cards row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    BentoStatCard(
                        label: "TOTAL JUNK",
                        value: appState.scanResults.totalSizeFormatted,
                        icon: "trash.fill",
                        color: .dcRed
                    )
                    BentoStatCard(
                        label: "SAFE TO PURGE",
                        value: ByteCountFormatter.string(fromByteCount: appState.scanResults.safeSize, countStyle: .file),
                        icon: "checkmark.shield.fill",
                        color: .dcGreen
                    )
                    BentoStatCard(
                        label: "FILES FOUND",
                        value: "\(appState.scanResults.allItems.count)",
                        icon: "doc.fill",
                        color: .dcCyan
                    )
                    BentoStatCard(
                        label: "RISK LEVEL",
                        value: appState.scanResults.reviewItems.isEmpty ? "LOW" : "REVIEW",
                        icon: "exclamationmark.triangle.fill",
                        color: appState.scanResults.reviewItems.isEmpty ? .dcGreen : .dcOrange
                    )
                }

                // Top items
                DetectionLogCard(items: Array(appState.scanResults.allItems.sorted { $0.size > $1.size }.prefix(8)))
            }
            .padding(28)
            .padding(.bottom, 100) // room for FAB
        }
    }
}

// MARK: - Health Gauge Bento
struct HealthGaugeBento: View {
    let health: Int
    @State private var animate = false

    var gaugeColor: Color {
        if health >= 80 { return .dcGreen }
        else if health >= 60 { return .dcOrange }
        else { return .dcRed }
    }

    var statusLabel: String {
        if health >= 80 { return "Excellent" }
        else if health >= 60 { return "Good" }
        else { return "Needs Attention" }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(.dcOverlayLine, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: animate ? CGFloat(health) / 100 : 0)
                    .stroke(
                        AngularGradient(colors: [gaugeColor.opacity(0.6), gaugeColor, gaugeColor.opacity(0.6)], center: .center),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: gaugeColor.opacity(0.4), radius: 8)
                    .animation(.spring(response: 1.2, dampingFraction: 0.7), value: health)

                VStack(spacing: 2) {
                    Text("\(health)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.dcText)
                    Text("%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.dcText.opacity(0.4))
                }
            }
            .frame(width: 140, height: 140)

            VStack(spacing: 4) {
                Text(statusLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(gaugeColor)
                Text("System Health")
                    .font(.system(size: 11))
                    .foregroundStyle(.dcText.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.dcOverlayLine, lineWidth: 0.5))
        .onAppear { animate = true }
    }
}

// MARK: - Storage Bento
struct StorageBentoCard: View {
    let info: StorageInfo
    var used: Double { Double(info.used) / Double(max(info.total, 1)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Macintosh HD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.dcText)
                    Text("\(info.usedFormatted) used of \(info.totalFormatted)")
                        .font(.system(size: 12))
                        .foregroundStyle(.dcText.opacity(0.4))
                }
                Spacer()
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(colors: [.dcGreen, .dcCyan], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .dcGreen.opacity(0.5), radius: 10)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.dcOverlayLine)
                    Capsule()
                        .fill(LinearGradient(
                            colors: used > 0.85
                                ? [.dcRed, .dcOrange]
                                : [.dcGreen, .dcCyan],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * used)
                        .shadow(color: .dcGreen.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 8)

            HStack {
                StorageLegendDot(color: .dcGreen, label: "Used", value: info.usedFormatted)
                Spacer()
                StorageLegendDot(color: .dcText.opacity(0.2), label: "Free", value: ByteCountFormatter.string(fromByteCount: info.free, countStyle: .file))
            }
        }
        .padding(24)
        .frame(maxHeight: .infinity)
        .background(.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.dcOverlayLine, lineWidth: 0.5))
    }
}

struct StorageLegendDot: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.dcText.opacity(0.35))
                Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.dcText)
            }
        }
    }
}

// MARK: - Bento Stat Cards
struct BentoStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
                    .shadow(color: color.opacity(0.5), radius: 4)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.dcText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.dcText.opacity(0.35))
                    .kerning(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.dcText.opacity(isHovered ? 0.07 : 0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHovered ? color.opacity(0.25) : .dcBorder, lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .onHover { h in isHovered = h }
    }
}

// MARK: - Detection Log
struct DetectionLogCard: View {
    let items: [ScanItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Detection Log")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.dcText)
                Spacer()
                Text("\(items.count) items")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.dcText.opacity(0.35))
            }

            VStack(spacing: 1) {
                ForEach(items) { item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(item.riskLevel.color.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Image(systemName: item.category.icon)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(item.riskLevel.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.dcText)
                                .lineLimit(1)
                            Text(item.path.path)
                                .font(.system(size: 10))
                                .foregroundStyle(.dcText.opacity(0.3))
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(item.sizeFormatted)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.dcText)
                            Text(item.riskLevel.label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(item.riskLevel.color)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(.dcText.opacity(0.02))

                    if items.last?.id != item.id {
                        Divider()
                            .background(.dcOverlayLine)
                            .padding(.horizontal, 14)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.dcBorder, lineWidth: 0.5))
        }
        .padding(20)
        .background(.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.dcBorder, lineWidth: 0.5))
    }
}

// MARK: - Legacy compatibility shims
struct FeatureLabel: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 18)
            Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(ObsidianTheme.text)
        }
    }
}

struct SystemHealthGauge: View {
    let health: Int
    var body: some View { HealthGaugeBento(health: health) }
}

struct StatCard: View {
    let label: String; let value: String; let icon: String; let color: Color
    var body: some View { BentoStatCard(label: label, value: value, icon: icon, color: color) }
}

struct TopItemsSection: View {
    let items: [ScanItem]
    var body: some View { DetectionLogCard(items: items) }
}

struct StorageBarView: View {
    let info: StorageInfo
    var body: some View { StorageBentoCard(info: info) }
}

// MARK: - Liquid Scanner Orb
struct LiquidScannerOrb: View {
    @EnvironmentObject var appState: AppState
    @State private var waveOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 48) {
            ZStack {
                // Outer glow rings
                ForEach(0..<2) { i in
                    Circle()
                        .stroke(.dcGreen.opacity(0.08 - Double(i) * 0.03), lineWidth: 1)
                        .frame(width: CGFloat(300 + i * 40), height: CGFloat(300 + i * 40))
                }

                Circle()
                    .stroke(.dcOverlayLine, lineWidth: 2)
                    .frame(width: 280, height: 280)

                ZStack {
                    Circle().fill(.dcBackground)
                    LiquidWave(progress: CGFloat(appState.scanProgress), waveHeight: 12, offset: waveOffset)
                        .fill(LinearGradient(
                            colors: [.dcGreen, .dcCyan],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .mask(Circle())
                    LiquidWave(progress: CGFloat(appState.scanProgress), waveHeight: 16, offset: waveOffset + 2)
                        .fill(LinearGradient(
                            colors: [.dcGreen.opacity(0.4), .dcCyan.opacity(0.3)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .mask(Circle())
                }
                .frame(width: 272, height: 272)

                VStack(spacing: 6) {
                    Text("\(Int(appState.scanProgress * 100))%")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.dcText)
                    Text("SCANNING")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(.dcText.opacity(0.4))
                        .kerning(2)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    waveOffset = .pi * 2
                }
            }

            VStack(spacing: 8) {
                Text("Analyzing system artifacts...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.dcText.opacity(0.6))

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.dcOverlayLine)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.dcGreen, .dcCyan],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * appState.scanProgress)
                            .shadow(color: .dcGreen.opacity(0.5), radius: 6)
                    }
                }
                .frame(width: 280, height: 4)
                .animation(.spring(), value: appState.scanProgress)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Liquid Wave Shape
struct LiquidWave: Shape {
    var progress: CGFloat
    var waveHeight: CGFloat
    var offset: CGFloat
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, offset) }
        set { progress = newValue.first; offset = newValue.second }
    }
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waterHeight = (1 - progress) * rect.height
        path.move(to: CGPoint(x: 0, y: waterHeight))
        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = waterHeight + sin((x / rect.width) * .pi * 2 + offset) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Storage Info Model
struct StorageInfo {
    let total: Int64
    let used: Int64
    let free: Int64
    var usedFormatted: String { ByteCountFormatter.string(fromByteCount: used, countStyle: .file) }
    var totalFormatted: String { ByteCountFormatter.string(fromByteCount: total, countStyle: .file) }
    
    static func current() -> StorageInfo {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            // volumeAvailableCapacityForImportantUsage accurately reflects Finder's "Available" space which includes purgeable data.
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            return StorageInfo(total: total, used: total - free, free: free)
        } catch {
            return StorageInfo(total: 0, used: 0, free: 0)
        }
    }
}
