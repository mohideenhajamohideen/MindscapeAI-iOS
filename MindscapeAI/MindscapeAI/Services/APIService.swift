import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

class APIService: ObservableObject {
    static let shared = APIService()
    private let baseURL = "https://memory-palace-leaning-model-ssbb3bwuaq-ew.a.run.app"
    
    func uploadDocument(_ data: Data, filename: String) async throws -> Palace {
        guard let url = URL(string: "\(baseURL)/api/process-content") else {
            throw APIError.invalidURL
        }
        
        print("🚀 Starting upload to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("close", forHTTPHeaderField: "Connection")
        request.setValue("", forHTTPHeaderField: "Expect") // Disable Expect: 100-continue
        
        var body = Data()
        
        // File data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        print("📦 Uploading file size: \(ByteCountFormatter.string(fromByteCount: Int64(body.count), countStyle: .file))")
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 600 // 10 minutes
        configuration.timeoutIntervalForResource = 600
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 1 // Force serial connections
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: configuration)
        
        print("⏳ Timeout set to: \(configuration.timeoutIntervalForRequest) seconds")
        
        let maxRetries = 3
        var currentRetry = 0
        
        while true {
            do {
                if currentRetry > 0 {
                    print("🔄 Retry attempt \(currentRetry)/\(maxRetries)")
                }
                
                let (responseData, response) = try await session.upload(for: request, from: body)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    throw APIError.serverError("Invalid response")
                }
                
                print("📥 Response Status: \(httpResponse.statusCode)")
                
                // Check for success
                if (200...299).contains(httpResponse.statusCode) {
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        print("📄 Response Body: \(responseString)")
                    }
                    
                    let palace = try JSONDecoder().decode(Palace.self, from: responseData)
                    print("✅ Decoding successful")
                    return palace
                }
                
                // Check for retryable errors (503 Service Unavailable, 504 Gateway Timeout)
                if [503, 504].contains(httpResponse.statusCode) && currentRetry < maxRetries {
                    let delay = Double(pow(2.0, Double(currentRetry))) // Exponential backoff: 1s, 2s, 4s
                    print("⚠️ Server returned \(httpResponse.statusCode). Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    currentRetry += 1
                    continue
                }
                
                // Non-retryable error or max retries reached
                print("❌ Server error: \(httpResponse.statusCode)")
                if let responseString = String(data: responseData, encoding: .utf8) {
                    print("📄 Error Body: \(responseString)")
                }
                throw APIError.serverError("Server returned \(httpResponse.statusCode)")
                
            } catch {
                // If it's a network error (not a server error response we threw), we might want to retry too?
                // For now, let's stick to retrying 503/504 as planned.
                // But if the upload itself fails (e.g. connection lost), we could retry.
                // Let's keep it simple for now and rethrow unless we want to catch specific URLErrors.
                print("❌ Upload error: \(error)")
                throw error
            }
        }
    }
}
