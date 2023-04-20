//
//  File.swift
//
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent


final class AssessmentInstance: Model, Content {
    static let schema = "AssessmentInstances"
    
    @ID(custom: "AssessmentInstanceID")
    var id: Int?

    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "DateStart")
    var dateStart: Date
    
    @Field(key: "DateComplete")
    var dateComplete: Date?
    
    @Field(key: "UserName")
    var name: String?
    
    @Field(key: "Email")
    var email: String?

    init() { }
    
    init(forAID aid: Int) {
        self.assessmentId = aid
        self.dateStart = Date()
    }
    
    init(id: Int, assessmentId: Int, dateStart: Date, dateComplete: Date?, name: String?, email: String?) {
        self.id = id
        self.dateStart = dateStart
        self.dateComplete = dateComplete
        self.name = name
        self.email = email
    }
}
