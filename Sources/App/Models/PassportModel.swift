//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor

typealias Passports = [PassportType: PassportModel]

enum PassportDomainResult: String, CaseIterable, Codable {
    case red
    case yellow
    case green
}

enum PassportType: String, Codable {
    case walkaway
    case expansion
    
    var domainList: [Int: PassportDomainType] {
        switch self {
        case .expansion:
            return [1: .readiness, 2: .foundation, 3: .resource, 4: .wellness, 5: .caring, 6: .accumulation, 7: .walkaway, 8: .partnership]
        case .walkaway:
            return [1: .readiness, 2: .wellness, 3: .foundation, 4: .longevity, 5: .caring, 6: .income, 7: .purpose, 8: .partnership]
        }
    }
}

enum PassportDomainType: String, Codable, CaseIterable {
    case readiness
    case foundation
    case resource
    case wellness
    case longevity
    case caring
    case income
    case purpose
    case partnership
    case accumulation
    case walkaway
}


final class PassportDomain: Content, Codable, Comparable {
    var index: Int
    var domainType: PassportDomainType
    var labels: [String]
    var resultParagraphs: [PassportDomainResult: String]
    var blurb: String
    
    init (_ app: Application, for domainType: PassportDomainType, atIndex index: Int) throws {
        self.domainType = domainType
        self.index = index
        self.resultParagraphs = [.red: "", .yellow: "", .green: ""]
        
        let filename = domainType.rawValue + ".txt"
        self.labels = try ResourceFileManager.parseLabels(ResourceFileManager.readFile(filename, inPath: "DomainLabels", app: app), filename: filename)
        
        var resultParagraphs = [PassportDomainResult: String]()
        for resultType in PassportDomainResult.allCases {
            let filename = domainType.rawValue + "-" + resultType.rawValue + ".htm"
            let contents = try ResourceFileManager.readFile(filename, inPath: "OutputParagraphs", app: app)
            resultParagraphs[resultType] = contents
        }
        self.resultParagraphs = resultParagraphs
        
        let filename2 = domainType.rawValue + "-blurb.txt"
        self.blurb = try ResourceFileManager.readFile(filename2, inPath: "OutputParagraphs", app: app)
    }
    
    static func < (lhs: PassportDomain, rhs: PassportDomain) -> Bool {
        lhs.index < rhs.index
    }
    
    static func == (lhs: PassportDomain, rhs: PassportDomain) -> Bool {
        lhs.index == rhs.index
    }
}


final class PassportModel: Content, Codable {
    let passportType: PassportType
    let domains: [PassportDomain]
    let intro: String
    let overallParagraphs: [PassportDomainResult : String]
    
    init (_ app: Application, forPassportType passportType: PassportType) throws {
        self.passportType = passportType
        self.domains = try self.passportType.domainList.map { try PassportDomain(app, for: $0.value, atIndex: $0.key) }
            .sorted()
        
        let filename = "intro-\(passportType.rawValue).htm"
        self.intro = try ResourceFileManager.readFile(filename, inPath: "", app: app)
        
        var resultParagraphs = [PassportDomainResult : String]()
        for resultType in PassportDomainResult.allCases {
            let filename2 = "overall-\(resultType.rawValue).htm"
            let contents = try ResourceFileManager.readFile(filename2, inPath: "OutputParagraphs", app: app)
            resultParagraphs[resultType] = contents
        }
        self.overallParagraphs = resultParagraphs
    }
}








