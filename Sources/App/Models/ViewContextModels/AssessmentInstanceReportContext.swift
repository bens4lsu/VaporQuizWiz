//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/20/23.
//

import Foundation
import Vapor

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
    let takerEmail: String
    let host: ConfigurationSettings.Host
    
    init(id: Int, assessment: AssessmentContext, takerName: String, takerEmail: String, host: ConfigurationSettings.Host) {
        self.id = id
        self.domainDetails = []
        self.assessmentName = assessment.name
        self.assessmentDisclosureText = assessment.disclosureText
        self.assessmentId = assessment.id
        self.takerName = takerName
        self.passportType = assessment.passportModel.passportType
        self.logoFileName = assessment.logoFileName
        self.disclosureText = assessment.disclosureText
        self.takerEmail = takerEmail
        
        var port = host.listenOnPort
        if host.server != "localhost" && host.server != "127.0.0.1" {
            port = -1
        }
        self.host = ConfigurationSettings.Host(listenOnPort: port, proto: host.proto, server: host.server)
    }
    
    convenience init(id: Int, assessment: AssessmentContext, details: [AssessmentInstanceDetailContext], takerName: String, takerEmail: String, host: ConfigurationSettings.Host) {
        self.init(id: id, assessment: assessment, takerName: takerName, takerEmail: takerEmail, host: host)
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


