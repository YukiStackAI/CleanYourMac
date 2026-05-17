import SwiftUI

// MARK: - Root Layout
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // ── OLED base ──────────────────────────────────────────
            Color.dcBackground.ignoresSafeArea()

            // ── Per-section ambient glow (slow, ambient only) ──────
            RadialGradient(
                colors: [appState.selectedSection.themeColor.opacity(0.09), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: appState.selectedSection)

            // ── Layout ─────────────────────────────────────────────
            HStack(spacing: 0) {
                SidebarView()
                    .frame(width: 236)
                    .zIndex(10)

                // Gradient separator
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                appState.selectedSection.themeColor.opacity(0.18),
                                .clear
                             ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .animation(.easeInOut(duration: 0.8), value: appState.selectedSection)

                DetailView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 820, minHeight: 560)
    }
}

// MARK: - Dynamic Background (compat)
struct DynamicBackground: View {
    let color: Color
    var body: some View {
        ZStack {
            Color.dcBackground.ignoresSafeArea()
            RadialGradient(colors: [color.opacity(0.12), .clear], center: .topLeading, startRadius: 0, endRadius: 800)
        }
        .animation(.easeInOut(duration: 1.2), value: color)
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack(spacing: 0) {

            // ── Logo Header ─────────────────────────────────────
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(LinearGradient(
                            colors: [.dcGreen, .dcCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 38, height: 38)
                        .shadow(color: .dcGreen.opacity(0.35), radius: 10, y: 4)

                    Image("owl")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(6)
                        .frame(width: 38, height: 38)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("CleanYourMac")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.dcText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("PLATINUM")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.dcGreen)
                        .kerning(1.8)
                }

                Spacer()

                // Live indicator
                Circle()
                    .fill(appState.isScanning ? .dcOrange : .dcGreen)
                    .frame(width: 6, height: 6)
                    .shadow(color: appState.isScanning ? .dcOrange : .dcGreen, radius: 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 26)
            .padding(.bottom, 22)

            // ── Nav Groups ───────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 2) {

                    NavGroup(label: "CLEAN & OPTIMIZE") {
                        SidebarNavItem(section: .dashboard,    selected: $appState.selectedSection)
                        SidebarNavItem(section: .systemJunk,   selected: $appState.selectedSection)
                        SidebarNavItem(section: .devCleaner,   selected: $appState.selectedSection)
                        SidebarNavItem(section: .aiPromptCleaner, selected: $appState.selectedSection)
                        SidebarNavItem(section: .largeFiles,   selected: $appState.selectedSection)
                        SidebarNavItem(section: .duplicates,   selected: $appState.selectedSection)
                        SidebarNavItem(section: .shredder,     selected: $appState.selectedSection)
                    }

                    SidebarDivider()

                    NavGroup(label: "PERFORMANCE") {
                        SidebarNavItem(section: .ramBooster,     selected: $appState.selectedSection)
                        SidebarNavItem(section: .spaceLens,      selected: $appState.selectedSection)
                        SidebarNavItem(section: .maintenance,    selected: $appState.selectedSection)
                        SidebarNavItem(section: .networkMonitor, selected: $appState.selectedSection)
                    }

                    SidebarDivider()

                    NavGroup(label: "PROTECTION") {
                        SidebarNavItem(section: .malwareScanner, selected: $appState.selectedSection)
                        SidebarNavItem(section: .appUninstaller, selected: $appState.selectedSection)
                        SidebarNavItem(section: .startupItems,   selected: $appState.selectedSection)
                        SidebarNavItem(section: .privacyCleaner, selected: $appState.selectedSection)
                    }

                    SidebarDivider()

                    SidebarNavItem(section: .settings, selected: $appState.selectedSection)
                        .padding(.horizontal, 8)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }

            // ── Status Widget ────────────────────────────────────
            SidebarStatusWidget()
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
        }
        .background(
            ZStack {
                Color.dcBackground
                // Very subtle left-edge shimmer
                LinearGradient(
                    colors: [.dcOverlay, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
    }
}

// MARK: - Nav Group wrapper
private struct NavGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            SidebarGroupLabel(label)
                .padding(.bottom, 2)
            content
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Sidebar Components

struct SidebarGroupLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 8.5, weight: .black))
            .foregroundStyle(.dcSubtext)
            .kerning(1.3)
            .padding(.leading, 16)
            .padding(.top, 10)
            .padding(.bottom, 1)
    }
}

struct SidebarDivider: View {
    var body: some View {
        Rectangle()
            .fill(.dcText.opacity(0.055))
            .frame(height: 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

struct SidebarNavItem: View {
    let section: SidebarSection
    @Binding var selected: SidebarSection
    @State private var isHovered = false

    var isSelected: Bool { selected == section }

    var body: some View {
        Button(action: { selected = section }) {
            HStack(spacing: 10) {

                // ── Icon ── (completely static, zero animation)
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected
                              ? section.themeColor.opacity(0.18)
                              : (isHovered ? .dcOverlayLine : Color.clear))
                        .frame(width: 28, height: 28)

                    Image(systemName: section.icon)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(isSelected
                                         ? section.themeColor
                                         : .dcText.opacity(isHovered ? 0.85 : 0.6))
                        .shadow(color: isSelected ? section.themeColor.opacity(0.6) : .clear, radius: 5)
                }

                // ── Label ── (completely static)
                Text(section.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .dcText : .dcText.opacity(isHovered ? 0.8 : 0.55))
                    .lineLimit(1)

                Spacer()

                // ── Active pill ── (static, no movement)
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(section.themeColor)
                        .frame(width: 3, height: 16)
                        .shadow(color: section.themeColor.opacity(0.8), radius: 4)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(section.themeColor.opacity(0.09))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(section.themeColor.opacity(0.2), lineWidth: 0.5)
                            )
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.dcOverlay)
                    }
                }
            )
        }
        .buttonStyle(.plain)
        .onHover { h in isHovered = h }
    }
}

// MARK: - Sidebar Status Widget
struct SidebarStatusWidget: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status row
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(appState.isScanning ? .dcOrange.opacity(0.2) : .dcGreen.opacity(0.15))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(appState.isScanning ? .dcOrange : .dcGreen)
                        .frame(width: 6, height: 6)
                        .shadow(color: appState.isScanning ? .dcOrange : .dcGreen, radius: 4)
                }
                Text(appState.isScanning ? "SCANNING" : "PROTECTED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.dcText)
                    .kerning(1.0)
                Spacer()
            }

            // Junk found
            if appState.totalJunkFound > 0 {
                HStack(alignment: .bottom, spacing: 3) {
                    Text(ByteCountFormatter.string(fromByteCount: appState.totalJunkFound, countStyle: .file))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.dcText)
                    Text("found")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.dcSubtext)
                        .padding(.bottom, 1)
                }
            } else {
                Text(appState.isScanning ? "Analyzing system..." : "System is clean")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.dcSubtext)
            }

            // Scan progress bar
            if appState.isScanning {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.dcBorder).frame(height: 3)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.dcGreen, .dcCyan],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(8, geo.size.width * appState.scanProgress), height: 3)
                            .shadow(color: .dcGreen.opacity(0.6), radius: 4)
                    }
                }
                .frame(height: 3)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.scanProgress)
            }
        }
        .padding(14)
        .background(.dcOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.dcBorder, lineWidth: 0.5))
    }
}

// MARK: - Legacy compat stubs
struct SidebarSectionGroup: View {
    let title: String
    let sections: [SidebarSection]
    @Binding var selected: SidebarSection
    let namespace: Namespace.ID
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SidebarGroupLabel(title)
            ForEach(sections, id: \.self) { section in
                SidebarNavItem(section: section, selected: $selected)
            }
        }
    }
}
struct SidebarRow: View {
    let section: SidebarSection
    let isSelected: Bool
    let namespace: Namespace.ID
    var body: some View { SidebarNavItem(section: section, selected: .constant(isSelected ? section : .dashboard)) }
}
struct StorageMiniWidget: View {
    @EnvironmentObject var appState: AppState
    var body: some View { SidebarStatusWidget() }
}

// MARK: - Detail Router  ← THE KEY FIX: pure opacity, no slide
struct DetailView: View {
    @EnvironmentObject var appState: AppState
    @State private var displayedSection: SidebarSection = .dashboard
    @State private var contentOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.dcBackground
            contentView(for: displayedSection)
                .opacity(contentOpacity)
        }
        .onChange(of: appState.selectedSection) { _, newSection in
            // Professional cross-fade: fade out → swap → fade in
            withAnimation(.easeOut(duration: 0.12)) {
                contentOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                displayedSection = newSection
                withAnimation(.easeIn(duration: 0.18)) {
                    contentOpacity = 1
                }
            }
        }
    }

    @ViewBuilder
    private func contentView(for section: SidebarSection) -> some View {
        switch section {
        case .dashboard:       DashboardView()
        case .systemJunk:      CleanerView(items: appState.scanResults.systemItems, title: "System Junk")
        case .devCleaner:      CleanerView(items: appState.scanResults.devItems, title: "Dev Workspace")
        case .aiPromptCleaner: AIPromptCleanerView()
        case .largeFiles:      LargeFilesView()
        case .duplicates:      DuplicatesView()
        case .shredder:        ShredderView()
        case .appUninstaller:  AppUninstallerView()
        case .startupItems:    StartupItemsView()
        case .maintenance:     MaintenanceView()
        case .malwareScanner:  MalwareScannerView()
        case .ramBooster:      RAMBoosterView()
        case .spaceLens:       SpaceLensView()
        case .privacyCleaner:  PrivacyCleanerView()
        case .networkMonitor:  NetworkMonitorView()
        case .settings:        SettingsView()
        }
    }
}
