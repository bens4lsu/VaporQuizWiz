//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent

class AssessmentController {
    var passports: Passports
    
    init(passports: Passports) {
        self.passports = passports
    }
    
    func new(_ req: Request, aid: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, forAssessmentId: aid, passports: passports)
    }
    
}
