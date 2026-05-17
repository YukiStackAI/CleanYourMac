import SwiftUI

// Helper to avoid compiler type-check timeout
private struct CleanButtonLabel: View {
    let isEmpty: Bool
    let accent: Color
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "trash").font(.system(size: 12, weight: .semibold))
            Text("Clean").font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(.dcText)
        .padding(.horizontal, 18).padding(.vertical, 11)
        .background(buildBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isEmpty ? 0.45 : 1)
    }

    @ViewBuilder
    private var buildBackground: some View {
        if isEmpty {
            Color.dcOverlayLine
        } else {
            LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}


struct CleanerView: View {
    let items: [ScanItem]
    let title: String

    @EnvironmentObject var appState: AppState
    @State private var localItems: [ScanItem] = []
    @State private var isCleaning = false
    @State private var cleanProgress: Double = 0
    @State private var showConfirmation = false
    @State private var selectedForExplain: ScanItem?
    @State private var filterRisk: RiskLevel? = nil

    private var selectedItems: [ScanItem] { localItems.filter { $0.isSelected } }
    private var selectedSize: Int64 { selectedItems.reduce(0) { $0 + $1.size } }

    private var filteredItems: [ScanItem] {
        if let filter = filterRisk {
            return localItems.filter { $0.riskLevel == filter }
        }
        return localItems.filter { $0.riskLevel != .danger }
    }

    private var groupedItems: [(String, [ScanItem])] {
        let grouped = Dictionary(grouping: filteredItems, by: { $0.category.groupLabel })
        return grouped.map { ($0.key, $0.value.sorted { $0.size > $1.size }) }
            .sorted { $0.1.reduce(0) { $0 + $1.size } > $1.1.reduce(0) { $0 + $1.size } }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Premium Header Bar ────────────────────────────────
            PageHeader(
                icon: appState.selectedSection.icon,
                title: title,
                subtitle: title == "Dev Workspace" ? "Clean up Xcode caches, derived data, and simulator artifacts" : "Remove unused system cache and temporary logs to free up space",
                accent: appState.selectedSection.themeColor
            )

            // ── Filter Toolbar ────────────────────────────────────
            HStack(spacing: 12) {
                // Filter pills
                HStack(spacing: 6) {
                    FilterPill(label: "All", isActive: filterRisk == nil, color: appState.selectedSection.themeColor) { filterRisk = nil }
                    FilterPill(label: "Safe", isActive: filterRisk == .safe, color: .dcGreen) { filterRisk = .safe }
                    FilterPill(label: "Review", isActive: filterRisk == .review, color: .dcOrange) { filterRisk = .review }
                }

                Spacer()

                // Selected size badge
                if !selectedItems.isEmpty {
                    HStack(spacing: 6) {
                        Circle().fill(appState.selectedSection.themeColor).frame(width: 6, height: 6)
                        Text(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(appState.selectedSection.themeColor)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(appState.selectedSection.themeColor.opacity(0.1))
                    .clipShape(Capsule())
                }

                Button(action: {
                    for i in localItems.indices {
                        if localItems[i].riskLevel == .safe { localItems[i].isSelected = true }
                    }
                }) {
                    Text("Select Safe")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.dcSubtext)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.dcOverlayLine)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.dcBorder, lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .disabled(localItems.isEmpty)

                Button(action: { showConfirmation = true }) {
                    CleanButtonLabel(
                        isEmpty: selectedItems.isEmpty,
                        accent: appState.selectedSection.themeColor
                    )
                }
                .buttonStyle(.plain)
                .disabled(selectedItems.isEmpty || isCleaning)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.dcSurface2)
            .overlay(alignment: .bottom) {
                Rectangle().fill(.dcBorder).frame(height: 0.5)
            }

            if isCleaning {
                CleaningProgressView(progress: cleanProgress, color: appState.selectedSection.themeColor)
            } else if localItems.isEmpty {
                EmptyCleanerView(title: title)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedItems, id: \.0) { groupName, groupItems in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(Array(groupItems.enumerated()), id: \.element.id) { index, item in
                                        CleanerItemRow(
                                            item: binding(for: item),
                                            index: index,
                                            accent: appState.selectedSection.themeColor,
                                            onExplain: { selectedForExplain = item }
                                        )
                                        if index < groupItems.count - 1 { Rectangle().fill(.dcOverlayLine).frame(height: 0.5).padding(.horizontal, 16) }
                                    }
                                }
                                .background(.dcOverlay)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(appState.selectedSection.themeColor.opacity(0.2), lineWidth: 0.5))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                            } header: {
                                GroupHeader(
                                    name: groupName,
                                    totalSize: groupItems.reduce(0) { $0 + $1.size },
                                    itemCount: groupItems.count,
                                    accent: appState.selectedSection.themeColor
                                )
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("")
        .onAppear { localItems = items }
        .onChange(of: items) { _, newItems in localItems = newItems }
        .sheet(item: $selectedForExplain) { item in
            ExplainSheet(item: item)
        }
        .confirmationDialog("Confirm Cleanup", isPresented: $showConfirmation) {
            Button("Clean Items", role: .destructive) { Task { await performClean() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clean \(selectedItems.count) items? This will free \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)).")
        }
    }

    private func binding(for item: ScanItem) -> Binding<ScanItem> {
        guard let index = localItems.firstIndex(where: { $0.id == item.id }) else {
            return .constant(item)
        }
        return $localItems[index]
    }

    private func performClean() async {
        isCleaning = true
        cleanProgress = 0
        let capturedProgress: @Sendable (Double) -> Void = { progress in
            Task { @MainActor in
                self.cleanProgress = progress
            }
        }
        _ = await appState.cleanerEngine.clean(items: selectedItems, progressHandler: capturedProgress)
        isCleaning = false
        localItems.removeAll { selectedItems.map(\.id).contains($0.id) }
    }
}

struct CleanerItemRow: View {
    @Binding var item: ScanItem
    let index: Int
    let accent: Color
    let onExplain: () -> Void
    @State private var isHovering = false
    @State private var isAppeared = false

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $item.isSelected)
                .toggleStyle(CheckboxToggleStyle(accent: accent))
                .labelsHidden()
                .disabled(item.riskLevel == .danger)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.riskLevel.color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: item.category.icon)
                    .foregroundStyle(item.riskLevel.color)
                    .font(.system(size: 13, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.dcText)
                        .lineLimit(1)
                    RiskBadge(level: item.riskLevel)
                }
                Text(item.path.path)
                    .font(.system(size: 10))
                    .foregroundStyle(.dcSubtext)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.sizeFormatted)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.dcText)
            
            Button(action: onExplain) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.dcSubtext)
                    .opacity(isHovering ? 1 : 0.5)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(isHovering ? .dcOverlayLine : Color.clear)
        .opacity(isAppeared ? 1 : 0)
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { isHovering = h } }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.03)) {
                isAppeared = true
            }
        }
    }
}

struct GroupHeader: View {
    let name: String
    let totalSize: Int64
    let itemCount: Int
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)
                .shadow(color: accent, radius: 3)
            Text(name.uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(accent)
                .kerning(1.0)
            Spacer()
            Text("\(itemCount) items")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.dcSubtext)
            Text("·").foregroundStyle(.dcSubtext.opacity(0.4)).font(.system(size: 10))
            Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent.opacity(0.8))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(.dcBackground.opacity(0.95))
    }
}

// CheckboxToggleStyle moved to Components.swift

struct RiskBadge: View {
    let level: RiskLevel
    var body: some View {
        if level != .safe {
            Text(level.label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(level.color.opacity(0.1))
                .foregroundStyle(level.color)
                .cornerRadius(4)
        }
    }
}

struct FilterPill: View {
    let label: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isActive ? color.opacity(0.15) : Color.clear)
                .foregroundStyle(isActive ? color : ObsidianTheme.textSecondary)
                .cornerRadius(100)
                .overlay(RoundedRectangle(cornerRadius: 100).stroke(isActive ? color.opacity(0.3) : Color.dcOverlayLine, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

struct CleaningProgressView: View {
    let progress: Double
    let color: Color
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 4)
                    .frame(width: 220, height: 220)
                
                ZStack {
                    Circle().fill(Color.dcSurface2)
                    LiquidWave(progress: CGFloat(progress), waveHeight: 10, offset: waveOffset)
                        .fill(LinearGradient(colors: [color.opacity(0.8), color], startPoint: .top, endPoint: .bottom))
                        .mask(Circle())
                }
                .frame(width: 212, height: 212)
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.dcText)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { waveOffset = .pi * 2 }
            }
            
            Text("Cleaning System Artifacts...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ObsidianTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyCleanerView: View {
    let title: String
    @EnvironmentObject var appState: AppState
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(appState.selectedSection.themeColor.opacity(0.1)).frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle").font(.system(size: 36, weight: .thin)).foregroundStyle(appState.selectedSection.themeColor.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("All Clean!").font(.system(size: 18, weight: .bold)).foregroundStyle(.dcText)
                Text("No junk detected in the \(title) sector.").font(.system(size: 13)).foregroundStyle(.dcSubtext).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExplainSheet: View {
    let item: ScanItem
    @Environment(\.dismiss) var dismiss
    @State private var explanation: String = ""
    @State private var isLoading = true
    private let llm = LLMService()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("File Analysis")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ObsidianTheme.textSecondary)
                }.buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name).font(.system(size: 16, weight: .semibold)).foregroundStyle(.dcText)
                Text(item.path.path).font(.system(size: 12)).foregroundStyle(ObsidianTheme.textSecondary).lineLimit(1)
            }
            .padding(16)
            .background(.dcOverlayLine)
            .cornerRadius(12)

            ScrollView(showsIndicators: false) {
                if isLoading {
                    ProgressView().padding(.top, 40).frame(maxWidth: .infinity)
                } else {
                    Text(explanation)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .foregroundStyle(ObsidianTheme.text)
                }
            }
        }
        .padding(24)
        .background(ObsidianTheme.background)
        .frame(width: 480, height: 400)
        .task {
            explanation = await llm.explain(item: item)
            isLoading = false
        }
    }
}
