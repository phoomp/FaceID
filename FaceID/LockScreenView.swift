//
//  LockScreenView.swift
//  FaceID
//
//  Created by Phoom Punpeng on 25/3/23.
//

import Foundation
import SwiftUI
import AppKit
import Combine
import Quartz


struct LockScreenView: View {
    @ObservedObject var state: WindowState
    @State var password = ""
    @State var showFaceIDGif = false
    @State var unlocked = false
    @State var color = Color.white
    
    var gif = QLImage("faceid-fast2")
    @State var iconOffset: CGFloat = 65

    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .opacity(0)
            VStack {
                Text("Use FaceID to Resume Session")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                
                Button {
                    showFaceIDGif = true
                    gif.preview.refreshPreviewItem()
                    unlocked = true
                    iconOffset = 0
                    let timer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { timer in
                        showFaceIDGif = false
                        state.active = false
                        print(state.active)
                    }
                } label: {
                    Text("Correct Face")
                }
                
                Button {
                    color = .red
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        color = .white
                    }
                    
                } label: {
                    Text("Wrong Face")
                }.disabled(color == .red)

            }
            VStack {
                ZStack {
                    gif
                        .frame(width: 100, height: 100)
                        .opacity(showFaceIDGif ? 1 : 0)
                        .animation(.default, value: showFaceIDGif)

                    Image(systemName: "faceid")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .opacity(unlocked ? 0 : 1)
                        .animation(.default, value: unlocked)
                        .foregroundColor(color)
                        .animation(.default, value: color)
                }
                .padding(.top, 40)
                .padding(.leading, iconOffset)
                .animation(.default, value: iconOffset)
                Spacer()
            }
        }
    }
}

    
struct Icon: View {
    var body: some View {
        Image(systemName: "person.circle.fill")
            .frame(width: 150, height: 150)
            .overlay(
                Circle()
            )
    }
}

struct QLImage: NSViewRepresentable {
    typealias NSViewType = QLPreviewView
    
    
    private let name: String
    public let preview: QLPreviewView

    init(_ name: String) {
        self.name = name
        self.preview = QLPreviewView(frame: .zero, style: .compact)
    }
    
    func makeNSView(context: NSViewRepresentableContext<QLImage>) -> QLPreviewView {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return QLPreviewView()
        }
        self.preview.autostarts = false
        self.preview.previewItem = url as QLPreviewItem
        
        return self.preview ?? QLPreviewView()
    }
    
    func updateNSView(_ nsView: QLPreviewView, context: NSViewRepresentableContext<QLImage>) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "gif")
        else {
            let _ = print("Cannot get image \(name)")
            return
        }
        nsView.previewItem = url as QLPreviewItem
    }
}
