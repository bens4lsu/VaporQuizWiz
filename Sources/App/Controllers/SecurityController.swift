//
//  File.swift
//  
//
//  Created by Ben Schultz on 5/1/23.
//

import Foundation
import Vapor

class SecurityController {
    
    private let isAuthorized = true
    
    func userAuthorized(_ req: Request) throws -> Bool {
        guard isAuthorized == true else {
            throw Abort(.unauthorized, reason: "User not authorized for admin functions")
        }
        return true
    }
}
