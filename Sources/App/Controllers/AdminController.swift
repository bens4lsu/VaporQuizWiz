//
//  File.swift
//  
//
//  Created by Ben Schultz on 5/1/23.
//

import Foundation
import Vapor
import Fluent

class AdminController {
     
    let ac: AssessmentController
    var assessmentList: [Assessment]?

    init(_ ac: AssessmentController) {
        self.ac = ac
    }
    
    func adminContext(_ req: Request) async throws -> AdminContext {
        let _ = try SecurityController.userAuthorized(req)
        let list = try await loadPassportList(req)
        return AdminContext(assessments: list, base: ac.baseString)
    }
    
    func assessmentResults(_ req: Request, aid: Int) async throws -> AdminResultsContext {
        let _ = try SecurityController.userAuthorized(req)
        var assessmentId: Int?
        let instances = try await AssessmentInstance.query(on: req.db)
            .filter(\.$dateComplete != nil)
            .filter(\.$assessmentId == aid)
            .all()
        
        let mylist = try await instances.asyncMap { row in
            guard let dateComplete = row.dateComplete else {
                throw Abort (.internalServerError, reason: "Attempt to retrieve result where dateComplete is not set.")
            }
            
            if assessmentId == nil {
                assessmentId = row.assessmentId
            }
            let aic = try await AssessmentInstanceContext(req, assessmentId: assessmentId!, instance: row.id!, passports: ac.passports, keys: ac.cryptKeys)
            let name = row.name ?? ""
            let email = row.email ?? ""
            return AdminResultContext(id: row.id!, name: name, email: email, dateComplete: dateComplete, reportLink: aic.reportLink, summaryLink: aic.qaLink, reportLinkPdf: aic.reportLinkPdf, summaryLinkPdf: aic.qaLinkPdf )
        }.sorted {
            $0.dateComplete > $1.dateComplete
        }
        return AdminResultsContext(mylist)
    }
    
    func assessmentTest(_ req: Request, aid: Int) async throws -> [String: String] {
        
        let _ = try SecurityController.userAuthorized(req)
        let context = try await AssessmentContext(req, id: aid, passports: ac.passports, keys: ac.cryptKeys)
        return ["url": context.urlForNewInstance, "embedCode": context.embedCode]
    }
    
    func newPassport(_ req: Request, name: String) async throws -> APIRouteController.NewPassportResponseStruct {
        let _ = try SecurityController.userAuthorized(req)
        guard name.lowercased().contains("walkaway") || name.lowercased().contains("expansion") else {
            throw Abort(.badRequest, reason: "New Passport name must include \"Walkaway\" or \"Expansion\"")
        }
        let assessment = Assessment(name: name)
        try await assessment.save(on: req.db)
        let list = try await self.loadPassportList(req, forceReload: true)
        return .init(id: assessment.id!, list: list)
    }
    
    func getPassport(_ req: Request, id: Int) async throws -> Assessment {
        let _ = try SecurityController.userAuthorized(req)
        guard let assessmentList = self.assessmentList,
              let thisAssessment = assessmentList.filter({ $0.id == id }).first
        else {
            throw Abort (.badRequest, reason: "Requested config info for passport with an invalid id.")
        }
        return thisAssessment
    }
     
    func savePassportValues(_ req: Request, id: Int, disclosureText: String, logoFileName: String, companyContactInfo: String) async throws {
        let _ = try SecurityController.userAuthorized(req)
        guard let assessment = try await Assessment.find(id, on: req.db) else {
            throw Abort(.badRequest, reason: "Assessment update requested with invalid id.")
        }
        assessment.disclosureText = disclosureText
        assessment.logoFileName = logoFileName
        assessment.companyContactInfo = companyContactInfo
        try await assessment.save(on: req.db)
        let _ = try await self.loadPassportList(req, forceReload: true)
    }
    
    private func loadPassportList(_ req: Request, forceReload: Bool = false) async throws -> [Assessment] {
        let _ = try SecurityController.userAuthorized(req)
        if assessmentList == nil || forceReload {
            var localList = try await Assessment.query(on: req.db).all()
            localList = localList.sorted{ $0.name < $1.name }
            assessmentList = localList
        }
        return assessmentList!
    }
}
