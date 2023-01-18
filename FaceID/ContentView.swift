//
//  ContentView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 12/1/23.
//

import SwiftUI


struct ContentView: View {
    @State var framesBetweenUpdates: Double = 10
    var cameraView: CameraView
    
    init() {
        self.cameraView = CameraView()
        self.cameraView.vc.saveAllFrames = false
    }
    
    var body: some View {
        VStack {
            self.cameraView
                .onChange(of: framesBetweenUpdates) { newValue in
                    self.cameraView.vc.set(framesBetweenUpdates: Int(newValue))
                }
            Spacer()
            SliderView(framesBetweenUpdates: $framesBetweenUpdates)
                .padding(.vertical)
                .frame(width: 800)
            Button {
                lockScreen()
            } label: {
                Text("Lock")
            }
            Button {
                startScreenSaver()
            } label: {
                Text("Screen Saver")
            }
            Button {
                unlockScreen(password: "Edifice@1213")
            } label: {
                Text("Unlock")
            }

        }
        .padding()
    }
}

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
        } .onSubmit {
            
        }
        Text("\(Int(framesBetweenUpdates))")
            .foregroundColor(isEditing ? .red : .blue)
            
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
