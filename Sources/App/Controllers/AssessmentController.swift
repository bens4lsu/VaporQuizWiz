//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/14/23.
//

import Foundation
import Vapor
import Fluent

class AssessmentController {
    
    enum ResponseStatus: Content {
        case success(AssessmentInstanceReportContext)
        case failure//(AssessmentInstanceContext)
    }
    
    var passports: Passports
    var logger: Logger
    
    init(passports: Passports, logger: Logger) {
        self.passports = passports
        self.logger = logger
    }
    
    func new(_ req: Request, aid: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, forAssessmentId: aid, passports: passports)
    }
    
    func existingContext(_ req: Request, aid: Int, instance: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, assessmentId: aid, instance: instance, passports: passports)
    }
    
    func processResponse(_ req: Request, variables: [String: String]) async throws -> ResponseStatus {
        guard let aid = Int(variables["aid"] ?? ""),
              let instance = Int(variables["instance"] ?? ""),
              let passportTypeString = variables["passportType"],
              let passportType = PassportType(rawValue: passportTypeString),
              let name = variables["name"],
              let email = variables["email"]
        else {
            logger.debug("Error validating aid, instance, or passportType:  aid = \(variables["aid"] ?? "nil"), instance = \(variables["instance"] ?? "nil"), passportType = \(variables["passportType"] ?? "nil")")
            return .failure
        }
        
        let assessmentInstanceContext = try await existingContext(req, aid: aid, instance: instance)
        assessmentInstanceContext.name = name
        assessmentInstanceContext.email = email
        var resultRowsToUpdate = [AssessmentInstanceDetail]()
        var resultRowsContext = [AssessmentInstanceDetailContext]()
        
        for i in 1...8 {
            let labelNow = "single_\(i)a"
            let labelGoal = "single_\(i)b"
            
            guard let ansNow = validAnswer(variables[labelNow]),
                  let ansGoal = validAnswer(variables[labelGoal]),
                  let passportModel = passports[passportType]
            else {
                logger.debug("Error validating numeric responses or domain type:  ansNow = \(variables[labelNow] ?? "nil"), ansGoal = \(variables[labelGoal] ?? "nil"), passportDomainType = \(passports[passportType]?.domains[i].domainType.rawValue ?? "nil")")
                return .failure
            }
            
            let passportDomain = passportModel.domains[i-1]
            let aiResult = AssessmentInstanceDetail(assessmentId: aid, assessmentInstanceId: instance, passportDomainType: passportDomain.domainType, now: ansNow, goal: ansGoal)
            resultRowsToUpdate.append(aiResult)
            
            let resultRowContext = AssessmentInstanceDetailContext(order: i, domain: passportDomain, now: ansNow, goal: ansGoal)
            resultRowsContext.append(resultRowContext)
        }
        
        // save answers to database
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            try await updateInstance(req, instance: assessmentInstanceContext.dbModel(), name: name, email: email)
            for i in 0..<resultRowsToUpdate.count {
                let row = resultRowsToUpdate[i]
                async let _ = row.save(on: req.db)
            }
        }
        let resultContext = try assessmentInstanceContext.reportContext(withDetails: resultRowsContext)
        return .success(resultContext)
    }
    
    private func validAnswer(_ answer: String?) -> Int? {
        guard let answer = answer,
              let int = Int(answer)
        else {
            return nil
        }
        guard int <= 12 && int >= 1 else {
            return nil
        }
        return int
    }
    
    private func updateInstance(_ req: Request, instance: AssessmentInstance, name: String, email: String) async throws {
//        instance.name = name
//        instance.email = email
//        instance.dateComplete = Date()
//        try await instance.save(on: req.db)
    }
    
}
