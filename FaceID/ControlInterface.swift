//
//  UnlockInterface.swift
//  FaceID
//
//  Created by Phoom Punpeng on 18/1/23.
//

import SwiftUI

struct ControlInterface: View {
    @Binding var userPassword: String
    @State var justSaved: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 10) {
                    Text("Password: ")
                    SecureField("Password", text: $userPassword)
                        .onChange(of: userPassword, perform: { _ in
                            justSaved = false
                        })
                        .onSubmit {
                            do {
                                try writeUnlockScript(password: userPassword)
                            } catch {
                                print("Error! \(error)")
                            }
                            UserDefaults.standard.set(userPassword, forKey: "userPassword")
                            justSaved = true
                        }
                }
                .frame(width: 200)
                Text(justSaved ? "Saved!" : "")
                    .foregroundColor(.red)
            }
            Button {
                lockScreen()
            } label: {
                Text("Lock")
                    .frame(width: 200)
            }
            Button {
                startScreenSaver()
            } label: {
                Text("Screen Saver")
                    .frame(width: 200)
            }
            Button {
                unlockScreen()
            } label: {
                Text("Unlock")
                    .frame(width: 200)
            }
        }
    }
}

struct ControlInterface_Previews: PreviewProvider {
    static var previews: some View {
        ControlInterface(userPassword: .constant("password"))
    }
}
