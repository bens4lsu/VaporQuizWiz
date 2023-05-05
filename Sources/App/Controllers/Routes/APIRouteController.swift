//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/18/23.
//

import Foundation
import Vapor

struct APIRouteController: RouteCollection {
    
    let ac: AssessmentController
    let settings: ConfigurationSettings
    let logger: Logger
    let adminC: AdminController
    
    init(passports: Passports, settings: ConfigurationSettings, logger: Logger) {
        self.ac = AssessmentController(passports: passports, logger: logger, settings: settings)
        self.settings = settings
        self.logger = logger
        self.adminC = AdminController(ac)
    }
    
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        api.get(":aid", use: newInstance)
        api.post("admin-results", use: adminResultTable)
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
}
