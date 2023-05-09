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
    
    private func loadPassportList(_ req: Request, forceReload: Bool = false) async throws -> [Assessment] {
        let _ = try SecurityController.userAuthorized(req)
        if assessmentList == nil || forceReload {
            let localList = try await Assessment.query(on: req.db).all()
            assessmentList = localList.sorted{ $0.name < $1.name }
        }
        return assessmentList!
    }
}
