//
//  Utils.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import Foundation
import AppKit
import CoreML
import Vision
import Combine
import Cocoa
import Accelerate
import SwiftUI


class WindowState: ObservableObject {
    @Published var active: Bool
    
    init(active: Bool) {
        self.active = active
    }
}

public func lockScreen() {
    Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { t in
        performLockScreenSequence()
    }
}


public func performLockScreenSequence() {
    let windowLevel = CGShieldingWindowLevel()
    let windowRect = NSScreen.main?.frame
    let visualEffect = NSVisualEffectView()
    
    var overlayWindow = NSWindow(contentRect: windowRect!, styleMask: .borderless, backing: .buffered, defer: false, screen: NSScreen.screens[0])
    overlayWindow.level = NSWindow.Level(rawValue: NSWindow.Level.RawValue(windowLevel))
    overlayWindow.backgroundColor = .black
    overlayWindow.alphaValue = 0.99
    
    visualEffect.blendingMode = .behindWindow
    visualEffect.state = .active
    visualEffect.material = .fullScreenUI
    overlayWindow.contentView = visualEffect
    
    var state = WindowState(active: true)
    
    let timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
        if state.active == false {
            overlayWindow.animationBehavior = .default
            var opacity: Double = 1
            let opacityTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { opacityTimer in
                if opacity > 0 {
                    opacity -= 0.02
                    overlayWindow.alphaValue = opacity
                    overlayWindow.update()
                }
                else {
                    opacityTimer.invalidate()
                    overlayWindow.close()
                }
            }
            timer.invalidate()
        }
    }
        
    let childView = NSHostingView(rootView: LockScreenView(state: state))
    childView.setFrameSize(NSSize(width: overlayWindow.frame.width, height: overlayWindow.frame.height))
//    childView.frame = CGRectMake(0, 0, childView.frame.width, childView.frame.height)
    
    overlayWindow.contentView?.addSubview(childView)
    
    var opacity: Double = 0
    overlayWindow.alphaValue = 0
    
    let opacityTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { opacityTimer in
        if opacity < 1 {
            opacity += 0.02
            overlayWindow.alphaValue = opacity
            overlayWindow.update()
        }
        else {
            opacityTimer.invalidate()
        }
    }
    overlayWindow.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces, .canJoinAllApplications]
    overlayWindow.makeKeyAndOrderFront(nil)
    overlayWindow.makeMain()
}


func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .applicationScriptsDirectory, in: .userDomainMask)
    return paths[0]
}


public func createImageClassifier() -> VNCoreMLModel? {
    let defaultConfig = MLModelConfiguration()
    defaultConfig.computeUnits = .all
    
    // Create an instance of the image classifier's wrapper class
    let imageClassifierWrapper = try? FaceNet3(configuration: defaultConfig)
    
    guard let imageClassifier = imageClassifierWrapper else {
        fatalError("Failed to create the FaceNet model instance")
    }
    
    // Get the underlying model instance.
    let imageClassifierModel = imageClassifier.model
    
    // Create a Vision instance using the image classifier's model instance.
    do {
        let imageClassifierVisionModel = try VNCoreMLModel(for: imageClassifierModel)
    } catch {
        print("error: \(error)")
    }
    guard let imageClassifierVisionModel = try? VNCoreMLModel(for: imageClassifierModel) else {
        fatalError("App failed to create a VNCoreML instance.")
    }
    
    return imageClassifierVisionModel
}


// https://stackoverflow.com/questions/55287140/how-to-crop-and-flip-cvpixelbuffer-and-return-cvpixelbuffer
extension CVPixelBuffer {
    func crop(to rect: CGRect) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(self, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(self) else {
            print("Failed getting base address for pixelBuffer")
            return nil
        }

        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)

        let imageChannels = 4
        let startPos = Int(rect.origin.y) * inputImageRowBytes + imageChannels * Int(rect.origin.x)
        let outWidth = UInt(rect.width)
        let outHeight = UInt(rect.height)
        let croppedImageRowBytes = Int(outWidth) * imageChannels

        var inBuffer = vImage_Buffer()
        inBuffer.height = outHeight
        inBuffer.width = outWidth
        inBuffer.rowBytes = inputImageRowBytes

        inBuffer.data = baseAddress + UnsafeMutableRawPointer.Stride(startPos)

        guard let croppedImageBytes = malloc(Int(outHeight) * croppedImageRowBytes) else {
            print("Cannot allocate memory")
            return nil
        }

        var outBuffer = vImage_Buffer(data: croppedImageBytes, height: outHeight, width: outWidth, rowBytes: croppedImageRowBytes)

        let scaleError = vImageScale_ARGB8888(&inBuffer, &outBuffer, nil, vImage_Flags(0))

        guard scaleError == kvImageNoError else {
            print("scale error")
            free(croppedImageBytes)
            return nil
        }

        return croppedImageBytes.toCVPixelBuffer(pixelBuffer: self, targetWith: Int(outWidth), targetHeight: Int(outHeight), targetImageRowBytes: croppedImageRowBytes)
    }
}

extension UnsafeMutableRawPointer {
    // Converts the vImage buffer to CVPixelBuffer
    func toCVPixelBuffer(pixelBuffer: CVPixelBuffer, targetWith: Int, targetHeight: Int, targetImageRowBytes: Int) -> CVPixelBuffer? {
        let pixelBufferType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        print("Format type: \(pixelBufferType)")
        print(kCVPixelBufferPixelFormatTypeKey)
        print("\(kCVPixelFormatType_OneComponent16Half)")
        print("\(kCVPixelFormatType_32BGRA)")
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }
        
        var targetPixelBuffer: CVPixelBuffer?
        let conversionStatus = CVPixelBufferCreateWithBytes(nil, targetWith, targetHeight, pixelBufferType, self, targetImageRowBytes, releaseCallBack, nil, nil, &targetPixelBuffer)
        
        guard conversionStatus == kCVReturnSuccess else {
            print("Conversion error")
            free(self)
            return nil
        }
        
        return targetPixelBuffer
    }
}
