import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor LLMService {

    func explain(item: ScanItem) async -> String {
        // Try Apple Intelligence first
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if let result = await tryAppleIntelligence(item: item) {
                return result
            }
        }
        #endif
        
        // Try Claude backup
        if let result = await tryClaude(item: item) {
            return result
        }
        
        // Fallback to hardcoded rules
        return fallbackExplanation(for: item)
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func tryAppleIntelligence(item: ScanItem) async -> String? {
        let model = SystemLanguageModel.default

        // Check if Apple Intelligence is available
        guard case .available = model.availability else {
            return nil
        }

        let session = LanguageModelSession()
        let prompt = """
        You are a helpful macOS system cleaner assistant. In 2-3 short sentences, explain:
        1. What this item is
        2. Whether it is safe to delete
        3. Whether it can be recreated automatically

        Item: \(item.name)
        Type: \(item.category.rawValue)
        Size: \(item.sizeFormatted)
        Last accessed: \(item.lastAccessedFormatted)
        Can recreate: \(item.canRecreate ? "Yes" : "No")

        Be concise, friendly, and practical. No markdown or bullet points.
        """

        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return nil
        }
    }
    #endif

    private func tryClaude(item: ScanItem) async -> String? {
        let apiKey = UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
        guard !apiKey.isEmpty else { return nil }
        
        let prompt = """
        You are a helpful macOS system cleaner assistant. In 2-3 short sentences, explain:
        1. What this item is
        2. Whether it is safe to delete
        3. Whether it can be recreated automatically

        Item: \(item.name)
        Type: \(item.category.rawValue)
        Size: \(item.sizeFormatted)
        Last accessed: \(item.lastAccessedFormatted)
        Can recreate: \(item.canRecreate ? "Yes" : "No")

        Be concise, friendly, and practical. No markdown or bullet points.
        """

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 150,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content = json["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }
        
        return nil
    }

    private func fallbackExplanation(for item: ScanItem) -> String {
        switch item.category {
        case .nodeModules:
            return "This is a Node.js dependency folder. Completely safe to delete — npm or yarn will recreate it automatically when you run `npm install` in the project."
        case .pythonVenv:
            return "This is a Python virtual environment. Safe to delete — recreate it with `python -m venv .venv` and reinstall packages with `pip install -r requirements.txt`."
        case .npmCache, .pipCache, .yarnCache, .pnpmCache:
            return "This is a package manager cache. Deleting it won't break anything — it will just be slightly slower next time you install packages as they re-download."
        case .xcodeDerivedData:
            return "Xcode's build cache. Safe to delete — Xcode will rebuild it automatically on next build. Your source code is completely unaffected."
        case .xcodeSimulator:
            return "iOS/macOS simulator runtimes. Safe to delete unused ones — they will re-download from Xcode if needed later."
        case .xcodeArchive:
            return "Xcode app archives used for distribution. Review before deleting — if you need to re-submit or debug a release, you may need these."
        case .dockerImage, .dockerBuildCache:
            return "Docker build cache or image data. Safe to clear unused ones — active containers won't be affected."
        case .appCache, .browserCache:
            return "Application cache files. Safe to delete — apps regenerate these automatically. You may need to re-login to some websites."
        case .buildArtifact:
            return "Build output folder. Completely safe to delete — regenerated by running your build command again."
        case .gradleCache, .mavenCache:
            return "Java build tool cache. Safe to delete — dependencies will re-download on next build."
        case .cargoCache:
            return "Rust package cache. Safe to delete — Cargo will re-download crates on next build."
        case .systemLog:
            return "System log files. Safe to delete — these are old logs and won't affect system operation."
        case .tempFile:
            return "Temporary files. Safe to delete — these are leftovers that are no longer needed."
        case .trashBin:
            return "Your Trash bin. These files are already deleted from their original location — emptying frees up this space permanently."
        default:
            return item.canRecreate ? "This can be recreated automatically. Safe to delete to free up space." : "Review before deleting — check if you still need this."
        }
    }
}
