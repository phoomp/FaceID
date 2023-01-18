//
//  SliderView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import SwiftUI

struct SliderView: View {
    @Binding var framesBetweenUpdates: Double
    @State var isEditing: Bool = false
    
    var minimumValue: Int = 0
    var maximumValue: Int = 80
    
    var body: some View {
        Slider(value: $framesBetweenUpdates, in: Double(minimumValue)...Double(maximumValue), step: 5) {
            Text("Frames Between Updates")
        } minimumValueLabel: {
            Text("\(minimumValue)")
        } maximumValueLabel: {
            Text("\(maximumValue)")
        } onEditingChanged: { editing in
            isEditing = editing
        }
    }
}
