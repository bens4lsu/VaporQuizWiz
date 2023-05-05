//
//  File.swift
//  
//
//  Created by Ben Schultz on 5/5/23.
//

import Foundation
import Vapor
import Fluent

struct UserContext: Content, Encodable, Comparable {
    var id: UUID
    var userName: String
    var emailAddress: String
    var isActive: Bool
    var isAdmin: Bool
    
    static func < (lhs: UserContext, rhs: UserContext) -> Bool {
        lhs.userName < rhs.userName
    }
    
    static func == (lhs: UserContext, rhs: UserContext) -> Bool {
        lhs.userName == rhs.userName
    }
}
