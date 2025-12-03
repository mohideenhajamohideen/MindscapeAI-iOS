import Foundation

struct Palace: Codable {
    let title: String
    let environmentTheme: EnvironmentTheme
    let concepts: [Concept]
    let learningPath: [String]
    let musicSessionId: String?
    let environmentConfig: EnvironmentConfig?
    
    enum CodingKeys: String, CodingKey {
        case title, concepts
        case environmentTheme = "environment_theme"
        case learningPath = "learning_path"
        case musicSessionId = "music_session_id"
        case environmentConfig = "environment_config"
    }
    
    static func loadingPlaceholder() -> Palace {
        return Palace(
            title: "Constructing Palace...",
            environmentTheme: EnvironmentTheme(theme: "library", description: nil, rationale: nil, confidence: nil),
            concepts: [],
            learningPath: [],
            musicSessionId: nil,
            environmentConfig: nil
        )
    }
}

struct EnvironmentTheme: Codable {
    let theme: String
    let description: String? // Made optional as it might not be in the theme object but in config
    let rationale: String?
    let confidence: Double?
}

struct EnvironmentConfig: Codable {
    let theme: String
    let themeName: String?
    let description: String?
    let floorTexture: String?
    let skybox: String?
    let objects: [EnvironmentObject]?
    
    enum CodingKeys: String, CodingKey {
        case theme, description, skybox, objects
        case themeName = "theme_name"
        case floorTexture = "floor_texture"
    }
}

struct EnvironmentObject: Codable {
    let type: String
    let name: String
    let position: [Float]
    let rotation: [Float]
    let textureUrl: String?
    let size: [Float]?
    let radius: Float?
    let height: Float?
    
    enum CodingKeys: String, CodingKey {
        case type, name, position, rotation, size, radius, height
        case textureUrl = "texture_url"
    }
}
