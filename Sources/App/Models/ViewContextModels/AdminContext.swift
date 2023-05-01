//
//  File.swift
//  
//
//  Created by Ben Schultz on 5/1/23.
//

import Foundation
import Vapor
import Leaf

final class AdminContext: Content {
    let assessments: [Assessment]
    let base: String
    
    init(assessments: [Assessment], base: String) {
        self.assessments = assessments
        self.base = base
    }
}

final class AdminResultContext: Content {
    let id: Int
    let name: String
    let email: String
    let dateComplete: Date
    let reportLink: String
    let summaryLink: String
    let reportLinkPdf: String
    let summaryLinkPdf: String
    
    init(id: Int, name: String, email: String, dateComplete: Date, reportLink: String, summaryLink: String, reportLinkPdf: String, summaryLinkPdf: String) {
        self.id = id
        self.name = name
        self.email = email
        self.dateComplete = dateComplete
        self.reportLink = reportLink
        self.summaryLink = summaryLink
        self.reportLinkPdf = reportLinkPdf
        self.summaryLinkPdf = summaryLinkPdf
    }
}

final class AdminResultsContext: Content {
    let results: [AdminResultContext]
    
    init(_ results: [AdminResultContext]) {
        self.results = results
    }
}
