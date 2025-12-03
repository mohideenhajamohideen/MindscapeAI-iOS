import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @State private var inputText = ""
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var isInputFocused: Bool
    
    let concept: Concept
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome Message
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 30))
                                        .foregroundColor(.purple)
                                        .padding(.top, 20)
                                    
                                    Text("Ask me anything about\n\(concept.name)")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, 20)
                                
                                ForEach(chatService.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if chatService.isLoading {
                                    HStack {
                                        DotLoadingView()
                                            .frame(height: 20)
                                        Spacer()
                                    }
                                    .padding(.leading)
                                    .id("loading")
                                }
                                
                                if let error = chatService.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .padding()
                                }
                                
                                Color.clear.frame(height: 10) // Bottom spacer
                            }
                            .padding()
                        }
                        .onChange(of: chatService.messages) { _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: chatService.isLoading) { loading in
                            if loading {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { focused in
                            if focused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    VStack(spacing: 0) {
                        Divider()
                        HStack(alignment: .bottom, spacing: 12) {
                            TextField("Ask a question...", text: $inputText, axis: .vertical)
                                .padding(12)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(20)
                                .focused($isInputFocused)
                                .lineLimit(1...5)
                                .disabled(chatService.isLoading)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(inputText.isEmpty || chatService.isLoading ? .gray : .blue)
                                    .shadow(radius: 2)
                            }
                            .disabled(inputText.isEmpty || chatService.isLoading)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
            .navigationTitle(concept.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        chatService.sendMessage(text, concept: concept)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = chatService.messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatService.ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                Text(.init(message.text)) // Enable Markdown
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomRight)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .padding(6)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Circle())
                    .foregroundColor(.purple)
                
                Text(.init(message.text)) // Enable Markdown
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomLeft)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                Spacer()
            }
        }
    }
}

struct DotLoadingView: View {
    @State private var showCircle1 = false
    @State private var showCircle2 = false
    @State private var showCircle3 = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .opacity(showCircle1 ? 1 : 0.3)
                .scaleEffect(showCircle1 ? 1 : 0.5)
            Circle()
                .opacity(showCircle2 ? 1 : 0.3)
                .scaleEffect(showCircle2 ? 1 : 0.5)
            Circle()
                .opacity(showCircle3 ? 1 : 0.3)
                .scaleEffect(showCircle3 ? 1 : 0.5)
        }
        .foregroundColor(.gray)
        .onAppear { performAnimation() }
    }
    
    func performAnimation() {
        let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
        withAnimation(animation) { showCircle1 = true }
        withAnimation(animation.delay(0.2)) { showCircle2 = true }
        withAnimation(animation.delay(0.4)) { showCircle3 = true }
    }
}

// Helper for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
