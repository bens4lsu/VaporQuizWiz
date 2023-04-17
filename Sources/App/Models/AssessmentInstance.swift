//
//  File.swift
//
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent


final class AssessmentInstance: Model, Content {
    static let schema = "AssessmentInstances"
    
    @ID(custom: "AssessmentInstanceID")
    var id: Int?

    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "DateStart")
    var dateStart: Date
    
    @Field(key: "DateComplete")
    var dateComplte: Date?

    init() { }
    
    init(forAID aid: Int) {
        self.assessmentId = aid
        self.dateStart = Date()
    }
}


final class AssessmentInstanceContext: Content {
    let id: Int
    let assessment: AssessmentContext
    let dateStart: Date
    var dateComplete: Date?
    var pageComplete: Int
    
    init(_ req: Request, forAssessmentId aid: Int, passports: Passports) async throws {
        let ai = AssessmentInstance(forAID: aid)
        try await ai.save(on: req.db)
        
        guard let id = ai.id else {
            throw Abort (.internalServerError, reason: "Error saving AssessmentInstance for \(aid) to database.")
        }
        
        self.id = id
        self.dateStart = ai.dateStart
        self.assessment = try await AssessmentContext(req, id: aid, passports: passports)
        self.pageComplete = 0
        self.dateComplete = nil
    }
    
}


