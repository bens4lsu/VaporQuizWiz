import Vapor
import Leaf

struct WebRouteController: RouteCollection {
    
    let ac: AssessmentController
    let settings: ConfigurationSettings
    let logger: Logger
    
    init(passports: Passports, settings: ConfigurationSettings, logger: Logger) {
        self.ac = AssessmentController(passports: passports)
        self.settings = settings
        self.logger = logger
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(":aid", use: newInstance)
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
    
    //private func presentation(_ req: Request, ) async throws
}
