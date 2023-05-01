//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent


final class Assessment: Model, Content, Codable {
    static let schema = "Assessments"
    
    @ID(custom: "AssessmentID")
    var id: Int?

    @Field(key: "Name")
    var name: String
    
    @Field(key: "DisclosureText")
    var disclosureText: String
    
    @Field(key: "LogoFileName")
    var logoFileName: String
    
    @Field(key: "CompanyContactInfo")
    var companyContactInfo: String

    init() { }

}

