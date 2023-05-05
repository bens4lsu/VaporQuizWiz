//
//  File.swift
//  
//
//  Created by Ben Schultz on 1/23/21.
//

import Foundation
import Vapor


class SessionController {
    

    static func getUserId(_ req: Request) throws -> UUID? {
        guard let userId = req.session.data["userId"],
              let uuid = UUID(uuidString: userId ) else {
            return nil
        }
        return uuid
    }

    static func setUserId(_ req: Request, _ userId: UUID) {
        req.session.data["userId"] = userId.uuidString
    }

    static func getIsAdmin(_ req: Request) -> Bool {
        req.session.data["isAdmin"] == "true"
    }
    
    static func setIsAdmin(_ req: Request, _ isAdmin: Bool) {
        let string = isAdmin ? "true" : "false"
        req.session.data["isAdmin"] = string
    }
    
    static func kill(_ req: Request) {
        req.session.data = SessionData()
    }
}

