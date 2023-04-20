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
        case failure(String)  // string is for redirect page
    }
    
    var passports: Passports
    var logger: Logger
    var cryptKeys: ConfigurationSettings.CryptKeys
    
    init(passports: Passports, logger: Logger, cryptKeys: ConfigurationSettings.CryptKeys) {
        self.passports = passports
        self.logger = logger
        self.cryptKeys = cryptKeys
    }
    
    func new(_ req: Request, aid: Int) async throws -> AssessmentInstanceContext {
        try await AssessmentInstanceContext(req, forAssessmentId: aid, passports: passports)
    }
    
    func existingContext(_ req: Request, aid: Int, instance: Int, showServerSideError: Bool = false) async throws -> AssessmentInstanceContext {
        let aic = try await AssessmentInstanceContext(req, assessmentId: aid, instance: instance, passports: passports)
        aic.showBossErrorMessage = showServerSideError
        return aic
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
            return try await handleErrorResponse(req, variables)
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
                return try await handleErrorResponse(req, variables)
            }
            
            let passportDomain = passportModel.domains[i-1]
            let aiResult = AssessmentInstanceDetail(assessmentId: aid, assessmentInstanceId: instance, passportDomainType: passportDomain.domainType, now: ansNow, goal: ansGoal)
            resultRowsToUpdate.append(aiResult)
            
            let resultRowContext = AssessmentInstanceDetailContext(order: i, domain: passportDomain, now: ansNow, goal: ansGoal)
            resultRowsContext.append(resultRowContext)
        }
        
        // save answers to database
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            
            for i in 0..<resultRowsToUpdate.count {
                let row = resultRowsToUpdate[i]
                async let _ = try updateResponseRow(req, row: row)
            }
            let tmpInstance = try await existingInstance(req, aic: assessmentInstanceContext)
            async let _ = updateInstance(req, instance: tmpInstance, name: name, email: email)
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
    
    private func handleErrorResponse(_ req: Request, _ variables: [String: String]) async throws -> ResponseStatus {
        guard let aid = Int(variables["aid"] ?? "") else {
            throw Abort (.internalServerError, reason: "Form submitted without data to identify the assessment being used.")
        }
        let aidStr = try BenCrypt.encode(String(aid), keys: cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let instance = Int(variables["instance"] ?? "")
        if instance != nil {
            let instanceStr = try BenCrypt.encode(String(instance!), keys: cryptKeys).addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            return .failure("/\(aidStr)/\(instanceStr)")
        }
        return .failure("/\(aidStr)")
    }
    
    
    private func updateInstance(_ req: Request, instance: AssessmentInstance, name: String, email: String) async throws {
        instance.name = name
        instance.email = email
        instance.dateComplete = Date()
        try await instance.update(on: req.db)
    }
    
    
    private func existingInstance(_ req: Request, aic: AssessmentInstanceContext) async throws -> AssessmentInstance {
        let instance = aic.id
        guard let assessmentInstance = try await AssessmentInstance.find(instance, on: req.db) else {
            throw Abort(.internalServerError, reason: "Assessment instance not found for id \(aic.id)")
        }
        return assessmentInstance
    }
    
    
    private func updateResponseRow(_ req: Request, row: AssessmentInstanceDetail) async throws {
        if let aidRow = try await getResponseRow(req, assessmentInstanceId: row.assessmentInstanceId, domainType: row.passportDomainType) {
            try await aidRow.update(on: req.db)
        }
        else {
            let aidRow = AssessmentInstanceDetail(assessmentId: row.assessmentId, assessmentInstanceId: row.assessmentInstanceId, passportDomainType: row.passportDomainType, now: row.now, goal: row.goal)
            try await aidRow.save(on: req.db)
        }
    }
    
    
    private func getResponseRow(_ req: Request, assessmentInstanceId: Int, domainType: PassportDomainType) async throws -> AssessmentInstanceDetail? {
        try await AssessmentInstanceDetail.query(on: req.db)
            .filter(\.$assessmentInstanceId == assessmentInstanceId)
            .filter(\.$passportDomainType == domainType)
            .first()
    }
}
