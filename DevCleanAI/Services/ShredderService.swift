import Foundation

struct ShredderService {
    enum ShredError: Error {
        case fileNotFound
        case accessDenied
        case writeError
    }
    
    func shred(url: URL, passes: Int = 1) async throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else { throw ShredError.fileNotFound }
        
        let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        let handle = try FileHandle(forWritingTo: url)
        let chunkSize = 1024 * 1024 // 1MB chunks
        let zeroChunk = Data(count: chunkSize)
        
        for _ in 0..<passes {
            // Write zeros in chunks
            var written: Int = 0
            try handle.seek(toOffset: 0)
            while written < fileSize {
                let toWrite = min(chunkSize, fileSize - written)
                try handle.write(contentsOf: zeroChunk.prefix(toWrite))
                written += toWrite
            }
            try handle.synchronize()
            
            // Write random data in chunks
            written = 0
            try handle.seek(toOffset: 0)
            var randomChunk = Data(count: chunkSize)
            while written < fileSize {
                let toWrite = min(chunkSize, fileSize - written)
                _ = randomChunk.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, toWrite, $0.baseAddress!) }
                try handle.write(contentsOf: randomChunk.prefix(toWrite))
                written += toWrite
            }
            try handle.synchronize()
        }
        
        try handle.close()
        try fileManager.removeItem(at: url)
    }
}
