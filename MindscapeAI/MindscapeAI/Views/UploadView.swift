import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @Binding var palace: Palace?
    @Binding var isUploading: Bool
    @State private var showDocumentPicker = false
    @State private var errorMessage: String?
    @State private var isDragging = false
    @State private var pulseAnimation = false
    
    // Theme Colors
    private let primaryGradient = LinearGradient(
        colors: [Color(hex: "4A00E0"), Color(hex: "8E2DE2")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0F0C29"), Color(hex: "302B63"), Color(hex: "24243E")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            // Ambient Orbs
            GeometryReader { proxy in
                Circle()
                    .fill(Color(hex: "8E2DE2").opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(Color(hex: "4A00E0").opacity(0.2))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .position(x: proxy.size.width, y: proxy.size.height * 0.8)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Hero Section
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(primaryGradient)
                            .frame(width: 120, height: 120)
                            .opacity(0.2)
                            .blur(radius: 20)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundStyle(primaryGradient)
                            .symbolEffect(.pulse, options: .repeating, isActive: isUploading)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Mindscape")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Transform your documents into\nimmersive memory palaces")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal)
                    }
                }
                
                // Upload Card
                if isUploading {
                    uploadingState
                } else {
                    uploadButton
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { url in
                uploadDocument(url: url)
            }
        }
    }
    
    var uploadButton: some View {
        Button(action: {
            showDocumentPicker = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    
                    VStack(spacing: 4) {
                        Text("Tap to Upload PDF")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("or drag and drop here")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 60)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: 400)
    }
    
    var uploadingState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        primaryGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: pulseAnimation ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            pulseAnimation = true
                        }
                    }
            }
            
            VStack(spacing: 8) {
                Text("Analyzing Content")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Constructing your memory palace...")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .transition(.scale.combined(with: .opacity))
    }
    
    private func uploadDocument(url: URL) {
        withAnimation {
            isUploading = true
            errorMessage = nil
        }
        
        Task {
            // We are using asCopy: false, so we MUST access the security scoped resource.
            // The URL provided by the picker is a security-scoped URL.
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                print("Attempting to read from: \(url.path)")
                
                // Read data immediately while we have access
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                // 1. Immediate Transition: Show placeholder
                DispatchQueue.main.async {
                    self.palace = Palace.loadingPlaceholder()
                }
                
                // 2. Perform Upload
                let generatedPalace = try await APIService.shared.uploadDocument(data, filename: filename)
                
                // 3. Update with Real Data
                DispatchQueue.main.async {
                    withAnimation {
                        self.palace = generatedPalace
                        self.isUploading = false
                    }
                }
            } catch {
                print("Upload error: \(error)")
                DispatchQueue.main.async {
                    withAnimation {
                        self.errorMessage = "Upload failed: \(error.localizedDescription)"
                        self.isUploading = false
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views & Extensions

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Use asCopy: false to open in place, which gives us a security scoped URL
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: false)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onPick(url)
            }
        }
    }
}
