import Foundation

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
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // File data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError("Invalid response")
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError("Server returned \(httpResponse.statusCode)")
        }
        
        do {
            let palace = try JSONDecoder().decode(Palace.self, from: responseData)
            return palace
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
}
