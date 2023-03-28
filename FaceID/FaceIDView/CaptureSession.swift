//
//  CaptureSession.swift
//  FaceID
//
//  Created by Phoom Punpeng on 28/3/23.
//

import Foundation
import AVKit
import AppKit

extension FaceIDViewController {
    public func getMinMaxFPS() -> (Double, Double) {
        guard let range = self.videoDevice?.activeFormat.videoSupportedFrameRateRanges else { return (0, 0) }
        return (Double(range.first!.minFrameRate), Double(range.first!.maxFrameRate))
    }
    
    func setupCaptureSession() {
        self.captureSession.beginConfiguration()
        
        // Resolution
        self.captureSession.sessionPreset = .vga640x480
        
        // Output to Vision Framework
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        guard self.captureSession.canAddOutput(output) else { return }
        self.captureSession.addOutput(output)
        
        // PreviewLayer
        let screenRect = NSScreen.main?.frame
        previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resize
        
        // Webcam Input
        self.videoDevice = AVCaptureDevice.default(for: .video) ?? nil
        if self.videoDevice == nil { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: self.videoDevice!) else { return }
        guard self.captureSession.canAddInput(videoDeviceInput) else { return }
        self.captureSession.addInput(videoDeviceInput)
        
//        print("frame rate: \(videoDevice.activeVideoMaxFrameDuration)")
//        print("frame rate: \(videoDevice.activeVideoMinFrameDuration)")
        
        // Finished configuring captureSession
        self.captureSession.commitConfiguration()
        
        DispatchQueue.main.async {
            self.previewLayer.frame = self.view.bounds
            self.view.layer?.addSublayer(self.previewLayer)
        }
        
        self.captureSession.startRunning()
        
        self.videoDevice!.set(frameRate: fps)

    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            
        case .notDetermined:
            requestPermission()
            
        case .denied:
            permissionGranted = false
            print("Camera access denied")
            
        default:
            permissionGranted = false
            print("An unknown error occurred")
            
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.permissionGranted = granted
        }
    }
}
