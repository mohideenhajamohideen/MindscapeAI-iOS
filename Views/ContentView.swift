import SwiftUI

struct ContentView: View {
    @State private var palace: Palace?
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            if let palace = palace {
                PalaceView(palace: palace)
                    .navigationTitle(palace.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Reset") {
                                self.palace = nil
                            }
                        }
                    }
            } else {
                UploadView(palace: $palace, isUploading: $isUploading)
                    .navigationTitle("Mindscape AI")
            }
        }
    }
}
