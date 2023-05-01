//
//  File.swift
//  
//
//  Created by Ben Schultz on 5/1/23.
//

import Foundation
import Vapor
import Fluent


final class AssessmentEmail: Model, Content {
    static let schema = "AssessmentEmails"
    
    @ID(custom: "AssessmentEmailID")
    var id: Int?

    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "EmailAddress")
    var emailAddress: String

    init() { }

}
