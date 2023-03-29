////
////  LockScreen.swift
////  FaceID
////
////  Created by Phoom Punpeng on 29/3/23.
////
//
//import Foundation
//import AppKit
//import AVKit
//import SwiftUI
//
//
////extension FaceIDViewController {
//    public func performLockScreenSequence() {
//        DispatchQueue.main.async {
//            let windowLevel = CGShieldingWindowLevel()
//            let windowRect = NSScreen.main?.frame
//            let visualEffect = NSVisualEffectView()
//            var overlayWindow = NSWindow(contentRect: windowRect!, styleMask: .borderless, backing: .buffered, defer: false, screen: NSScreen.screens[0])
//            overlayWindow.level = NSWindow.Level(rawValue: NSWindow.Level.RawValue(windowLevel))
//            overlayWindow.backgroundColor = .black
//            overlayWindow.alphaValue = 0.99
//
//            visualEffect.blendingMode = .behindWindow
//            visualEffect.state = .active
//            visualEffect.material = .fullScreenUI
//            overlayWindow.contentView = visualEffect
//
//            let state = WindowState(active: true)
//
//            let timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
//                if state.active == false {
//                    overlayWindow.animationBehavior = .default
//                    var opacity: Double = 1
//                    let opacityTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { opacityTimer in
//                        if opacity > 0 {
//                            opacity -= 0.02
//                            overlayWindow.alphaValue = opacity
//                            overlayWindow.update()
//                        }
//                        else {
//                            opacityTimer.invalidate()
//                            overlayWindow.close()
//                        }
//                    }
//                    timer.invalidate()
//                }
//            }
//
//            let childView = NSHostingView(rootView: LockScreenView(state: state))
//            childView.setFrameSize(NSSize(width: overlayWindow.frame.width, height: overlayWindow.frame.height))
//        //    childView.frame = CGRectMake(0, 0, childView.frame.width, childView.frame.height)
//
//            overlayWindow.contentView?.addSubview(childView)
//
//            var opacity: Double = 0
//            overlayWindow.alphaValue = 0
//
//            let opacityTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { opacityTimer in
//                if opacity < 1 {
//                    opacity += 0.02
//                    overlayWindow.alphaValue = opacity
//                    overlayWindow.update()
//                }
//                else {
//                    opacityTimer.invalidate()
//                }
//            }
//            overlayWindow.collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces, .canJoinAllApplications]
//            overlayWindow.makeKeyAndOrderFront(nil)
//            overlayWindow.makeMain()
//        }
//    }
////}
