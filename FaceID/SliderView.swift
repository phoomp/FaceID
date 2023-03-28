//
//  SliderView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import SwiftUI

struct SliderView: View {
    @Binding var fps: Double
    @State var isEditing: Bool = false
    
    var minFPS: Double
    var maxFPS: Double
    
    var body: some View {
        VStack {
            Slider(value: $fps, in: minFPS...maxFPS, step: 1) {
                Text("Capture FPS")
            } minimumValueLabel: {
                Text("\(Int(minFPS))")
            } maximumValueLabel: {
                Text("\(Int(maxFPS))")
            } onEditingChanged: { editing in
                isEditing = editing
            }
        }
    }
}
