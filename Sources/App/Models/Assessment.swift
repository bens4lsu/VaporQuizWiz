//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent


final class Assessment: Model, Content {
    static let schema = "Assessments"
    
    @ID(custom: "AssessmentID")
    var id: Int?

    @Field(key: "Name")
    var name: String
    
    @Field(key: "DisclosureText")
    var disclosureText: String

    init() { }

}

final class AssessmentContext: Content {
    let id: Int
    let name: String
    let disclosureText: String
    let passportModel: PassportModel
    
    init(_ req: Request, id: Int, passports: Passports) async throws {
        let assessment = try await Assessment.find(id, on: req.db)
        
        guard let id = assessment?.id,
              let name = assessment?.name,
              let disclosureText = assessment?.disclosureText
        else {
            throw Abort (.internalServerError, reason: "Error loading assessment \(id) from database.")
        }
        
        self.id = id
        self.name = name
        self.disclosureText = disclosureText
        
        guard let walkaway = passports[.walkaway],
              let expansion = passports[.expansion]
        else {
            throw Abort(.internalServerError, reason: "passports[.walkaway] or passports[.expansion] not properly intitialized.")
        }
        
        if name.lowercased().contains("walkaway") {
            self.passportModel = walkaway
        }
        else if name.lowercased().contains("expansion") {
            self.passportModel = expansion
        }
        else {
            throw Abort(.internalServerError, reason: "Can not initialize passport model.  Assessment name should contain either \"Walkaway\" or \"Expansion\"")
        }
    }
    
    
}
