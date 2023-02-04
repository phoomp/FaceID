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
    private var framesInvalid: Int = 0
    private var framesBetweenUpdates: Int = 10
    private var screenLocked: Bool = false

    var saveAllFrames: Bool = true
    var performFaceRecognition: Bool = true
    var facenetModel = createImageClassifier()
    var boxView: BoundingBox = BoundingBox()
    var saveThisFace: Bool = false
    var lockLikeManiac: Bool = false
    var framesBeforeLock: Int = 20
    
    
    var validFaces: [[Double]] = []
    var minimumSimilarity = 0.035
    
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
        output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
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
        previewLayer.videoGravity = .resize
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
    
    func performFaceLocalization(on pixelBuffer: CVPixelBuffer) -> [(CGRect, VNFaceLandmarks2D)] {
        let imageSequenceHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        var allResults: [(CGRect, VNFaceLandmarks2D)] = []
        
        let faceLandmarkRequest = VNDetectFaceLandmarksRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            for result in results {
                allResults.append((result.boundingBox, result.landmarks!))
                print("Confidence: \(result.landmarks!.confidence)")
            }
        }
        
//        let detectedFaceRequest = VNDetectFaceRectanglesRequest { request, error in
//            guard let results = request.results as? [VNFaceObservation],
//                  let result = results.first
//            else {
//                return
//            }
//            boundingBox = result.boundingBox
//        }
        
        do {
            try imageSequenceHandler.perform([faceLandmarkRequest])
        } catch {
            print("Vision request error")
            print(error.localizedDescription)
        }
        
        return allResults
    }
    
    func performFaceNetClassification(on image: CGImage) -> (Bool, Float) {
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        var positive: Bool = false
        var minDist: Double = 1000
        
        let facenetRequest = VNCoreMLRequest(model: self.facenetModel!) { request, error in
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let result = results.first else {
                fatalError("Could not decode results")
            }
            guard let rawResult = result.featureValue.multiArrayValue else { return }
            (positive, minDist) = self.processFacenetResults(result: rawResult)
        }
        
        do {
            try handler.perform([facenetRequest])
        } catch {
            print("FaceNet Error")
            print(error.localizedDescription)
        }
        
        return (positive, Float(minDist))
    }
    
    func euclideanNorm(arr1: [Double], arr2: [Double]) -> Double {
        var sumBeforeRoot: Double = 0
        for (_, (m1, m2)) in zip(arr1, arr2).enumerated() {
            sumBeforeRoot += pow((m2 - m1), 2)
        }
        
        return sumBeforeRoot.squareRoot()
    }
    
    func getLandmarkDistance(on landmark: VNFaceLandmarks2D) {
        if self.saveThisFace {
            let allPoints = landmark.allPoints!.normalizedPoints
            for point in allPoints {
                point
            }
        }
    }
    
    func convertToDoubleArray(from mlArray: MLMultiArray) -> [Double] {
        var array: [Double] = []
            
        // Get length
        let length = mlArray.count
        
        // Set content of multi array to our out put array
        for i in 0...length - 1 {
            array.append(Double(truncating: mlArray[[0, NSNumber(value: i)]]))
        }
        
        return array
    }
    
    func processFacenetResults(result: MLMultiArray) -> (Bool, Double) {
        // Euclidean Norm
        if self.saveThisFace {
            let doubleArray = self.convertToDoubleArray(from: result)
            self.validFaces.append(doubleArray)
            return (true, 0)  // Just go ahead and return 0 because the user said this face is valid.
        }
        
        var minDist: Double = 1000
        var dists: [Double] = []
        
        for face in self.validFaces {
            let doubleArray = self.convertToDoubleArray(from: result)
            var dist: Double = self.euclideanNorm(arr1: doubleArray, arr2: face)
            dists.append(dist)
//            print("Raw: \(doubleArray)")
//            print("GT: \(face)")
//            print("Dist: \(dist)")
            if dist < minDist {
                minDist = dist
            }
        }
        
        var avgDist: Double = 0
        for element in dists {
            avgDist += element
        }
        avgDist /= Double(dists.count)
        
        return (avgDist < self.minimumSimilarity, avgDist)
    }
    
    func displayObservationResults(boundingBoxes: [CGRect], landmarks: [VNFaceLandmarks2D], positives: [Bool], minDists: [Float]) {
        self.boxView.boxRects = boundingBoxes
        self.boxView.landmarks = landmarks
        DispatchQueue.main.async {
            self.boxView.frame = CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height)
            for minDist in minDists {
                if minDist < Float(self.minimumSimilarity) {
                    self.boxView.colors.append(.green)
                }
                else {
                    self.boxView.colors.append(.red)
                }
            }
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
//        self.processWithFaceNet(on: pixelBuffer)
        self.processWithVision(on: pixelBuffer)
    }
    
    func processWithVision(on pixelBuffer: CVPixelBuffer) {
        let results = performFaceLocalization(on: pixelBuffer)
        
        for result in results {
            let boundingBox = result.0
            let landmarks = result.1
        }
    }
    
    func processWithFaceNet(on pixelBuffer: CVPixelBuffer) {
        let results = performFaceLocalization(on: pixelBuffer)
        var boundingBoxes: [CGRect] = []
        var positives: [Bool] = []
        var minDists: [Float] = []
        var landmarks: [VNFaceLandmarks2D] = []
        
        for result in results {
            let boundingBox = result.0
            let landmark = result.1
            boundingBoxes.append(boundingBox)
            landmarks.append(landmark)
            
            guard let image = self.cropAndConvert(pixelBuffer: pixelBuffer, boundingBox: boundingBox) else {
    //            print("Cannot crop image, skipping.")
                if self.framesInvalid > self.framesBeforeLock {
                    startScreenSaver()
                    self.screenLocked = true
                    if !self.lockLikeManiac {
                        self.framesInvalid = 0
                    }
                }
                return
            }
            let (positive, minDist) = performFaceNetClassification(on: image)
//            print("Positive: \(positive)")
//            print("minDist: \(minDist)")
            
            positives.append(positive)
            minDists.append(minDist)
            
            // Lock/Unlocking Logic
            if positive {
                self.framesInvalid = 0
                if self.screenLocked {
                    unlockScreen()
                    self.screenLocked = false
                }
            }
        }
        self.displayObservationResults(boundingBoxes: boundingBoxes, landmarks: landmarks, positives: positives, minDists: minDists)
        DispatchQueue.global(qos: .utility).async {
            let cgImage = self.saveFullImage(pixelBuffer: pixelBuffer)
        }
        
        print("Frames invalid: \(self.framesInvalid)")
        
        if self.framesInvalid > self.framesBeforeLock {
            startScreenSaver()
            self.screenLocked = true
            if !self.lockLikeManiac {
                self.framesInvalid = 0
            }
        }
        
        self.framesInvalid += 1
    }
    func cropAndConvert(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) -> CGImage? {
        let cgImage = self.createCGImage(from: pixelBuffer, save: false, boundingBox: boundingBox)
        guard let croppedImage = cgImage?.cropping(to: boundingBox) else { return nil }
        return croppedImage
    }
}
