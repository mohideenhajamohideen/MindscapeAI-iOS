import SwiftUI
import SceneKit

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
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Floor
        let floor = SCNNode(geometry: SCNFloor())
        floor.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        scene.rootNode.addChildNode(floor)
        
        // Concepts
        for concept in palace.concepts {
            guard let position = concept.position else { continue }
            
            let sphere = SCNSphere(radius: 1.0)
            sphere.firstMaterial?.diffuse.contents = UIColor.cyan
            sphere.firstMaterial?.emission.contents = UIColor.blue
            
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(position.x, position.y, position.z)
            node.name = concept.id
            
            // Add label
            let text = SCNText(string: concept.name, extrusionDepth: 0.1)
            text.font = UIFont.systemFont(ofSize: 1)
            text.firstMaterial?.diffuse.contents = UIColor.white
            
            let textNode = SCNNode(geometry: text)
            textNode.position = SCNVector3(-1, 1.5, 0)
            textNode.scale = SCNVector3(0.5, 0.5, 0.5)
            // Billboard constraint so text always faces camera
            textNode.constraints = [SCNBillboardConstraint()]
            
            node.addChildNode(textNode)
            scene.rootNode.addChildNode(node)
        }
        
        return scene
    }
    
    class Coordinator: NSObject {
        var parent: PalaceSceneView
        
        init(_ parent: PalaceSceneView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [:])
            
            if let hit = hitResults.first {
                // Find the parent node that represents the concept (in case we hit the text)
                var node = hit.node
                while node.parent != sceneView.scene?.rootNode && node.parent != nil {
                    node = node.parent!
                }
                
                if let conceptId = node.name,
                   let concept = parent.palace.concepts.first(where: { $0.id == conceptId }) {
                    parent.selectedConcept = concept
                }
            } else {
                parent.selectedConcept = nil
            }
        }
    }
}
