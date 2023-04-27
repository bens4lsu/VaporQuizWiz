//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/20/23.
//

import Foundation
import Vapor

final class AssessmentInstanceContext: Content, Error {
    let id: Int
    let assessment: AssessmentContext
    let dateStart: Date
    var dateComplete: Date?
    //var pageComplete: Int
    var name: String?
    var email: String?
    var showBossErrorMessage: Bool = false
    var instanceIdEncrypted: String
    var hostname: String
    var port: Int
    
    init(_ req: Request, forAssessmentId aid: Int, passports: Passports, keys: ConfigurationSettings.CryptKeys) async throws {
        let ai = AssessmentInstance(forAID: aid)
        try await ai.save(on: req.db)
        
        guard let id = ai.id else {
            throw Abort (.internalServerError, reason: "Error saving AssessmentInstance for \(aid) to database.")
        }
        
        self.id = id
        self.dateStart = ai.dateStart
        self.assessment = try await AssessmentContext(req, id: aid, passports: passports, keys: keys)
        //self.pageComplete = 0
        self.dateComplete = nil
        self.instanceIdEncrypted = try BenCrypt.encode(String(id), keys: keys)
        self.hostname = req.application.http.server.configuration.hostname
        self.port = req.application.http.server.configuration.port
        
    }
    
    init(_ req: Request, assessmentId aid: Int, instance: Int, passports: Passports, keys: ConfigurationSettings.CryptKeys) async throws {
        guard let ai = try await AssessmentInstance.find(instance, on: req.db) else {
            throw Abort (.badRequest, reason: "attempt to look up assessment instance that does not exist.")
        }
        self.id = instance
        self.dateStart = ai.dateStart
        self.assessment = try await AssessmentContext(req, id: aid, passports: passports, keys: keys)
        //self.pageComplete = 5
        self.dateComplete = ai.dateComplete
        self.name = ai.name
        self.email = ai.email
        self.instanceIdEncrypted = try BenCrypt.encode(String(id), keys: keys)
        self.hostname = req.application.http.server.configuration.hostname
        self.port = req.application.http.server.configuration.port
    }
    
    func reportContext(withDetails details: [AssessmentInstanceDetailContext]) throws -> AssessmentInstanceReportContext {
        guard let name = self.name else {
            throw Abort (.internalServerError, reason: "Attempt to generate a report context before the assessment taker's name is stored.")
        }
        
        return AssessmentInstanceReportContext(id: self.id, assessment: self.assessment, details: details, takerName: name, takerEmail: email ?? "", hostname: self.hostname, port: self.port)
    }
}
