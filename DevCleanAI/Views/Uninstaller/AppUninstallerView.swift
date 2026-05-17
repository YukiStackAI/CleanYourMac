import SwiftUI

struct AppUninstallerView: View {
    @EnvironmentObject var appState: AppState
    @State private var apps: [InstalledApp] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedApp: InstalledApp?
    @State private var showConfirmation = false
    @State private var removeRelatedFiles = true
    private let service = AppUninstallerService()

    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────
            PageHeader(
                icon: "app.dashed",
                title: "App Uninstaller",
                subtitle: "Locate and remove applications along with their hidden leftovers",
                accent: appState.selectedSection.themeColor
            )

            HSplitView {
                // App list
                VStack(spacing: 0) {
                    // Search Console
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(appState.selectedSection.themeColor)
                            .font(.system(size: 14, weight: .bold))
                        TextField("Search applications...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.dcOverlay)
                    .cornerRadius(10)
                    .padding(16)
                    .background(Color.dcSurface2)

                    Divider().background(Color.dcOverlayLine)

                    if isLoading {
                        VStack(spacing: 20) {
                            ProgressView().tint(appState.selectedSection.themeColor).scaleEffect(1.2)
                            Text("Mapping applications...").font(.system(size: 12, weight: .medium)).foregroundStyle(.dcSubtext)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredApps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "questionmark.app.dashed")
                                .font(.system(size: 32))
                                .foregroundStyle(.dcSubtext.opacity(0.4))
                            Text("No apps found")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.dcSubtext)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredApps, selection: $selectedApp) { app in
                            AppListRow(app: app, isSelected: selectedApp?.id == app.id, accent: appState.selectedSection.themeColor)
                                .tag(app)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture { selectedApp = app }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .frame(minWidth: 320, idealWidth: 360)
                .background(Color.dcSurface2.opacity(0.5))

                // Detail panel
                ZStack {
                    if let app = selectedApp {
                        AppDetailPanel(
                            app: app,
                            removeRelatedFiles: $removeRelatedFiles,
                            accent: appState.selectedSection.themeColor,
                            onUninstall: { showConfirmation = true }
                        )
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    } else {
                        VStack(spacing: 32) {
                            ZStack {
                                Circle()
                                    .stroke(appState.selectedSection.themeColor.opacity(0.1), lineWidth: 1)
                                    .frame(width: 160, height: 160)
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 64, weight: .thin))
                                    .foregroundStyle(appState.selectedSection.themeColor.opacity(0.3))
                            }
                            
                            VStack(spacing: 8) {
                                Text("No Application Selected")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.dcText)
                                Text("Select an app from the list to analyze its footprint\nand identify orphan files.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.dcSubtext)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedApp?.id)
            }
        }
        .background(Color.dcBackground)
        .task { await loadApps() }
        .confirmationDialog(
            "Confirm Uninstallation",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Uninstall Application", role: .destructive) { Task { await uninstall() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Moving \(selectedApp?.name ?? "") and \(removeRelatedFiles ? "all related files" : "the primary app") to Trash.")
        }
    }

    private func loadApps() async {
        isLoading = true
        apps = await service.scanInstalledApps()
        isLoading = false
    }

    private func uninstall() async {
        guard let app = selectedApp else { return }
        try? await service.uninstall(app: app, removeRelatedFiles: removeRelatedFiles)
        withAnimation {
            apps.removeAll { $0.id == app.id }
            selectedApp = nil
        }
    }
}

struct AppListRow: View {
    let app: InstalledApp
    let isSelected: Bool
    let accent: Color
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.path.path))
                .resizable()
                .frame(width: 36, height: 36)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.dcText)
                Text(app.version.isEmpty ? "Unknown Version" : "v\(app.version)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .dcSubtext)
            }
            
            Spacer()
            
            Text(ByteCountFormatter.string(fromByteCount: app.totalSize, countStyle: .file))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .dcSubtext)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? accent : (isHovered ? Color.dcOverlay : Color.dcSurface.opacity(0.3)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .white.opacity(0.2) : (isHovered ? accent.opacity(0.2) : Color.dcBorder), lineWidth: 0.5)
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .onHover { h in withAnimation(.spring(response: 0.2)) { isHovered = h } }
    }
}

struct AppDetailPanel: View {
    let app: InstalledApp
    @Binding var removeRelatedFiles: Bool
    let accent: Color
    let onUninstall: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // App header card
                HStack(spacing: 24) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.path.path))
                        .resizable()
                        .frame(width: 90, height: 90)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.dcText)
                        
                        HStack(spacing: 8) {
                            Text(app.bundleID)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(accent)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(accent.opacity(0.1))
                                .clipShape(Capsule())
                            
                            if let lastUsed = app.lastUsed {
                                Text("Last used \(lastUsed, style: .date)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.dcSubtext)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(24)
                .background(Color.dcSurface)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.dcOverlayLine, lineWidth: 0.5))

                // Bento Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricBlock(label: "BINARY SIZE", value: ByteCountFormatter.string(fromByteCount: app.size, countStyle: .file), icon: "app.fill", accent: accent)
                    MetricBlock(label: "RESOURCES", value: "\(app.relatedFiles.count)", icon: "folder.fill", accent: accent)
                    MetricBlock(label: "TOTAL FOOTPRINT", value: ByteCountFormatter.string(fromByteCount: app.totalSize, countStyle: .file), icon: "chart.pie.fill", accent: accent)
                }

                // Related files section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Leftover & Support Files").font(.system(size: 15, weight: .bold)).foregroundStyle(Color.dcText)
                            Text("Identification of caches, logs, and application support items").font(.system(size: 11)).foregroundStyle(.dcSubtext)
                        }
                        Spacer()
                        Toggle("", isOn: $removeRelatedFiles).toggleStyle(CheckboxToggleStyle(accent: accent)).labelsHidden()
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 1) {
                        if app.relatedFiles.isEmpty {
                            HStack {
                                Spacer()
                                Text("No auxiliary files detected").font(.system(size: 12, weight: .medium)).foregroundStyle(.dcSubtext).padding(20)
                                Spacer()
                            }
                        } else {
                            ForEach(app.relatedFiles.prefix(12), id: \.self) { url in
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(accent.opacity(0.6))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(url.lastPathComponent).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.dcText).lineLimit(1)
                                        Text(url.path).font(.system(size: 10)).foregroundStyle(.dcSubtext).lineLimit(1).truncationMode(.middle)
                                    }
                                    
                                    Spacer()
                                    
                                    if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                                        Text(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundStyle(.dcSubtext)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.dcText.opacity(0.02))
                                
                                if url != app.relatedFiles.prefix(12).last {
                                    Divider().background(Color.dcOverlayLine).padding(.horizontal, 16)
                                }
                            }
                            
                            if app.relatedFiles.count > 12 {
                                Text("+ \(app.relatedFiles.count - 12) more hidden items...")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(accent.opacity(0.7))
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.dcOverlay)
                            }
                        }
                    }
                    .background(Color.dcSurface)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.dcOverlayLine, lineWidth: 0.5))
                    .opacity(removeRelatedFiles ? 1 : 0.4)
                    .animation(.easeInOut, value: removeRelatedFiles)
                }

                // Final Action
                VStack(spacing: 16) {
                    Button(action: onUninstall) {
                        HStack(spacing: 12) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text("COMPLETE UNINSTALL")
                                .font(.system(size: 14, weight: .black))
                                .kerning(1)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Color(hex: "#B91C1C"), Color(hex: "#EF4444")], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#B91C1C").opacity(0.35), radius: 15, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                        Text("This will move the selected application and its \(app.relatedFiles.count) resource files to the Trash.")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.dcSubtext)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 16)
            }
            .padding(32)
        }
    }
}

struct MetricBlock: View {
    let label: String
    let value: String
    let icon: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(accent.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(accent)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(Color.dcText)
                Text(label).font(.system(size: 9, weight: .black)).foregroundStyle(.dcSubtext).kerning(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.dcSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.dcOverlayLine, lineWidth: 0.5))
    }
}
