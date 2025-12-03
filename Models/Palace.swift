import Foundation

struct Palace: Codable {
    let title: String
    let environmentTheme: EnvironmentTheme
    let environmentConfig: EnvironmentConfig?
    let concepts: [Concept]
    let learningPath: [String]
    let musicSessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case title, concepts
        case environmentTheme = "environment_theme"
        case environmentConfig = "environment_config"
        case learningPath = "learning_path"
        case musicSessionId = "music_session_id"
    }
}

struct EnvironmentTheme: Codable {
    let theme: String
    let description: String?
    let rationale: String?
}

struct EnvironmentConfig: Codable {
    let floorTexture: String?
    let objects: [EnvironmentObject]?
    
    enum CodingKeys: String, CodingKey {
        case floorTexture = "floor_texture"
        case objects
    }
}

struct EnvironmentObject: Codable {
    let type: String
    let name: String?
    let position: [Float]
    let rotation: [Float]
    let size: [Float]?
    let radius: Float?
    let height: Float?
    let textureUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case type, name, position, rotation, size, radius, height
        case textureUrl = "texture_url"
    }
}
