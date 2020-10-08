/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

// modified Will Loew-Blosser to demonstrate use of the CIDepthBlurEffect

import AVFoundation
import UIKit
import Accelerate
// review the Accelerate docuementation
// this is a CG (Core Graphics) oriented set of vector functions to operate
// on image formats
// mostly it operates from a source buffer to a target buffer of bytes that then
// are output as a CGImage. See workFlow documentation in Accelerate/vImage

extension CVPixelBuffer {
  func normalize() {
    let width = CVPixelBufferGetWidth(self)
    let height = CVPixelBufferGetHeight(self)
    
    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    let pixelBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)

    // MARK: TO_DO
    var minPixel: Float = 1.0  // change to Float16 in Swift 5.3 (Xcode 12, currently in beta 2020-09-12)
    var maxPixel: Float = 0.0
    
    /// You might be wondering why the for loops below use `stride(from:to:step:)`
    /// instead of a simple `Range` such as `0 ..< height`?
    /// The answer is because in Swift 5.1, the iteration of ranges performs badly when the
    /// compiler optimisation level (`SWIFT_OPTIMIZATION_LEVEL`) is set to `-Onone`,
    /// which is eactly what happens when running this sample project in Debug mode.
    /// If this was a production app then it might not be worth worrying about but it is still
    /// worth being aware of.
    
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    
    let range = maxPixel - minPixel
    NSLog("CVPixelBuffer #normalize start maxPixel = \(maxPixel), min = \(minPixel) range = \(range)")
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        pixelBuffer[y * width + x] = (pixel - minPixel) / range
      }
    }

 // check for new values
     minPixel = 1.0
     maxPixel = 0.0
    for y in stride(from: 0, to: height, by: 1) {
      for x in stride(from: 0, to: width, by: 1) {
        let pixel = pixelBuffer[y * width + x]
        minPixel = min(pixel, minPixel)
        maxPixel = max(pixel, maxPixel)
      }
    }
    let newRange = maxPixel - minPixel
     NSLog("CVPixelBuffer #normalize finish maxPixel = \(maxPixel), min = \(minPixel) range = \(newRange)")


    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

  }

    func setUpNormalize() -> CVPixelBuffer {
        // grayscale buffer float32 ie Float
        // return normalized CVPixelBuffer

        CVPixelBufferLockBaseAddress(self,
                                     CVPixelBufferLockFlags(rawValue: 0))
        let width = CVPixelBufferGetWidthOfPlane(self, 0)
        let height = CVPixelBufferGetHeightOfPlane(self, 0)
        let count = width * height

        let selfBaseAddress = CVPixelBufferGetBaseAddressOfPlane(self, 0)
            // UnsafeMutableRawPointer

        let pixelBufferBase  = unsafeBitCast(selfBaseAddress, to: UnsafeMutablePointer<Float>.self)

        let lumaCopy  =   UnsafeMutablePointer<Float>.allocate(capacity: count)
        lumaCopy.initialize(from: pixelBufferBase, count: count)

        // Calculate standard deviation.
       var mean = Float.nan
       var stdDev = Float.nan

            // normalize to a 0..1 range in self (cvPixelBuffer).
        vDSP_normalize(lumaCopy, 1, //UnsafePointer<Float> Single-precision input vector, vDSP_Stride
                       pixelBufferBase, 1, //UnsafePointer<Float>?  Single-precision output vector, or NULL , vDSP_Stride
                       &mean, &stdDev,  //Single-precision mean, stdDev of the elements of A
                       vDSP_Length(count))  //Number of elements in A
        NSLog("CVPixelBuffer #setupNormalize mean = \(mean) stdDev = \(stdDev)")
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        lumaCopy.deallocate()

        return self

    }

}
