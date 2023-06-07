//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/18/23.
//

import Foundation
import Vapor

struct APIRouteController: RouteCollection {
    
    
    var adminC: AdminController
    var ac: AssessmentController { adminC.ac }
    var settings: ConfigurationSettings { adminC.ac.settings }
    var logger: Logger { adminC.ac.logger }
    
    init(adminController: AdminController) {
        self.adminC = adminController
    }
    
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get(":aid", use: newInstance)
        api.post("admin-results", use: adminResultTable)
        api.post("admin-test", use: adminTest)
        api.post("admin-new-passport", use: adminNewPassport)
        api.post("admin-get-passport-config", use: adminGetPassportConfig)
        api.post("admin-save-passport-config", use: adminSavePassportConfig)
    }
    
    private func newInstance(_ req: Request) async throws -> Response {
        guard let aidStr = req.parameters.get("aid"),
              let aid = try Int(BenCrypt.decode(aidStr, keys: settings.cryptKeys))
        else {
            throw Abort(.badRequest, reason: "Invalid assessment token")
        }
        return try await ac.new(req, aid: aid).encodeResponse(for: req)
    }
    
    private func adminResultTable(_ req: Request) async throws -> Response {
        struct ReqAid: Decodable {
            let aid: Int
        }
        let reqAid = try req.content.decode(ReqAid.self)
        return try await adminC.assessmentResults(req, aid: reqAid.aid).encodeResponse(for: req)
    }
    
    private func adminTest(_ req: Request) async throws -> Response {
        struct ReqAid: Decodable {
            let aid: Int
        }
        let reqAid = try req.content.decode(ReqAid.self)
        return try await adminC.assessmentTest(req, aid: reqAid.aid).encodeResponse(for: req)
    }
    
    private func adminNewPassport(_ req: Request) async throws -> Response {
        struct ReqName: Decodable {
            let newPassportName: String
        }
        let reqName = try req.content.decode(ReqName.self)
        return try await adminC.newPassport(req, name: reqName.newPassportName).encodeResponse(for: req)
    }
    
    private func adminGetPassportConfig(_ req: Request) async throws -> Response {
        struct ReqAid: Decodable {
            let aid: Int
        }
        let reqAid = try req.content.decode(ReqAid.self)
        return try await adminC.getPassport(req, id: reqAid.aid).encodeResponse(for: req)
    }
    
    private func adminSavePassportConfig(_ req: Request) async throws -> Response {
        struct ReqValues: Decodable {
            let aid: Int
            let disclosureText: String
            let logoFileName: String
            let companyContactInfo: String
        }
        let reqValues = try req.content.decode(ReqValues.self)
        let _ = try await adminC.savePassportValues(req, id: reqValues.aid,
                                                    disclosureText: reqValues.disclosureText,
                                                    logoFileName: reqValues.logoFileName,
                                                    companyContactInfo: reqValues.companyContactInfo)
        return try await "ok".encodeResponse(for: req)
    }
}

extension APIRouteController {
    struct NewPassportResponseStruct: Content {
        let id: Int
        let list: [Assessment]
    }
}
