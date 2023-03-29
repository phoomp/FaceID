//
//  Instance.swift
//  FaceID
//
//  Created by Phoom Punpeng on 29/3/23.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

public struct Instance: Codable {
    var hostName: String
    var userName: String
    var disabled: Int
    
    @ServerTimestamp var lastActive: Timestamp?
    @ServerTimestamp var createdAt: Timestamp?
}
