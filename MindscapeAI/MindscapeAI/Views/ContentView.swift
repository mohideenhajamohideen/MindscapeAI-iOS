import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var palace: Palace?
    @State private var isUploading = false
    
    var body: some View {
        if !authService.isAuthenticated {
            LoginView()
                .transition(.opacity)
        } else {
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
                        .navigationTitle("")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Logout") {
                                    withAnimation {
                                        authService.logout()
                                    }
                                }
                            }
                        }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .transition(.opacity)
        }
    }
}
