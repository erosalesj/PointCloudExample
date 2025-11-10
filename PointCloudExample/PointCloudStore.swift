import Foundation
import SceneKit
import simd

actor PointCloudStore {
    private var vertices: [PointVertex] = []

    func add(_ newVertices: [PointVertex]) {
        vertices.append(contentsOf: newVertices)
    }

    func clear() {
        vertices.removeAll()
    }

    func all() -> [PointVertex] { vertices }

    /// Build an SCNGeometry from collected vertices. Returns nil if empty.
    func geometry() -> SCNGeometry? {
        guard !vertices.isEmpty else { return nil }

        // positions
        var positionArray = [Float] ()
        positionArray.reserveCapacity(vertices.count * 3)
        
        var colorArray = [Float] ()
        colorArray.reserveCapacity(vertices.count * 4)
        
        

        for v in vertices {
            positionArray.append(v.position.x)
            positionArray.append(v.position.y)
            positionArray.append(v.position.z)
            
            colorArray.append(v.color.x)
            colorArray.append(v.color.y)
            colorArray.append(v.color.z)
            colorArray.append(v.color.w)
        }
        
        let posData = Data(bytes: positionArray, count: positionArray.count * MemoryLayout<Float>.size)
        let colorData = Data(bytes: colorArray, count: colorArray.count * MemoryLayout<Float>.size)

        let posSource = SCNGeometrySource(data: posData,
                                          semantic: .vertex,
                                          vectorCount: vertices.count,
                                          usesFloatComponents: true,
                                          componentsPerVector: 3,
                                          bytesPerComponent: MemoryLayout<Float>.size,
                                          dataOffset: 0,
                                          dataStride: MemoryLayout<Float>.size * 3)

        let colorSource = SCNGeometrySource(data: colorData,
                                            semantic: .color,
                                            vectorCount: vertices.count,
                                            usesFloatComponents: true,
                                            componentsPerVector: 4,
                                            bytesPerComponent: MemoryLayout<Float>.size,
                                            dataOffset: 0,
                                            dataStride: MemoryLayout<Float>.size * 4)

        // indices: each point as a single index
        var indices = [Int32]()
        indices.reserveCapacity(vertices.count)
        for i in 0..<vertices.count { indices.append(Int32(i)) }
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<Int32>.size)

        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .point,
                                         primitiveCount: vertices.count,
                                         bytesPerIndex: MemoryLayout<Int32>.size)

        let geo = SCNGeometry(sources: [posSource, colorSource], elements: [element])
        return geo
    }
}
