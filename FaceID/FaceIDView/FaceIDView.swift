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
    
    // Runtime data
    var setup = false
    var validFaces: [[Double]] = []
    var lastDists: [Double] = []
    
    // User-editables
    public var training = false
    public var fps: Double = 30 {
        didSet {
            self.videoDevice?.set(frameRate: fps)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()

        guard self.permissionGranted else { return }
        self.setupCaptureSession()
    }
    
    override func loadView() {
        self.view = NSView()
    }
}
