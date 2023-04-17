import Foundation
import Vapor
import Fluent


final class AssessmentInstanceResult: Model, Content {
    static let schema = "AssessmentInstanceResults"
    
    @ID(custom: "AssessmentInstanceResultID")
    var id: Int?

    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "AssessmentInstandID")
    var assessmentInstanceId: Int
    
    @Field(key: "PassportDomainType")
    var passportDomainType: PassportDomainType
    
    @Field(key: "Now")
    var now: Int8
    
    @Field(key: "Goal")
    var goal: Int8

    init() { }

}
