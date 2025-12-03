import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemIndigo), Color.black]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo / Title
                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .cyan, radius: 10)
                    
                    Text("Mindscape: Memory Palace")
                        .font(.custom("Avenir-Heavy", size: 32)) // Slightly smaller to fit
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // Form Fields
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(ModernTextFieldStyle(icon: "envelope.fill"))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(ModernTextFieldStyle(icon: "lock.fill"))
                }
                .padding(.horizontal, 30)
                
                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Action Button
                Button(action: {
                    Task {
                        if isSignUp {
                            await authService.signup(email: email, password: password)
                        } else {
                            await authService.login(email: email, password: password)
                        }
                    }
                }) {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isSignUp ? "Sign Up" : "Log In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                }
                .padding(.horizontal, 30)
                .disabled(authService.isLoading)
                
                // Toggle Mode
                Button(action: {
                    withAnimation {
                        isSignUp.toggle()
                        authService.errorMessage = nil
                    }
                }) {
                    Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    let icon: String
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            configuration
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .foregroundColor(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
