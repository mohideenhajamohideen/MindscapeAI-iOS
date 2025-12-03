import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func login(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await MainActor.run {
            isLoading = false
            if email.contains("@") && password.count >= 6 {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid email or password"
            }
        }
    }
    
    func signup(email: String, password: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run {
            isLoading = false
            if email.contains("@") && password.count >= 6 {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid email or weak password"
            }
        }
    }
    
    func logout() {
        isAuthenticated = false
    }
}
