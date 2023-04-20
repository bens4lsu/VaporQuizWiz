import Foundation
import Vapor
import Fluent


final class AssessmentInstanceDetail: Model, Content {
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
    
    func context(passportModel: PassportModel) throws -> AssessmentInstanceDetailContext {
        guard let passportDomain = passportModel.domains.first (where: { $0.domainType == self.passportDomainType }) else {
            throw Abort (.internalServerError, reason: "Domain not found in passport model.")
        }
        
        return AssessmentInstanceDetailContext (order: passportDomain.index, domain: passportDomain, now: self.now, goal: self.goal)
    }
}
