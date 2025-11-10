import Foundation
import ARKit
import simd

/// A simple POD used across modules
public struct PointVertex {
    public var position: simd_float3
    public var color: simd_float4

    public init(position: simd_float3, color: simd_float4) {
        self.position = position
        self.color = color
    }
}

actor PointCloud {
    // process a single ARFrame and return captured vertices
    func process(frame: ARFrame) async -> [PointVertex] {
        guard let depth = (frame.smoothedSceneDepth ?? frame.sceneDepth),
              let depthBuffer = PixelBuffer<Float32>(pixelBuffer: depth.depthMap),
              let confidenceMap = depth.confidenceMap,
              let confidenceBuffer = PixelBuffer<UInt8>(pixelBuffer: confidenceMap),
              let imageBuffer = YCBCRBuffer(pixelBuffer: frame.capturedImage)
        else {
            return []
        }

        var vertices: [PointVertex] = []
        vertices.reserveCapacity((depthBuffer.size.width * depthBuffer.size.height) / 8)

        for row in 0..<depthBuffer.size.height {
            for col in 0..<depthBuffer.size.width {
                let confidenceRawValue = Int(confidenceBuffer.value(x: col, y: row))
                guard let confidence = ARConfidenceLevel(rawValue: confidenceRawValue) else { continue }
                if confidence != .high { continue }

                let depthValue = depthBuffer.value(x: col, y: row)
                if depthValue.isNaN || depthValue <= 0 || depthValue > 2.0 { continue }

                let normalizedCoord = simd_float2(Float(col) / Float(depthBuffer.size.width),
                                                 Float(row) / Float(depthBuffer.size.height))

                let imageSize = imageBuffer.size.asFloat
                let pixelRow = Int(round(normalizedCoord.y * imageSize.y))
                let pixelColumn = Int(round(normalizedCoord.x * imageSize.x))
               
                let normalizedDistance = min(depthValue / 2.0, 1.0) //normalize 0-2m to 0-1
                let color = distanceColor(distance: normalizedDistance)

                // convert to camera local 3D point
                let screenPoint = simd_float3(normalizedCoord * imageSize, 1)
                let intrinsics = frame.camera.intrinsics
                let localPoint = simd_inverse(intrinsics) * screenPoint * depthValue

                // flip axes to match ARKit coordinate system
                let flipYZ = matrix_float4x4(columns: (
                    simd_float4(1, 0, 0, 0),
                    simd_float4(0, -1, 0, 0),
                    simd_float4(0, 0, -1, 0),
                    simd_float4(0, 0, 0, 1)
                ))

                // get camera transform and convert to world
                let rotationAngle: Float = .pi/2 // assume portrait for now (matches sample)
                let q = simd_quaternion(rotationAngle, simd_float3(0, 0, 1))
                let rotation = matrix_float4x4(q)
                let cameraTransform = frame.camera.viewMatrix(for: .portrait).inverse * rotation * flipYZ

                let local = simd_float4(localPoint, 1)
                let worldPoint = cameraTransform * local
                let worldPosition = simd_make_float3(worldPoint.x / worldPoint.w, worldPoint.y / worldPoint.w, worldPoint.z / worldPoint.w)

                vertices.append(PointVertex(position: worldPosition, color: color))
            }
        }

        return vertices
    }
    
    /// Generate color based on distance (0.0 = close/blue, 1.0 = far/red)
    private func distanceColor(distance: Float) -> simd_float4 {
        // Create a gradient from blue (close) to red (far)
        // Blue -> Cyan -> Green -> Yellow -> Red
        let r: Float
        let g: Float
        let b: Float
        
        if distance < 0.25 {
            // Blue to Cyan (0.0 - 0.25)
            let t = distance * 4.0
            r = 0.0
            g = t
            b = 1.0
        } else if distance < 0.5 {
            // Cyan to Green (0.25 - 0.5)
            let t = (distance - 0.25) * 4.0
            r = 0.0
            g = 1.0
            b = 1.0 - t
        } else if distance < 0.75 {
            // Green to Yellow (0.5 - 0.75)
            let t = (distance - 0.5) * 4.0
            r = t
            g = 1.0
            b = 0.0
        } else {
            // Yellow to Red (0.75 - 1.0)
            let t = (distance - 0.75) * 4.0
            r = 1.0
            g = 1.0 - t
            b = 0.0
        }
        
        return simd_float4(r, g, b, 1.0)
    }
    
}

