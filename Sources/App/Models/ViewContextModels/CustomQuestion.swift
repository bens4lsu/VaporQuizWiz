//
//  File.swift
//  
//
//  Created by Ben Schultz on 6/20/23.
//

import Foundation


class CustomQuestion: Codable, Comparable {
    static func == (lhs: CustomQuestion, rhs: CustomQuestion) -> Bool {
        lhs.questionNumber == rhs.questionNumber
    }
    
    static func < (lhs: CustomQuestion, rhs: CustomQuestion) -> Bool {
        lhs.questionNumber < rhs.questionNumber
    }
    
    let id: String
    let questionNumber: Int
    let label: String
    let regex: String?
    let errorMessage: String?
    
    init(id: String, questionNumber: Int, label: String, regex: String?, errorMessage: String?) {
        self.questionNumber = questionNumber
        self.label = label
        self.regex = regex
        self.errorMessage = errorMessage
        self.id = id
    }
    
    init(id: String, questionNumber: Int, label: String) {
        self.questionNumber = questionNumber
        self.label = label
        self.regex = nil
        self.errorMessage = nil
        self.id = id
    }
}
