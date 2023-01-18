//
//  Utils.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import Foundation
import AppKit


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

public func unlockScreen(password: String) {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = ["/Users/phoom/Documents/test.scpt"]
     
    try! task.run()
}


