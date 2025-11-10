import Foundation
import ARKit
import SceneKit
import SwiftUI

@MainActor
class ARManager: NSObject, ARSessionDelegate, ObservableObject {
    let sceneView = ARSCNView()
    private var isProcessing = false
    @Published var isCapturing = false

    // store merged points
    private let store = PointCloudStore()
    private let processor = PointCloud()

    override init() {
        super.init()

        sceneView.session.delegate = self

        // basic scene
        sceneView.scene = SCNScene()

        // start session
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        sceneView.session.run(configuration)
    }

    // ARSessionDelegate method to receive frames
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { await self.process(frame: frame) }
    }

    // process a frame and skip frames that arrive while processing
    private func process(frame: ARFrame) async {
        guard !isProcessing else { return }
        isProcessing = true

        // get vertices from processor
        let vertices = await processor.process(frame: frame)

        if isCapturing {
            await store.add(vertices)
            // update visualization
            if let geometry = await store.geometry() {
                // replace existing node
                sceneView.scene.rootNode.enumerateChildNodes { node, _ in
                    if node.name == "pointCloud" { node.removeFromParentNode() }
                }
                let node = SCNNode(geometry: geometry)
                node.name = "pointCloud"
                node.geometry?.firstMaterial?.lightingModel = .constant
                node.geometry?.firstMaterial?.readsFromDepthBuffer = false
                sceneView.scene.rootNode.addChildNode(node)
            }
        }

        isProcessing = false
    }

    func startCapturing() {
        isCapturing = true
    }

    func stopCapturing() {
        isCapturing = false
    }

    func exportPLY() async -> String {
        let vertices = await store.all()
        return PLYExporter.export(vertices: vertices)
    }

    func clearCaptured() async {
        await store.clear()
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "pointCloud" { node.removeFromParentNode() }
        }
    }
}
