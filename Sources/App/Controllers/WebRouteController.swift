import Vapor
import Leaf

struct WebRouteController: RouteCollection {
    
    let ac: AssessmentController
    let settings: ConfigurationSettings
    let logger: Logger
    
    init(passports: Passports, settings: ConfigurationSettings, logger: Logger) {
        self.ac = AssessmentController(passports: passports, logger: logger, cryptKeys: settings.cryptKeys)
        self.settings = settings
        self.logger = logger
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
        routes.post("evaluate", use: processAssessment)
        routes.get("report", ":aid", "instance", use: report)
        routes.get("qasummary", ":aid", "instance", use: qaSummary)
    }
    

    private func newInstance(_ req: Request) async throws -> View {
        guard let aidStr = req.parameters.get("aid"),
              let aid = try Int(BenCrypt.decode(aidStr, keys: settings.cryptKeys))
        else {
            throw Abort(.badRequest, reason: "Invalid assessment token")
        }
        let instance = try await ac.new(req, aid: aid)
        return try await req.view.render("QPage", instance)
    }
    
    private func report(_ req: Request) async throws -> View {
        guard let aidStr = req.parameters.get("aid"),
              let instanceStr = req.parameters.get("instance")
        else {
            throw Abort(.badRequest, reason: "Invalid assessment or instance token on request for report")
        }
        let context = try await ac.reportContext(req, aidStr: aidStr, instanceStr: instanceStr)
        return try await req.view.render("Report", context)
    }
    
    private func qaSummary(_ req: Request) async throws -> View {
        guard let aidStr = req.parameters.get("aid"),
              let instanceStr = req.parameters.get("instance")
        else {
            throw Abort(.badRequest, reason: "Invalid assessment or instance token on request for report")
        }
        let context = try await ac.qaSummaryContext(req, aidStr: aidStr, instanceStr: instanceStr)
        return try await req.view.render("QASummary", context)
    }
    
    private func processAssessment(_ req: Request) async throws -> Response {
        let variables = try req.content.decode([String: String].self)
//        for (key, value) in variables {
//            print("\(key): \(value)")
//        }
        let result = try await ac.processResponse(req, variables: variables)
        switch result {
        case .success(let resultContext):
            return try await req.view.render("Report", resultContext).encodeResponse(for: req)
        case .failure(let redirectPath):
            return req.redirect(to: redirectPath)
        }
    }
}
