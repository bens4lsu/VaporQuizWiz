import Foundation
import Vapor
import Fluent


final class AssessmentInstanceResult: Model, Content {
    static let schema = "AssessmentInstanceResults"
    
    @ID(custom: "AssessmentInstanceResultID")
    var id: Int?

    @Field(key: "AssessmentID")
    var assessmentId: Int
    
    @Field(key: "AssessmentInstanceID")
    var assessmentInstanceId: Int
    
    @Field(key: "PassportDomainType")
    var passportDomainType: PassportDomainType
    
    @Field(key: "Now")
    var now: Int
    
    @Field(key: "Goal")
    var goal: Int

    init() { }
    
    init(assessmentId: Int, assessmentInstanceId: Int, passportDomainType: PassportDomainType, now: Int, goal: Int) {
        self.assessmentId = assessmentId
        self.assessmentInstanceId = assessmentInstanceId
        self.passportDomainType = passportDomainType
        self.now = now
        self.goal = goal
    }

}
