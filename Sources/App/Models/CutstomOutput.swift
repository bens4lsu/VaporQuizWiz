//
//  File.swift
//  
//
//  Created by Ben Schultz on 6/12/23.
//

import Foundation
import Vapor

class CustomOutput: Codable {
    let domains: [PassportDomainType: [PassportDomainResult: String]]
    let overall: [PassportDomainResult: String]
    
    init(_ app: Application, aid: Int) {
        var domains = [PassportDomainType: [PassportDomainResult: String]]()
        var overall = [PassportDomainResult: String]()
        for domainType in PassportDomainType.allCases {
            for domainResult in PassportDomainResult.allCases {
                let filename = "\(domainType.rawValue)-\(domainResult.rawValue).htm"
                if let contents = try? ResourceFileManager.readFile(filename, inPath: "OutputParagraphs/\(aid)", app: app) {
                    let inner = [domainResult: contents]
                    domains[domainType] = inner
                }
            }
        }
        for domainResult in PassportDomainResult.allCases {
            let filename = "overall-\(domainResult.rawValue).htm"
            if let contents = try? ResourceFileManager.readFile(filename, inPath: "OutputParagraphs/\(aid)", app: app) {
                overall[domainResult] = contents
            }
        }
        self.domains = domains
        self.overall = overall
    }
}

