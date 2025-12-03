import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @Binding var palace: Palace?
    @Binding var isUploading: Bool
    @State private var showDocumentPicker = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Create Your Memory Palace")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Upload a PDF to generate an immersive 3D learning experience.")
                .multilineTextAlignment(.center)
                .padding()
                .foregroundColor(.secondary)
            
            if isUploading {
                ProgressView("Analyzing content...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    showDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                        Text("Select PDF")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { url in
                uploadDocument(url: url)
            }
        }
    }
    
    private func uploadDocument(url: URL) {
        isUploading = true
        errorMessage = nil
        
        Task {
            do {
                // Access security scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    errorMessage = "Permission denied"
                    isUploading = false
                    return
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                let generatedPalace = try await APIService.shared.uploadDocument(data, filename: filename)
                
                DispatchQueue.main.async {
                    self.palace = generatedPalace
                    self.isUploading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                    self.isUploading = false
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf], asCopy: true)
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
