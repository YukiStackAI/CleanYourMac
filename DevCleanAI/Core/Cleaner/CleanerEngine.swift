import Foundation
import AppKit

actor CleanerEngine {

    enum CleanResult {
        case success(freedBytes: Int64)
        case partialSuccess(freedBytes: Int64, errors: [CleanError])
        case failure(CleanError)
    }

    struct CleanError: Error {
        let item: ScanItem
        let underlying: Error
    }

    /// Move selected items to Trash. NEVER permanently deletes.
    func clean(items: [ScanItem], progressHandler: @Sendable (Double) -> Void) async -> CleanResult {
        guard !items.isEmpty else { return .success(freedBytes: 0) }

        var freedBytes: Int64 = 0
        var errors: [CleanError] = []
        let total = Double(items.count)

        for (index, item) in items.enumerated() {
            // Safety check — never delete dangerous items
            guard item.riskLevel != .danger else {
                errors.append(CleanError(
                    item: item,
                    underlying: CleanEngineError.dangerousItem("Item marked as dangerous — skipped for safety")
                ))
                continue
            }

            do {
                try await moveToTrash(url: item.path)
                freedBytes += item.size
            } catch {
                errors.append(CleanError(item: item, underlying: error))
            }

            await MainActor.run {
                progressHandler(Double(index + 1) / total)
            }
        }

        if errors.isEmpty {
            return .success(freedBytes: freedBytes)
        } else if freedBytes > 0 {
            return .partialSuccess(freedBytes: freedBytes, errors: errors)
        } else {
            return .failure(errors.first!)
        }
    }

    private func moveToTrash(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.main.async {
                do {
                    var resultingURL: NSURL?
                    try FileManager.default.trashItem(at: url, resultingItemURL: &resultingURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Get the total size of items that would be freed
    func calculateFreeable(items: [ScanItem]) -> Int64 {
        items.filter { $0.riskLevel != .danger }.reduce(0) { $0 + $1.size }
    }
}

enum CleanEngineError: LocalizedError {
    case dangerousItem(String)
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .dangerousItem(let msg): return msg
        case .permissionDenied(let path): return "Permission denied: \(path)"
        }
    }
}
