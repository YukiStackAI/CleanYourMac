import SwiftUI

struct AIPromptCleanerView: View {
    @EnvironmentObject var appState: AppState
    @State private var prompt: String = ""
    @State private var isSearching: Bool = false
    @State private var localItems: [ScanItem] = []
    @State private var isCleaning: Bool = false
    @State private var cleanProgress: Double = 0
    @State private var showConfirmation: Bool = false
    @State private var selectedForExplain: ScanItem? = nil
    @State private var searchPerformed: Bool = false
    @State private var isCustomScanning: Bool = false
    @State private var showSuccessOverlay: Bool = false
    @State private var clearedBytes: Int64 = 0

    private var selectedItems: [ScanItem] { localItems.filter { $0.isSelected } }
    private var selectedSize: Int64 { selectedItems.reduce(0) { $0 + $1.size } }

    private let suggestions = [
        "Find node_modules",
        "Xcode caches and DerivedData",
        "Python venvs over 10MB",
        "Docker containers & build caches",
        "System temp logs and caches",
        "Trash folders"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Header Bar ────────────────────────────────────────
            PageHeader(
                icon: "sparkles",
                title: "AI Prompt Cleaner",
                subtitle: "Describe what you want to find in plain English, and our smart engine will locate and select those files.",
                accent: .dcGreen
            )

            if showSuccessOverlay {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.dcGreen.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.dcGreen)
                            .shadow(color: Color.dcGreen.opacity(0.4), radius: 10)
                    }
                    VStack(spacing: 8) {
                        Text("Cleanup Successful!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.dcText)
                        Text("Successfully cleared \(ByteCountFormatter.string(fromByteCount: clearedBytes, countStyle: .file)) of custom matched files.")
                            .font(.system(size: 13))
                            .foregroundStyle(.dcSubtext)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showSuccessOverlay = false
                            prompt = ""
                            localItems = []
                            searchPerformed = false
                        }
                    }) {
                        Text("Back to Prompt Cleaner")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.dcBackground)
                            .padding(.horizontal, 24).padding(.vertical, 12)
                            .background(Color.dcGreen)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isCleaning {
                CleaningProgressView(progress: cleanProgress, color: .dcGreen)
            } else if appState.scanResults.allItems.isEmpty && !appState.isScanning && !isCustomScanning {
                // First-time scan requirement view
                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.dcGreen.opacity(0.12), .dcCyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 42))
                            .foregroundStyle(LinearGradient(colors: [.dcGreen, .dcCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }

                    VStack(spacing: 10) {
                        Text("Workspace Scan Required")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.dcText)
                        Text("To find custom prompt-based files, CleanYourMac first needs to analyze your folders. This build index will be matched against your queries instantly.")
                            .font(.system(size: 13))
                            .foregroundStyle(.dcSubtext)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 420)
                    }

                    Button(action: {
                        Task {
                            isCustomScanning = true
                            await appState.runFullScan()
                            isCustomScanning = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("Scan Entire Workspace")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.dcBackground)
                        .padding(.horizontal, 28).padding(.vertical, 13)
                        .background(LinearGradient(colors: [.dcGreen, Color(hex: "#10B981")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(14)
                        .shadow(color: .dcGreen.opacity(0.25), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.isScanning || isCustomScanning {
                // Scan in progress view
                VStack(spacing: 24) {
                    ProgressView()
                        .scaleEffect(1.2)
                    VStack(spacing: 6) {
                        Text("Analyzing Workspace Index...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.dcText)
                        Text("\(Int(appState.scanProgress * 100))% complete")
                            .font(.system(size: 11))
                            .foregroundStyle(.dcSubtext)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Primary Prompt Cleaner view
                VStack(spacing: 0) {
                    
                    // ── Search & Suggestions Pane ─────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        // Glassmorphic search bar
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(LinearGradient(colors: [.dcGreen, .dcCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            
                            TextField("Ask AI: e.g. 'find all node_modules over 500MB' or 'temporary caches'...", text: $prompt)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundStyle(.dcText)
                                .onSubmit {
                                    performSearch()
                                }
                            
                            if !prompt.isEmpty {
                                Button(action: { prompt = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.dcSubtext.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Button(action: {
                                performSearch()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "magnifyingglass")
                                    Text("Ask AI")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(LinearGradient(colors: [.dcGreen, .dcCyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .cornerRadius(9)
                                .shadow(color: .dcGreen.opacity(0.3), radius: 5)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.dcOverlay)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dcBorder, lineWidth: 1))
                        
                        // Suggestion Pills
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SUGGESTED PROMPTS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.dcSubtext.opacity(0.8))
                                .kerning(0.8)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(suggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            prompt = suggestion
                                            performSearch()
                                        }) {
                                            Text(suggestion)
                                                .font(.system(size: 11, weight: .medium))
                                                .padding(.horizontal, 12).padding(.vertical, 7)
                                                .background(.dcOverlayLine)
                                                .foregroundStyle(.dcSubtext)
                                                .cornerRadius(9)
                                                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.dcBorder, lineWidth: 0.5))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.dcSurface2.opacity(0.4))
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.dcBorder).frame(height: 0.5)
                    }

                    // ── Results pane ──────────────────────────────────────
                    if isSearching {
                        VStack {
                            ProgressView().scaleEffect(0.8).padding(.bottom, 8)
                            Text("Analyzing workspace matching query...").font(.system(size: 12)).foregroundStyle(.dcSubtext)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if !searchPerformed {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundStyle(.dcSubtext.opacity(0.4))
                            Text("Ready to Find Your Files")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.dcSubtext)
                            Text("Enter a prompt above to scan index files matching your custom rule.")
                                .font(.system(size: 11))
                                .foregroundStyle(.dcSubtext.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if localItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .font(.system(size: 48, weight: .thin))
                                .foregroundStyle(.dcSubtext.opacity(0.4))
                            Text("No matching files found")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.dcSubtext)
                            Text("Try matching categories like 'deriveddata', 'venv', or 'large files'.")
                                .font(.system(size: 11))
                                .foregroundStyle(.dcSubtext.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Matching Items Checklist
                        VStack(spacing: 0) {
                            // Checked Items Counter & Selection Buttons
                            HStack {
                                Button(action: {
                                    for idx in localItems.indices {
                                        localItems[idx].isSelected = true
                                    }
                                }) {
                                    Text("Select All")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color.dcGreen)
                                }
                                .buttonStyle(.plain)
                                
                                Text("·")
                                    .foregroundStyle(.dcSubtext.opacity(0.5))
                                
                                Button(action: {
                                    for idx in localItems.indices {
                                        localItems[idx].isSelected = false
                                    }
                                }) {
                                    Text("Clear Selection")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.dcSubtext)
                                }
                                .buttonStyle(.plain)
                                
                                Spacer()
                                
                                Text("Matched \(localItems.count) files")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.dcSubtext)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 8)
                            
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 0) {
                                    VStack(spacing: 0) {
                                        ForEach(Array(localItems.enumerated()), id: \.element.id) { index, item in
                                            CleanerItemRow(
                                                item: binding(for: item),
                                                index: index,
                                                accent: .dcGreen,
                                                onExplain: { selectedForExplain = item }
                                            )
                                            if index < localItems.count - 1 {
                                                Rectangle().fill(.dcOverlayLine).frame(height: 0.5).padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .background(.dcOverlay)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.dcGreen.opacity(0.2), lineWidth: 0.5))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                            }
                            
                            // Bottom Action Panel
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SELECTED FOR CLEANUP")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.dcSubtext)
                                        .kerning(0.8)
                                    Text("\(selectedItems.count) items (Size: \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.dcText)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    showConfirmation = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash.fill")
                                        Text("Clean Selection")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.dcBackground)
                                    .padding(.horizontal, 24).padding(.vertical, 12)
                                    .background(selectedItems.isEmpty ? Color.dcOverlayLine : Color.dcGreen)
                                    .cornerRadius(12)
                                    .shadow(color: selectedItems.isEmpty ? .clear : .dcGreen.opacity(0.2), radius: 6)
                                }
                                .buttonStyle(.plain)
                                .disabled(selectedItems.isEmpty)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.dcSurface2)
                            .overlay(alignment: .top) {
                                Rectangle().fill(Color.dcBorder).frame(height: 0.5)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedForExplain) { item in
            ExplainSheet(item: item)
        }
        .confirmationDialog("Confirm Clean", isPresented: $showConfirmation) {
            Button("Clean Items", role: .destructive) {
                Task {
                    await performClean()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(selectedItems.count) matching items? This will free \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)).")
        }
    }

    private func performSearch() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSearching = true
        searchPerformed = true
        
        Task {
            let searcher = DiskSearcher()
            let matched = await searcher.search(prompt: prompt)
            
            await MainActor.run {
                self.localItems = matched.map { item in
                    var updated = item
                    // Pre-select safe items by default, keep review items unchecked
                    updated.isSelected = (item.riskLevel == .safe)
                    return updated
                }
                isSearching = false
            }
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
        clearedBytes = selectedSize
        
        let capturedProgress: @Sendable (Double) -> Void = { progress in
            Task { @MainActor in
                self.cleanProgress = progress
            }
        }
        
        _ = await appState.cleanerEngine.clean(items: selectedItems, progressHandler: capturedProgress)
        
        // Keep AppState in sync!
        let removedIds = Set(selectedItems.map(\.id))
        appState.removeCleanedItems(ids: removedIds, freedSize: clearedBytes)
        
        isCleaning = false
        
        withAnimation {
            showSuccessOverlay = true
        }
    }

    // ── Smart Off-line Match Engine ────────────────────────────────
    private func findMatchingItems(for query: String) -> [ScanItem] {
        let lowerQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowerQuery.isEmpty { return [] }

        var matched: [ScanItem] = []
        let allItems = appState.scanResults.allItems

        // Check if there are specific size conditions, e.g., "over 50MB", "greater than 1GB"
        var sizeThreshold: Int64 = 0
        if lowerQuery.contains("over") || lowerQuery.contains("greater") || lowerQuery.contains("larger") || lowerQuery.contains(">") || lowerQuery.contains("above") {
            if lowerQuery.contains("gb") || lowerQuery.contains("gigabyte") {
                if let num = extractNumber(from: lowerQuery, suffix: "gb") {
                    sizeThreshold = num * 1024 * 1024 * 1024
                } else {
                    sizeThreshold = 1024 * 1024 * 1024
                }
            } else if lowerQuery.contains("mb") || lowerQuery.contains("megabyte") {
                if let num = extractNumber(from: lowerQuery, suffix: "mb") {
                    sizeThreshold = num * 1024 * 1024
                } else {
                    sizeThreshold = 50 * 1024 * 1024
                }
            } else if lowerQuery.contains("kb") || lowerQuery.contains("kilobyte") {
                if let num = extractNumber(from: lowerQuery, suffix: "kb") {
                    sizeThreshold = num * 1024
                }
            }
        }

        for item in allItems {
            let name = item.name.lowercased()
            let path = item.path.path.lowercased()
            let cat = item.category.rawValue.lowercased()
            
            var isMatch = false
            
            // 1. Check direct name or path string match
            if name.contains(lowerQuery) || path.contains(lowerQuery) || cat.contains(lowerQuery) {
                isMatch = true
            }
            
            // 2. Custom categories semantic parsing
            if lowerQuery.contains("node") || lowerQuery.contains("module") || lowerQuery.contains("npm") {
                if item.category == .nodeModules || item.category == .npmCache { isMatch = true }
            }
            if lowerQuery.contains("python") || lowerQuery.contains("venv") || lowerQuery.contains("pip") || lowerQuery.contains("conda") {
                if item.category == .pythonVenv || item.category == .pipCache || item.category == .condaEnv { isMatch = true }
            }
            if lowerQuery.contains("yarn") || lowerQuery.contains("pnpm") {
                if item.category == .yarnCache || item.category == .pnpmCache { isMatch = true }
            }
            if lowerQuery.contains("xcode") || lowerQuery.contains("derived") || lowerQuery.contains("simulator") || lowerQuery.contains("archive") {
                if item.category == .xcodeDerivedData || item.category == .xcodeSimulator || item.category == .xcodeArchive { isMatch = true }
            }
            if lowerQuery.contains("docker") || lowerQuery.contains("container") || lowerQuery.contains("image") {
                if item.category == .dockerImage || item.category == .dockerContainer || item.category == .dockerBuildCache { isMatch = true }
            }
            if lowerQuery.contains("cache") || lowerQuery.contains("caches") || lowerQuery.contains("temp") || lowerQuery.contains("temporary") || lowerQuery.contains("log") {
                if [.appCache, .browserCache, .tempFile, .systemLog, .gradleCache, .mavenCache, .cargoCache, .gemCache, .cocoaPodsCache].contains(item.category) {
                    isMatch = true
                }
            }
            if lowerQuery.contains("trash") || lowerQuery.contains("bin") {
                if item.category == .trashBin { isMatch = true }
            }
            if lowerQuery.contains("build") || lowerQuery.contains("artifact") || lowerQuery.contains("dist") || lowerQuery.contains("target") {
                if item.category == .buildArtifact { isMatch = true }
            }
            
            // If size filtering is requested, apply size check
            if sizeThreshold > 0 && item.size < sizeThreshold {
                isMatch = false
            }

            // Safety check: skip dangerous items from being selected/found automatically
            if item.riskLevel == .danger {
                isMatch = false
            }

            if isMatch {
                matched.append(item)
            }
        }
        
        return matched
    }

    private func extractNumber(from text: String, suffix: String) -> Int64? {
        let pattern = "(\\d+)\\s*\(suffix)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) else {
            // Fallback: extract the first contiguous number in the whole text
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
}
