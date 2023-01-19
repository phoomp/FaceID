//
//  PlayerView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 13/1/23.
//

import Foundation
import AVKit
import SwiftUI
import AppKit
import Combine
import Vision

struct CameraView: NSViewControllerRepresentable {
    var vc: CameraViewController = CameraViewController()
    
//    mutating func set(framesBetweenUpdates: Double) {
//        self.framesBetweenUpdates = framesBetweenUpdates
//    }
    func makeNSViewController(context: Context) -> some NSViewController {
        return vc
    }
    
    func updateNSViewController(_ nsViewController: NSViewControllerType, context: Context) {}
}


class CameraViewController: NSViewController {
    private var permissionGranted = false
    private var captureSession = AVCaptureSession()
    private var previewLayer = AVCaptureVideoPreviewLayer()
    private var sessionQueue = DispatchQueue(label: "sessionQueue")
    private var count: Int = 0
    private var framesBetweenUpdates: Int = 10
    var saveAllFrames: Bool = true
    var performFaceRecognition: Bool = true
    var boxView: BoundingBox = BoundingBox()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermission()
                
        sessionQueue.async {
            guard self.permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
        
        self.boxView = BoundingBox(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        self.view.addSubview(self.boxView)
    }
    
    override func loadView() {
        self.view = NSView()
    }
    
    func setupCaptureSession() {
        self.captureSession.beginConfiguration()
        
        // Resolution
        self.captureSession.sessionPreset = .vga640x480
        
        // Webcam
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        guard self.captureSession.canAddInput(videoDeviceInput) else { return }
        self.captureSession.addInput(videoDeviceInput)
        
        // Output to VN and FaceNet
        let output = AVCaptureVideoDataOutput()
        let settings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_OneComponent16Half]
//        output.videoSettings = settings
        output.alwaysDiscardsLateVideoFrames = false
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        guard self.captureSession.canAddOutput(output) else {
            print("Error setting up output for capture session")
            return
        }
        self.captureSession.addOutput(output)
        
        // PreviewLayer
        let screenRect = NSScreen.main?.frame
        print("width: \(String(describing: screenRect?.width)), height: \(String(describing: screenRect?.height))")
        
        previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        self.captureSession.commitConfiguration()
        
        // Connect previewLayer and face frame
        DispatchQueue.main.async {
            self.previewLayer.frame = self.view.bounds
            self.view.addSubview(self.boxView)
            self.view.layer?.addSublayer(self.previewLayer)
        }
    }
    
    func set(framesBetweenUpdates: Int) {
        print("Set to \(framesBetweenUpdates)")
        self.framesBetweenUpdates = framesBetweenUpdates
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
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    func performVisionRequests(on pixelBuffer: CVPixelBuffer) {
        let imageSequenceHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        let detectedFaceRequest = VNDetectFaceRectanglesRequest { request, error in
            let probability: Float = self.performFaceRecognition ? self.performFaceNetInference(pixelBuffer: pixelBuffer) : 0.00
            self.displayObservationResults(request: request, probability: probability, error: error)
        }
        
        do {
            try imageSequenceHandler.perform([detectedFaceRequest])
        } catch {
            print("Vision request error")
            print(error.localizedDescription)
        }
    }
    
    func performFaceNetInference(pixelBuffer: CVPixelBuffer) -> Float {
        let configuration = MLModelConfiguration()
        guard let model = try? FaceNet(configuration: configuration) else {
            fatalError("Could not initialize model with configuration \(configuration)")
        }
        
        // WORKAROUND: Convert to CGImage and back to CVPixelBuffer. Not the most efficient, but better than converting to kCVPixelFormat directly
        let cgImage = createCGImage(from: pixelBuffer, save: false, boundingBox: nil)
        
        
//        let reshapedImage = MLMultiArray(pixelBuffer: pixelBuffer, shape: [3, 96, 96])
        guard let reshapedImage = try? MLMultiArray(shape: [1, 3, 96, 96], dataType: .float16) else {
            fatalError("Failed to create MLMultiArray")
        }
        
        let modelInput = FaceNetInput(input_1: reshapedImage)
        guard let output = try? model.prediction(input: modelInput) else { return 0.00 }
        
        print(output)
        
        return 1.00
    }
    
    func displayObservationResults(request: VNRequest, probability: Float, error: Error?) {
        guard let results = request.results as? [VNFaceObservation],
              let result = results.first
        else {
            return
        }
        
        self.boxView.boxRect = result.boundingBox
        DispatchQueue.main.async {
            self.boxView.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
            self.boxView.needsDisplay = true
        }
    }
    
    func saveFullImage(pixelBuffer: CVPixelBuffer) {
        guard let image = self.createCGImage(from: pixelBuffer, save: self.saveAllFrames, boundingBox: nil) else {
            print("Error converting image")
            return
        }
    }
    
    func createCGImage(from pixelBuffer: CVPixelBuffer, save: Bool, boundingBox: CGRect?) -> CGImage? {
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        
        if save {
            do {
                try ciContext.writePNGRepresentation(of: ciImage, to: URL(filePath: "/Users/phoom/Documents/pics/\(UUID()).png"), format: .RGBA8, colorSpace: ciImage.colorSpace!)
            } catch {
                print("Error: \(error)")
            }
        }
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }
}

extension AVCaptureDevice {
    func set(frameRate: Double) {
        guard let range = activeFormat.videoSupportedFrameRateRanges.first, range.minFrameRate...range.maxFrameRate ~= frameRate else {
            print("Requested FPS \(frameRate) is not supported by the device's activeFormat")
            return
        }
        
        do {
            try lockForConfiguration()
            
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            
            unlockForConfiguration()
        } catch {
            print("LockForConfiguration failed with error \(error)")
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), count >= self.framesBetweenUpdates else {
            count += 1
            return
        }
        count = 0
        performVisionRequests(on: pixelBuffer)
        DispatchQueue.global(qos: .utility).async {
            let cgImage = self.saveFullImage(pixelBuffer: pixelBuffer)
        }
    }
}
