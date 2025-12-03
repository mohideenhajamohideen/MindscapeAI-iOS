import SwiftUI

struct ConceptDetailView: View {
    let concept: Concept
    @StateObject private var audioService = AudioService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let imageUrl = concept.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    } placeholder: {
                        ProgressView()
                            .frame(height: 200)
                    }
                }
                
                Text(concept.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let audioUrl = concept.audioUrl, let url = URL(string: audioUrl) {
                    Button(action: {
                        if audioService.isPlaying {
                            audioService.stop()
                        } else {
                            audioService.play(url: url)
                        }
                    }) {
                        HStack {
                            Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 44))
                            Text(audioService.isPlaying ? "Pause Narration" : "Play Narration")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description")
                        .font(.headline)
                    Text(concept.description)
                        .font(.body)
                }
                
                if !concept.keyFacts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Key Facts")
                            .font(.headline)
                        ForEach(concept.keyFacts, id: \.self) { fact in
                            HStack(alignment: .top) {
                                Text("•")
                                Text(fact)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mnemonic")
                        .font(.headline)
                    Text(concept.mnemonicPrompt)
                        .font(.body)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onDisappear {
            audioService.stop()
        }
    }
}
