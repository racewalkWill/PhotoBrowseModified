

import AVFoundation
import UIKit
import Accelerate
// review the Accelerate docuementation
// this is a CG (Core Graphics) oriented set of vector functions to operate
// on image formats
// mostly it operates from a source buffer to a target buffer of bytes that then
// are output as a CGImage. See workFlow documentation in Accelerate/vImage

extension CVPixelBuffer {
    func vectorNormalize( targetVector: UnsafeMutableBufferPointer<Float>) -> [Float] {
        // range = max - min
        // normalized to 0..1 is (pixel - minPixel) / range

        // see Documentation "Using vDSP for Vector-based Arithmetic" in vDSP under system "Accelerate" documentation

        // see also the Accelerate documentation section 'Vector extrema calculation'
        // Maximium static func maximum<U>(U) -> Float
        //      Returns the maximum element of a single-precision vector.

        //static func minimum<U>(U) -> Float
        //      Returns the minimum element of a single-precision vector.


        let maxValue = vDSP.maximum(targetVector)
        let minValue = vDSP.minimum(targetVector)

        let range = maxValue - minValue
        let negMinValue = -minValue

        let subtractVector = vDSP.add(negMinValue, targetVector)
            // adding negative value is subtracting
        let result = vDSP.divide(subtractVector, range)

        return result
    }

    func setUpNormalize() -> CVPixelBuffer {
        // grayscale buffer float32 ie Float
        // return normalized CVPixelBuffer

        CVPixelBufferLockBaseAddress(self,
                                     CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidthOfPlane(self, 0)
        let height = CVPixelBufferGetHeightOfPlane(self, 0)
        let count = width * height

        let bufferBaseAddress = CVPixelBufferGetBaseAddressOfPlane(self, 0)
            // UnsafeMutableRawPointer

        let pixelBufferBase  = unsafeBitCast(bufferBaseAddress, to: UnsafeMutablePointer<Float>.self)
        let pixelBufferPointer = UnsafeMutableBufferPointer<Float>(start: pixelBufferBase, count: count)

        let normalizedDisparity = vectorNormalize(targetVector: pixelBufferPointer)

        pixelBufferBase.initialize(from: normalizedDisparity, count: count)
            // copy back the normalized map into the CVPixelBuffer

        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

        return self

    }

}

