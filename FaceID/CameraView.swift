//
//  CameraView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 13/1/23.
//

import SwiftUI

struct CameraView: View {
    @Binding var framesBetweenUpdates: Double
    
    var body: some View {
        CameraPreview(framesBetweenUpdates: $framesBetweenUpdates)
    }
}
//
//struct CameraView_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraView(framesBetweenUpdates: .constant(10))
//    }
//}
