import Foundation
import CoreVideo
import simd

final class YCBCRBuffer {
    let size: Size
    private let pixelBuffer: CVPixelBuffer
    private let yPlane: UnsafeMutableRawPointer
    private let cbCrPlane: UnsafeMutableRawPointer
    private let ySize: Size
    private let cbCrSize: Size

    init?(pixelBuffer: CVPixelBuffer) {
        self.pixelBuffer = pixelBuffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
              let cbCrPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
        else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
        }

        self.yPlane = yPlane
        self.cbCrPlane = cbCrPlane

        size = .init(width: CVPixelBufferGetWidth(pixelBuffer),
                     height: CVPixelBufferGetHeight(pixelBuffer))

        ySize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                      height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))

        cbCrSize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                         height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 1))
    }

    func color(x: Int, y: Int) -> simd_float4 {
        // clamp coordinates
        let px = max(0, min(x, size.width - 1))
        let py = max(0, min(y, size.height - 1))

        let yIndex = py * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) + px
        // uv are subsampled (2x)
        let uvx = px / 2
        let uvy = py / 2
        let uvIndex = uvy * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) + uvx * 2

        let yValue = yPlane.advanced(by: yIndex).assumingMemoryBound(to: UInt8.self).pointee
        let cbValue = cbCrPlane.advanced(by: uvIndex).assumingMemoryBound(to: UInt8.self).pointee
        let crValue = cbCrPlane.advanced(by: uvIndex + 1).assumingMemoryBound(to: UInt8.self).pointee

        let yf = Float(Int(yValue)) - 16
        let cbf = Float(Int(cbValue)) - 128
        let crf = Float(Int(crValue)) - 128

        var r = 1.164 * yf + 1.596 * crf
        var g = 1.164 * yf - 0.392 * cbf - 0.813 * crf
        var b = 1.164 * yf + 2.017 * cbf

        r = min(max(r / 255.0, 0), 1)
        g = min(max(g / 255.0, 0), 1)
        b = min(max(b / 255.0, 0), 1)

        return simd_float4(r, g, b, 1)
    }

    deinit {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }
}
