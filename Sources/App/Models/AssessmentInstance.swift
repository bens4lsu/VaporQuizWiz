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
    var dateComplete: Date?
    
    @Field(key: "UserName")
    var name: String?
    
    @Field(key: "Email")
    var email: String?

    init() { }
    
    init(forAID aid: Int) {
        self.assessmentId = aid
        self.dateStart = Date()
    }
    
    init(id: Int, assessmentId: Int, dateStart: Date, dateComplete: Date?, name: String?, email: String?) {
        self.id = id
        self.dateStart = dateStart
        self.dateComplete = dateComplete
        self.name = name
        self.email = email
    }
}


final class AssessmentInstanceContext: Content, Error {
    let id: Int
    let assessment: AssessmentContext
    let dateStart: Date
    var dateComplete: Date?
    //var pageComplete: Int
    var name: String?
    var email: String?
    var showBossErrorMessage: Bool = false
    
    init(_ req: Request, forAssessmentId aid: Int, passports: Passports) async throws {
        let ai = AssessmentInstance(forAID: aid)
        try await ai.save(on: req.db)
        
        guard let id = ai.id else {
            throw Abort (.internalServerError, reason: "Error saving AssessmentInstance for \(aid) to database.")
        }
        
        self.id = id
        self.dateStart = ai.dateStart
        self.assessment = try await AssessmentContext(req, id: aid, passports: passports)
        //self.pageComplete = 0
        self.dateComplete = nil
    }
    
    init(_ req: Request, assessmentId aid: Int, instance: Int, passports: Passports) async throws {
        guard let ai = try await AssessmentInstance.find(instance, on: req.db) else {
            throw Abort (.badRequest, reason: "attempt to look up assessment instance that does not exist.")
        }
        self.id = instance
        self.dateStart = ai.dateStart
        self.assessment = try await AssessmentContext(req, id: aid, passports: passports)
        //self.pageComplete = 5
        self.dateComplete = ai.dateComplete
        self.name = ai.name
        self.email = ai.email
    }
    
    func reportContext(withDetails details: [AssessmentInstanceDetailContext]) throws -> AssessmentInstanceReportContext {
        guard let name = self.name else {
            throw Abort (.internalServerError, reason: "Attempt to generate a report context before the assessment taker's name is stored.")
        }
        
        return AssessmentInstanceReportContext(id: self.id, assessment: self.assessment, details: details, takerName: name)
    }
}

final class AssessmentInstanceReportContext: Content, Codable {

    let id: Int
    private var domainDetails: [AssessmentInstanceDetailContext]
    var overallDistance = 0
    let assessmentName: String
    let assessmentDisclosureText: String
    let assessmentId: Int
    let takerName: String
    let passportType: PassportType
    var overallResult: PassportDomainResult?
    var overallParagraph: String?
    let logoFileName: String
    let disclosureText: String
    
    init(id: Int, assessment: AssessmentContext, takerName: String) {
        self.id = id
        self.domainDetails = []
        self.assessmentName = assessment.name
        self.assessmentDisclosureText = assessment.disclosureText
        self.assessmentId = assessment.id
        self.takerName = takerName
        self.passportType = assessment.passportModel.passportType
        self.logoFileName = assessment.logoFileName
        self.disclosureText = assessment.disclosureText
    }
    
    convenience init(id: Int, assessment: AssessmentContext, details: [AssessmentInstanceDetailContext], takerName: String) {
        self.init(id: id, assessment: assessment, takerName: takerName)
        self.domainDetails = details
        self.overallDistance = Self.overallDistance(basedOn: details)
        self.overallResult = Self.overallResult(basedOn: details)
        self.overallParagraph = assessment.passportModel.overallParagraphs[self.overallResult!]!
        
    }
    
    func updateDetails(details: [AssessmentInstanceDetailContext]) {
        self.domainDetails = details
        self.overallDistance = Self.overallDistance(basedOn: details)
    }
    
    static func overallDistance (basedOn detailRows: [AssessmentInstanceDetailContext]) -> Int {
        detailRows.reduce(0) { $0 + $1.score }
    }
    
    static func overallResult (basedOn detailRows: [AssessmentInstanceDetailContext]) -> PassportDomainResult {
        let countGreen = resultCount(of: .green, in: detailRows)
        let countRed = resultCount(of: .red, in: detailRows)
        if countGreen >= 7 {
            return .green
        }
        else if countRed >= 4 {
            return.red
        }
        return .yellow
    }
    
    static func resultCount(of resultType: PassportDomainResult, in rows: [AssessmentInstanceDetailContext]) -> Int {
        return rows.map {
            if $0.result == resultType {
                return 1
            }
            else {
                return 0
            }
        }.reduce(0) { $0 + $1 }
    }
}


