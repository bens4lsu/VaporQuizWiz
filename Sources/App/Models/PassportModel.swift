//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor


enum PassportDomainResult: String, CaseIterable {
    case red
    case yellow
    case green
}

enum PassportType {
    case walkaway
    case expansion
    
    var domainList: [PassportDomainType] {
        switch self {
        case .walkaway:
            return [.readiness, .foundation, .resource, .wellness]
        case .expansion:
            return [.readiness]
        }
    }
}

enum PassportDomainType: String {
    case readiness
    case foundation
    case resource
    case wellness
}


class PassportDomain {
    var domainType: PassportDomainType
    var labels: [String]
    var resultParagraphs: [PassportDomainResult: String]
    
    init (_ app: Application, for domainType: PassportDomainType) throws {
        self.domainType = domainType
        self.resultParagraphs = [.red: "", .yellow: "", .green: ""]
        
        let filename = domainType.rawValue + ".txt"
        self.labels = try parseLabels(readFile(filename, inPath: "DomainLabels"), filename: filename)
        
        var resultParagraphs = [PassportDomainResult: String]()
        for resultType in PassportDomainResult.allCases {
            let filename = domainType.rawValue + "-" + resultType.rawValue + ".htm"
            let contents = try readFile(filename, inPath: "OutputParagraphs")
            resultParagraphs[resultType] = contents
        }
        self.resultParagraphs = resultParagraphs
        
        
        
        func readFile(_ filename: String, inPath: String) throws -> String {
            let path = app.directory.resourcesDirectory
                .appending(inPath + "/")
                .appending(filename)
            let contents = try String(contentsOfFile: path)
            return contents
        }
        
        func parseLabels(_ fileContents: String, filename: String) throws -> [String] {
            let lines = fileContents.components(separatedBy: .newlines)
                .filter { !$0.isEmpty }
            guard lines.count == 4 else {
                throw Abort(.internalServerError, reason: "file at \(filename) improperly configured.  Should contain four lines of text.")
            }
            return lines
        }
    }
}

class PassportModel {
    let passportType: PassportType
    let domains: [PassportDomain]
    
    init (_ app: Application, forPassportType passportType: PassportType) throws {
        self.passportType = passportType
        self.domains = try self.passportType.domainList.map { try PassportDomain(app, for: $0) }
    }
}




