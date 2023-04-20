//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/20/23.
//

import Foundation
import Vapor

class AssessmentInstanceDetailContext: Codable {
    let order: Int
    let score: Int
    let result:  PassportDomainResult
    let domainType: PassportDomainType
    let resultParagraph: String
    let now: Int
    let goal: Int
    let blurb: String

    
    init(order: Int, domain: PassportDomain, now: Int, goal: Int) {
        self.order = order
        self.domainType = domain.domainType
        self.score = Self.score(now: now, goal: goal)
        self.result = Self.result(now: now)
        self.resultParagraph = domain.resultParagraphs[result]!
        self.now = now
        self.goal = goal
        self.blurb = domain.blurb
    }
    
    
    static func score(now: Int, goal: Int) -> Int {
        if goal > now {
            return goal - now
        }
        return 0
    }
    
    static func result(now: Int) -> PassportDomainResult {
        if now <= 6 {
            return .red
        }
        else if now <= 9 {
            return .yellow
        }
        return .green
    }
    
}

