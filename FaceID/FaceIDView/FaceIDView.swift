//
//  FaceIDView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 26/3/23.
//

import Foundation
import AppKit
import AVKit
import SwiftUI
import Vision


struct FaceIDView: NSViewControllerRepresentable {
    var vc: FaceIDViewController = FaceIDViewController()

    func makeNSViewController(context: Context) -> some NSViewController {
        return vc
    }

    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {}
}


class FaceIDViewController: NSViewController {
    // Capture session
    var permissionGranted = false
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var videoDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video) ?? nil
    
    // Lockscreen Window
//    let windowLevel = CGShieldingWindowLevel()
//    let windowRect = NSScreen.main?.frame
//    let visualEffect = NSVisualEffectView()
//    var overlayWindow = NSWindow(contentRect: windowRect!, styleMask: .borderless, backing: .buffered, defer: false, screen: NSScreen.screens[0])
    
    
    // Runtime data
    var setup = false
    var validFaces: [[Double]] = [[]]
    let threshold: Double = 1
    var validTime: CMTime = CMTimeMake(value: 0, timescale: 1)
    public var state = WindowState(active: false)
    
    // User-editables
    public var training = true
    public var fps: Double = 30 {
        didSet {
            self.videoDevice?.set(frameRate: fps)
        }
    }
    public var secsBeforeLock: Float64 = 5
    public var secsBeforeUnlock: Float64 = 0.3
    
    
//    public func setupLockScreen() {
//        self.overlayWindow.level = NSWindow.Level(rawValue: NSWindow.Level.RawValue(windowLevel))
//        self.overlayWindow.backgroundColor = .black
//        self.overlayWindow.alphaValue = 0.99
//
//        self.visualEffect.blendingMode = .behindWindow
//        self.visualEffect.state = .active
//        self.visualEffect.material = .fullScreenUI
//        self.overlayWindow.contentView = visualEffect
//
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()
//        setupLockScreen()
        guard self.permissionGranted else { return }
        self.setupCaptureSession()
    }
    
    override func loadView() {
        self.view = NSView()
    }
}
