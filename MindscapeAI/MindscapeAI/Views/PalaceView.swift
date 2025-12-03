import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct PalaceView: View {
    let palace: Palace
    @State private var selectedConcept: Concept?
    
    var body: some View {
        ZStack {
            PalaceSceneView(palace: palace, selectedConcept: $selectedConcept)
                .edgesIgnoringSafeArea(.all)
            
            if let concept = selectedConcept {
                VStack {
                    Spacer()
                    ConceptPreviewCard(concept: concept)
                        .padding()
                        .transition(.move(edge: .bottom))
                }
            }
            
            if palace.concepts.isEmpty {
                VStack {
                    Spacer()
                    HStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Constructing your Memory Palace...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
            }
        }
    }
}

struct ConceptPreviewCard: View {
    let concept: Concept
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(concept.name)
                .font(.headline)
            Text(concept.description)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)
            
            Button("View Details") {
                showDetails = true
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .sheet(isPresented: $showDetails) {
            ConceptDetailView(concept: concept)
        }
    }
}

struct PalaceSceneView: UIViewRepresentable {
    let palace: Palace
    @Binding var selectedConcept: Concept?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.black
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Critical: Update coordinator's parent to access the latest state (real palace data)
        context.coordinator.parent = self
        
        guard let scene = uiView.scene else { return }
        
        // Check if we have new concepts to add
        let existingNodeNames = scene.rootNode.childNodes.compactMap { $0.name }
        
        for (index, concept) in palace.concepts.enumerated() {
            if !existingNodeNames.contains(concept.id) {
                // Add new concept with animation
                addConceptNode(concept, index: index, totalCount: palace.concepts.count, to: scene)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // 1. Camera Rig & Cinematic Fly-in
        let cameraRig = SCNNode()
        cameraRig.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(cameraRig)
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 200 // Increase draw distance
        
        // Start Position (Inside Entrance, Centered on Palace at X=-10)
        let startPos = SCNVector3(-10, 5, 30)
        let endPos = SCNVector3(-10, 2, 8)
        let lookAtTarget = SCNVector3(-10, 2, -20) // Look towards the throne area
        
        cameraNode.position = startPos
        cameraNode.look(at: lookAtTarget)
        cameraRig.addChildNode(cameraNode)
        
        // Fly-in Animation
        let flyInAction = SCNAction.customAction(duration: 5.0) { node, elapsedTime in
            let percentage = elapsedTime / 5.0
            
            let currentX = startPos.x + (endPos.x - startPos.x) * Float(percentage)
            let currentY = startPos.y + (endPos.y - startPos.y) * Float(percentage)
            let currentZ = startPos.z + (endPos.z - startPos.z) * Float(percentage)
            
            node.position = SCNVector3(currentX, currentY, currentZ)
            node.look(at: lookAtTarget)
        }
        flyInAction.timingMode = .easeOut
        
        // After fly-in, start the gentle orbit
        let startOrbit = SCNAction.run { _ in
            let rotation = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 80) // Very slow orbit
            let repeatRotation = SCNAction.repeatForever(rotation)
            cameraRig.runAction(repeatRotation)
        }
        
        cameraNode.runAction(SCNAction.sequence([flyInAction, startOrbit]))
        
        // 2. Lighting (Brilliant Setup)
        let omniLight = SCNNode()
        omniLight.light = SCNLight()
        omniLight.light?.type = .omni
        omniLight.light?.color = UIColor(white: 1.0, alpha: 1.0)
        omniLight.light?.intensity = 1200
        omniLight.position = SCNVector3(0, 15, 10)
        scene.rootNode.addChildNode(omniLight)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // 3. Load Palace Model
        if let sceneUrl = Bundle.main.url(forResource: "palace", withExtension: "usdz") {
            if let palaceScene = try? SCNScene(url: sceneUrl, options: nil) {
                for child in palaceScene.rootNode.childNodes {
                    // Heuristic Texturing
                    if let name = child.name?.lowercased() {
                        if name.contains("floor") || name.contains("ground") || name.contains("plane") {
                            if let floorTexture = palace.environmentConfig?.floorTexture {
                                loadTexture(from: floorTexture) { image in
                                    child.geometry?.firstMaterial?.diffuse.contents = image
                                    child.geometry?.firstMaterial?.diffuse.wrapS = .repeat
                                    child.geometry?.firstMaterial?.diffuse.wrapT = .repeat
                                }
                            }
                        }
                    }
                    
                    // Auto-Scale & Position
                    let (minVec, maxVec) = child.boundingBox
                    let width = maxVec.x - minVec.x
                    let height = maxVec.y - minVec.y
                    let length = maxVec.z - minVec.z
                    
                    if width > 0 && height > 0 {
                        let targetSize: Float = 60.0
                        let maxDimension = max(width, max(height, length))
                        let scaleFactor = targetSize / maxDimension
                        
                        child.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                        
                        // Centered Position (X=-10, Y=0, Z=-5)
                        let offsetX: Float = -10.0
                        let offsetY: Float = 0.0
                        let offsetZ: Float = -5.0
                        
                        child.position = SCNVector3(
                            (-((minVec.x + maxVec.x) / 2) * scaleFactor) + offsetX,
                            (-minVec.y * scaleFactor) + offsetY,
                            (-((minVec.z + maxVec.z) / 2) * scaleFactor) + offsetZ
                        )
                        
                        scene.rootNode.addChildNode(child)
                    } else {
                        scene.rootNode.addChildNode(child)
                    }
                }
            } else {
                createProceduralRoom(in: scene)
            }
        } else {
            createProceduralRoom(in: scene)
        }
        
        // 4. Environment Objects (Pillars, etc.) - Keep backend positioning for these
        if let objects = palace.environmentConfig?.objects {
            for obj in objects {
                if let node = createEnvironmentNode(from: obj) {
                    scene.rootNode.addChildNode(node)
                    if let textureUrl = obj.textureUrl {
                        loadTexture(from: textureUrl) { image in
                            node.geometry?.firstMaterial?.diffuse.contents = image
                        }
                    }
                }
            }
        }
        
        // 5. Concepts (Initial Load)
        for (index, concept) in palace.concepts.enumerated() {
            addConceptNode(concept, index: index, totalCount: palace.concepts.count, to: scene)
        }
        
        return scene
    }
    
    private func addConceptNode(_ concept: Concept, index: Int, totalCount: Int, to scene: SCNScene) {
        let radius: Float = 8.0
        // Arc from -60 to +60 degrees
        let startAngle: Float = -60.0 * (.pi / 180.0)
        let endAngle: Float = 60.0 * (.pi / 180.0)
        let angleStep = totalCount > 1 ? (endAngle - startAngle) / Float(totalCount - 1) : 0
        
        let angle = startAngle + (Float(index) * angleStep)
        let x = (radius * sin(angle)) - 11.0 // Shift left by 5 more units (total -11)
        let z = radius * cos(angle) - 4.0 // Shift arc back slightly
        
        // Create Brilliant Sphere (Colorless base to show texture)
        let sphere = SCNSphere(radius: 0.8)
        let material = sphere.firstMaterial!
        material.diffuse.contents = UIColor.white // White base for textures
        material.specular.contents = UIColor.white // Shiny
        material.emission.contents = UIColor(white: 0.1, alpha: 1) // Slight glow, neutral
        material.shininess = 50.0
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(x, 1.5, z) // Float at eye level
        node.name = concept.id
        
        // Start invisible and scaled down for "Pop" animation
        node.opacity = 0
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        
        if let imageURL = concept.imageUrl {
            loadTexture(from: imageURL) { image in
                material.diffuse.contents = image
            }
        }
        
        // Floating Animation (Bobbing)
        let randomDelay = Double.random(in: 0...1)
        let moveUp = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.5)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        let sequence = SCNAction.sequence([moveUp, moveDown])
        let repeatBob = SCNAction.repeatForever(sequence)
        
        // Pop-in Animation
        let scaleUp = SCNAction.scale(to: 1.0, duration: 0.5)
        scaleUp.timingMode = .easeOut
        let fadeIn = SCNAction.fadeIn(duration: 0.5)
        let appear = SCNAction.group([scaleUp, fadeIn])
        
        node.runAction(SCNAction.sequence([
            SCNAction.wait(duration: Double(index) * 0.2), // Staggered appearance
            appear,
            SCNAction.wait(duration: randomDelay),
            repeatBob
        ]))
        
        // Text Label
        let text = SCNText(string: concept.name, extrusionDepth: 0.02)
        text.font = UIFont(name: "Avenir-Heavy", size: 0.5) ?? UIFont.systemFont(ofSize: 0.5, weight: .bold)
        text.firstMaterial?.diffuse.contents = UIColor(white: 0.1, alpha: 1.0) // Dark Charcoal
        text.firstMaterial?.emission.contents = UIColor.clear // No glow for sharp contrast
        text.flatness = 0.1 // Smoother text curves
        
        let textNode = SCNNode(geometry: text)
        // Center text
        let (min, max) = textNode.boundingBox
        let dx = min.x - 0.5 * (max.x - min.x)
        let dy = min.y - 0.5 * (max.y - min.y)
        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)
        
        textNode.position = SCNVector3(0, 1.2, 0) // Above sphere
        textNode.constraints = [SCNBillboardConstraint()]
        
        node.addChildNode(textNode)
        scene.rootNode.addChildNode(node)
    }
    
    private func createProceduralRoom(in scene: SCNScene) {
        print("🏗️ Creating procedural room...")
        
        // Floor
        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray // Brighter
        floor.geometry?.firstMaterial?.lightingModel = .physicallyBased
        // Important: SCNFloor is reflective by default, making it look black if skybox is black
        (floor.geometry as? SCNFloor)?.reflectivity = 0.0 
        scene.rootNode.addChildNode(floor)
        
        // Load Floor Texture
        if let floorURL = palace.environmentConfig?.floorTexture {
            loadTexture(from: floorURL) { image in
                floor.geometry?.firstMaterial?.diffuse.contents = image
            }
        }
        
        // Simple Walls
        let wallHeight: CGFloat = 15.0
        let roomSize: CGFloat = 60.0
        
        let wallGeo = SCNBox(width: roomSize, height: wallHeight, length: 1.0, chamferRadius: 0)
        wallGeo.firstMaterial?.diffuse.contents = UIColor.white
        wallGeo.firstMaterial?.lightingModel = .physicallyBased
        
        // Back Wall
        let backWall = SCNNode(geometry: wallGeo)
        backWall.position = SCNVector3(0, Float(wallHeight)/2, -Float(roomSize)/2)
        scene.rootNode.addChildNode(backWall)
        
        // Left Wall
        let leftWall = SCNNode(geometry: wallGeo)
        leftWall.position = SCNVector3(-Float(roomSize)/2, Float(wallHeight)/2, 0)
        leftWall.eulerAngles.y = .pi / 2
        scene.rootNode.addChildNode(leftWall)
        
        // Right Wall
        let rightWall = SCNNode(geometry: wallGeo)
        rightWall.position = SCNVector3(Float(roomSize)/2, Float(wallHeight)/2, 0)
        rightWall.eulerAngles.y = .pi / 2
        scene.rootNode.addChildNode(rightWall)
    }
    
    private func createEnvironmentNode(from obj: EnvironmentObject) -> SCNNode? {
        var geometry: SCNGeometry?
        
        switch obj.type {
        case "box":
            if let size = obj.size, size.count == 3 {
                geometry = SCNBox(width: CGFloat(size[0]), height: CGFloat(size[1]), length: CGFloat(size[2]), chamferRadius: 0)
            }
        case "cylinder":
            if let radius = obj.radius, let height = obj.height {
                geometry = SCNCylinder(radius: CGFloat(radius), height: CGFloat(height))
            }
        case "sphere":
            if let radius = obj.radius {
                geometry = SCNSphere(radius: CGFloat(radius))
            }
        default:
            return nil
        }
        
        guard let geom = geometry else { return nil }
        
        let node = SCNNode(geometry: geom)
        
        // Position
        if obj.position.count == 3 {
            node.position = SCNVector3(obj.position[0], obj.position[1], obj.position[2])
        }
        
        // Rotation (Euler angles in radians)
        if obj.rotation.count == 3 {
            node.eulerAngles = SCNVector3(obj.rotation[0], obj.rotation[1], obj.rotation[2])
        }
        
        node.name = obj.name
        return node
    }
    
    private func loadTexture(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid texture URL: \(urlString)")
            return
        }
        
        print("🖼️ Loading texture from: \(urlString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Texture load failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("❌ Texture load server error: \(httpResponse.statusCode)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                print("✅ Texture loaded successfully: \(url.lastPathComponent)")
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("❌ Failed to decode texture image data")
            }
        }.resume()
    }
    
    class Coordinator: NSObject {
        var parent: PalaceSceneView
        
        init(_ parent: PalaceSceneView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
            
            print("👆 Tap at \(location)")
            print("🎯 Hit \(hitResults.count) objects")
            
            for hit in hitResults {
                // Find the parent node that represents the concept
                var node = hit.node
                print("   - Hit node: \(node.name ?? "unnamed")")
                
                // Traverse up to find the concept root node
                // We stop if we hit the scene root or if we find a node with a name that matches a concept
                while node.parent != sceneView.scene?.rootNode && node.parent != nil {
                    // Check if this intermediate node is a concept
                    if let name = node.name, parent.palace.concepts.contains(where: { $0.id == name }) {
                        break
                    }
                    node = node.parent!
                }
                
                if let conceptId = node.name,
                   let concept = parent.palace.concepts.first(where: { $0.id == conceptId }) {
                    print("✅ Selected concept: \(concept.name)")
                    
                    // Update on main thread
                    DispatchQueue.main.async {
                        withAnimation {
                            self.parent.selectedConcept = concept
                        }
                    }
                    return // Stop after finding the first concept
                }
            }
            
            // If we got here, we didn't hit a concept
            print("❌ No concept found")
            DispatchQueue.main.async {
                withAnimation {
                    self.parent.selectedConcept = nil
                }
            }
        }
    }
}
