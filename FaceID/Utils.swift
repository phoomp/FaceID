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
    let t = Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { t in
        performLockScreen()
    }
}


public func performLockScreen() {
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
                    print(opacity)
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
            print(opacity)
            overlayWindow.alphaValue = opacity
            overlayWindow.update()
        }
        else {
            opacityTimer.invalidate()
        }
    }
    overlayWindow.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces]
    overlayWindow.makeKeyAndOrderFront(nil)
    overlayWindow.makeMain()
}

public func startScreenSaver() {
    return
    let url = NSURL(fileURLWithPath: "/System/Library/CoreServices/ScreenSaverEngine.app", isDirectory: true) as URL

    let path = "/bin"
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.arguments = [path]
    NSWorkspace.shared.openApplication(at: url,
                                       configuration: configuration,
                                       completionHandler: nil)
}

public func writeUnlockScript(password: String) throws {
    if password.contains("\"") {
        fatalError("Password cannot contain the character \"")
    }
    
    let stringToWrite: String = """
        tell application "System Events" to key code 53
        delay 0.1
        tell application "System Events" to keystroke return
        delay 0.25
        tell application "System Events" to keystroke "\(password)"
        tell application "System Events" to keystroke return
    """
    
    DispatchQueue.global(qos: .userInitiated).async {
        let filename = getDocumentsDirectory().appending(path: "unlock.scpt")
        
        do {
            try stringToWrite.write(to: filename, atomically: true, encoding: .utf8)
        } catch {
            print("Error: \(error)")
        }
    }
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .applicationScriptsDirectory, in: .userDomainMask)
    return paths[0]
}

public func unlockScreen() {
    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        let scriptPath = getDocumentsDirectory().appending(path: "unlock.scpt")
        task.launchPath = "/usr/bin/osascript"
        print("Running script at \(scriptPath.path(percentEncoded: false))")
        task.arguments = [scriptPath.path(percentEncoded: false)]
         
        try! task.run()
    }
}

// Facenet model definition
public func createImageClassifier() -> VNCoreMLModel? {
    // Use a default model configuration
    let defaultConfig = MLModelConfiguration()
    defaultConfig.computeUnits = .all
//    defaultConfig.
    
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


func normalize3(cgImage: CGImage) -> NSImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent),
                                      bitsPerPixel: UInt32(cgImage.bitsPerPixel),
                                      colorSpace: Unmanaged.passRetained(colorSpace),
                                      bitmapInfo: cgImage.bitmapInfo,
                                      version: 0,
                                      decode: nil,
                                      renderingIntent: cgImage.renderingIntent)

    var source = vImage_Buffer()
    var result = vImageBuffer_InitWithCGImage(
        &source,
        &format,
        nil,
        cgImage,
        vImage_Flags(kvImageNoFlags))

    guard result == kvImageNoError else { return nil }

    defer { free(source.data) }

    var destination = vImage_Buffer()
    result = vImageBuffer_Init(
        &destination,
        vImagePixelCount(cgImage.height),
        vImagePixelCount(cgImage.width),
        32,
        vImage_Flags(kvImageNoFlags))

    guard result == kvImageNoError else { return nil }

    result = vImageContrastStretch_ARGB8888(&source, &destination, vImage_Flags(kvImageNoFlags))
    guard result == kvImageNoError else { return nil }

    defer { free(destination.data) }

    return vImageCreateCGImageFromBuffer(&destination, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil).map {
        NSImage(cgImage: $0.takeRetainedValue(), size: NSSize(width: 96, height: 96))
    }
}
