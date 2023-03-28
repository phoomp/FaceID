//
//  FaceRecognition.swift
//  FaceID
//
//  Created by Phoom Punpeng on 28/3/23.
//

import Foundation
import AVKit
import AppKit
import Vision
import CoreML


extension FaceIDViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func performFaceLocalization(on pixelBuffer: CVPixelBuffer) -> [(CGRect, VNFaceLandmarks2D)] {
        let imageSequenceHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        var allResults: [(CGRect, VNFaceLandmarks2D)] = []

        let faceLandmarkRequest = VNDetectFaceLandmarksRequest { request, error in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            for result in results {
                allResults.append((result.boundingBox, result.landmarks!))
            }
        }

        do {
            try imageSequenceHandler.perform([faceLandmarkRequest])
        } catch {
            print("Vision request error")
            print(error.localizedDescription)
        }

        return allResults
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let results = self.performFaceLocalization(on: pixelBuffer)
        
        for (box, landmarks) in results {
            let pointSet = PointSet(facePoints: landmarks.allPoints!.normalizedPoints)
            let dists = pointSet.calculateDistances()
            let diff = self.euclideanNorm(arr1: dists, arr2: lastDists)
//            print("diff: \(diff)")
            self.lastDists = dists
        }
    }

    func createCGImage(from pixelBuffer: CVPixelBuffer) -> String {
        let ciContext = CIContext()
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let filename = "/Users/phoom/Documents/FaceID/imgs/\(UUID()).png"
        
        do {
            try ciContext.writePNGRepresentation(of: ciImage, to: URL(filePath: filename), format: .BGRA8, colorSpace: ciImage.colorSpace!)
        } catch {
            print("Error: \(error)")
        }
        
        return filename
    }
    
    func euclideanNorm(arr1: [Double], arr2: [Double]) -> Double {
        var sumBeforeRoot: Double = 0
        for (m1, m2) in zip(arr1, arr2) {
            sumBeforeRoot += pow((m2 - m1), 2)
        }

        return sumBeforeRoot.squareRoot()
    }
}
