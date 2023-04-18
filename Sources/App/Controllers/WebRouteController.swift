import Vapor
import Leaf

struct WebRouteController: RouteCollection {
    
    let ac: AssessmentController
    let settings: ConfigurationSettings
    let logger: Logger
    
    init(passports: Passports, settings: ConfigurationSettings, logger: Logger) {
        self.ac = AssessmentController(passports: passports, logger: logger)
        self.settings = settings
        self.logger = logger
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
        routes.post("process_assessment", use: processAssessment)
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
    
    private func processAssessment(_ req: Request) async throws -> Response {
        let variables = try req.content.decode([String: String].self)
        for (key, value) in variables {
            print("\(key): \(value)")
        }
        let result = try await ac.processResults(req, variables: variables)
        return try await result.encodeResponse(for: req)
    }
}
