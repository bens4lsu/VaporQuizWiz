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
}

class AssessmentInstanceDetailContext: Codable {
    let order: Int
    let score: Int
    let result:  PassportDomainResult
    let domainType: PassportDomainType
    let resultParagraph: String
    let now: Int
    let goal: Int
    let blurb: String
    
//    init(order: Int, domain: PassportDomain, result: PassportDomainResult) {
//        self.order = order
//        self.score = score
//        self.result = result
//        self.domainType = domain.domainType
//        self.resultParagraph = domain.resultParagraphs[result]!
//    }
    
    
    init(order: Int, domain: PassportDomain, now: Int, goal: Int) {
        self.order = order
        self.domainType = domain.domainType
        self.score = Self.score(now: now, goal: goal)
        self.result = Self.result(now: now)
        self.resultParagraph = domain.resultParagraphs[result]!
        self.now = now
        self.goal = goal
        self.blurb = domain.blurb
    }
    
    static func score(now: Int, goal: Int) -> Int {
        if goal > now {
            return goal - now
        }
        return 0
    }
    
    static func result(now: Int) -> PassportDomainResult {
        if now <= 6 {
            return .red
        }
        else if now <= 9 {
            return .yellow
        }
        return .green
    }
    
}
