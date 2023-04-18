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
    var passports: Passports
    var logger: Logger
    
    init(passports: Passports, logger: Logger) {
        self.passports = passports
        self.logger = logger
    }
    
    func new(_ req: Request, aid: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, forAssessmentId: aid, passports: passports)
    }
    
    func processResults(_ req: Request, variables: [String: String]) async throws -> Bool {
        guard let aid = Int(variables["aid"] ?? ""),
              let instance = Int(variables["instance"] ?? ""),
              let passportTypeString = variables["passportType"],
              let passportType = PassportType(rawValue: passportTypeString),
              let name = variables["name"],
              let email = variables["email"]
        else {
            logger.debug("Error validating aid, instance, or passportType:  aid = \(variables["aid"] ?? "nil"), instance = \(variables["instance"] ?? "nil"), passportType = \(variables["passportType"] ?? "nil")")
            return false
        }
        
        var resultRowsToUpdate = [AssessmentInstanceResult]()
        for i in 1...8 {
            let labelNow = "single_\(i)a"
            let labelGoal = "single_\(i)b"
            guard let ansNow = validAnswer(variables[labelNow]),
                  let ansGoal = validAnswer(variables[labelGoal]),
                  let passportDomainType = passports[passportType]?.domains[i-1].domainType
            else {
                logger.debug("Error validating numeric responses or domain type:  ansNow = \(variables[labelNow] ?? "nil"), ansGoal = \(variables[labelGoal] ?? "nil"), passportDomainType = \(passports[passportType]?.domains[i].domainType.rawValue ?? "nil")")
                return false
            }
            let aiResult = AssessmentInstanceResult(assessmentId: aid, assessmentInstanceId: instance, passportDomainType: passportDomainType, now: ansNow, goal: ansGoal)
            resultRowsToUpdate.append(aiResult)
        }
        
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            try await updateInstance(req, instance: instance, name: name, email: email)
            for i in 0..<resultRowsToUpdate.count {
                let row = resultRowsToUpdate[i]
                async let _ = row.save(on: req.db)
            }
        }
        return true
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
    
    private func updateInstance(_ req: Request, instance: Int, name: String, email: String) async throws {
        guard let assessmentInstance = try await AssessmentInstance.find(instance, on: req.db) else {
            throw Abort(.internalServerError, reason: "invalid instance number passed to AssessmentController.updateInstance().")
        }
        assessmentInstance.name = name
        assessmentInstance.email = email
        assessmentInstance.dateComplete = Date()
        try await assessmentInstance.save(on: req.db)
    }
    
}
