import Foundation
import Combine

class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Backend URL
    private let urlString = "https://memory-palace-leaning-model-ssbb3bwuaq-ew.a.run.app/chat/concept"
    
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    func sendMessage(_ text: String, concept: Concept) {
        let userMessage = ChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Construct chat history for backend
        let history = messages.suffix(10).map { msg in
            ["role": msg.isUser ? "user" : "model", "content": msg.text]
        }
        
        let body: [String: Any] = [
            "concept_name": concept.name,
            "concept_description": concept.description,
            "concept_facts": concept.keyFacts,
            "message": text,
            "chat_history": history
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            self.errorMessage = "Failed to encode request"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseText = json["response"] as? String {
                        
                        let aiMessage = ChatMessage(text: responseText, isUser: false)
                        self?.messages.append(aiMessage)
                        
                    } else {
                        self?.errorMessage = "Failed to parse response"
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}
