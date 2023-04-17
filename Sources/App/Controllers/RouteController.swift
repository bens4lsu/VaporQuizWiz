import Fluent
import Vapor

struct RouteController: RouteCollection {
    
    let ac: AssessmentController
    let settings: ConfigurationSettings
    
    init(passports: Passports, settings: ConfigurationSettings) {
        self.ac = AssessmentController(passports: passports)
        self.settings = settings
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
    }

    private func newInstance(_ req: Request) async throws -> Response {
        guard let aidStr = req.parameters.get("aid"),
              let aid = try Int(BenCrypt.decode(aidStr, keys: settings.cryptKeys))
        else {
            throw Abort(.badRequest, reason: "Invalid assessment token")
        }
        
        return try await ac.new(req, aid: aid).encodeResponse(for: req)
    }
    
    //private func presentation(_ req: Request, ) async throws
}
