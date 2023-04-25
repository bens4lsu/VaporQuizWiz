//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/25/23.
//

import Foundation

enum PDFPageType: String {
    case report
    case qAndASummary
    
    var pathPartForHtmlVersion: String {
        switch self {
        case .report:
            return "report"
        case .qAndASummary:
            return "qasummary"
        }
    }
}
