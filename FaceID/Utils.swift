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


public func lockScreen() -> Void {
    let libHandle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY)
    let sym = dlsym(libHandle, "SACLockScreenImmediate")
    typealias mF = @convention(c) () -> Void
    
    let SACLockScreenImmediate = unsafeBitCast(sym, to: mF.self)
    SACLockScreenImmediate()
}

public func startScreenSaver() {
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
        delay 3
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
public func createImageClassifer() -> VNCoreMLModel {
    // Use a default model configuration
    let defaultConfig = MLModelConfiguration()
    
    // Create an instance of the image classifier's wrapper class
    let imageClassifierWrapper = try? FaceNet(configuration: defaultConfig)
    
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
