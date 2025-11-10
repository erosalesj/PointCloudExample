import Foundation
import simd

/// Simple ASCII PLY exporter for PointVertex
enum PLYExporter {
    static func export(vertices: [PointVertex]) -> String {
        var out = "ply\nformat ascii 1.0\n"
        out += "element vertex \(vertices.count)\n"
        out += "property float x\nproperty float y\nproperty float z\n"
        out += "property uchar red\nproperty uchar green\nproperty uchar blue\n"
        out += "end_header\n"

        for v in vertices {
            // convert color [0..1] to 0..255
            let r = UInt8(max(0, min(255, Int(round(v.color.x * 255)))))
            let g = UInt8(max(0, min(255, Int(round(v.color.y * 255)))))
            let b = UInt8(max(0, min(255, Int(round(v.color.z * 255)))))
            out += "\(v.position.x) \(v.position.y) \(v.position.z) \(r) \(g) \(b)\n"
        }

        return out
    }
}
