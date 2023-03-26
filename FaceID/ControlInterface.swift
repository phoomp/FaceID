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
            }
            Button {
                lockScreen()
            } label: {
                Text("Lock")
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
