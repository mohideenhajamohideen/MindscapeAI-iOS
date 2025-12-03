import Foundation

struct Concept: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let mnemonicPrompt: String
    let audioScript: String
    let keyFacts: [String]
    let connections: [String]
    var imageUrl: String?
    var audioUrl: String?
    var position: Position?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, connections
        case mnemonicPrompt = "mnemonic_prompt"
        case audioScript = "audio_script"
        case keyFacts = "key_facts"
        case imageUrl = "image_url"
        case audioUrl = "audio_url"
        case position
    }
}

struct Position: Codable {
    let x: Float
    let y: Float
    let z: Float
}
