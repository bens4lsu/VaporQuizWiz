//
//  File.swift
//  
//
//  Created by Ben Schultz on 6/20/23.
//

import Foundation
import Vapor
import Fluent


final class AssessmentAdditionalInfo: Model, Content, Codable {
    static let schema = "AssessmentAdditionalInformation"
    
    @ID(custom: "AssessmentAdditionalID")
    var id: Int?

    @Field(key: "AssessmentInstanceID")
    var assessmentInstanceId: Int
    
    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "AdditionalInfoKey")
    var additionalInfoKey: String
    
    @Field(key: "AdditionalInfoValue")
    var additionalInfoValue: String

    init() { }
    
    init(assessmentInstanceId: Int, assessmentId: Int, additionalInfoKey: String, additionalInfoValue: String) {
        self.assessmentInstanceId = assessmentInstanceId
        self.assessmentId = assessmentId
        self.additionalInfoKey = additionalInfoKey
        self.additionalInfoValue = additionalInfoValue
    }

}

